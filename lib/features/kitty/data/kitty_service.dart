/// Service für Bordkassen-Verwaltung, Salden und Zahlungsanweisungen (Slice S5).
library;

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';
import '../domain/calculation/kitty_engine.dart';
import '../domain/models/kitty_models.dart';
import '../domain/models/receipt_models.dart';

/// Exception wenn beim Löschen eines einzelnen Belegs die physische Bilddatei
/// bereits fehlt (defekte Belegreferenz) und keine explizite Referenzbereinigung
/// (`allowBrokenReferenceCleanup: true`) angefordert wurde (Amendment 3 Finding D).
class ReceiptFileMissingOnDeleteException implements Exception {
  final int receiptId;
  final String filePath;

  /// Relativer Pfad der fehlenden Belegdatei (Alias für [filePath]).
  String get relativePath => filePath;

  const ReceiptFileMissingOnDeleteException({
    required this.receiptId,
    required this.filePath,
  });

  @override
  String toString() =>
      'ReceiptFileMissingOnDeleteException: Physische Belegdatei für Beleg $receiptId fehlt ($filePath). '
      'Keine stille vollständige Löschung gemeldet.';
}


/// Aggregiertes Kassen-Datenobjekt für die Benutzeroberfläche.
class TripKittyData {
  final Trip trip;
  final KittyModel model;
  final List<KittyMember> members;
  final List<KittyExpense> expenses;
  final List<KittyDeposit> deposits;
  final SharedKittyCalculationResult? sharedResult;
  final IndividualSettlementResult? individualResult;

  const TripKittyData({
    required this.trip,
    required this.model,
    required this.members,
    required this.expenses,
    required this.deposits,
    this.sharedResult,
    this.individualResult,
  });

  /// Gibt die Liste der Netto-Salden für alle Crew-Mitglieder zurück.
  List<MemberBalance> get balances =>
      sharedResult?.memberBalances ?? individualResult?.memberBalances ?? const [];

  /// Gibt die Liste der berechneten Ausgleichszahlungen zurück.
  List<PaymentTransfer> get transfers =>
      sharedResult?.settlementTransfers ?? individualResult?.simplifiedTransfers ?? const [];

  /// Gibt das aktuelle Kassen-Guthaben in Cent zurück (Shared Kitty oder historische Kasse).
  int get cashBalanceCents =>
      sharedResult?.currentBalanceInCents ?? individualResult?.currentBalanceInCents ?? 0;

  /// Gibt den Kassenwart zurück.
  KittyMember? get treasurer =>
      sharedResult?.treasurer ??
      individualResult?.treasurer ??
      (trip.treasurerMemberId != null
          ? members.where((m) => m.id == trip.treasurerMemberId).firstOrNull
          : members.where((m) => m.isSkipperFree).firstOrNull ?? members.firstOrNull);
}

/// Eingabe-Objekt zum Erfassen oder Bearbeiten einer Ausgabe (SC-KAS-02, RECEIPT1).
class ExpenseInput {
  final int tripId;
  final String title;
  final int amountInCents;
  final ExpenseCategory category;
  final int? paidByMemberId;
  final bool isPaidFromKitty;
  final Map<int, int>? customSplitInCents;
  final DateTime? createdAt;
  final String? currency;
  final List<DraftReceipt> draftReceipts;

  const ExpenseInput({
    required this.tripId,
    required this.title,
    required this.amountInCents,
    required this.category,
    this.paidByMemberId,
    this.isPaidFromKitty = false,
    this.customSplitInCents,
    this.createdAt,
    this.currency,
    this.draftReceipts = const [],
  });
}

/// Service zur Verwaltung der Bordkassendaten.
class KittyService {
  final TripDao tripDao;
  final ExpenseDao expenseDao;
  final ReceiptFileService receiptFileService;
  final KittyEngine engine;

  KittyService({
    required this.tripDao,
    required this.expenseDao,
    ReceiptFileService? receiptFileService,
    this.engine = const KittyEngine(),
  }) : receiptFileService = BackupCoordinator.resolveReceiptFileService(
          tripDao.attachedDatabase,
          receiptFileService,
        );

  Future<T> _runGuarded<T>(String operationName, Future<T> Function() action) {
    return BackupCoordinator.runSynchronizedStorageOperation<T>(
      db: tripDao.attachedDatabase,
      receiptFileService: receiptFileService,
      operationName: operationName,
      action: action,
    );
  }

  /// Lädt den vollständigen Kassenstand inklusive Salden und Abrechnung.
  /// Führt vor dem ersten Datenzugriff die App-/Storage-Recovery (inkl. Papierkorb-TTL) aus (R2, Amendment 3 Finding B & Amendment 5 Finding G).
  Future<TripKittyData> loadKittyData(int tripId) async {
    return _runGuarded('loadKittyData', () async {
      await receiptFileService.cleanupExpiredTrash();

      final trip = await tripDao.getTripById(tripId);
      if (trip == null) {
        throw TripNotFoundException('Törn $tripId nicht gefunden.');
      }

      final rawCrew = await tripDao.getCrewForTrip(tripId);
      final rawExpenses = await expenseDao.getExpensesForTrip(tripId);
      final rawDeposits = await expenseDao.getKittyPaymentsForTrip(tripId);
      final rawReceipts = await expenseDao.getReceiptsForTrip(tripId);

      final receiptsByExpense = <int, List<ExpenseReceiptItem>>{};
      for (final r in rawReceipts) {
        receiptsByExpense.putIfAbsent(r.expenseId, () => []).add(
          ExpenseReceiptItem(
            id: r.id,
            tripId: r.tripId,
            expenseId: r.expenseId,
            filePath: r.filePath,
            fileName: r.fileName,
            byteSize: r.byteSize,
            sortOrder: r.sortOrder,
            createdAt: r.createdAt,
          ),
        );
      }

      for (final list in receiptsByExpense.values) {
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }

      final members = rawCrew.map(_mapCrewMember).toList();
      final expenses = rawExpenses.map((e) => _mapExpense(e, receiptsByExpense[e.id])).toList();
      final deposits = rawDeposits.map(_mapDeposit).toList();

      final model = trip.kittyModel;

      SharedKittyCalculationResult? sharedRes;
      IndividualSettlementResult? indRes;

      if (model == KittyModel.sharedKitty) {
        sharedRes = engine.calculateSharedKitty(
          members: members,
          deposits: deposits,
          expenses: expenses,
          treasurerMemberId: trip.treasurerMemberId,
          currency: trip.currency,
        );
      } else {
        indRes = engine.calculateIndividualSettlement(
          members: members,
          expenses: expenses,
          deposits: deposits,
          treasurerMemberId: trip.treasurerMemberId,
          currency: trip.currency,
        );
      }

      return TripKittyData(
        trip: trip,
        model: model,
        members: members,
        expenses: expenses,
        deposits: deposits,
        sharedResult: sharedRes,
        individualResult: indRes,
      );
    });
  }

  KittyMember _mapCrewMember(CrewMember c) {
    Map<ExpenseCategory, bool> partMap = {};
    try {
      final jsonMap = json.decode(c.categoryParticipation) as Map<String, dynamic>;
      if (jsonMap['all'] == true) {
        partMap = {for (final cat in ExpenseCategory.values) cat: true};
      } else {
        for (final cat in ExpenseCategory.values) {
          partMap[cat] = jsonMap[cat.rawValue] == true;
        }
      }
    } catch (_) {
      partMap = {for (final cat in ExpenseCategory.values) cat: true};
    }

    return KittyMember(
      id: c.id,
      name: c.name,
      isSkipperFree: c.isSkipperFree,
      skipperFreeScope: c.skipperFreeScope,
      categoryParticipation: partMap,
      iban: c.iban,
      paypalLink: c.paypalLink,
      revolutLink: c.revolutLink,
    );
  }

  KittyExpense _mapExpense(Expense e, [List<ExpenseReceiptItem>? receipts]) {
    Map<int, int>? customSplit;
    if (e.customSplit != null && e.customSplit!.isNotEmpty) {
      try {
        final splitJson = json.decode(e.customSplit!) as Map<String, dynamic>;
        customSplit = splitJson.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      } catch (_) {}
    }

    return KittyExpense(
      id: e.id,
      tripId: e.tripId,
      title: e.note ?? e.category.displayName,
      amountInCents: (e.amount * 100).round(),
      currency: e.currency,
      category: e.category,
      paidByMemberId: e.paidByCrewMemberId,
      isPaidFromKitty: e.isPaidFromKitty,
      createdAt: e.createdAt,
      customSplitInCents: customSplit,
      receipts: receipts ?? const [],
    );
  }

  KittyDeposit _mapDeposit(KittyPayment p) {
    return KittyDeposit(
      id: p.id,
      tripId: p.tripId,
      memberId: p.crewMemberId,
      amountInCents: (p.amount * 100).round(),
      paidAt: p.paidAt,
    );
  }

  void _validateExpenseInput(
    ExpenseInput input, [
    List<CrewMember>? crewMembers,
    String? tripCurrency,
  ]) {
    if (input.isPaidFromKitty && input.paidByMemberId != null) {
      throw ArgumentError(
        'Ungültige Zahlungsquelle: Kassenausgaben dürfen keinen persönlichen Zahler haben (paidByMemberId muss null sein).',
      );
    }
    if (!input.isPaidFromKitty && input.paidByMemberId == null) {
      throw ArgumentError(
        'Ungültige Zahlungsquelle: Personenausgaben müssen ein Crew-Mitglied als Zahler haben (paidByMemberId darf nicht null sein).',
      );
    }
    if (input.paidByMemberId != null && crewMembers != null) {
      if (!crewMembers.any((c) => c.id == input.paidByMemberId)) {
        throw ArgumentError(
          'Zahler für Ausgabe (ID: ${input.paidByMemberId}) ist nicht in den Crew-Mitgliedern enthalten.',
        );
      }
    }
    if (input.currency != null && tripCurrency != null && input.currency != tripCurrency) {
      throw ArgumentError(
        'Währung der Ausgabe (${input.currency}) weicht von der Törn-Währung ($tripCurrency) ab.',
      );
    }
    if (input.customSplitInCents != null && input.customSplitInCents!.isNotEmpty) {
      int splitSum = 0;
      for (final entry in input.customSplitInCents!.entries) {
        if (entry.value < 0) {
          throw ArgumentError(
            'CustomSplit-Anteil darf nicht negativ sein (Mitglied ${entry.key}: ${entry.value} Cent).',
          );
        }
        if (crewMembers != null && !crewMembers.any((c) => c.id == entry.key)) {
          throw ArgumentError(
            'CustomSplit enthält ungültiges/fremdes Mitglied ID ${entry.key}.',
          );
        }
        splitSum += entry.value;
      }
      if (splitSum != input.amountInCents) {
        throw ArgumentError(
          'CustomSplit-Summe ($splitSum Cent) entspricht nicht dem Ausgabenbetrag (${input.amountInCents} Cent).',
        );
      }
    }
  }

  /// Erfasst eine neue Ausgabe (SC-KAS-02, RECEIPT1).
  Future<int> addExpense(ExpenseInput input) async {
    return _runGuarded('addExpense', () async {
      final trip = await tripDao.getTripById(input.tripId);
      final crew = await tripDao.getCrewForTrip(input.tripId);
      _validateExpenseInput(input, crew, trip?.currency);
      final effectiveCurrency = input.currency ?? trip?.currency ?? 'EUR';
      final euros = input.amountInCents / 100.0;
      String? splitJson;
      if (input.customSplitInCents != null) {
        final strMap = input.customSplitInCents!.map((k, v) => MapEntry(k.toString(), v));
        splitJson = json.encode(strMap);
      }

      final expenseId = await expenseDao.addExpense(
        ExpensesCompanion.insert(
          tripId: input.tripId,
          amount: euros,
          currency: Value(effectiveCurrency),
          category: input.category,
          note: Value(input.title),
          isPaidFromKitty: Value(input.isPaidFromKitty),
          paidByCrewMemberId: Value(input.paidByMemberId),
          customSplit: Value(splitJson),
          createdAt: Value(input.createdAt ?? DateTime.now()),
        ),
      );

      final savedFiles = <String>[];
      try {
        if (input.draftReceipts.isNotEmpty) {
          for (var i = 0; i < input.draftReceipts.length; i++) {
            final draft = input.draftReceipts[i];
            final processed = await receiptFileService.saveReceiptImage(
              tripId: input.tripId,
              expenseId: expenseId,
              imageBytes: draft.bytes,
              preferredFileName: draft.fileName,
            );
            savedFiles.add(processed.relativePath);
            await expenseDao.addReceipt(
              ExpenseReceiptsCompanion.insert(
                tripId: input.tripId,
                expenseId: expenseId,
                filePath: processed.filePath,
                fileName: processed.fileName,
                byteSize: Value(processed.byteSize),
                sortOrder: Value(i),
                createdAt: Value(draft.createdAt),
              ),
            );
          }
        }
      } catch (e) {
        for (final f in savedFiles) {
          try {
            await receiptFileService.deleteReceiptFile(f);
          } catch (_) {}
        }
        try {
          await receiptFileService.deleteExpenseReceiptFolder(input.tripId, expenseId);
        } catch (_) {}
        await expenseDao.deleteExpense(expenseId);
        rethrow;
      }

      return expenseId;
    });
  }

  /// Fügt einer bestehenden Ausgabe einen Beleg hinzu (RECEIPT1 & R2: Rollback der Datei bei DB-Fehler).
  Future<ExpenseReceiptItem> addReceiptToExpense({
    required int tripId,
    required int expenseId,
    required Uint8List imageBytes,
    String? preferredFileName,
    int? sortOrder,
  }) async {
    return _runGuarded('addReceiptToExpense', () async {
      final expense = await expenseDao.getExpenseById(expenseId);
      if (expense == null) {
        throw ArgumentError('Ausgabe mit ID $expenseId existiert nicht.');
      }
      if (expense.tripId != tripId) {
        throw ArgumentError(
          'Ausgabe $expenseId gehört nicht zu Törn $tripId (sondern zu Törn ${expense.tripId}).',
        );
      }

      final existing = await expenseDao.getReceiptsForExpense(expenseId);
      final effectiveSortOrder = sortOrder ?? existing.length;

      final processed = await receiptFileService.saveReceiptImage(
        tripId: tripId,
        expenseId: expenseId,
        imageBytes: imageBytes,
        preferredFileName: preferredFileName,
      );

      final int id;
      try {
        id = await expenseDao.addReceipt(
          ExpenseReceiptsCompanion.insert(
            tripId: tripId,
            expenseId: expenseId,
            filePath: processed.filePath,
            fileName: processed.fileName,
            byteSize: Value(processed.byteSize),
            sortOrder: Value(effectiveSortOrder),
            createdAt: Value(DateTime.now()),
          ),
        );
      } catch (e) {
        // R2: Wenn das DB-Insert scheitert, darf keine neue verwaiste Bilddatei zurückbleiben.
        try {
          await receiptFileService.deleteReceiptFile(processed.filePath);
          if (existing.isEmpty) {
            await receiptFileService.deleteExpenseReceiptFolder(tripId, expenseId);
          }
        } catch (_) {}
        rethrow;
      }

      return ExpenseReceiptItem(
        id: id,
        tripId: tripId,
        expenseId: expenseId,
        filePath: processed.filePath,
        fileName: processed.fileName,
        byteSize: processed.byteSize,
        sortOrder: effectiveSortOrder,
        createdAt: DateTime.now(),
      );
    });
  }

  /// Löscht einen Beleg aus DB und Dateisystem (RECEIPT1, R2 & Amendment 3 Finding D).
  ///
  /// Dokumentierte Architekturentscheidung für defekte Belegreferenzen (Finding D):
  /// - `deleteReceiptFile()` liefert `true`, wenn die physische Datei existierte und gelöscht wurde,
  ///   und `false`, wenn die physische Datei bereits fehlte (defekte Belegreferenz).
  /// - Im Standardbetrieb ([allowBrokenReferenceCleanup] == `false`) wird bei fehlender physischer Datei
  ///   KEINE unbemerkte erfolgreiche Löschung gemeldet und der DB-Datensatz nicht still gelöscht,
  ///   sondern [ReceiptFileMissingOnDeleteException] geworfen.
  /// - Soll eine bereits als defekt erkannte Belegreferenz gezielt bereinigt werden, kann der Aufrufer
  ///   explizit `allowBrokenReferenceCleanup: true` übergeben.
  /// - Scheitert die DB-Löschung (Exception oder `count == 0`), nachdem die physische Datei gelöscht wurde,
  ///   werden die zuvor gesicherten Datei-Bytes über `writeReceiptBytesAtPath` konsistent wiederhergestellt.
  Future<bool> deleteReceipt(
    int receiptId, {
    bool allowBrokenReferenceCleanup = false,
  }) async {
    return _runGuarded('deleteReceipt', () async {
      final receipt = await expenseDao.getReceiptById(receiptId);
      if (receipt == null) return false;

      final backupBytes = await receiptFileService.readReceiptBytes(receipt.filePath);
      final fileDeleted = await receiptFileService.deleteReceiptFile(receipt.filePath);

      if (!fileDeleted || backupBytes == null) {
        if (!allowBrokenReferenceCleanup) {
          throw ReceiptFileMissingOnDeleteException(
            receiptId: receiptId,
            filePath: receipt.filePath,
          );
        }
        final count = await expenseDao.deleteReceipt(receiptId);
        return count > 0;
      }

      try {
        final count = await expenseDao.deleteReceipt(receiptId);
        if (count <= 0) {
          await receiptFileService.writeReceiptBytesAtPath(receipt.filePath, backupBytes);
          return false;
        }
        return true;
      } catch (e) {
        await receiptFileService.writeReceiptBytesAtPath(receipt.filePath, backupBytes);
        rethrow;
      }
    });
  }


  /// Erfasst eine Einzahlung in die Bordkasse (SC-KAS-03).
  Future<int> addDeposit({
    required int tripId,
    required int memberId,
    required int amountInCents,
  }) async {
    return _runGuarded('addDeposit', () async {
      final euros = amountInCents / 100.0;
      return expenseDao.addKittyPayment(
        KittyPaymentsCompanion.insert(
          tripId: tripId,
          crewMemberId: memberId,
          amount: euros,
          paidAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Aktualisiert das Kassenmodell für den Törn (Bordkasse vs. Einzelabrechnung).
  Future<bool> switchKittyModel(int tripId, KittyModel newModel) async {
    return _runGuarded('switchKittyModel', () async {
      final trip = await tripDao.getTripById(tripId);
      if (trip == null) return false;
      return tripDao.updateTrip(trip.copyWith(kittyModel: newModel));
    });
  }

  /// Aktualisiert die Kategoriebeteiligung eines Mitglieds (SC-KAS-04).
  Future<bool> updateMemberParticipation({
    required int memberId,
    required Map<ExpenseCategory, bool> participation,
    required bool isSkipperFree,
    String? skipperFreeScope,
  }) async {
    return _runGuarded('updateMemberParticipation', () async {
      final crew = await tripDao.db.select(tripDao.db.crewMembers).get();
      final member = crew.where((c) => c.id == memberId).firstOrNull;
      if (member == null) return false;

      final jsonMap = participation.map((k, v) => MapEntry(k.rawValue, v));
      final updated = member.copyWith(
        categoryParticipation: json.encode(jsonMap),
        isSkipperFree: isSkipperFree,
        skipperFreeScope: Value(skipperFreeScope),
      );
      return tripDao.updateCrewMember(updated);
    });
  }

  /// Löscht eine Ausgabe (R2: konsistente Behandlung von Datei- und DB-Fehlern).
  /// Standardmäßig wird bei [softDelete] = true der Belegordner für das Undo-Fenster
  /// in den temporären Papierkorb verschoben; bei [softDelete] = false wird nach
  /// erfolgreichem DB-Delete auch der Papierkorb geleert.
  Future<int> deleteExpense(int id, {bool softDelete = true}) async {
    return _runGuarded('deleteExpense', () async {
      final expense = await expenseDao.getExpenseById(id);
      if (expense == null) {
        return expenseDao.deleteExpense(id);
      }

      await receiptFileService.moveToTrash(expense.tripId, id);

      final int deletedCount;
      try {
        deletedCount = await expenseDao.deleteExpense(id);
      } catch (e) {
        try {
          await receiptFileService.restoreFromTrash(expense.tripId, id);
        } catch (_) {}
        rethrow;
      }

      if (!softDelete) {
        try {
          await receiptFileService.purgeTrash(tripId: expense.tripId, expenseId: id);
        } catch (e) {
          // DB ist bereits gelöscht, Fehler weitergeben
          rethrow;
        }
      }

      return deletedCount;
    });
  }

  /// Löscht Belege einer gelöschten Ausgabe endgültig aus dem Papierkorb nach Ablauf des Undo-Fensters.
  Future<void> purgeDeletedExpenseReceipts(int tripId, int expenseId) async {
    return _runGuarded('purgeDeletedExpenseReceipts', () async {
      return receiptFileService.purgeTrash(tripId: tripId, expenseId: expenseId);
    });
  }

  /// Aktualisiert eine bestehende Ausgabe (FEEDBACK_R1 Punkt 8).
  Future<bool> updateExpense({
    required int id,
    required ExpenseInput input,
  }) async {
    return _runGuarded('updateExpense', () async {
      final trip = await tripDao.getTripById(input.tripId);
      final crew = await tripDao.getCrewForTrip(input.tripId);
      final allExpenses = await expenseDao.getExpensesForTrip(input.tripId);
      final existing = allExpenses.where((e) => e.id == id).firstOrNull;
      _validateExpenseInput(input, crew, trip?.currency);
      final effectiveCurrency = input.currency ?? existing?.currency ?? trip?.currency ?? 'EUR';
      final euros = input.amountInCents / 100.0;
      String? splitJson;
      if (input.customSplitInCents != null) {
        final strMap = input.customSplitInCents!.map((k, v) => MapEntry(k.toString(), v));
        splitJson = json.encode(strMap);
      }

      return expenseDao.updateExpense(
        Expense(
          id: id,
          tripId: input.tripId,
          amount: euros,
          currency: effectiveCurrency,
          category: input.category,
          paidByCrewMemberId: input.paidByMemberId,
          isPaidFromKitty: input.isPaidFromKitty,
          customSplit: splitJson,
          note: input.title,
          createdAt: input.createdAt ?? existing?.createdAt ?? DateTime.now(),
        ),
      );
    });
  }

  /// Stellt eine gelöschte Ausgabe samt Belegen transaktions- und dateisystemsicher wieder her (Undo, R2).
  Future<int> restoreExpense(KittyExpense exp) async {
    return _runGuarded('restoreExpense', () async {
      if (exp.isPaidFromKitty && exp.paidByMemberId != null) {
        throw ArgumentError(
          'Ungültige Zahlungsquelle für Wiederherstellung: Kassenausgaben dürfen keinen persönlichen Zahler haben.',
        );
      }
      if (!exp.isPaidFromKitty && exp.paidByMemberId == null) {
        throw ArgumentError(
          'Ungültige Zahlungsquelle für Wiederherstellung: Personenausgaben müssen ein Crew-Mitglied als Zahler haben.',
        );
      }

      bool filesRestored = false;
      try {
        return await expenseDao.db.transaction(() async {
          final newId = await expenseDao.addExpense(
            ExpensesCompanion.insert(
              id: Value(exp.id),
              tripId: exp.tripId,
              amount: exp.amountInCents / 100.0,
              currency: Value(exp.currency),
              category: exp.category,
              note: Value(exp.title),
              isPaidFromKitty: Value(exp.isPaidFromKitty),
              paidByCrewMemberId: Value(exp.paidByMemberId),
              customSplit: Value(
                exp.customSplitInCents != null
                    ? json.encode(exp.customSplitInCents!.map((k, v) => MapEntry(k.toString(), v)))
                    : null,
              ),
              createdAt: Value(exp.createdAt),
            ),
          );

          for (final r in exp.receipts) {
            await expenseDao.addReceipt(
              ExpenseReceiptsCompanion.insert(
                id: Value(r.id),
                tripId: exp.tripId,
                expenseId: exp.id,
                filePath: r.filePath,
                fileName: r.fileName,
                byteSize: Value(r.byteSize),
                sortOrder: Value(r.sortOrder),
                createdAt: Value(r.createdAt),
              ),
            );
          }

          // Belege im Dateisystem aus dem Papierkorb wiederherstellen
          await receiptFileService.restoreFromTrash(exp.tripId, exp.id);
          filesRestored = true;

          // Prüfe, dass alle erwarteten Belegdateien tatsächlich im aktiven Verzeichnis existieren
          for (final r in exp.receipts) {
            final bytes = await receiptFileService.readReceiptBytes(r.filePath);
            if (bytes == null || bytes.isEmpty) {
              throw StateError(
                'Wiederherstellung fehlgeschlagen: Belegdatei ${r.filePath} für Ausgabe ${exp.id} wurde im Papierkorb nicht gefunden.',
              );
            }
          }

          return newId;
        });
      } catch (e) {
        if (filesRestored) {
          try {
            await receiptFileService.moveToTrash(exp.tripId, exp.id);
          } catch (_) {}
        }
        rethrow;
      }
    });
  }

  /// Aktualisiert die Zahlungsdaten eines Crew-Mitglieds (FEEDBACK_R1 Punkt 10).
  Future<bool> updateMemberPaymentDetails({
    required int memberId,
    String? iban,
    String? paypalLink,
    String? revolutLink,
  }) async {
    return _runGuarded('updateMemberPaymentDetails', () async {
      return tripDao.updateCrewMemberPaymentDetails(
        memberId: memberId,
        iban: iban,
        paypalLink: paypalLink,
        revolutLink: revolutLink,
      );
    });
  }

  /// Aktualisiert den Kassenwart eines Törns (FB1-D).
  Future<bool> setTreasurer(int tripId, int? memberId) async {
    return _runGuarded('setTreasurer', () async {
      return tripDao.setTripTreasurer(tripId, memberId);
    });
  }

  /// Löscht eine Einzahlung.
  Future<int> deleteDeposit(int id) async {
    return _runGuarded('deleteDeposit', () async {
      return expenseDao.deleteKittyPayment(id);
    });
  }

  /// Archiviert den Törn nach erfolgreicher Kassenabrechnung.
  Future<bool> archiveTrip(int tripId) async {
    return _runGuarded('archiveTrip', () async {
      final trip = await tripDao.getTripById(tripId);
      if (trip == null) return false;
      return tripDao.updateTrip(
        trip.copyWith(
          isArchived: true,
          phase: TripPhase.conclusion,
        ),
      );
    });
  }
}

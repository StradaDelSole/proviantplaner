/// Service für Bordkassen-Verwaltung, Salden und Zahlungsanweisungen (Slice S5).
library;

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';
import '../domain/calculation/kitty_engine.dart';
import '../domain/models/kitty_models.dart';
import '../domain/models/receipt_models.dart';


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
  }) : receiptFileService = receiptFileService ?? ReceiptFileService();

  /// Lädt den vollständigen Kassenstand inklusive Salden und Abrechnung.
  Future<TripKittyData> loadKittyData(int tripId) async {
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
        await receiptFileService.deleteReceiptFile(f);
      }
      await receiptFileService.deleteExpenseReceiptFolder(input.tripId, expenseId);
      await expenseDao.deleteExpense(expenseId);
      rethrow;
    }

    return expenseId;
  }

  /// Fügt einer bestehenden Ausgabe einen Beleg hinzu (RECEIPT1).
  Future<ExpenseReceiptItem> addReceiptToExpense({
    required int tripId,
    required int expenseId,
    required Uint8List imageBytes,
    String? preferredFileName,
    int? sortOrder,
  }) async {
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

    final id = await expenseDao.addReceipt(
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
  }

  /// Löscht einen Beleg aus DB und Dateisystem (RECEIPT1).
  Future<bool> deleteReceipt(int receiptId) async {
    final receipt = await expenseDao.getReceiptById(receiptId);
    if (receipt == null) return false;

    await receiptFileService.deleteReceiptFile(receipt.filePath);
    final count = await expenseDao.deleteReceipt(receiptId);
    return count > 0;
  }


  /// Erfasst eine Einzahlung in die Bordkasse (SC-KAS-03).
  Future<int> addDeposit({
    required int tripId,
    required int memberId,
    required int amountInCents,
  }) {
    final euros = amountInCents / 100.0;
    return expenseDao.addKittyPayment(
      KittyPaymentsCompanion.insert(
        tripId: tripId,
        crewMemberId: memberId,
        amount: euros,
        paidAt: Value(DateTime.now()),
      ),
    );
  }

  /// Aktualisiert das Kassenmodell für den Törn (Bordkasse vs. Einzelabrechnung).
  Future<bool> switchKittyModel(int tripId, KittyModel newModel) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) return false;
    return tripDao.updateTrip(trip.copyWith(kittyModel: newModel));
  }

  /// Aktualisiert die Kategoriebeteiligung eines Mitglieds (SC-KAS-04).
  Future<bool> updateMemberParticipation({
    required int memberId,
    required Map<ExpenseCategory, bool> participation,
    required bool isSkipperFree,
    String? skipperFreeScope,
  }) async {
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
  }

  /// Löscht eine Ausgabe.
  /// Standardmäßig wird bei [softDelete] = true der Belegordner für das 5-Sekunden-Undo-Fenster
  /// in den temporären Papierkorb verschoben statt sofort unwiderruflich gelöscht.
  Future<int> deleteExpense(int id, {bool softDelete = true}) async {
    final expense = await expenseDao.getExpenseById(id);
    if (expense != null) {
      if (softDelete) {
        await receiptFileService.moveToTrash(expense.tripId, id);
      } else {
        await receiptFileService.deleteExpenseReceiptFolder(expense.tripId, id);
      }
    }
    return expenseDao.deleteExpense(id);
  }

  /// Löscht Belege einer gelöschten Ausgabe endgültig aus dem Papierkorb nach Ablauf des Undo-Fensters.
  Future<void> purgeDeletedExpenseReceipts(int tripId, int expenseId) {
    return receiptFileService.purgeTrash(tripId: tripId, expenseId: expenseId);
  }

  /// Aktualisiert eine bestehende Ausgabe (FEEDBACK_R1 Punkt 8).
  Future<bool> updateExpense({
    required int id,
    required ExpenseInput input,
  }) async {
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
  }

  /// Stellt eine gelöschte Ausgabe wieder her (Rückgängig-Funktion).
  Future<int> restoreExpense(KittyExpense exp) async {
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

    // Belege im Dateisystem aus dem Papierkorb wiederherstellen
    await receiptFileService.restoreFromTrash(exp.tripId, exp.id);

    // Belege wiederherstellen, falls vorhanden
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

    return newId;
  }

  /// Aktualisiert die Zahlungsdaten eines Crew-Mitglieds (FEEDBACK_R1 Punkt 10).
  Future<bool> updateMemberPaymentDetails({
    required int memberId,
    String? iban,
    String? paypalLink,
    String? revolutLink,
  }) {
    return tripDao.updateCrewMemberPaymentDetails(
      memberId: memberId,
      iban: iban,
      paypalLink: paypalLink,
      revolutLink: revolutLink,
    );
  }

  /// Aktualisiert den Kassenwart eines Törns (FB1-D).
  Future<bool> setTreasurer(int tripId, int? memberId) {
    return tripDao.setTripTreasurer(tripId, memberId);
  }

  /// Löscht eine Einzahlung.
  Future<int> deleteDeposit(int id) => expenseDao.deleteKittyPayment(id);

  /// Archiviert den Törn nach erfolgreicher Kassenabrechnung.
  Future<bool> archiveTrip(int tripId) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) return false;
    return tripDao.updateTrip(
      trip.copyWith(
        isArchived: true,
        phase: TripPhase.conclusion,
      ),
    );
  }
}

/// Koordinator für Datensicherung und Wiederherstellung (Slice S8).
/// Serialisiert alle SQLite-Tabellen in JSON und stellt sie transaktionssicher wieder her.
library;

import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/hullq_backup_service.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

/// Exception wenn eine referenzierte Belegdatei fehlt oder unlesbar ist (Finding A & R3).
class BackupIntegrityException implements Exception {
  final String message;
  const BackupIntegrityException(this.message);
  @override
  String toString() => 'BackupIntegrityException: $message';
}

/// Exception wenn die Beleg-Gesamtgröße im Backup das Limit überschreitet (Finding F).
class BackupSizeLimitExceededException implements Exception {
  final String message;
  final int totalBytes;
  final int maxBytes;
  const BackupSizeLimitExceededException({
    required this.message,
    required this.totalBytes,
    required this.maxBytes,
  });
  @override
  String toString() => 'BackupSizeLimitExceededException: $message';
}

/// Exception wenn ein Backup-Datensatz korrupt oder unvollständig ist (Finding A, C & R3).
class BackupCorruptException implements Exception {
  final String message;
  const BackupCorruptException(this.message);
  @override
  String toString() => 'BackupCorruptException: $message';
}

/// Exception wenn nach einem Prozessabbruch ein unklarer oder widersprüchlicher
/// Restore-Zustand vorliegt, der nicht eindeutig sicher aufgelöst werden kann (Amendment 3 Finding A & B).
/// In diesem Fall wird keine destruktive Operation ausgeführt und der Datenzugriff
/// explizit als nicht verfügbar gemeldet.
class RestoreRecoveryException implements Exception {
  final String message;
  const RestoreRecoveryException(this.message);
  @override
  String toString() => 'RestoreRecoveryException: $message';
}

/// Verwaltet den Export aller lokalen Törndaten in die Cloud und den Import daraus.
class BackupCoordinator {
  static int _restoreNonce = 0;

  final AppDatabase _db;
  final HullqBackupService _backupService;
  final HullqAuthService _authService;
  final ReceiptFileService _receiptFileService;

  BackupCoordinator({
    required AppDatabase db,
    required HullqBackupService backupService,
    required HullqAuthService authService,
    ReceiptFileService? receiptFileService,
  })  : _db = db,
        _backupService = backupService,
        _authService = authService,
        _receiptFileService = receiptFileService ?? ReceiptFileService();

  /// Prüft, ob eine Sicherung in der Cloud existiert.
  Future<bool> hasBackup() async {
    final data = await _backupService.restoreData();
    return data != null && data.isNotEmpty;
  }

  /// Maximale Gesamtgröße aller Belege in einem Cloud-Backup (50 MB) zum Schutz vor Speicher-/Worker-Limits.
  static const int defaultMaxBackupReceiptBytes = 50 * 1024 * 1024;

  static Future<void> _writeDbRestoreToken(AppDatabase db, String restoreToken) async {
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS _provy_restore_state ('
      'id INTEGER PRIMARY KEY CHECK (id = 1), '
      'restore_token TEXT NOT NULL, '
      'committed_at TEXT NOT NULL'
      ')',
    );
    await db.customStatement(
      'INSERT OR REPLACE INTO _provy_restore_state (id, restore_token, committed_at) VALUES (1, ?, ?)',
      [restoreToken, DateTime.now().toIso8601String()],
    );
  }

  static Future<String?> _readDbRestoreToken(AppDatabase db) async {
    try {
      final row = await db
          .customSelect('SELECT restore_token FROM _provy_restore_state WHERE id = 1')
          .getSingleOrNull();
      return row?.read<String>('restore_token');
    } catch (_) {
      return null;
    }
  }

  /// Statischer, einmalig beim App-Start sowie vor Lese-/Schreibzugriffen ausgeführter
  /// Recovery-Pfad (R1, Amendment 3 Finding A, B, C).
  ///
  /// Trennt strikt zwischen:
  /// 1. **Erfolgreich committet (Roll-Forward):** Der SQLite-Commit-Nachweis (`_provy_restore_state.restore_token`
  ///    bzw. konsistente erwartete Belegpfade) liegt vor und alle neuen Dateien sind in `receipts/` vorhanden
  ///    -> bereinigt `receipts_rollback/` und `restore_journal.json`.
  /// 2. **Noch nicht committet (Roll-Back):** SQLite hat die Transaktion nicht committet, die DB-Belegpfade
  ///    entsprechen dem Vor-Restore-Zustand und alle vorherigen Dateien sind in `receipts_rollback/`
  ///    vollständig vorhanden -> stellt `receipts_rollback/` nach `receipts/` wieder her.
  /// 3. **Unklarer Zustand nach Crash:** Fehlt das Journal bei vorhandenem Rollback-Ordner, ist das Journal
  ///    beschädigt oder fehlen für den jeweiligen Pfad benötigte Belegdateien -> **niemals blind zurückrollen
  ///    oder löschen**; wirft [RestoreRecoveryException].
  static Future<void> recoverStorageState({
    required AppDatabase db,
    required ReceiptFileService receiptFileService,
  }) async {
    final docsDir = await receiptFileService.getDocsDir();
    final hasArtifacts = receiptFileService.hasPendingRecoveryArtifactsSync(docsDir);
    if (!hasArtifacts && receiptFileService.isInitialRecoveryCompleted) {
      return;
    }

    await receiptFileService.runSingleFlightRecovery(() async {
      await _performRestoreAndTripDeleteRecovery(
        db: db,
        receiptFileService: receiptFileService,
        docsDir: docsDir,
      );
    });
  }

  static Future<void> _performRestoreAndTripDeleteRecovery({
    required AppDatabase db,
    required ReceiptFileService receiptFileService,
    required Directory docsDir,
  }) async {
    final journal = await receiptFileService.readRestoreJournal();
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_rollback'));
    final stagedActiveDir = Directory(p.join(docsDir.path, 'receipts_staging_active'));
    final stagingDir = Directory(p.join(docsDir.path, 'receipts_staging'));

    final hasJournal = journal != null;
    final hasRollback = rollbackDir.existsSync();
    final hasStagedActive = stagedActiveDir.existsSync();
    final hasStaging = stagingDir.existsSync();

    if (hasJournal || hasRollback || hasStagedActive || hasStaging) {
      // Amendment 4 – Finding E: Crash nach dem Anlegen von receipts_staging_active/ (bzw. receipts_staging/),
      // aber VOR writeRestoreJournal() und VOR promoteStagedReceipts():
      // Es existiert ausschließlich ein Staging-Artefakt ohne Journal und ohne Rollback-Verzeichnis.
      if (!hasJournal && !hasRollback) {
        final currentDbReceipts = await db.select(db.expenseReceipts).get();
        for (final r in currentDbReceipts) {
          final relPath = p.posix.normalize(r.filePath.replaceAll('\\', '/'));
          if (relPath.startsWith('receipts_staging') || relPath.startsWith('receipts_rollback')) {
            throw RestoreRecoveryException(
              'Unklarer Staging-Zustand ohne Journal: DB-Beleg "$relPath" verweist auf ein Staging-/Rollback-Verzeichnis. '
              'Keine destruktive Operation ausgeführt.',
            );
          }
          final activeFile = File(p.join(docsDir.path, relPath));
          if (!activeFile.existsSync() || activeFile.lengthSync() <= 0) {
            throw RestoreRecoveryException(
              'Unklarer Staging-Zustand ohne Journal: Produktive Belegdatei "$relPath" fehlt oder ist leer. '
              'Staging-Artefakte werden zum Schutz vor Datenverlust nicht gelöscht.',
            );
          }
          if (r.byteSize > 0 && activeFile.lengthSync() != r.byteSize) {
            throw RestoreRecoveryException(
              'Unklarer Staging-Zustand ohne Journal: Produktive Belegdatei "$relPath" weicht von der erwarteten Dateigröße ab. '
              'Staging-Artefakte werden zum Schutz vor Datenverlust nicht gelöscht.',
            );
          }
        }

        // Alle produktiven DB-Belegdateien sind nachweislich vollständig und unverändert in receipts/ vorhanden ->
        // Verwaiste Vor-Journal-Staging-Artefakte sicher und wiederholbar bereinigen.
        await receiptFileService.cleanPreJournalStagingArtifacts();
      } else {
        if (journal == null || journal['corrupt'] == true) {
          throw const RestoreRecoveryException(
            'Unklarer Restore-Zustand nach Prozessabbruch: Recovery-Journal fehlt oder ist beschädigt. '
            'Keine destruktive Operation ausgeführt.',
          );
        }

        final expectedRaw = journal['expectedReceiptPaths'];
        if (expectedRaw is! List) {
          throw const RestoreRecoveryException(
            'Unklarer Restore-Zustand: expectedReceiptPaths im Recovery-Journal ungültig. '
            'Keine destruktive Operation ausgeführt.',
          );
        }

        final expectedPaths =
            expectedRaw.map((e) => p.posix.normalize(e.toString().replaceAll('\\', '/'))).toSet();
        final previousRaw = journal['previousReceiptPaths'] as List<dynamic>?;
        final previousPaths = previousRaw
            ?.map((e) => p.posix.normalize(e.toString().replaceAll('\\', '/')))
            .toSet();
        final journalToken = journal['restoreToken'] as String?;
        final phase = journal['phase'] as String?;

        final dbRestoreToken = await _readDbRestoreToken(db);
        final currentDbReceipts = await db.select(db.expenseReceipts).get();
        final currentDbPaths =
            currentDbReceipts.map((r) => p.posix.normalize(r.filePath.replaceAll('\\', '/'))).toSet();

        final dbMatchesExpected =
            currentDbPaths.length == expectedPaths.length && currentDbPaths.containsAll(expectedPaths);

        // Belastbarer Commit-Nachweis:
        // Wenn ein restoreToken im Journal hinterlegt ist, entscheidet der in derselben SQLite-Transaktion
        // committete `_provy_restore_state`-Token (bzw. `phase == 'committed'`).
        // Für Token-lose Legacy-Journale gilt der Abgleich gegen nicht-leere `expectedPaths`.
        final bool isCommittedInDb;
        if (journalToken != null) {
          isCommittedInDb = (dbRestoreToken == journalToken) || (phase == 'committed' && dbMatchesExpected);
        } else {
          isCommittedInDb =
              (phase == 'committed' && dbMatchesExpected) || (expectedPaths.isNotEmpty && dbMatchesExpected);
        }

        if (isCommittedInDb) {
          // Fall 1: Erfolgreich committet -> ausschließlich Roll-Forward! Niemals alte Dateien aktivieren!
          if (!dbMatchesExpected) {
            throw const RestoreRecoveryException(
              'Widersprüchlicher Post-Commit-Zustand: SQLite-Commit-Token liegt vor, aber DB-Belegpfade '
              'weichen vom Journal ab. Keine destruktive Operation ausgeführt.',
            );
          }

          final activeDir = Directory(p.join(docsDir.path, 'receipts'));
          if (hasStagedActive && !activeDir.existsSync()) {
            stagedActiveDir.renameSync(activeDir.path);
          }

          for (final relPath in expectedPaths) {
            final bytes = await receiptFileService.readReceiptBytes(relPath);
            if (bytes == null || bytes.isEmpty) {
              throw RestoreRecoveryException(
                'Unklarer Post-Commit-Zustand: Erwartete neue Belegdatei "$relPath" fehlt nach SQLite-Commit. '
                'Keine destruktive Bereinigung ausgeführt.',
              );
            }
          }

          await receiptFileService.finalizeRestoreStaging();
        } else {
          // Fall 2: Noch nicht in SQLite committet -> Vor-Commit-Prüfung vor einem Roll-Back
          if (phase == 'committed') {
            throw const RestoreRecoveryException(
              'Widersprüchlicher Restore-Zustand: Journal ist als committed markiert, aber SQLite-Commit-Nachweis fehlt. '
              'Keine destruktive Operation ausgeführt.',
            );
          }

          if (previousPaths != null) {
            final dbMatchesPrevious =
                currentDbPaths.length == previousPaths.length && currentDbPaths.containsAll(previousPaths);
            if (!dbMatchesPrevious) {
              throw const RestoreRecoveryException(
                'Unklarer Pre-Commit-Zustand: SQLite-Belegpfade stimmen nicht mit dem Vor-Restore-Zustand überein. '
                'Kein blinder Rollback ausgeführt.',
              );
            }
          } else if (journalToken == null && currentDbPaths.isEmpty) {
            throw const RestoreRecoveryException(
              'Unklarer Restore-Zustand ohne Commit-Token und ohne DB-Belegreferenzen. '
              'Kein blinder Rollback ausgeführt.',
            );
          }

          // Prüfe, dass alle von der aktuellen (nicht-committeten) DB benötigten bisherigen Dateien
          // physisch wiederherstellbar vorhanden sind (in receipts_rollback/ bzw. receipts/)
          for (final relPath in currentDbPaths) {
            final File candidateFile;
            if (hasRollback) {
              final subPath = relPath.startsWith('receipts/')
                  ? relPath.substring('receipts/'.length)
                  : relPath;
              candidateFile = File(p.join(rollbackDir.path, subPath));
            } else {
              candidateFile = File(p.join(docsDir.path, relPath));
            }
            if (!candidateFile.existsSync() || candidateFile.lengthSync() <= 0) {
              throw RestoreRecoveryException(
                'Unklarer Pre-Commit-Zustand: Vorherige Belegdatei "$relPath" fehlt im Rollback-Verzeichnis. '
                'Kein blinder Rollback ausgeführt.',
              );
            }
          }

          await receiptFileService.abortRestoreStaging(stagedActiveDir: stagedActiveDir);
        }
      }
    }

    // Unterbrochene Trip-Löschungen konsistent gegen den SQLite-Stand auflösen (Finding C):
    // - Existiert der Trip noch in SQLite (Absturz vor DB-Commit): Dateien wiederherstellen.
    // - Existiert der Trip nicht mehr in SQLite (Absturz nach DB-Commit / fehlgeschlagenes Cleanup): final löschen.
    final pendingTripIds = await receiptFileService.listPendingTripDeleteRollbackIds();
    for (final tripId in pendingTripIds) {
      final trip = await db.tripDao.getTripById(tripId);
      if (trip != null) {
        await receiptFileService.restoreTripDeleteRollback(tripId);
      } else {
        await receiptFileService.finalizeTripDeleteRollback(tripId);
      }
    }

    try {
      await receiptFileService.cleanupExpiredTrash();
    } catch (_) {}
  }

  /// Prüft und behebt beim App-Start oder vor Backup-/Restore-Operationen einen durch
  /// Prozessabbruch unterbrochenen Restore- oder Lösch-Vorgang (R1, Amendment 3 Finding A, B, C).
  Future<void> recoverInterruptedRestore() async {
    await recoverStorageState(
      db: _db,
      receiptFileService: _receiptFileService,
    );
  }

  /// Validiert, dass übergebene Bytes ein unterstütztes, dekodierbares Bild sind (R3).
  bool _isValidImageBytes(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    try {
      final decoded = img.decodeImage(bytes);
      return decoded != null && decoded.width > 0 && decoded.height > 0;
    } catch (_) {
      return false;
    }
  }

  /// Erstellt eine Sicherung aller Törns.
  /// Gemäß PRD nur für angemeldete Mitglieder verfügbar.
  Future<bool> createBackup({int maxBackupReceiptBytes = defaultMaxBackupReceiptBytes}) async {
    final status = await _authService.getMembershipStatus();
    if (status == HullqMembershipStatus.trial) {
      throw StateError('Sicherung ist nur für angemeldete HullQ-Mitglieder verfügbar.');
    }

    await recoverInterruptedRestore();

    final allTrips = await _db.tripDao.getAllTrips();
    final allBoatProfiles = await _db.boatProfileDao.getAllProfiles(includeArchived: true);
    final tripsBackupList = <Map<String, dynamic>>[];
    int totalReceiptBytes = 0;

    for (final trip in allTrips) {
      final days = await _db.tripDao.getDaysForTrip(trip.id);
      final crew = await _db.tripDao.getCrewForTrip(trip.id);
      final stops = await _db.tripDao.getShoppingStopsForTrip(trip.id);
      final items = await _db.listItemDao.getListItemsForTrip(trip.id);

      final allocations = <ListItemAllocation>[];
      for (final item in items) {
        final itemAllocations = await _db.listItemDao.getAllocationsForListItem(item.id);
        allocations.addAll(itemAllocations);
      }

      final expenses = await _db.expenseDao.getExpensesForTrip(trip.id);
      final expenseIds = expenses.map((e) => e.id).toSet();
      final payments = await _db.expenseDao.getKittyPaymentsForTrip(trip.id);
      final receipts = await _db.expenseDao.getReceiptsForTrip(trip.id);

      final receiptsBackup = <Map<String, dynamic>>[];
      for (final r in receipts) {
        if (!expenseIds.contains(r.expenseId)) {
          throw BackupIntegrityException(
            'Beleg ${r.id} verweist auf eine nicht existente Ausgabe ${r.expenseId} in Törn ${trip.id}.',
          );
        }
        final bytes = await _receiptFileService.readReceiptBytes(r.filePath);
        if (bytes == null || bytes.isEmpty) {
          throw BackupIntegrityException(
            'Belegdatei für Beleg ${r.id} fehlt oder ist leer: ${r.filePath}. Ein unvollständiges Backup wird nicht erstellt.',
          );
        }
        if (r.byteSize > 0 && bytes.length != r.byteSize) {
          throw BackupIntegrityException(
            'Belegdatei für Beleg ${r.id} hat abweichende Dateigröße (${bytes.length} statt erwartet ${r.byteSize} Bytes).',
          );
        }
        if (!_isValidImageBytes(bytes)) {
          throw BackupIntegrityException(
            'Belegdatei für Beleg ${r.id} enthält keine gültigen Bilddaten: ${r.filePath}.',
          );
        }
        totalReceiptBytes += bytes.length;
        if (totalReceiptBytes > maxBackupReceiptBytes) {
          throw BackupSizeLimitExceededException(
            message:
                'Die Gesamtgröße aller Belege (${(totalReceiptBytes / (1024 * 1024)).toStringAsFixed(1)} MB) überschreitet das Limit von ${(maxBackupReceiptBytes / (1024 * 1024)).toStringAsFixed(0)} MB.',
            totalBytes: totalReceiptBytes,
            maxBytes: maxBackupReceiptBytes,
          );
        }
        receiptsBackup.add({
          'id': r.id,
          'tripId': r.tripId,
          'expenseId': r.expenseId,
          'filePath': r.filePath,
          'fileName': r.fileName,
          'byteSize': bytes.length,
          'sortOrder': r.sortOrder,
          'createdAt': r.createdAt.toIso8601String(),
          'imageBase64': base64Encode(bytes),
        });
      }

      tripsBackupList.add({
        'trip': _serializeTrip(trip),
        'days': days.map(_serializeDay).toList(),
        'crew': crew.map(_serializeCrew).toList(),
        'stops': stops.map(_serializeStop).toList(),
        'items': items.map(_serializeListItem).toList(),
        'allocations': allocations.map(_serializeAllocation).toList(),
        'expenses': expenses.map(_serializeExpense).toList(),
        'payments': payments.map(_serializePayment).toList(),
        'receipts': receiptsBackup,
      });
    }

    final backupPayload = jsonEncode({
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'boatProfiles': allBoatProfiles.map(_serializeBoatProfile).toList(),
      'trips': tripsBackupList,
    });

    return _backupService.backupData(backupPayload);
  }

  /// Stellt alle gesicherten Törns und Bootsprofile crash-sicher wieder her.
  /// Gewährleistet relationale Integrität durch Neu-Verknüpfung der generierten IDs.
  Future<bool> restoreBackup() async {
    final status = await _authService.getMembershipStatus();
    if (status == HullqMembershipStatus.trial) {
      throw StateError('Wiederherstellung ist nur für angemeldete HullQ-Mitglieder verfügbar.');
    }

    await recoverInterruptedRestore();

    final jsonStr = await _backupService.restoreData();
    if (jsonStr == null || jsonStr.isEmpty) {
      return false;
    }

    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final rawProfiles = decoded['boatProfiles'] as List<dynamic>? ?? [];
    final tripsList = decoded['trips'] as List<dynamic>? ?? [];

    // Pre-Flight-Validierung aller Belege und ihrer Zuordnungen (Finding A, C & R3):
    // Kein Restore startet und keine aktiven Daten werden verändert, wenn ein Beleg korrupt,
    // nicht dekodierbar oder keiner gültigen Ausgabe zugeordnet ist.
    for (final rawTripData in tripsList) {
      final tripData = rawTripData as Map<String, dynamic>;
      final tMap = tripData['trip'] as Map<String, dynamic>?;
      final oldTripId = tMap?['id'] as int?;
      final expenses = tripData['expenses'] as List<dynamic>? ?? [];
      final validOldExpenseIds = <int>{};
      for (final e in expenses) {
        final eMap = e as Map<String, dynamic>;
        final expId = eMap['id'];
        if (expId is int) {
          validOldExpenseIds.add(expId);
        }
      }

      final receipts = tripData['receipts'] as List<dynamic>? ?? [];
      for (final r in receipts) {
        final rMap = r as Map<String, dynamic>;
        final receiptId = rMap['id'];
        final oldExpenseId = rMap['expenseId'];
        if (oldExpenseId is! int || !validOldExpenseIds.contains(oldExpenseId)) {
          throw BackupCorruptException(
            'Beleg $receiptId verweist auf eine fehlende oder ungültige Ausgabe (expenseId: $oldExpenseId).',
          );
        }
        final receiptTripId = rMap['tripId'];
        if (receiptTripId != null && oldTripId != null && receiptTripId != oldTripId) {
          throw BackupCorruptException(
            'Beleg $receiptId gehört zu Törn $receiptTripId, befindet sich aber im Backup-Block von Törn $oldTripId.',
          );
        }

        final b64 = rMap['imageBase64'] as String?;
        if (b64 == null || b64.trim().isEmpty) {
          throw BackupCorruptException(
            'Beleg $receiptId im Backup enthält keine Bilddaten (imageBase64 fehlt oder ist leer).',
          );
        }
        Uint8List decodedBytes;
        try {
          decodedBytes = base64Decode(b64);
          if (decodedBytes.isEmpty) {
            throw BackupCorruptException(
              'Beleg $receiptId im Backup enthält leere Bilddaten.',
            );
          }
        } catch (e) {
          if (e is BackupCorruptException) rethrow;
          throw BackupCorruptException(
            'Belegbild für Beleg $receiptId im Backup konnte nicht als Base64 dekodiert werden.',
          );
        }

        final storedByteSize = rMap['byteSize'];
        if (storedByteSize != null) {
          if (storedByteSize is! int || storedByteSize <= 0 || storedByteSize != decodedBytes.length) {
            throw BackupCorruptException(
              'Beleg $receiptId hat inkonsistente Größenangabe (byteSize: $storedByteSize, tatsächliche Bytes: ${decodedBytes.length}).',
            );
          }
        }

        if (!_isValidImageBytes(decodedBytes)) {
          throw BackupCorruptException(
            'Beleg $receiptId im Backup enthält kein unterstütztes, dekodierbares Bildformat.',
          );
        }
      }
    }

    final docsDir = await _receiptFileService.getDocsDir();
    final stagedActiveDir = Directory(p.join(docsDir.path, 'receipts_staging_active'));
    if (stagedActiveDir.existsSync()) {
      stagedActiveDir.deleteSync(recursive: true);
    }
    stagedActiveDir.createSync(recursive: true);

    final previousDbReceipts = await _db.select(_db.expenseReceipts).get();
    final previousReceiptPaths =
        previousDbReceipts.map((r) => p.posix.normalize(r.filePath.replaceAll('\\', '/'))).toList();
    _restoreNonce++;
    final restoreToken = 'restore_${DateTime.now().microsecondsSinceEpoch}_$_restoreNonce';
    final expectedReceiptPaths = <String>[];

    bool dbCommitted = false;
    try {
      await _db.transaction(() async {
        // Vorhandene Daten bereinigen
        await _db.customStatement('PRAGMA foreign_keys = OFF');
        try {
          await _db.delete(_db.expenseReceipts).go();
          await _db.delete(_db.kittyPayments).go();
          await _db.delete(_db.expenses).go();
          await _db.delete(_db.listItemAllocations).go();
          await _db.delete(_db.listItems).go();
          await _db.delete(_db.shoppingStops).go();
          await _db.delete(_db.crewMembers).go();
          await _db.delete(_db.tripDays).go();
          await _db.delete(_db.trips).go();
          await _db.delete(_db.boatProfiles).go();

          // 0. Bootsprofile einfügen (falls in Backup vorhanden)
          final profileIdMap = <int, int>{};
          for (final rawProfile in rawProfiles) {
            final pMap = rawProfile as Map<String, dynamic>;
            final oldProfileId = pMap['id'] as int;
            final newProfileId = await _db.into(_db.boatProfiles).insert(
              BoatProfilesCompanion.insert(
                name: pMap['name'] as String,
                manufacturer: Value(pMap['manufacturer'] as String?),
                model: Value(pMap['model'] as String?),
                fridgeCapacity: Value(pMap['fridgeCapacity'] as int? ?? 100),
                hasFreezer: Value(pMap['hasFreezer'] as bool? ?? false),
                freezerCapacity: Value(pMap['freezerCapacity'] as int? ?? 0),
                waterTankLiters: Value(pMap['waterTankLiters'] as int? ?? 0),
                isWaterTankDrinkable: Value(pMap['isWaterTankDrinkable'] as bool? ?? false),
                hasWatermaker: Value(pMap['hasWatermaker'] as bool? ?? false),
                isArchived: Value(pMap['isArchived'] as bool? ?? false),
                createdAt: pMap['createdAt'] != null
                    ? Value(DateTime.parse(pMap['createdAt'] as String))
                    : const Value.absent(),
              ),
            );
            profileIdMap[oldProfileId] = newProfileId;
          }

          int receiptCounter = 0;
          for (final rawTripData in tripsList) {
            final tripData = rawTripData as Map<String, dynamic>;
            final tMap = tripData['trip'] as Map<String, dynamic>;

            // 1. Trip einfügen
            final oldBoatProfileId = tMap['boatProfileId'] as int?;
            final newBoatProfileId = oldBoatProfileId != null ? profileIdMap[oldBoatProfileId] : null;

            final newTripId = await _db.into(_db.trips).insert(
              TripsCompanion.insert(
                name: tMap['name'] as String,
                startDate: DateTime.parse(tMap['startDate'] as String),
                region: Value(tMap['region'] as String? ?? 'warm'),
                climate: Value(tMap['climate'] as String? ??
                    (tMap['region'] == 'temperate'
                        ? 'cool'
                        : (tMap['region'] == 'hot_or_remote' ? 'hot' : 'warm'))),
                isCharter: Value(tMap['isCharter'] as bool? ?? true),
                boatProfileId: Value(newBoatProfileId),
                boatName: Value(tMap['boatName'] as String?),
                boatManufacturer: Value(tMap['boatManufacturer'] as String?),
                boatModel: Value(tMap['boatModel'] as String?),
                boatType: Value(tMap['boatType'] as String? ?? 'mono'),
                fridgeCapacity: Value(tMap['fridgeCapacity'] as int? ?? 100),
                appetite: tMap['appetite'] != null
                    ? Value(CrewAppetite.fromString(tMap['appetite'] as String))
                    : const Value.absent(),
                reserveDays: Value(tMap['reserveDays'] as String? ?? 'few_days'),
                drinkingHabit: tMap['drinkingHabit'] != null
                    ? Value(CrewDrinking.fromString(tMap['drinkingHabit'] as String))
                    : const Value.absent(),
                hasStorageChecklist: Value(tMap['hasStorageChecklist'] as bool? ?? true),
                phase: tMap['phase'] != null
                    ? Value(TripPhase.fromString(tMap['phase'] as String))
                    : const Value.absent(),
                isArchived: Value(tMap['isArchived'] as bool? ?? false),
                currency: Value(tMap['currency'] as String? ?? 'EUR'),
                kittyModel: tMap['kittyModel'] != null
                    ? Value(KittyModel.fromString(tMap['kittyModel'] as String))
                    : const Value.absent(),
                hasFreezer: Value(tMap['hasFreezer'] as bool? ?? false),
                freezerCapacity: Value(tMap['freezerCapacity'] as int? ?? 0),
                waterTankLiters: Value(tMap['waterTankLiters'] as int? ?? 0),
                isWaterTankDrinkable: Value(tMap['isWaterTankDrinkable'] as bool? ?? false),
                hasWatermaker: Value(tMap['hasWatermaker'] as bool? ?? false),
                createdAt: tMap['createdAt'] != null
                    ? Value(DateTime.parse(tMap['createdAt'] as String))
                    : const Value.absent(),
              ),
            );

            final stopIdMap = <int, int>{};
            final crewIdMap = <int, int>{};
            final listItemIdMap = <int, int>{};

            // 2. ShoppingStops einfügen
            final stops = tripData['stops'] as List<dynamic>? ?? [];
            for (final s in stops) {
              final sMap = s as Map<String, dynamic>;
              final oldStopId = sMap['id'] as int;
              final newStopId = await _db.into(_db.shoppingStops).insert(
                ShoppingStopsCompanion.insert(
                  tripId: newTripId,
                  name: sMap['name'] as String,
                  dayNumber: Value(sMap['dayNumber'] as int? ?? 1),
                  isInitial: Value(sMap['isInitial'] as bool? ?? false),
                ),
              );
              stopIdMap[oldStopId] = newStopId;
            }

            // 3. TripDays einfügen
            final days = tripData['days'] as List<dynamic>? ?? [];
            for (final d in days) {
              final dMap = d as Map<String, dynamic>;
              await _db.into(_db.tripDays).insert(
                TripDaysCompanion.insert(
                  tripId: newTripId,
                  dayNumber: dMap['dayNumber'] as int,
                  lunchRestaurant: Value(dMap['lunchRestaurant'] as bool? ?? false),
                  dinnerRestaurant: Value(dMap['dinnerRestaurant'] as bool? ?? false),
                  dayType: Value(dMap['dayType'] as String?),
                  portName: Value(dMap['portName'] as String?),
                ),
              );
            }

            // 4. CrewMembers einfügen
            final crew = tripData['crew'] as List<dynamic>? ?? [];
            for (final c in crew) {
              final cMap = c as Map<String, dynamic>;
              final oldCrewId = cMap['id'] as int;
              final newCrewId = await _db.into(_db.crewMembers).insert(
                CrewMembersCompanion.insert(
                  tripId: newTripId,
                  name: cMap['name'] as String,
                  isChild: Value(cMap['isChild'] as bool? ?? false),
                  isVegetarian: Value(cMap['isVegetarian'] as bool? ?? false),
                  isNonDrinker: Value(cMap['isNonDrinker'] as bool? ?? false),
                  customEatLevel: Value(cMap['customEatLevel'] as String?),
                  customDrinkLevel: Value(cMap['customDrinkLevel'] as String?),
                  categoryParticipation: Value(cMap['categoryParticipation'] as String? ?? '{"all": true}'),
                  isSkipperFree: Value(cMap['isSkipperFree'] as bool? ?? false),
                  skipperFreeScope: Value(cMap['skipperFreeScope'] as String?),
                ),
              );
              crewIdMap[oldCrewId] = newCrewId;
            }

            // Falls treasurerMemberId vorhanden, jetzt über crewIdMap aktualisieren
            if (tMap['treasurerMemberId'] != null) {
              final oldTreasurerId = tMap['treasurerMemberId'] as int;
              final newTreasurerId = crewIdMap[oldTreasurerId];
              if (newTreasurerId != null) {
                await (_db.update(_db.trips)..where((t) => t.id.equals(newTripId))).write(
                  TripsCompanion(treasurerMemberId: Value(newTreasurerId)),
                );
              }
            }

            // 5. ListItems einfügen
            final items = tripData['items'] as List<dynamic>? ?? [];
            for (final i in items) {
              final iMap = i as Map<String, dynamic>;
              final oldItemId = iMap['id'] as int;
              final newItemId = await _db.into(_db.listItems).insert(
                ListItemsCompanion.insert(
                  tripId: newTripId,
                  catalogId: iMap['catalogId'] as String,
                  isCustom: Value(iMap['isCustom'] as bool? ?? false),
                  customName: Value(iMap['customName'] as String?),
                  customUnit: Value(iMap['customUnit'] as String?),
                  customDepartment: Value(iMap['customDepartment'] as String?),
                  selected: Value(iMap['selected'] as bool? ?? true),
                  share: Value(iMap['share'] as double? ?? 1.0),
                  calculatedQuantity: Value(iMap['calculatedQuantity'] as double? ?? 0.0),
                  calculatedPackages: Value(iMap['calculatedPackages'] as int? ?? 1),
                  overriddenPackages: Value(iMap['overriddenPackages'] as int?),
                  customPackageSize: Value(iMap['customPackageSize'] as double?),
                ),
              );
              listItemIdMap[oldItemId] = newItemId;
            }

            // 6. ListItemAllocations einfügen
            final allocations = tripData['allocations'] as List<dynamic>? ?? [];
            for (final a in allocations) {
              final aMap = a as Map<String, dynamic>;
              final oldItemId = aMap['listItemId'] as int;
              final oldStopId = aMap['shoppingStopId'] as int;
              final newItemId = listItemIdMap[oldItemId];
              final newStopId = stopIdMap[oldStopId];
              if (newItemId != null && newStopId != null) {
                await _db.into(_db.listItemAllocations).insert(
                  ListItemAllocationsCompanion.insert(
                    tripId: newTripId,
                    listItemId: newItemId,
                    shoppingStopId: newStopId,
                    allocatedPackages: aMap['allocatedPackages'] as int,
                    isBought: Value(aMap['isBought'] as bool? ?? false),
                    isStored: Value(aMap['isStored'] as bool? ?? false),
                  ),
                );
              }
            }

            // 7. Expenses einfügen
            final expenseIdMap = <int, int>{};
            final expenses = tripData['expenses'] as List<dynamic>? ?? [];
            for (final e in expenses) {
              final eMap = e as Map<String, dynamic>;
              final oldExpenseId = eMap['id'] as int;
              final oldPayerId = eMap['paidByCrewMemberId'] as int?;
              if (oldPayerId != null && !crewIdMap.containsKey(oldPayerId)) {
                throw StateError(
                  'Cannot restore expense: payer ID $oldPayerId could not be mapped to restored crew.',
                );
              }
              final newPayerId = oldPayerId != null ? crewIdMap[oldPayerId] : null;

              String? remappedCustomSplit;
              final rawSplit = eMap['customSplit'] as String?;
              if (rawSplit != null && rawSplit.isNotEmpty) {
                final dynamic decoded = jsonDecode(rawSplit);
                if (decoded is Map) {
                  final remappedMap = <String, dynamic>{};
                  for (final entry in decoded.entries) {
                    final oldId = int.tryParse(entry.key.toString());
                    if (oldId == null || !crewIdMap.containsKey(oldId)) {
                      throw StateError(
                        'Cannot restore custom split: member ID ${entry.key} could not be mapped to restored crew.',
                      );
                    }
                    final newId = crewIdMap[oldId]!;
                    remappedMap[newId.toString()] = entry.value;
                  }
                  remappedCustomSplit = jsonEncode(remappedMap);
                } else {
                  remappedCustomSplit = rawSplit;
                }
              }

              final newExpenseId = await _db.into(_db.expenses).insert(
                ExpensesCompanion.insert(
                  tripId: newTripId,
                  amount: eMap['amount'] as double,
                  currency: Value(eMap['currency'] as String? ?? 'EUR'),
                  category: ExpenseCategory.fromString(eMap['category'] as String),
                  paidByCrewMemberId: Value(newPayerId),
                  isPaidFromKitty: Value(eMap['isPaidFromKitty'] as bool? ?? false),
                  customSplit: Value(remappedCustomSplit),
                  note: Value(eMap['note'] as String?),
                  createdAt: eMap['createdAt'] != null
                      ? Value(DateTime.parse(eMap['createdAt'] as String))
                      : const Value.absent(),
                ),
              );
              expenseIdMap[oldExpenseId] = newExpenseId;
            }

            // 8. KittyPayments einfügen
            final payments = tripData['payments'] as List<dynamic>? ?? [];
            for (final p in payments) {
              final pMap = p as Map<String, dynamic>;
              final oldMemberId = pMap['crewMemberId'] as int;
              if (!crewIdMap.containsKey(oldMemberId)) {
                throw StateError(
                  'Cannot restore kitty payment: member ID $oldMemberId could not be mapped to restored crew.',
                );
              }
              final newMemberId = crewIdMap[oldMemberId]!;
              await _db.into(_db.kittyPayments).insert(
                KittyPaymentsCompanion.insert(
                  tripId: newTripId,
                  crewMemberId: newMemberId,
                  amount: pMap['amount'] as double,
                  paidAt: pMap['paidAt'] != null
                      ? Value(DateTime.parse(pMap['paidAt'] as String))
                      : const Value.absent(),
                ),
              );
            }

            // 9. Receipts einfügen (RECEIPT1 & R3: kein stilles Überspringen!)
            final receipts = tripData['receipts'] as List<dynamic>? ?? [];
            for (final r in receipts) {
              final rMap = r as Map<String, dynamic>;
              final oldExpenseId = rMap['expenseId'] as int?;
              final newExpenseId = oldExpenseId != null ? expenseIdMap[oldExpenseId] : null;
              if (newExpenseId == null) {
                throw BackupCorruptException(
                  'Beleg ${rMap['id']} konnte keiner wiederhergestellten Ausgabe zugeordnet werden (expenseId: $oldExpenseId).',
                );
              }

              final base64Image = rMap['imageBase64'] as String;
              final fileName = _receiptFileService.sanitizeFileName(rMap['fileName'] as String?);
              final imageBytes = base64Decode(base64Image);

              // Kollisionsfreie interne Datei im Staging-Ordner erzeugen
              receiptCounter++;
              final uniqueInternalName =
                  'rcpt_${DateTime.now().microsecondsSinceEpoch}_${rMap['id'] ?? 0}_$receiptCounter.jpg';
              final stagedExpenseDir = Directory(
                p.join(stagedActiveDir.path, 'trip_$newTripId', 'expense_$newExpenseId'),
              );
              if (!stagedExpenseDir.existsSync()) {
                stagedExpenseDir.createSync(recursive: true);
              }
              final stagedFile = File(p.join(stagedExpenseDir.path, uniqueInternalName));
              stagedFile.writeAsBytesSync(imageBytes, flush: true);

              final relativeFilePath = p.posix.join(
                'receipts',
                'trip_$newTripId',
                'expense_$newExpenseId',
                uniqueInternalName,
              );
              expectedReceiptPaths.add(relativeFilePath);

              await _db.into(_db.expenseReceipts).insert(
                ExpenseReceiptsCompanion.insert(
                  tripId: newTripId,
                  expenseId: newExpenseId,
                  filePath: relativeFilePath,
                  fileName: fileName,
                  byteSize: Value(imageBytes.length),
                  sortOrder: Value(rMap['sortOrder'] as int? ?? 0),
                  createdAt: rMap['createdAt'] != null
                      ? Value(DateTime.parse(rMap['createdAt'] as String))
                      : const Value.absent(),
                ),
              );
            }
          }
        } finally {
          await _db.customStatement('PRAGMA foreign_keys = ON');
        }

        // R1 & Amendment 3 Finding A:
        // Zwei-Phasen-Promotion INNERHALB der SQLite-Transaktion mit belastbarem Commit-Nachweis.
        // 1. Schreibt den eindeutigen `restoreToken` in die SQLite-Tabelle `_provy_restore_state`
        //    (wird exakt mit der SQLite-Transaktion committet oder zurückgerollt).
        // 2. Schreibt das Recovery-Journal (`restore_journal.json`) mit `restoreToken`,
        //    `previousReceiptPaths` und `expectedReceiptPaths`.
        // 3. Promoviert die gestagten Dateien nach `receipts/`, während die bisherigen Dateien
        //    in `receipts_rollback/` verbleiben.
        await _writeDbRestoreToken(_db, restoreToken);
        await _receiptFileService.writeRestoreJournal(
          expectedReceiptPaths: expectedReceiptPaths,
          restoreToken: restoreToken,
          phase: 'promoting',
          previousReceiptPaths: previousReceiptPaths,
        );
        await _receiptFileService.promoteStagedReceipts(
          stagedActiveDir: stagedActiveDir,
        );
      });
      dbCommitted = true;
    } catch (e) {
      // Phase 1 (Noch nicht committet): Rückabwicklung auf den vorherigen Dateistand ist zulässig.
      if (!dbCommitted) {
        await _receiptFileService.abortRestoreStaging(stagedActiveDir: stagedActiveDir);
      }
      rethrow;
    }

    // Phase 2 (Erfolgreich in SQLite committet, dbCommitted == true):
    // Ab hier darf NIEMALS mehr abortRestoreStaging() aufgerufen werden oder der alte Dateistand
    // aktiviert werden! Ausschließlicher Roll-Forward / Finalisierung (Amendment 3 Finding A):
    try {
      await _receiptFileService.markRestoreJournalCommitted(
        restoreToken: restoreToken,
        expectedReceiptPaths: expectedReceiptPaths,
        previousReceiptPaths: previousReceiptPaths,
      );
    } catch (_) {}

    await _receiptFileService.finalizeRestoreStaging();
    return true;
  }

  Map<String, dynamic> _serializeTrip(Trip t) => {
        'id': t.id,
        'name': t.name,
        'startDate': t.startDate.toIso8601String(),
        'daysCount': t.daysCount,
        'region': t.region,
        'climate': t.climate,
        'isCharter': t.isCharter,
        'boatProfileId': t.boatProfileId,
        'boatName': t.boatName,
        'boatManufacturer': t.boatManufacturer,
        'boatModel': t.boatModel,
        'boatType': t.boatType,
        'fridgeCapacity': t.fridgeCapacity,
        'hasFreezer': t.hasFreezer,
        'freezerCapacity': t.freezerCapacity,
        'waterTankLiters': t.waterTankLiters,
        'isWaterTankDrinkable': t.isWaterTankDrinkable,
        'hasWatermaker': t.hasWatermaker,
        'appetite': t.appetite.rawValue,
        'reserveDays': t.reserveDays,
        'drinkingHabit': t.drinkingHabit.rawValue,
        'hasStorageChecklist': t.hasStorageChecklist,
        'phase': t.phase.rawValue,
        'isArchived': t.isArchived,
        'currency': t.currency,
        'kittyModel': t.kittyModel.rawValue,
        'treasurerMemberId': t.treasurerMemberId,
        'createdAt': t.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _serializeBoatProfile(BoatProfile p) => {
        'id': p.id,
        'name': p.name,
        'manufacturer': p.manufacturer,
        'model': p.model,
        'fridgeCapacity': p.fridgeCapacity,
        'hasFreezer': p.hasFreezer,
        'freezerCapacity': p.freezerCapacity,
        'waterTankLiters': p.waterTankLiters,
        'isWaterTankDrinkable': p.isWaterTankDrinkable,
        'hasWatermaker': p.hasWatermaker,
        'isArchived': p.isArchived,
        'createdAt': p.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _serializeDay(TripDay d) => {
        'id': d.id,
        'tripId': d.tripId,
        'dayNumber': d.dayNumber,
        'lunchRestaurant': d.lunchRestaurant,
        'dinnerRestaurant': d.dinnerRestaurant,
        'dayType': d.dayType,
        'portName': d.portName,
      };

  Map<String, dynamic> _serializeStop(ShoppingStop s) => {
        'id': s.id,
        'tripId': s.tripId,
        'dayNumber': s.dayNumber,
        'name': s.name,
        'isInitial': s.isInitial,
      };

  Map<String, dynamic> _serializeCrew(CrewMember c) => {
        'id': c.id,
        'tripId': c.tripId,
        'name': c.name,
        'isChild': c.isChild,
        'isVegetarian': c.isVegetarian,
        'isNonDrinker': c.isNonDrinker,
        'customEatLevel': c.customEatLevel,
        'customDrinkLevel': c.customDrinkLevel,
        'categoryParticipation': c.categoryParticipation,
        'isSkipperFree': c.isSkipperFree,
        'skipperFreeScope': c.skipperFreeScope,
      };

  Map<String, dynamic> _serializeListItem(ListItem i) => {
        'id': i.id,
        'tripId': i.tripId,
        'catalogId': i.catalogId,
        'isCustom': i.isCustom,
        'customName': i.customName,
        'customUnit': i.customUnit,
        'customDepartment': i.customDepartment,
        'selected': i.selected,
        'share': i.share,
        'calculatedQuantity': i.calculatedQuantity,
        'calculatedPackages': i.calculatedPackages,
        'overriddenPackages': i.overriddenPackages,
        'customPackageSize': i.customPackageSize,
      };

  Map<String, dynamic> _serializeAllocation(ListItemAllocation a) => {
        'id': a.id,
        'tripId': a.tripId,
        'listItemId': a.listItemId,
        'shoppingStopId': a.shoppingStopId,
        'allocatedPackages': a.allocatedPackages,
        'isBought': a.isBought,
        'isStored': a.isStored,
      };

  Map<String, dynamic> _serializeExpense(Expense e) => {
        'id': e.id,
        'tripId': e.tripId,
        'amount': e.amount,
        'currency': e.currency,
        'category': e.category.rawValue,
        'paidByCrewMemberId': e.paidByCrewMemberId,
        'isPaidFromKitty': e.isPaidFromKitty,
        'customSplit': e.customSplit,
        'note': e.note,
        'createdAt': e.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _serializePayment(KittyPayment p) => {
        'id': p.id,
        'tripId': p.tripId,
        'crewMemberId': p.crewMemberId,
        'amount': p.amount,
        'paidAt': p.paidAt.toIso8601String(),
      };
}

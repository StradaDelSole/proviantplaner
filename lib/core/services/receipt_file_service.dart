/// Dateisystem- und Bildverarbeitungsdienst für Belege (RECEIPT1).
/// Speichert, skaliert, entfernt EXIF-Metadaten und verwaltet lokale Belegdateien.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ergebnis des Speicherns oder Verarbeitens eines Belegs.
class ProcessedReceiptFile {
  final String relativePath;
  final String absolutePath;
  final String fileName;
  final int byteSize;
  final String mimeType;

  const ProcessedReceiptFile({
    required this.relativePath,
    required this.absolutePath,
    required this.fileName,
    required this.byteSize,
    required this.mimeType,
  });

  String get filePath => relativePath;
}

class ReceiptFileService {
  static int _uniqueFileNonce = 0;

  final Future<Directory> Function() getDocsDir;

  /// Optionaler Hook zur gezielten Fehler-Injektion in Tests (R1, R2).
  /// Wird vor Dateisystemoperationen mit dem Operationsnamen aufgerufen.
  void Function(String operation)? faultInjector;

  ReceiptFileService({
    Future<Directory> Function()? docsDirProvider,
    this.faultInjector,
  }) : getDocsDir = docsDirProvider ?? _resolveDefaultDocsDir;

  static Future<Directory> _resolveDefaultDocsDir() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp;
    }
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  /// Bereinigt vom Nutzer oder System übergebene Dateinamen und verhindert Path Traversal.
  String sanitizeFileName(String? preferredFileName) {
    if (preferredFileName == null || preferredFileName.trim().isEmpty) {
      return 'receipt.jpg';
    }
    var base = p.basename(preferredFileName.trim());
    base = base.replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '_');
    if (base.isEmpty || base == '.' || base == '..') {
      return 'receipt.jpg';
    }
    return base;
  }

  /// Generiert einen internen, garantiert eindeutigen Dateinamen zur Vermeidung von Kollisionen.
  String _generateInternalFileName() {
    _uniqueFileNonce++;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'rcpt_${timestamp}_$_uniqueFileNonce.jpg';
  }

  /// Optimiert ein Bild (Resize falls > 1800px Kantenlänge, EXIF-Strip, JPEG 82%)
  /// und liefert die bereinigten JPEG-Bytes zurück.
  Uint8List optimizeImageBytes(Uint8List rawBytes) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(rawBytes);
    } catch (_) {
      throw const FormatException('Das Bildformat konnte nicht dekodiert werden.');
    }
    if (decoded == null) {
      throw const FormatException('Das Bildformat konnte nicht dekodiert werden.');
    }

    // Orientierung korrigieren (bakeOrientation entfernt EXIF orientation tags)
    final oriented = img.bakeOrientation(decoded);

    // Skalieren, falls Dimensionen sehr groß sind (z.B. 4000x3000 -> max 1800px)
    img.Image processed = oriented;
    const maxDimension = 1800;
    if (oriented.width > maxDimension || oriented.height > maxDimension) {
      if (oriented.width >= oriented.height) {
        processed = img.copyResize(oriented, width: maxDimension);
      } else {
        processed = img.copyResize(oriented, height: maxDimension);
      }
    }

    // Neu codieren als JPEG mit Qualität 82 (kompakt, gestrippte EXIF/GPS-Daten)
    return Uint8List.fromList(img.encodeJpg(processed, quality: 82));
  }

  /// Speichert ein Belegbild für eine konkrete Ausgabe ab.
  /// Verwendet einen internen kollisionsfreien Dateinamen und speichert den bereinigten Anzeigenamen.
  Future<ProcessedReceiptFile> saveReceiptImage({
    required int tripId,
    required int expenseId,
    required Uint8List imageBytes,
    String? preferredFileName,
  }) async {
    faultInjector?.call('saveReceiptImage');
    final docsDir = await getDocsDir();
    final relativeFolder = p.join('receipts', 'trip_$tripId', 'expense_$expenseId');
    final targetDir = Directory(p.join(docsDir.path, relativeFolder));

    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final optimized = optimizeImageBytes(imageBytes);
    final sanitizedDisplayName = sanitizeFileName(preferredFileName);
    final internalFileName = _generateInternalFileName();
    final targetRelativePath = p.posix.join('receipts', 'trip_$tripId', 'expense_$expenseId', internalFileName);
    final targetFile = File(p.join(docsDir.path, targetRelativePath));

    if (!p.isWithin(docsDir.path, targetFile.path)) {
      throw ArgumentError('Ungültiger Pfad (Path Traversal erkannt): $preferredFileName');
    }

    targetFile.writeAsBytesSync(optimized, flush: true);

    return ProcessedReceiptFile(
      relativePath: targetRelativePath,
      absolutePath: targetFile.path,
      fileName: sanitizedDisplayName,
      byteSize: optimized.length,
      mimeType: 'image/jpeg',
    );
  }

  /// Speichert rohe (oder bereits optimierte) Bytes direkt ab, z.B. bei Backup-Restore oder Tests.
  Future<ProcessedReceiptFile> saveRawReceiptBytes({
    required int tripId,
    required int expenseId,
    required Uint8List bytes,
    required String fileName,
    bool generateUniqueName = true,
  }) async {
    faultInjector?.call('saveRawReceiptBytes');
    final docsDir = await getDocsDir();
    final relativeFolder = p.join('receipts', 'trip_$tripId', 'expense_$expenseId');
    final targetDir = Directory(p.join(docsDir.path, relativeFolder));

    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final sanitizedDisplayName = sanitizeFileName(fileName);
    final actualFileName = generateUniqueName ? _generateInternalFileName() : sanitizedDisplayName;
    final targetRelativePath = p.posix.join('receipts', 'trip_$tripId', 'expense_$expenseId', actualFileName);
    final targetFile = File(p.join(docsDir.path, targetRelativePath));

    if (!p.isWithin(docsDir.path, targetFile.path)) {
      throw ArgumentError('Ungültiger Pfad (Path Traversal erkannt): $fileName');
    }

    targetFile.writeAsBytesSync(bytes, flush: true);

    return ProcessedReceiptFile(
      relativePath: targetRelativePath,
      absolutePath: targetFile.path,
      fileName: sanitizedDisplayName,
      byteSize: bytes.length,
      mimeType: 'image/jpeg',
    );
  }

  /// Schreibt Roh-Bytes exakt unter einem bekannten relativen Pfad (z.B. für Rollback bei DB-Fehler).
  Future<void> writeReceiptBytesAtPath(String relativePath, Uint8List bytes) async {
    final docsDir = await getDocsDir();
    final targetFile = File(p.join(docsDir.path, relativePath));
    if (!p.isWithin(docsDir.path, targetFile.path)) {
      throw ArgumentError('Ungültiger Pfad: $relativePath');
    }
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsBytesSync(bytes, flush: true);
  }

  /// Liest die Bytes eines Belegs anhand seines relativen Pfads.
  Future<Uint8List?> readReceiptBytes(String relativePath) async {
    final docsDir = await getDocsDir();
    final file = File(p.join(docsDir.path, relativePath));
    if (file.existsSync()) {
      return file.readAsBytesSync();
    }
    return null;
  }

  /// Gibt den absoluten Pfad zu einem relativen Belegpfad zurück.
  Future<String> resolveAbsolutePath(String relativePath) async {
    final docsDir = await getDocsDir();
    return p.join(docsDir.path, relativePath);
  }

  /// Löscht eine einzelne Belegdatei.
  /// Wirft bei echten I/O-Fehlern eine [FileSystemException] statt sie zu verschlucken (R2).
  Future<bool> deleteReceiptFile(String relativePath) async {
    faultInjector?.call('deleteReceiptFile');
    final docsDir = await getDocsDir();
    final file = File(p.join(docsDir.path, relativePath));
    if (file.existsSync()) {
      file.deleteSync();
      return true;
    }
    return false;
  }

  /// Löscht den gesamten Belegordner einer Ausgabe (aktiv und im Papierkorb).
  /// Wirft bei echten I/O-Fehlern eine [FileSystemException] statt sie zu verschlucken (R2).
  Future<void> deleteExpenseReceiptFolder(int tripId, int expenseId) async {
    faultInjector?.call('deleteExpenseReceiptFolder');
    final docsDir = await getDocsDir();
    final activeDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId', 'expense_$expenseId'));
    if (activeDir.existsSync()) {
      activeDir.deleteSync(recursive: true);
    }
    final trashDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
    if (trashDir.existsSync()) {
      trashDir.deleteSync(recursive: true);
    }
  }

  /// Löscht alle Belege eines Törns (bei Törn-Löschung aus Aktiv- und Papierkorb-Verzeichnis).
  /// Wirft bei echten I/O-Fehlern eine [FileSystemException] statt sie zu verschlucken (R2).
  Future<void> deleteTripReceipts(int tripId) async {
    faultInjector?.call('deleteTripReceipts');
    final docsDir = await getDocsDir();
    final activeDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId'));
    if (activeDir.existsSync()) {
      activeDir.deleteSync(recursive: true);
    }
    final trashDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId'));
    if (trashDir.existsSync()) {
      trashDir.deleteSync(recursive: true);
    }
  }

  /// Verschiebt alle Belege eines Törns vor einer Törn-Löschung in ein Rollback-Verzeichnis,
  /// damit bei einem DB- oder I/O-Fehler ein konsistenter Rollback möglich ist (R2).
  Future<void> stageTripDeleteRollback(int tripId) async {
    faultInjector?.call('stageTripDeleteRollback');
    final docsDir = await getDocsDir();
    final activeDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId'));
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_trip_rollback', 'trip_$tripId'));
    if (rollbackDir.existsSync()) {
      rollbackDir.deleteSync(recursive: true);
    }
    if (activeDir.existsSync()) {
      await _moveDirectory(activeDir, rollbackDir);
    }
  }

  /// Stellt die Belege eines Törns aus dem Rollback-Verzeichnis wieder her, falls `deleteTrip` fehlschlägt (R2).
  Future<void> restoreTripDeleteRollback(int tripId) async {
    final docsDir = await getDocsDir();
    final activeDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId'));
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_trip_rollback', 'trip_$tripId'));
    if (rollbackDir.existsSync()) {
      await _moveDirectory(rollbackDir, activeDir);
    }
  }

  /// Finalisiert die Törn-Löschung im Dateisystem nach erfolgreichem DB-Delete (R2).
  Future<void> finalizeTripDeleteRollback(int tripId) async {
    faultInjector?.call('deleteTripReceipts');
    final docsDir = await getDocsDir();
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_trip_rollback', 'trip_$tripId'));
    if (rollbackDir.existsSync()) {
      rollbackDir.deleteSync(recursive: true);
    }
    final trashDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId'));
    if (trashDir.existsSync()) {
      trashDir.deleteSync(recursive: true);
    }
  }

  // --- Zwei-Phasen-Staging, Recovery-Journal & Rollback für Restore (R1) ---

  /// Bereitet das Staging-Verzeichnis für einen Backup-Restore vor.
  Future<Directory> prepareStagingDirectory() async {
    final docsDir = await getDocsDir();
    final stagingDir = Directory(p.join(docsDir.path, 'receipts_staging'));
    if (stagingDir.existsSync()) {
      stagingDir.deleteSync(recursive: true);
    }
    stagingDir.createSync(recursive: true);
    return stagingDir;
  }

  /// Bereinigt das Staging-Verzeichnis.
  Future<void> cleanStagingDirectory() async {
    final docsDir = await getDocsDir();
    final stagingDir = Directory(p.join(docsDir.path, 'receipts_staging'));
    if (stagingDir.existsSync()) {
      stagingDir.deleteSync(recursive: true);
    }
  }

  /// Schreibt Belegbytes in das Staging-Verzeichnis.
  Future<File> stageReceiptBytes({
    required int stagedIndex,
    required Uint8List bytes,
  }) async {
    final docsDir = await getDocsDir();
    final stagingDir = Directory(p.join(docsDir.path, 'receipts_staging'));
    if (!stagingDir.existsSync()) {
      stagingDir.createSync(recursive: true);
    }
    final file = File(p.join(stagingDir.path, 'staged_rcpt_$stagedIndex.jpg'));
    file.writeAsBytesSync(bytes, flush: true);
    return file;
  }

  /// Schreibt das Restore-Recovery-Journal vor der Datei-Promotion und dem SQLite-Commit (R1).
  Future<void> writeRestoreJournal({
    required List<String> expectedReceiptPaths,
  }) async {
    faultInjector?.call('writeRestoreJournal');
    final docsDir = await getDocsDir();
    final journalFile = File(p.join(docsDir.path, 'restore_journal.json'));
    final payload = jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'expectedReceiptPaths': expectedReceiptPaths,
    });
    journalFile.writeAsStringSync(payload, flush: true);
  }

  /// Liest das Restore-Recovery-Journal, falls ein unterbrochener Restore vorliegt (R1).
  Future<Map<String, dynamic>?> readRestoreJournal() async {
    final docsDir = await getDocsDir();
    final journalFile = File(p.join(docsDir.path, 'restore_journal.json'));
    if (!journalFile.existsSync()) return null;
    try {
      final content = journalFile.readAsStringSync();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{'corrupt': true};
    }
  }

  /// Löscht das Restore-Recovery-Journal.
  Future<void> deleteRestoreJournal() async {
    final docsDir = await getDocsDir();
    final journalFile = File(p.join(docsDir.path, 'restore_journal.json'));
    if (journalFile.existsSync()) {
      journalFile.deleteSync();
    }
  }

  /// Phase 1 des Restore-Commits (wird INNERHALB der SQLite-Transaktion vor dem DB-COMMIT ausgeführt, R1):
  /// Verschiebt das bestehende `receipts`-Verzeichnis nach `receipts_rollback` und aktiviert
  /// `stagedActiveDir` als neues `receipts`-Verzeichnis, OHNE `receipts_rollback` bereits zu löschen.
  /// Scheitert dieser Schritt, bricht die umgebende SQLite-Transaktion automatisch per Rollback ab,
  /// und `abortRestoreStaging` stellt `receipts_rollback` wieder nach `receipts` her.
  Future<void> promoteStagedReceipts({
    required Directory stagedActiveDir,
  }) async {
    faultInjector?.call('promoteStagedReceipts_beforeBackupMove');
    final docsDir = await getDocsDir();
    final activeDir = Directory(p.join(docsDir.path, 'receipts'));
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_rollback'));

    if (rollbackDir.existsSync()) {
      rollbackDir.deleteSync(recursive: true);
    }

    if (activeDir.existsSync()) {
      await _moveDirectory(activeDir, rollbackDir);
    }

    faultInjector?.call('promoteStagedReceipts_afterBackupMove');

    if (stagedActiveDir.existsSync()) {
      await _moveDirectory(stagedActiveDir, activeDir);
    } else {
      activeDir.createSync(recursive: true);
    }

    faultInjector?.call('promoteStagedReceipts_afterPromote');
  }

  /// Phase 2 des Restore-Commits (wird NACH erfolgreichem SQLite-COMMIT ausgeführt, R1):
  /// Entfernt das Rollback-Verzeichnis, das Staging-Verzeichnis und das Recovery-Journal.
  Future<void> finalizeRestoreStaging() async {
    faultInjector?.call('finalizeRestoreStaging');
    final docsDir = await getDocsDir();
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_rollback'));
    if (rollbackDir.existsSync()) {
      rollbackDir.deleteSync(recursive: true);
    }
    await deleteRestoreJournal();
    await cleanStagingDirectory();
  }

  /// Kompatibilitätsmethode für einstufigen Commit (führt Promote + Finalize nacheinander aus).
  Future<void> commitRestoreStaging({
    required Directory stagedActiveDir,
  }) async {
    await promoteStagedReceipts(stagedActiveDir: stagedActiveDir);
    await finalizeRestoreStaging();
  }

  /// Bricht den Restore ab und stellt den vorherigen Zustand aus dem Rollback-Verzeichnis wieder her.
  Future<void> abortRestoreStaging({
    Directory? stagedActiveDir,
  }) async {
    final docsDir = await getDocsDir();
    final activeDir = Directory(p.join(docsDir.path, 'receipts'));
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_rollback'));
    final defaultStagedActiveDir = stagedActiveDir ?? Directory(p.join(docsDir.path, 'receipts_staging_active'));

    if (defaultStagedActiveDir.existsSync()) {
      defaultStagedActiveDir.deleteSync(recursive: true);
    }

    if (rollbackDir.existsSync()) {
      if (activeDir.existsSync()) {
        activeDir.deleteSync(recursive: true);
      }
      await _moveDirectory(rollbackDir, activeDir);
    }

    await deleteRestoreJournal();
    await cleanStagingDirectory();
  }

  // --- Soft-Delete & Papierkorb für Expense-Undo (Finding D & R2) ---

  /// Verschiebt die Belege einer Ausgabe in den Papierkorb für die Undo-Dauer
  /// und hinterlegt einen Zeitstempel zur automatischen Bereinigung verwaister Undo-Dateien nach App-Crash (R2).
  Future<void> moveToTrash(int tripId, int expenseId, {DateTime? trashedAt}) async {
    faultInjector?.call('moveToTrash');
    final docsDir = await getDocsDir();
    final activeExpenseDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId', 'expense_$expenseId'));
    if (!activeExpenseDir.existsSync()) return;

    final trashExpenseDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
    await _moveDirectory(activeExpenseDir, trashExpenseDir);

    final markerFile = File(p.join(trashExpenseDir.path, '.trashed_at'));
    markerFile.writeAsStringSync((trashedAt ?? DateTime.now()).toIso8601String(), flush: true);
  }

  /// Stellt die Belege einer Ausgabe aus dem Papierkorb wieder her (Undo).
  Future<void> restoreFromTrash(int tripId, int expenseId) async {
    faultInjector?.call('restoreFromTrash');
    final docsDir = await getDocsDir();
    final trashExpenseDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
    if (!trashExpenseDir.existsSync()) return;

    final markerFile = File(p.join(trashExpenseDir.path, '.trashed_at'));
    if (markerFile.existsSync()) {
      markerFile.deleteSync();
    }

    final activeExpenseDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId', 'expense_$expenseId'));
    await _moveDirectory(trashExpenseDir, activeExpenseDir);
  }

  /// Löscht Belege im Papierkorb endgültig (nach Ablauf des Undo-Fensters).
  Future<void> purgeTrash({int? tripId, int? expenseId}) async {
    faultInjector?.call('purgeTrash');
    final docsDir = await getDocsDir();
    if (tripId != null && expenseId != null) {
      final trashExpenseDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
      if (trashExpenseDir.existsSync()) {
        trashExpenseDir.deleteSync(recursive: true);
      }
    } else if (tripId != null) {
      final trashTripDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId'));
      if (trashTripDir.existsSync()) {
        trashTripDir.deleteSync(recursive: true);
      }
    } else {
      final trashDir = Directory(p.join(docsDir.path, 'receipts_trash'));
      if (trashDir.existsSync()) {
        trashDir.deleteSync(recursive: true);
      }
    }
  }

  /// Bereinigt abgelaufene oder nach einem Prozessabbruch verwaiste temporäre Undo-Dateien im Papierkorb (R2).
  Future<void> cleanupExpiredTrash({
    Duration maxAge = const Duration(minutes: 2),
    DateTime? now,
  }) async {
    final docsDir = await getDocsDir();
    final trashRoot = Directory(p.join(docsDir.path, 'receipts_trash'));
    if (!trashRoot.existsSync()) return;

    final effectiveNow = now ?? DateTime.now();

    for (final tripEntity in trashRoot.listSync(recursive: false)) {
      if (tripEntity is Directory) {
        for (final expEntity in tripEntity.listSync(recursive: false)) {
          if (expEntity is Directory) {
            DateTime? trashedAt;
            final markerFile = File(p.join(expEntity.path, '.trashed_at'));
            if (markerFile.existsSync()) {
              try {
                final raw = markerFile.readAsStringSync();
                trashedAt = DateTime.tryParse(raw.trim());
              } catch (_) {}
            }
            if (trashedAt == null) {
              final stat = expEntity.statSync();
              trashedAt = stat.modified;
            }
            if (effectiveNow.difference(trashedAt) >= maxAge) {
              expEntity.deleteSync(recursive: true);
            }
          }
        }
        // Leeren Trip-Ordner im Papierkorb aufräumen
        if (tripEntity.existsSync()) {
          final remaining = tripEntity.listSync(recursive: false);
          if (remaining.isEmpty) {
            tripEntity.deleteSync(recursive: true);
          }
        }
      }
    }
  }

  Future<void> _moveDirectory(Directory src, Directory dst) async {
    if (!src.existsSync()) return;
    if (dst.existsSync()) {
      dst.deleteSync(recursive: true);
    }
    dst.parent.createSync(recursive: true);
    try {
      src.renameSync(dst.path);
    } catch (_) {
      _copyDirectorySync(src, dst);
      src.deleteSync(recursive: true);
    }
  }

  void _copyDirectorySync(Directory src, Directory dst) {
    dst.createSync(recursive: true);
    for (final entity in src.listSync(recursive: false)) {
      if (entity is Directory) {
        _copyDirectorySync(entity, Directory(p.join(dst.path, p.basename(entity.path))));
      } else if (entity is File) {
        entity.copySync(p.join(dst.path, p.basename(entity.path)));
      }
    }
  }
}

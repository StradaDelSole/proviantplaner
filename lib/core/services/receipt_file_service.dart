/// Dateisystem- und Bildverarbeitungsdienst für Belege (RECEIPT1).
/// Speichert, skaliert, entfernt EXIF-Metadaten und verwaltet lokale Belegdateien.
library;

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

  ReceiptFileService({
    Future<Directory> Function()? docsDirProvider,
  }) : getDocsDir = docsDirProvider ?? _resolveDefaultDocsDir;

  static Future<Directory> _resolveDefaultDocsDir() async {
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
    final docsDir = await getDocsDir();
    final relativeFolder = p.join('receipts', 'trip_$tripId', 'expense_$expenseId');
    final targetDir = Directory(p.join(docsDir.path, relativeFolder));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final optimized = optimizeImageBytes(imageBytes);
    final sanitizedDisplayName = sanitizeFileName(preferredFileName);
    final internalFileName = _generateInternalFileName();
    final targetRelativePath = p.posix.join('receipts', 'trip_$tripId', 'expense_$expenseId', internalFileName);
    final targetFile = File(p.join(docsDir.path, targetRelativePath));

    if (!p.isWithin(docsDir.path, targetFile.path)) {
      throw ArgumentError('Ungültiger Pfad (Path Traversal erkannt): $preferredFileName');
    }

    await targetFile.writeAsBytes(optimized, flush: true);

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
    final docsDir = await getDocsDir();
    final relativeFolder = p.join('receipts', 'trip_$tripId', 'expense_$expenseId');
    final targetDir = Directory(p.join(docsDir.path, relativeFolder));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final sanitizedDisplayName = sanitizeFileName(fileName);
    final actualFileName = generateUniqueName ? _generateInternalFileName() : sanitizedDisplayName;
    final targetRelativePath = p.posix.join('receipts', 'trip_$tripId', 'expense_$expenseId', actualFileName);
    final targetFile = File(p.join(docsDir.path, targetRelativePath));

    if (!p.isWithin(docsDir.path, targetFile.path)) {
      throw ArgumentError('Ungültiger Pfad (Path Traversal erkannt): $fileName');
    }

    await targetFile.writeAsBytes(bytes, flush: true);

    return ProcessedReceiptFile(
      relativePath: targetRelativePath,
      absolutePath: targetFile.path,
      fileName: sanitizedDisplayName,
      byteSize: bytes.length,
      mimeType: 'image/jpeg',
    );
  }

  /// Liest die Bytes eines Belegs anhand seines relativen Pfads.
  Future<Uint8List?> readReceiptBytes(String relativePath) async {
    final docsDir = await getDocsDir();
    final file = File(p.join(docsDir.path, relativePath));
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  /// Gibt den absoluten Pfad zu einem relativen Belegpfad zurück.
  Future<String> resolveAbsolutePath(String relativePath) async {
    final docsDir = await getDocsDir();
    return p.join(docsDir.path, relativePath);
  }

  /// Löscht eine einzelne Belegdatei.
  Future<bool> deleteReceiptFile(String relativePath) async {
    try {
      final docsDir = await getDocsDir();
      final file = File(p.join(docsDir.path, relativePath));
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Löscht den gesamten Belegordner einer Ausgabe (aktiv und im Papierkorb).
  Future<void> deleteExpenseReceiptFolder(int tripId, int expenseId) async {
    try {
      final docsDir = await getDocsDir();
      final activeDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId', 'expense_$expenseId'));
      if (await activeDir.exists()) {
        await activeDir.delete(recursive: true);
      }
      final trashDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
      if (await trashDir.exists()) {
        await trashDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Löscht alle Belege eines Törns (bei Törn-Löschung aus Aktiv- und Papierkorb-Verzeichnis).
  Future<void> deleteTripReceipts(int tripId) async {
    try {
      final docsDir = await getDocsDir();
      final activeDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId'));
      if (await activeDir.exists()) {
        await activeDir.delete(recursive: true);
      }
      final trashDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId'));
      if (await trashDir.exists()) {
        await trashDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  // --- Staging- und Rollback-Mechanismen für crash-sicheren Restore (Finding C) ---

  /// Bereitet das Staging-Verzeichnis für einen Backup-Restore vor.
  Future<Directory> prepareStagingDirectory() async {
    final docsDir = await getDocsDir();
    final stagingDir = Directory(p.join(docsDir.path, 'receipts_staging'));
    if (await stagingDir.exists()) {
      await stagingDir.delete(recursive: true);
    }
    await stagingDir.create(recursive: true);
    return stagingDir;
  }

  /// Bereinigt das Staging-Verzeichnis.
  Future<void> cleanStagingDirectory() async {
    try {
      final docsDir = await getDocsDir();
      final stagingDir = Directory(p.join(docsDir.path, 'receipts_staging'));
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Schreibt Belegbytes in das Staging-Verzeichnis.
  Future<File> stageReceiptBytes({
    required int stagedIndex,
    required Uint8List bytes,
  }) async {
    final docsDir = await getDocsDir();
    final stagingDir = Directory(p.join(docsDir.path, 'receipts_staging'));
    if (!await stagingDir.exists()) {
      await stagingDir.create(recursive: true);
    }
    final file = File(p.join(stagingDir.path, 'staged_rcpt_$stagedIndex.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Atomarer Commit des Restores:
  /// Das bisherige Produktivverzeichnis wird bei Bedarf gesichert, das gestagte Verzeichnis
  /// wird zum neuen Produktivverzeichnis `receipts`.
  Future<void> commitRestoreStaging({
    required Directory stagedActiveDir,
  }) async {
    final docsDir = await getDocsDir();
    final activeDir = Directory(p.join(docsDir.path, 'receipts'));
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_rollback'));

    if (await rollbackDir.exists()) {
      await rollbackDir.delete(recursive: true);
    }

    if (await activeDir.exists()) {
      await _moveDirectory(activeDir, rollbackDir);
    }

    if (await stagedActiveDir.exists()) {
      await _moveDirectory(stagedActiveDir, activeDir);
    } else {
      // Keine Belege im Backup -> leeres Verzeichnis erzeugen
      await activeDir.create(recursive: true);
    }

    // Erfolgreich -> Rollback- und Staging-Verzeichnisse aufräumen
    if (await rollbackDir.exists()) {
      await rollbackDir.delete(recursive: true);
    }
    await cleanStagingDirectory();
  }

  /// Bricht den Restore ab und stellt den vorherigen Zustand aus dem Rollback-Verzeichnis wieder her.
  Future<void> abortRestoreStaging({
    Directory? stagedActiveDir,
  }) async {
    final docsDir = await getDocsDir();
    final activeDir = Directory(p.join(docsDir.path, 'receipts'));
    final rollbackDir = Directory(p.join(docsDir.path, 'receipts_rollback'));

    if (stagedActiveDir != null && await stagedActiveDir.exists()) {
      await stagedActiveDir.delete(recursive: true);
    }

    if (await rollbackDir.exists()) {
      if (await activeDir.exists()) {
        await activeDir.delete(recursive: true);
      }
      await _moveDirectory(rollbackDir, activeDir);
    }

    await cleanStagingDirectory();
  }

  // --- Soft-Delete & Papierkorb für Expense-Undo (Finding D) ---

  /// Verschiebt die Belege einer Ausgabe in den Papierkorb für die Undo-Dauer.
  Future<void> moveToTrash(int tripId, int expenseId) async {
    final docsDir = await getDocsDir();
    final activeExpenseDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId', 'expense_$expenseId'));
    if (!await activeExpenseDir.exists()) return;

    final trashExpenseDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
    await _moveDirectory(activeExpenseDir, trashExpenseDir);
  }

  /// Stellt die Belege einer Ausgabe aus dem Papierkorb wieder her (Undo).
  Future<void> restoreFromTrash(int tripId, int expenseId) async {
    final docsDir = await getDocsDir();
    final trashExpenseDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
    if (!await trashExpenseDir.exists()) return;

    final activeExpenseDir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId', 'expense_$expenseId'));
    await _moveDirectory(trashExpenseDir, activeExpenseDir);
  }

  /// Löscht Belege im Papierkorb endgültig (nach Ablauf des Undo-Fensters).
  Future<void> purgeTrash({int? tripId, int? expenseId}) async {
    final docsDir = await getDocsDir();
    if (tripId != null && expenseId != null) {
      final trashExpenseDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
      if (await trashExpenseDir.exists()) {
        await trashExpenseDir.delete(recursive: true);
      }
    } else if (tripId != null) {
      final trashTripDir = Directory(p.join(docsDir.path, 'receipts_trash', 'trip_$tripId'));
      if (await trashTripDir.exists()) {
        await trashTripDir.delete(recursive: true);
      }
    } else {
      final trashDir = Directory(p.join(docsDir.path, 'receipts_trash'));
      if (await trashDir.exists()) {
        await trashDir.delete(recursive: true);
      }
    }
  }

  Future<void> _moveDirectory(Directory src, Directory dst) async {
    if (!await src.exists()) return;
    if (await dst.exists()) {
      await dst.delete(recursive: true);
    }
    await dst.parent.create(recursive: true);
    try {
      await src.rename(dst.path);
    } catch (_) {
      await _copyDirectory(src, dst);
      await src.delete(recursive: true);
    }
  }

  Future<void> _copyDirectory(Directory src, Directory dst) async {
    await dst.create(recursive: true);
    await for (final entity in src.list(recursive: false)) {
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(p.join(dst.path, p.basename(entity.path))));
      } else if (entity is File) {
        await entity.copy(p.join(dst.path, p.basename(entity.path)));
      }
    }
  }
}



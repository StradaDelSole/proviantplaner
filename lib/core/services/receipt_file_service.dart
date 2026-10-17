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
  final Future<Directory> Function() getDocsDir;

  ReceiptFileService({
    Future<Directory> Function()? docsDirProvider,
  }) : getDocsDir = docsDirProvider ?? getApplicationDocumentsDirectory;

  /// Optimiert ein Bild (Resize falls > 1800px Kantenlänge, EXIF-Strip, JPEG 85%)
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
    final fileName = preferredFileName ?? 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetRelativePath = p.join(relativeFolder, fileName);
    final targetFile = File(p.join(docsDir.path, targetRelativePath));

    await targetFile.writeAsBytes(optimized, flush: true);

    return ProcessedReceiptFile(
      relativePath: targetRelativePath,
      absolutePath: targetFile.path,
      fileName: fileName,
      byteSize: optimized.length,
      mimeType: 'image/jpeg',
    );
  }

  /// Speichert rohe (oder bereits optimierte) Bytes direkt ab, z.B. bei Backup-Restore.
  Future<ProcessedReceiptFile> saveRawReceiptBytes({
    required int tripId,
    required int expenseId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final docsDir = await getDocsDir();
    final relativeFolder = p.join('receipts', 'trip_$tripId', 'expense_$expenseId');
    final targetDir = Directory(p.join(docsDir.path, relativeFolder));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetRelativePath = p.join(relativeFolder, fileName);
    final targetFile = File(p.join(docsDir.path, targetRelativePath));
    await targetFile.writeAsBytes(bytes, flush: true);

    return ProcessedReceiptFile(
      relativePath: targetRelativePath,
      absolutePath: targetFile.path,
      fileName: fileName,
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

  /// Löscht den gesamten Belegordner einer Ausgabe.
  Future<void> deleteExpenseReceiptFolder(int tripId, int expenseId) async {
    try {
      final docsDir = await getDocsDir();
      final dir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId', 'expense_$expenseId'));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Löscht alle Belege eines Törns (bei Törn-Löschung).
  Future<void> deleteTripReceipts(int tripId) async {
    try {
      final docsDir = await getDocsDir();
      final dir = Directory(p.join(docsDir.path, 'receipts', 'trip_$tripId'));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}


/// Domänenmodelle für Belege zu Bordkassenausgaben (RECEIPT1).
library;

import 'dart:typed_data';

/// Repräsentiert ein Belegfoto zu einer Ausgabe.
class ExpenseReceiptItem {
  final int id;
  final int expenseId;
  final int tripId;
  final String filePath; // Relativer Pfad im App-Dokumentenverzeichnis
  final String fileName;
  final int sortOrder;
  final int byteSize;
  final String mimeType;
  final DateTime createdAt;

  const ExpenseReceiptItem({
    required this.id,
    required this.expenseId,
    required this.tripId,
    required this.filePath,
    required this.fileName,
    this.sortOrder = 0,
    this.byteSize = 0,
    this.mimeType = 'image/jpeg',
    required this.createdAt,
  });
}

/// Temporärer Beleg-Kandidat vor dem Speichern einer Ausgabe.
class DraftReceipt {
  final Uint8List bytes;
  final String fileName;
  final String? tempPath;
  final DateTime createdAt;

  DraftReceipt({
    required this.bytes,
    required this.fileName,
    this.tempPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}



/// Riverpod Provider für die Bordkasse (Slice S5).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'kitty_service.dart';

/// Die zwei Ansichts-Segmente im Bordkassen-Reiter (SC-KAS-01).
enum KittyViewSegment {
  expenses,
  people,
}

/// Provider für den ReceiptFileService.
final receiptFileServiceProvider = Provider<ReceiptFileService>((ref) {
  return ReceiptFileService();
});

/// Provider für den KittyService.
final kittyServiceProvider = Provider<KittyService>((ref) {
  final db = ref.watch(databaseProvider);
  final receiptFileService = ref.watch(receiptFileServiceProvider);
  return KittyService(
    tripDao: db.tripDao,
    expenseDao: db.expenseDao,
    receiptFileService: receiptFileService,
  );
});


/// Aktives Segment in der Übersicht ("Ausgaben" oder "Personen").
final kittyViewSegmentProvider = StateProvider<KittyViewSegment>((ref) {
  return KittyViewSegment.expenses;
});

/// Lädt und aktualisiert die Bordkassendaten für einen Törn.
final tripKittyDataProvider =
    FutureProvider.family<TripKittyData, int>((ref, tripId) async {
  final service = ref.watch(kittyServiceProvider);
  return service.loadKittyData(tripId);
});

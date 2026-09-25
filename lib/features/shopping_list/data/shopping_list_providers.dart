/// Riverpod Provider für die Vorratsliste und ihre Sichten (Slice S4).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'shopping_list_service.dart';

/// Die zwei Hauptsichten der Vorratsliste gemäß SC-LST-01.
enum ShoppingListViewMode {
  plan,
  shop,
}

/// Provider für den ShoppingListService.
final shoppingListServiceProvider = Provider<ShoppingListService>((ref) {
  final db = ref.watch(databaseProvider);
  final catalogRepo = ref.watch(catalogRepositoryProvider);
  final tripService = ref.watch(tripServiceProvider);

  return ShoppingListService(
    tripDao: db.tripDao,
    listItemDao: db.listItemDao,
    catalogRepository: catalogRepo,
    tripService: tripService,
  );
});

/// Aktiver Sichten-Modus ("Planen" oder "Einkaufen").
final shoppingListViewModeProvider = StateProvider<ShoppingListViewMode>((ref) {
  return ShoppingListViewMode.plan;
});

/// Filter nach Einkaufsstopp (null = Alle Stopps).
final selectedStopFilterProvider = StateProvider<int?>((ref) => null);

/// Lädt und aktualisiert die Vorratsliste für einen Törn.
final tripShoppingListProvider =
    FutureProvider.family<TripShoppingListData, int>((ref, tripId) async {
  final service = ref.watch(shoppingListServiceProvider);
  return service.loadShoppingList(tripId);
});

/// Lädt die Einlagerungs-Checkliste für einen Törn.
final storageChecklistProvider =
    FutureProvider.family<List<StorageChecklistEntry>, int>((ref, tripId) async {
  final service = ref.watch(shoppingListServiceProvider);
  return service.loadStorageChecklist(tripId);
});

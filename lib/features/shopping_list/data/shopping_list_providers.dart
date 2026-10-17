/// Riverpod Provider für die Vorratsliste und ihre Sichten (Slice S4).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/provisioning_review_models.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'shopping_list_service.dart';

/// Sortiermodus der Vorratsliste gemäß FEEDBACK_R1 Punkt 7:
/// Eine Liste, umschaltbar nach Kategorie oder Supermarkt-Abteilung.
enum ShoppingListSortMode {
  category,
  department;

  // Rückwärtskompatibilität für bestehende S4-Tests
  static const ShoppingListSortMode plan = ShoppingListSortMode.category;
  static const ShoppingListSortMode shop = ShoppingListSortMode.department;
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

/// Aktiver Sortiermodus ("Nach Kategorie" oder "Nach Abteilung").
/// PIVOT1 / Decision 16: Vorratsliste standardmäßig nach Supermarkt-Abteilung.
final shoppingListSortModeProvider = StateProvider<ShoppingListSortMode>((ref) {
  return ShoppingListSortMode.department;
});

/// Rückwärtskompatibler Alias
final shoppingListViewModeProvider = shoppingListSortModeProvider;
typedef ShoppingListViewMode = ShoppingListSortMode;

/// Filter nach Einkaufsstopp (null = Alle Stopps).
final selectedStopFilterProvider = StateProvider<int?>((ref) => null);

/// Stream-Provider für alle ListItems eines Törns.
final tripListItemsProvider = StreamProvider.family<List<ListItem>, int>((ref, tripId) {
  final db = ref.watch(databaseProvider);
  return db.listItemDao.watchListItemsForTrip(tripId);
});

/// Stream-Provider für alle Allocations eines Törns.
final tripAllocationsProvider = StreamProvider.family<List<ListItemAllocation>, int>((ref, tripId) {
  final db = ref.watch(databaseProvider);
  return db.listItemDao.watchAllocationsForTrip(tripId);
});

/// Lädt und aktualisiert die Vorratsliste für einen Törn.
/// Reaktiv verknüpft mit den Drift-Streams für Törn, Tage, Stopps, Crew, ListItems und Allocations,
/// sodass jede Mutation in der Datenbank unmittelbar eine Neuberechnung auslöst.
final tripShoppingListProvider =
    FutureProvider.family<TripShoppingListData, int>((ref, tripId) async {
  ref.watch(tripByIdProvider(tripId));
  ref.watch(tripDaysByIdProvider(tripId));
  ref.watch(tripStopsByIdProvider(tripId));
  ref.watch(tripCrewByIdProvider(tripId));
  ref.watch(tripListItemsProvider(tripId));
  ref.watch(tripAllocationsProvider(tripId));

  final service = ref.watch(shoppingListServiceProvider);
  return service.loadShoppingList(tripId);
});

/// Lädt die Einlagerungs-Checkliste für einen Törn.
final storageChecklistProvider =
    FutureProvider.family<List<StorageChecklistEntry>, int>((ref, tripId) async {
  final service = ref.watch(shoppingListServiceProvider);
  return service.loadStorageChecklist(tripId);
});

/// Führt die flüchtige Vorratsprüfung durch (PIVOT2).
/// Reaktiv verknüpft mit tripShoppingListProvider, tripCrewByIdProvider und tripDaysByIdProvider,
/// sodass jede Änderung an Artikeln, Packungszahlen, Stopps, Allokationen, Crew oder Tagen
/// den Review automatisch und unterbrechungsfrei aktualisiert.
final provisioningReviewProvider =
    FutureProvider.family<ProvisioningReviewResult, int>((ref, tripId) async {
  final listData = await ref.watch(tripShoppingListProvider(tripId).future);
  final crew = await ref.watch(tripCrewByIdProvider(tripId).future);
  final days = await ref.watch(tripDaysByIdProvider(tripId).future);
  final service = ref.watch(shoppingListServiceProvider);
  return service.reviewProvisioningListData(
    listData: listData,
    crew: crew,
    days: days,
  );
});

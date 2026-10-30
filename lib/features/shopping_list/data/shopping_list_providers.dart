/// Riverpod Provider für die Vorratsliste und ihre Sichten (Slice S4).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
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
final Provider<ShoppingListService> shoppingListServiceProvider =
    Provider<ShoppingListService>((ref) {
  final db = ref.watch(databaseProvider);
  final catalogRepo = ref.watch(catalogRepositoryProvider);
  final tripService = ref.watch(tripServiceProvider);

  final service = ShoppingListService(
    tripDao: db.tripDao,
    listItemDao: db.listItemDao,
    catalogRepository: catalogRepo,
    tripService: tripService,
  );
  service.onTripDataChanged = (tripId) {
    ref.read(tripDataVersionProvider(tripId).notifier).update((v) => v + 1);
  };
  return service;
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

/// Lädt und aktualisiert die Vorratsliste für einen Törn.
final tripShoppingListProvider =
    FutureProvider.family<TripShoppingListData, int>((ref, tripId) async {
  await ref.watch(appStartupRecoveryProvider.future);
  ref.watch(tripDataVersionProvider(tripId));
  final service = ref.watch(shoppingListServiceProvider);
  return service.loadShoppingList(tripId);
});

/// Lädt die Einlagerungs-Checkliste für einen Törn.
final storageChecklistProvider =
    FutureProvider.family<List<StorageChecklistEntry>, int>((ref, tripId) async {
  await ref.watch(appStartupRecoveryProvider.future);
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

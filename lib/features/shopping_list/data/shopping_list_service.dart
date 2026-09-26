/// Service für die Verwaltung und Gruppierung der Vorratsliste (Slice S4).
library;

import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/database/tables.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

/// Aggregiertes Datenobjekt der gesamten Vorratsliste für einen Törn.
class TripShoppingListData {
  final Trip trip;
  final List<ShoppingStop> stops;
  final List<ShoppingListItemView> allItems;
  final List<ShoppingListCategoryView> categories;
  final List<ShoppingListDepartmentView> departments;

  const TripShoppingListData({
    required this.trip,
    required this.stops,
    required this.allItems,
    required this.categories,
    required this.departments,
  });
}

/// Parameter-Objekt zum Erstellen einer eigenen Position (SC-LST-05).
class CustomItemInput {
  final int tripId;
  final String name;
  final double quantity;
  final String unit;
  final String department;
  final String? categoryId;
  final int? shoppingStopId;

  const CustomItemInput({
    required this.tripId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.department,
    this.categoryId,
    this.shoppingStopId,
  });
}

/// Eintrag in der Einlagerungs-Checkliste (SC-STO-01).
class StorageChecklistEntry {
  final String hintKey;
  final String title;
  final String explanation;
  final List<ShoppingListItemView> affectedItems;
  final bool isCompleted;

  const StorageChecklistEntry({
    required this.hintKey,
    required this.title,
    required this.explanation,
    required this.affectedItems,
    required this.isCompleted,
  });
}

/// Service zur Aufbereitung und Verwaltung aller Vorratselemente.
class ShoppingListService {
  final TripDao tripDao;
  final ListItemDao listItemDao;
  final CatalogRepository catalogRepository;
  final TripService tripService;

  ShoppingListService({
    required this.tripDao,
    required this.listItemDao,
    required this.catalogRepository,
    required this.tripService,
  });

  /// Lädt alle Vorräte, Gruppierungen und Zuordnungen für den angegebenen Törn.
  Future<TripShoppingListData> loadShoppingList(int tripId) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) {
      throw ArgumentError('Törn mit ID $tripId wurde nicht gefunden.');
    }

    final stops = await tripDao.getShoppingStopsForTrip(tripId);
    final rawItems = await listItemDao.getListItemsForTrip(tripId);

    if (catalogRepository.catalog == null) {
      await catalogRepository.loadFromBundle();
    }
    final catalog = catalogRepository.catalog!;

    final allAllocations = await (listItemDao.select(listItemDao.listItemAllocations)
          ..where((tbl) => tbl.tripId.equals(tripId)))
        .get();

    final allocationsByItem = <int, Map<int, ListItemAllocation>>{};
    for (final alloc in allAllocations) {
      allocationsByItem.putIfAbsent(alloc.listItemId, () => {})[alloc.shoppingStopId] = alloc;
    }

    final itemViews = _buildItemViews(rawItems, catalog, allocationsByItem);
    final categories = _buildCategoryViews(catalog, itemViews);
    final departments = _buildDepartmentViews(itemViews);

    return TripShoppingListData(
      trip: trip,
      stops: stops,
      allItems: itemViews,
      categories: categories,
      departments: departments,
    );
  }

  /// Erzeugt die flache Liste aller ItemViews.
  List<ShoppingListItemView> _buildItemViews(
    List<ListItem> rawItems,
    CatalogData catalog,
    Map<int, Map<int, ListItemAllocation>> allocationsByItem,
  ) {
    final result = <ShoppingListItemView>[];

    for (final raw in rawItems) {
      if (raw.isCustom) {
        result.add(_buildCustomItemView(raw, allocationsByItem[raw.id] ?? {}));
      } else {
        final variant = catalog.getVariant(raw.catalogId);
        if (variant != null) {
          result.add(_buildCatalogItemView(raw, variant, allocationsByItem[raw.id] ?? {}));
        }
      }
    }
    return result;
  }

  ShoppingListItemView _buildCustomItemView(
    ListItem raw,
    Map<int, ListItemAllocation> allocations,
  ) {
    final dept = CatalogDepartment.fromString(
      raw.customDepartment ?? 'haushalt',
      id: raw.catalogId,
      field: 'customDepartment',
    );

    return ShoppingListItemView(
      item: raw,
      variant: null,
      id: raw.catalogId,
      name: raw.customName ?? 'Eigene Position',
      unit: raw.customUnit ?? 'Stück',
      department: dept,
      categoryId: 'haushalt',
      calculatedPackages: raw.calculatedPackages,
      overriddenPackages: raw.overriddenPackages,
      calculatedQuantity: raw.calculatedQuantity,
      customPackageSize: raw.customPackageSize ?? 1.0,
      isSelected: raw.selected,
      share: raw.share,
      isCustom: true,
      shelfLifeDays: 30,
      storageHints: const [],
      checkState: raw.checkState,
      allocationsByStop: allocations,
    );
  }

  ShoppingListItemView _buildCatalogItemView(
    ListItem raw,
    CatalogVariant variant,
    Map<int, ListItemAllocation> allocations,
  ) {
    return ShoppingListItemView(
      item: raw,
      variant: variant,
      id: variant.id,
      name: variant.nameDe,
      unit: variant.pack.unit,
      department: variant.department,
      categoryId: variant.group,
      calculatedPackages: raw.calculatedPackages,
      overriddenPackages: raw.overriddenPackages,
      calculatedQuantity: raw.calculatedQuantity,
      customPackageSize: raw.customPackageSize ?? variant.pack.size,
      isSelected: raw.selected,
      share: raw.share,
      isCustom: false,
      shelfLifeDays: variant.shelfLifeDays,
      storageHints: variant.storage,
      checkState: raw.checkState,
      allocationsByStop: allocations,
    );
  }

  /// Baut die hierarchische Kategoriestruktur für die Planungsansicht.
  List<ShoppingListCategoryView> _buildCategoryViews(
    CatalogData catalog,
    List<ShoppingListItemView> items,
  ) {
    final itemsByGroup = <String, List<ShoppingListItemView>>{};
    for (final it in items) {
      if (!it.isCustom && it.variant != null) {
        itemsByGroup.putIfAbsent(it.variant!.group, () => []).add(it);
      }
    }

    final categoryViews = <ShoppingListCategoryView>[];
    for (final cat in catalog.categories) {
      final groupsInCat = catalog.groups.where((g) => g.category == cat.id).toList();
      final groupViews = <ShoppingListGroupView>[];

      for (final g in groupsInCat) {
        final variants = itemsByGroup[g.id] ?? [];
        if (variants.isNotEmpty) {
          groupViews.add(ShoppingListGroupView(group: g, variants: variants));
        }
      }

      if (groupViews.isNotEmpty) {
        categoryViews.add(ShoppingListCategoryView(category: cat, groups: groupViews));
      }
    }
    return categoryViews;
  }

  /// Baut die Abteilungsübersicht in fester Ladenreihenfolge (Design Brief 5.3).
  List<ShoppingListDepartmentView> _buildDepartmentViews(List<ShoppingListItemView> items) {
    const storeOrder = [
      CatalogDepartment.obstGemuese,
      CatalogDepartment.backwaren,
      CatalogDepartment.molkerei,
      CatalogDepartment.fleischFisch,
      CatalogDepartment.trockenware,
      CatalogDepartment.konserven,
      CatalogDepartment.suesswaren,
      CatalogDepartment.getraenke,
      CatalogDepartment.drogerie,
      CatalogDepartment.haushalt,
      CatalogDepartment.apotheke,
      CatalogDepartment.technik,
    ];

    final departmentViews = <ShoppingListDepartmentView>[];
    for (final dept in storeOrder) {
      final matching = items.where((it) => it.department == dept).toList();
      if (matching.isNotEmpty) {
        departmentViews.add(ShoppingListDepartmentView(department: dept, items: matching));
      }
    }
    return departmentViews;
  }

  /// Erhöht die Packungsanzahl um 1 (+ Stepper).
  Future<void> incrementPackages(ShoppingListItemView itemView) async {
    final next = itemView.effectivePackages + 1;
    await listItemDao.setOverriddenPackages(itemView.item.id, next);
  }

  /// Verringert die Packungsanzahl um 1 (− Stepper, min. 0).
  Future<void> decrementPackages(ShoppingListItemView itemView) async {
    final next = (itemView.effectivePackages - 1) < 0 ? 0 : itemView.effectivePackages - 1;
    await listItemDao.setOverriddenPackages(itemView.item.id, next);
  }

  /// Setzt eine manuelle Überschreibung zurück ("zurücksetzen").
  Future<void> resetOverride(ShoppingListItemView itemView) async {
    await listItemDao.setOverriddenPackages(itemView.item.id, null);
  }

  /// Setzt die Packungsanzahl direkt per Eingabe (FEEDBACK_R1 Punkt 6).
  Future<void> setPackages(ShoppingListItemView itemView, int packages) async {
    final clamped = packages < 0 ? 0 : packages;
    await listItemDao.setOverriddenPackages(itemView.item.id, clamped);
  }

  /// Aktualisiert den Prüfstatus einer Position (vorhanden / fehlt / nachkaufen).
  Future<void> updateCheckState({
    required int tripId,
    required int listItemId,
    required CheckItemState state,
  }) async {
    await listItemDao.setCheckState(listItemId, state);
    await tripService.recalculateTrip(tripId);
  }

  /// Ändert die Packungsgröße und berechnet die Packungszahl neu.
  Future<void> updateCustomPackageSize({
    required int tripId,
    required int listItemId,
    required double packSize,
  }) async {
    await listItemDao.setCustomPackageSize(listItemId, packSize);
    await tripService.recalculateTrip(tripId);
  }

  /// Schaltet die Auswahl einer Variante an oder aus.
  Future<void> toggleVariantSelected({
    required int tripId,
    required int listItemId,
    required bool isSelected,
  }) async {
    await listItemDao.setSelected(listItemId, isSelected);
    await tripService.recalculateTrip(tripId);
  }

  /// Aktualisiert den Prozent-Anteil einer Variante.
  Future<void> updateVariantShare({
    required int tripId,
    required int listItemId,
    required double share,
  }) async {
    await listItemDao.setShare(listItemId, share);
    await tripService.recalculateTrip(tripId);
  }

  /// Weist einem Einkaufsstopp eine Teilmenge an Packungen zu.
  Future<int> allocateToStop({
    required int tripId,
    required int listItemId,
    required int shoppingStopId,
    required int packages,
  }) {
    return listItemDao.setAllocation(
      tripId: tripId,
      listItemId: listItemId,
      shoppingStopId: shoppingStopId,
      packages: packages,
    );
  }

  /// Legt eine eigene Position an.
  Future<int> addCustomItem(CustomItemInput input) {
    return listItemDao.addCustomItem(
      tripId: input.tripId,
      name: input.name,
      quantity: input.quantity,
      unit: input.unit,
      department: input.department,
      categoryId: input.categoryId,
      shoppingStopId: input.shoppingStopId,
    );
  }

  /// Schaltet den Gekauft-Status im Einkaufsmodus um.
  Future<bool> toggleBought({
    required int tripId,
    required int listItemId,
    required int shoppingStopId,
    required bool isBought,
  }) {
    return listItemDao.toggleBought(
      tripId: tripId,
      listItemId: listItemId,
      shoppingStopId: shoppingStopId,
      isBought: isBought,
    );
  }

  /// Lädt die Einlagerungs-Checkliste nach Hinweisen aus dem Katalog.
  Future<List<StorageChecklistEntry>> loadStorageChecklist(int tripId) async {
    final listData = await loadShoppingList(tripId);
    final catalog = catalogRepository.catalog!;
    final hints = catalog.storageHints;

    final entries = <StorageChecklistEntry>[];
    for (final hintKey in hints.keys) {
      final affected = listData.allItems
          .where((it) => it.isSelected && it.storageHints.contains(hintKey))
          .toList();

      if (affected.isNotEmpty) {
        final allStored = affected.every((it) {
          final allocs = it.allocationsByStop.values;
          return allocs.isNotEmpty && allocs.every((a) => a.isStored);
        });

        entries.add(
          StorageChecklistEntry(
            hintKey: hintKey,
            title: _hintTitle(hintKey),
            explanation: hints[hintKey] ?? '',
            affectedItems: affected,
            isCompleted: allStored,
          ),
        );
      }
    }
    return entries;
  }

  /// Überschrift für die Einlagerungs-Schritte.
  String _hintTitle(String hintKey) => switch (hintKey) {
        'remove_cardboard' => 'Kartons an Land auspacken',
        'wash_produce' => 'Frischeprodukte waschen & trocknen',
        'potatoes_onions' => 'Kartoffeln & Zwiebeln dunkel lagern',
        'remove_labels' => 'Etiketten entfernen & Deckel beschriften',
        'eggs' => 'Eier kühl & dunkel lagern',
        'cool_first' => 'Sofort in die Kühlung',
        'keep_dry' => 'Trocken und dicht verpacken',
        _ => 'Lagerungshinweis',
      };

  /// Markiert alle Elemente eines Lagerungshinweises als eingelagert.
  Future<void> toggleStorageHint(StorageChecklistEntry entry, bool isStored) async {
    for (final it in entry.affectedItems) {
      await listItemDao.setStored(it.item.id, isStored);
    }
  }
}

/// Service für die Verwaltung und Gruppierung der Vorratsliste (Slice S4).
library;

import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/database/tables.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/calculation_result.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
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

  /// Berechnet das Gesamtgewicht und -volumen aller übernommenen Positionen auf der Vorratsliste.
  ProvisionWeightVolume get weightAndVolume {
    final adoptedVariants = allItems
        .where((it) => it.isOnList)
        .map((it) => VariantCalculationResult(
              variantId: it.id,
              groupId: it.variant?.group ?? it.categoryId,
              nameDe: it.name,
              department: it.department,
              isSelected: it.isSelected,
              share: it.share,
              calculatedNeedAmount: it.calculatedQuantity,
              unit: it.unit,
              packSize: it.effectivePackSize,
              packUnit: it.variant?.pack.unit ?? it.unit,
              calculatedPackages: it.calculatedPackages,
              effectivePackages: it.effectivePackages,
              shelfLifeDays: it.shelfLifeDays,
              effectiveShelfLifeDays: it.shelfLifeDays,
              buyFreshUnderway: false,
              storage: it.storageHints,
              tags: it.variant?.tags ?? [],
            ))
        .toList();
    return QuantityEngine.calculateWeightAndVolume(adoptedVariants);
  }
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

    final days = await tripDao.getDaysForTrip(tripId);
    final crew = await tripDao.getCrewForTrip(tripId);

    TripCalculationResult? calcResult;
    if (catalogRepository.quantities != null) {
      final engine = QuantityEngine(
        catalog: catalog,
        quantities: catalogRepository.quantities!,
      );
      final tripDayInputs = days.map((d) => TripDayInput(
        dayNumber: d.dayNumber,
        isLunchRestaurant: d.lunchRestaurant,
        isEveningRestaurant: d.dinnerRestaurant,
      )).toList();
      final crewInputs = crew.map((c) => CrewMemberInput(
        id: c.id.toString(),
        name: c.name,
        isAdult: !c.isChild,
        isVegetarian: c.isVegetarian,
        noAlcohol: c.isNonDrinker,
        customEatLevel: c.customEatLevel != null ? EatProfileLevel.fromString(c.customEatLevel!) : null,
        customDrinkLevel: c.customDrinkLevel != null ? DrinkProfileLevel.fromString(c.customDrinkLevel!) : null,
      )).toList();
      final userItemStates = <String, UserItemState>{};
      for (final it in rawItems) {
        userItemStates[it.catalogId] = UserItemState(
          isSelected: it.selected,
          share: it.share,
          customPackSize: it.customPackageSize,
        );
      }
      calcResult = engine.calculateTrip(
        QuantityCalculationInput(
          daysCount: trip.daysCount,
          climate: trip.climate,
          region: trip.climate,
          fridgeCapacityLiters: trip.fridgeCapacity.toDouble(),
          hasFreezer: trip.hasFreezer,
          freezerCapacityLiters: trip.freezerCapacity > 0 ? trip.freezerCapacity.toDouble() : null,
          waterTankLiters: trip.waterTankLiters > 0 ? trip.waterTankLiters.toDouble() : null,
          isWaterTankDrinkable: trip.isWaterTankDrinkable,
          crewAppetite: trip.appetite,
          crewReserve: trip.reserveDays == 'all_anchoring_days',
          crewDrinking: trip.drinkingHabit,
          tripDays: tripDayInputs,
          crewMembers: crewInputs,
          userItemStates: userItemStates,
        ),
      );
    }

    final itemViews = _buildItemViews(rawItems, catalog, allocationsByItem, calcResult);
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
    TripCalculationResult? calcResult,
  ) {
    final result = <ShoppingListItemView>[];

    for (final raw in rawItems) {
      if (raw.isCustom) {
        result.add(_buildCustomItemView(raw, allocationsByItem[raw.id] ?? {}));
      } else {
        final variant = catalog.getVariant(raw.catalogId);
        if (variant != null) {
          result.add(_buildCatalogItemView(catalog, raw, variant, allocationsByItem[raw.id] ?? {}, calcResult));
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
      isAdopted: raw.isAdopted,
      allocationsByStop: allocations,
    );
  }

  ShoppingListItemView _buildCatalogItemView(
    CatalogData catalog,
    ListItem raw,
    CatalogVariant variant,
    Map<int, ListItemAllocation> allocations,
    TripCalculationResult? calcResult,
  ) {
    final group = catalog.getGroup(variant.group);
    final vr = calcResult?.getVariantResult(variant.id);
    return ShoppingListItemView(
      item: raw,
      variant: variant,
      id: variant.id,
      name: variant.nameDe,
      unit: variant.pack.unit,
      department: variant.department,
      categoryId: group?.category ?? variant.group,
      calculatedPackages: raw.calculatedPackages,
      overriddenPackages: raw.overriddenPackages,
      calculatedQuantity: raw.calculatedQuantity,
      customPackageSize: raw.customPackageSize ?? variant.pack.size,
      isSelected: raw.selected,
      share: raw.share,
      isCustom: false,
      shelfLifeDays: vr?.effectiveShelfLifeDays ?? variant.shelfLifeDays,
      storageHints: variant.storage,
      storageNotice: vr?.storageNotice,
      remainderNotice: vr?.remainderNotice,
      checkState: raw.checkState,
      isAdopted: raw.isAdopted,
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

  /// Erhöht die Packungsanzahl um 1 (+ Stepper). Übernimmt die Position, falls noch nicht auf der Liste.
  Future<void> incrementPackages(ShoppingListItemView itemView) async {
    if (!itemView.isAdopted) {
      final initial = itemView.calculatedPackages > 0 ? itemView.calculatedPackages : 1;
      await listItemDao.adoptItem(itemView.item.id, packages: initial);
    } else {
      final next = itemView.effectivePackages + 1;
      await listItemDao.adoptItem(itemView.item.id, packages: next);
    }
  }

  /// Verringert die Packungsanzahl um 1 (− Stepper, bei <= 0 wird die Position entfernt).
  Future<void> decrementPackages(ShoppingListItemView itemView) async {
    final next = itemView.effectivePackages - 1;
    if (next <= 0) {
      await listItemDao.unadoptItem(itemView.item.id);
    } else {
      await listItemDao.adoptItem(itemView.item.id, packages: next);
    }
  }

  /// Setzt eine manuelle Überschreibung zurück ("zurücksetzen").
  Future<void> resetOverride(ShoppingListItemView itemView) async {
    await listItemDao.setOverriddenPackages(itemView.item.id, null);
  }

  /// Setzt die Packungsanzahl direkt per Eingabe (FEEDBACK_R1 Punkt 5 & 6).
  Future<void> setPackages(ShoppingListItemView itemView, int packages) async {
    if (packages <= 0) {
      await listItemDao.unadoptItem(itemView.item.id);
    } else {
      await listItemDao.adoptItem(itemView.item.id, packages: packages);
    }
  }

  /// Übernimmt einen einzelnen Vorschlag auf die Vorratsliste (FB1-B).
  Future<void> adoptItem({required int tripId, required int listItemId, int? packages}) async {
    await listItemDao.adoptItem(listItemId, packages: packages);
  }

  /// Entfernt eine Position von der Vorratsliste (FB1-B).
  Future<void> unadoptItem({required int tripId, required int listItemId}) async {
    await listItemDao.unadoptItem(listItemId);
  }

  /// Übernimmt alle Vorschläge von Varianten mit default_selected == true (FB1-B).
  Future<void> adoptAllSuggestions(int tripId) async {
    if (catalogRepository.catalog == null) {
      await catalogRepository.loadFromBundle();
    }
    final catalog = catalogRepository.catalog!;
    final defaultSelectedIds = catalog.variants
        .where((v) => v.defaultSelected)
        .map((v) => v.id)
        .toSet();

    await listItemDao.adoptSuggestions(
      tripId: tripId,
      defaultSelectedCatalogIds: defaultSelectedIds,
    );
  }

  /// Übernimmt alle Vorschläge einer bestimmten Kategorie (FB1-B).
  Future<void> adoptCategorySuggestions({
    required int tripId,
    required String categoryId,
  }) async {
    if (catalogRepository.catalog == null) {
      await catalogRepository.loadFromBundle();
    }
    final catalog = catalogRepository.catalog!;
    final catGroupIds = catalog.groups.where((g) => g.category == categoryId).map((g) => g.id).toSet();
    final defaultSelectedIds = catalog.variants
        .where((v) => catGroupIds.contains(v.group) && v.defaultSelected)
        .map((v) => v.id)
        .toSet();

    await listItemDao.adoptCategorySuggestions(
      tripId: tripId,
      categoryDefaultSelectedIds: defaultSelectedIds,
    );
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

  /// Schaltet die Auswahl einer Variante an oder aus (FB1-B: Übernehmen / Entfernen).
  Future<void> toggleVariantSelected({
    required int tripId,
    required int listItemId,
    required bool isSelected,
  }) async {
    if (isSelected) {
      await listItemDao.adoptItem(listItemId);
    } else {
      await listItemDao.unadoptItem(listItemId);
    }
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

  /// Verschiebt Packungen von einem Stopp zu einem anderen Stopp.
  Future<void> movePackagesBetweenStops({
    required ShoppingListItemView it,
    required int fromStopId,
    required int toStopId,
    required int packagesCount,
  }) async {
    final currentFromAlloc = it.allocationsByStop[fromStopId]?.allocatedPackages ?? 0;
    final newFrom = (currentFromAlloc - packagesCount).clamp(0, it.effectivePackages);
    final currentToAlloc = it.allocationsByStop[toStopId]?.allocatedPackages ?? 0;
    final newTo = currentToAlloc + packagesCount;

    await listItemDao.setAllocation(
      tripId: it.item.tripId,
      listItemId: it.item.id,
      shoppingStopId: fromStopId,
      packages: newFrom,
    );
    await listItemDao.setAllocation(
      tripId: it.item.tripId,
      listItemId: it.item.id,
      shoppingStopId: toStopId,
      packages: newTo,
    );
  }

  /// Verarbeitet nicht gekaufte Artikel eines Einkaufsstopps (FIX-A / Issue #14).
  /// [postpone]: true = "Später" (verschiebt auf Folge-Stopp), false = "Streichen" (Menge reduzieren/entfernen).
  Future<void> handleUnboughtItems({
    required int tripId,
    required int currentStopId,
    required bool postpone,
    int? targetStopId,
  }) async {
    final listData = await loadShoppingList(tripId);
    final currentStop = listData.stops.where((s) => s.id == currentStopId).firstOrNull;
    if (currentStop == null) return;

    final isFirstStop = listData.stops.firstOrNull?.id == currentStopId;

    final unboughtItems = <({ShoppingListItemView item, int unboughtCount})>[];
    for (final it in listData.allItems) {
      if (!it.isOnList) continue;
      final totalOtherAlloc = it.allocationsByStop.entries
          .where((e) => e.key != currentStopId)
          .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
      final countAtStop = it.packagesAtStop(
        currentStopId,
        isFirstStop: isFirstStop,
        totalOtherAllocated: totalOtherAlloc,
      );
      final isBought = it.isBoughtAtStop(currentStopId);
      if (countAtStop > 0 && !isBought) {
        unboughtItems.add((item: it, unboughtCount: countAtStop));
      }
    }

    if (unboughtItems.isEmpty) return;

    if (postpone) {
      int nextStopId;
      if (targetStopId != null) {
        nextStopId = targetStopId;
      } else {
        final laterStops = listData.stops.where((s) => s.dayNumber >= currentStop.dayNumber && s.id != currentStopId).toList();
        if (laterStops.isNotEmpty) {
          nextStopId = laterStops.first.id;
        } else {
          final nextDay = (currentStop.dayNumber + 1).clamp(1, listData.trip.daysCount);
          nextStopId = await tripService.addShoppingStop(
            tripId: tripId,
            name: 'Einkaufsstopp Tag $nextDay',
            dayNumber: nextDay,
          );
        }
      }

      for (final entry in unboughtItems) {
        final it = entry.item;
        final unbought = entry.unboughtCount;

        final currentAlloc = it.allocationsByStop[currentStopId];
        if (currentAlloc != null) {
          final newCurrent = (currentAlloc.allocatedPackages - unbought).clamp(0, it.effectivePackages);
          await listItemDao.setAllocation(
            tripId: tripId,
            listItemId: it.item.id,
            shoppingStopId: currentStopId,
            packages: newCurrent,
          );
        }

        final targetAlloc = it.allocationsByStop[nextStopId]?.allocatedPackages ?? 0;
        await listItemDao.setAllocation(
          tripId: tripId,
          listItemId: it.item.id,
          shoppingStopId: nextStopId,
          packages: targetAlloc + unbought,
        );
      }
    } else {
      for (final entry in unboughtItems) {
        final it = entry.item;
        final unbought = entry.unboughtCount;
        final newEffective = it.effectivePackages - unbought;

        final currentAlloc = it.allocationsByStop[currentStopId];
        if (currentAlloc != null) {
          final newCur = (currentAlloc.allocatedPackages - unbought).clamp(0, it.effectivePackages);
          await listItemDao.setAllocation(
            tripId: tripId,
            listItemId: it.item.id,
            shoppingStopId: currentStopId,
            packages: newCur,
          );
        }

        if (newEffective <= 0) {
          await listItemDao.unadoptItem(it.item.id);
        } else {
          await listItemDao.adoptItem(it.item.id, packages: newEffective);
        }
      }
    }
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

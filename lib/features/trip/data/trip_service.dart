/// Service für Törn-Verwaltung, Restaurant-Toggles und reaktive Mengenberechnung (Slice S3).
library;

import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';

class TripService {
  final TripDao tripDao;
  final ListItemDao listItemDao;
  final CatalogRepository catalogRepository;

  TripService({
    required this.tripDao,
    required this.listItemDao,
    required this.catalogRepository,
  });

  /// Erstellt einen vollständigen Törn mit Boot, Einstellungen, Crew und erstem Einkaufsstopp.
  /// Führt unmittelbar die Initial-Berechnung aller Vorräte durch.
  Future<int> createTripWithCrew({
    required String name,
    required DateTime startDate,
    required int daysCount,
    required bool isCharter,
    required String boatType,
    String? climate,
    String? region,
    required double fridgeCapacityLiters,
    required CrewAppetite crewAppetite,
    required bool crewReserve,
    required CrewDrinking crewDrinking,
    required List<CrewMemberInput> crewMembers,
  }) async {
    final effectiveClimate = climate ??
        (region != null
            ? (region == 'temperate'
                ? 'cool'
                : (region == 'hot_or_remote'
                    ? 'hot'
                    : (region == 'mediterranean' || region == 'mediterranean_summer' ? 'warm' : region)))
            : 'warm');

    // 1. Törn anlegen (TripDao legt automatisch TripDays und den ersten ShoppingStop an)
    final tripCompanion = TripsCompanion.insert(
      name: name,
      startDate: startDate,
      daysCount: Value(daysCount),
      region: Value(effectiveClimate),
      climate: Value(effectiveClimate),
      isCharter: Value(isCharter),
      boatType: Value(boatType),
      fridgeCapacity: Value(fridgeCapacityLiters.round()),
      hasStorageChecklist: Value(effectiveClimate == 'hot'),
      appetite: Value(crewAppetite),
      reserveDays: Value(crewReserve ? 'all_anchoring_days' : 'none'),
      drinkingHabit: Value(crewDrinking),
      createdAt: Value(DateTime.now()),
    );

    final tripId = await tripDao.createTrip(tripCompanion, initialStopName: 'Ersteinkauf Basis');

    // 2. Crew-Mitglieder speichern
    for (final member in crewMembers) {
      await tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: member.name,
          isChild: Value(!member.isAdult),
          isVegetarian: Value(member.isVegetarian),
          isNonDrinker: Value(member.noAlcohol),
          customEatLevel: Value(member.customEatLevel?.rawValue),
          customDrinkLevel: Value(member.customDrinkLevel?.rawValue),
          iban: Value(member.iban),
          paypalLink: Value(member.paypalLink),
          revolutLink: Value(member.revolutLink),
        ),
      );
    }

    // 3. Vorratsmengen initial berechnen und persistieren
    await recalculateTrip(tripId);

    return tripId;
  }

  /// Berechnet alle Vorräte für den Törn reaktiv neu.
  /// Bestehende manuelle Überschreibungen (overriddenPackages) bleiben unberührt erhalten!
  Future<void> recalculateTrip(int tripId) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) return;

    final days = await tripDao.getDaysForTrip(tripId);
    final crew = await tripDao.getCrewForTrip(tripId);
    final existingItems = await listItemDao.getListItemsForTrip(tripId);

    // Katalog-Repositories sicherstellen
    if (catalogRepository.catalog == null || catalogRepository.quantities == null) {
      await catalogRepository.loadFromBundle();
    }

    final engine = QuantityEngine(
      catalog: catalogRepository.catalog!,
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
      iban: c.iban,
      paypalLink: c.paypalLink,
      revolutLink: c.revolutLink,
    )).toList();

    // Map der Nutzertätigkeiten (Überschreibungen, Abwahlen etc.)
    final userItemStates = <String, UserItemState>{};
    final existingItemMap = <String, ListItem>{};
    for (final item in existingItems) {
      existingItemMap[item.catalogId] = item;
      userItemStates[item.catalogId] = UserItemState(
        isSelected: item.selected,
        share: item.share,
        overriddenPackages: null,
        customPackSize: item.customPackageSize,
      );
    }

    final calculationResult = engine.calculateTrip(
      QuantityCalculationInput(
        daysCount: trip.daysCount,
        climate: trip.climate,
        region: trip.climate,
        fridgeCapacityLiters: trip.fridgeCapacity.toDouble(),
        crewAppetite: trip.appetite,
        crewReserve: trip.reserveDays == 'all_anchoring_days',
        crewDrinking: trip.drinkingHabit,
        tripDays: tripDayInputs,
        crewMembers: crewInputs,
        userItemStates: userItemStates,
      ),
    );

    // Ergebnisse in DB aktualisieren / einfügen
    for (final group in calculationResult.groupResults) {
      for (final variant in group.variantResults) {
        final existing = existingItemMap[variant.variantId];
        if (existing != null) {
          // Nur berechnete Menge & Packungen aktualisieren (overriddenPackages bleibt erhalten)
          await listItemDao.updateListItem(
            existing.copyWith(
              calculatedQuantity: variant.calculatedNeedAmount,
              calculatedPackages: variant.calculatedPackages,
            ),
          );
        } else {
          // Neu einfügen (FB1-B: Liste startet leer, Vorschläge vorhanden)
          await listItemDao.addListItem(
            ListItemsCompanion.insert(
              tripId: tripId,
              catalogId: variant.variantId,
              calculatedQuantity: Value(variant.calculatedNeedAmount),
              calculatedPackages: Value(variant.calculatedPackages),
              selected: Value(variant.isSelected),
              isAdopted: const Value(false),
              share: Value(variant.share),
              overriddenPackages: const Value(null),
              customPackageSize: Value(variant.packSize),
            ),
          );
        }
      }
    }
  }

  /// Schaltet Mittags-Restaurantbesuch für einen Tag um und berechnet Mengen sofort neu.
  Future<void> toggleLunchRestaurant(TripDay day) async {
    final updated = day.copyWith(lunchRestaurant: !day.lunchRestaurant);
    await tripDao.updateTripDay(updated);
    await recalculateTrip(day.tripId);
  }

  /// Schaltet Abends-Restaurantbesuch für einen Tag um und berechnet Mengen sofort neu.
  Future<void> toggleEveningRestaurant(TripDay day) async {
    final updated = day.copyWith(dinnerRestaurant: !day.dinnerRestaurant);
    await tripDao.updateTripDay(updated);
    await recalculateTrip(day.tripId);
  }

  /// Aktualisiert Hafenname oder Tagestyp für einen Tag (reine Info, keine Rechenlogik).
  Future<void> updateDayInfo(TripDay day, {String? portName, String? dayType}) async {
    final updated = day.copyWith(
      portName: Value(portName ?? day.portName),
      dayType: Value(dayType ?? day.dayType),
    );
    await tripDao.updateTripDay(updated);
  }

  // --- Einkaufsstopps CRUD ---

  /// Fügt einen neuen Einkaufsstopp hinzu.
  Future<int> addShoppingStop({
    required int tripId,
    required String name,
    required int dayNumber,
  }) {
    return tripDao.addShoppingStop(
      ShoppingStopsCompanion.insert(
        tripId: tripId,
        name: name,
        dayNumber: Value(dayNumber),
        isInitial: const Value(false),
      ),
    );
  }

  /// Aktualisiert einen Einkaufsstopp (z. B. Umbenennen).
  Future<bool> updateShoppingStop(ShoppingStop stop) {
    return tripDao.updateShoppingStop(stop);
  }

  /// Löscht einen Einkaufsstopp.
  /// Gibt false zurück, wenn es der initiale Stopp ist (dieser darf nicht gelöscht werden).
  Future<bool> deleteShoppingStop(int stopId) {
    return tripDao.deleteShoppingStop(stopId);
  }
}

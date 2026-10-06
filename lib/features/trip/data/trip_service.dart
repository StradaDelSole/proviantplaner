/// Service für Törn-Verwaltung, Restaurant-Toggles und reaktive Mengenberechnung (Slice S3).
library;

import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

class TripService {
  final TripDao tripDao;
  final ListItemDao listItemDao;
  final CatalogRepository catalogRepository;
  final BoatProfileDao? boatProfileDao;

  TripService({
    required this.tripDao,
    required this.listItemDao,
    required this.catalogRepository,
    this.boatProfileDao,
  });

  /// Erstellt einen vollständigen Törn mit Boot, Einstellungen, Crew und erstem Einkaufsstopp.
  /// Führt unmittelbar die Initial-Berechnung aller Vorräte durch.
  /// Falls [boatProfileId] angegeben ist, werden Identitäts- und Bootswerte als Snapshot übernommen.
  Future<int> createTripWithCrew({
    required String name,
    required DateTime startDate,
    required int daysCount,
    bool isCharter = true,
    String boatType = 'monohull',
    String? climate,
    String? region,
    double? fridgeCapacityLiters,
    bool? hasFreezer,
    double? freezerCapacityLiters,
    double? waterTankLiters,
    bool? isWaterTankDrinkable,
    CrewAppetite crewAppetite = CrewAppetite.normal,
    bool crewReserve = false,
    CrewDrinking crewDrinking = CrewDrinking.normal,
    required List<CrewMemberInput> crewMembers,
    int restaurantDinnersCount = 0,
    int restaurantLunchesCount = 0,
    int? boatProfileId,
    String? boatName,
    String? boatManufacturer,
    String? boatModel,
    bool? hasWatermaker,
  }) async {
    final effectiveClimate = climate ??
        (region != null
            ? (region == 'temperate'
                ? 'cool'
                : (region == 'hot_or_remote'
                    ? 'hot'
                    : (region == 'mediterranean' || region == 'mediterranean_summer' ? 'warm' : region)))
            : 'warm');

    // Falls ein Bootsprofil angegeben ist, dessen Werte als Basis für den Snapshot laden
    BoatProfile? profile;
    if (boatProfileId != null && boatProfileDao != null) {
      profile = await boatProfileDao!.getProfileById(boatProfileId);
    }

    final effectiveBoatName = boatName ?? profile?.name;
    final effectiveBoatManufacturer = boatManufacturer ?? profile?.manufacturer;
    final effectiveBoatModel = boatModel ?? profile?.model;
    final effectiveFridgeCapacity = fridgeCapacityLiters != null
        ? fridgeCapacityLiters.round()
        : (profile != null ? profile.fridgeCapacity : 100);
    final effectiveHasFreezer = hasFreezer ?? (profile != null ? profile.hasFreezer : false);
    final effectiveFreezerCapacity = freezerCapacityLiters != null
        ? freezerCapacityLiters.round()
        : (profile != null ? profile.freezerCapacity : 0);
    final effectiveWaterTankLiters = waterTankLiters != null
        ? waterTankLiters.round()
        : (profile != null ? profile.waterTankLiters : 0);
    final effectiveIsWaterTankDrinkable = isWaterTankDrinkable ??
        (profile != null ? profile.isWaterTankDrinkable : false);
    final effectiveHasWatermaker = hasWatermaker ?? (profile?.hasWatermaker ?? false);

    // 1. Törn anlegen (TripDao legt automatisch TripDays und den ersten ShoppingStop an)
    final tripCompanion = TripsCompanion.insert(
      name: name,
      startDate: startDate,
      daysCount: Value(daysCount),
      region: Value(effectiveClimate),
      climate: Value(effectiveClimate),
      isCharter: Value(isCharter),
      boatProfileId: Value(boatProfileId),
      boatName: Value(effectiveBoatName),
      boatManufacturer: Value(effectiveBoatManufacturer),
      boatModel: Value(effectiveBoatModel),
      boatType: Value(boatType),
      fridgeCapacity: Value(effectiveFridgeCapacity),
      hasFreezer: Value(effectiveHasFreezer),
      freezerCapacity: Value(effectiveFreezerCapacity),
      waterTankLiters: Value(effectiveWaterTankLiters),
      isWaterTankDrinkable: Value(effectiveIsWaterTankDrinkable),
      hasWatermaker: Value(effectiveHasWatermaker),
      hasStorageChecklist: Value(effectiveClimate == 'hot'),
      appetite: Value(crewAppetite),
      reserveDays: Value(crewReserve ? 'all_anchoring_days' : 'none'),
      drinkingHabit: Value(crewDrinking),
      createdAt: Value(DateTime.now()),
    );

    final tripId = await tripDao.createTrip(tripCompanion, initialStopName: 'Ersteinkauf Basis');

    // 1b. Restaurantbesuche initial setzen falls angegeben
    if (restaurantDinnersCount > 0 || restaurantLunchesCount > 0) {
      final days = await tripDao.getDaysForTrip(tripId);
      for (int i = 0; i < days.length; i++) {
        final shouldDinner = i < restaurantDinnersCount;
        final shouldLunch = i < restaurantLunchesCount;
        if (shouldDinner || shouldLunch) {
          await tripDao.updateTripDay(days[i].copyWith(
            dinnerRestaurant: shouldDinner,
            lunchRestaurant: shouldLunch,
          ));
        }
      }
    }

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
        hasFreezer: trip.hasFreezer,
        freezerCapacityLiters: trip.freezerCapacity > 0 ? trip.freezerCapacity.toDouble() : null,
        waterTankLiters: trip.waterTankLiters > 0 ? trip.waterTankLiters.toDouble() : null,
        isWaterTankDrinkable: trip.isWaterTankDrinkable,
        hasWatermaker: trip.hasWatermaker,
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

  /// Setzt die genaue Anzahl an Restaurant-Abendessen und -Mittagessen und berechnet Mengen sofort neu.
  Future<void> setRestaurantCounts(int tripId, {required int dinners, required int lunches}) async {
    final days = await tripDao.getDaysForTrip(tripId);
    for (int i = 0; i < days.length; i++) {
      final shouldDinner = i < dinners;
      final shouldLunch = i < lunches;
      if (days[i].dinnerRestaurant != shouldDinner || days[i].lunchRestaurant != shouldLunch) {
        await tripDao.updateTripDay(days[i].copyWith(
          dinnerRestaurant: shouldDinner,
          lunchRestaurant: shouldLunch,
        ));
      }
    }
    await recalculateTrip(tripId);
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

  /// Archiviert oder de-archiviert einen Törn.
  Future<bool> archiveTrip(int tripId, {bool archive = true}) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) return false;
    return tripDao.updateTrip(trip.copyWith(isArchived: archive));
  }

  /// Setzt die Phase des Törns (FIX-A).
  Future<bool> setTripPhase(int tripId, TripPhase phase) {
    return tripDao.setTripPhase(tripId, phase);
  }

  /// Führt einen expliziten Resync der Bootsdaten eines Törns mit dem verknüpften Bootsprofil durch (PIVOT3-A).
  /// Aktualisiert die Snapshot-Werte des Törns auf den aktuellen Stand des verknüpften Bootsprofils.
  /// Gibt false zurück, wenn kein Törn, keine boatProfileId oder kein passendes Profil gefunden wurde.
  Future<bool> resyncTripBoatProfile(int tripId) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null || trip.boatProfileId == null || boatProfileDao == null) {
      return false;
    }
    final profile = await boatProfileDao!.getProfileById(trip.boatProfileId!);
    if (profile == null) {
      return false;
    }

    final updated = trip.copyWith(
      boatName: Value(profile.name),
      boatManufacturer: Value(profile.manufacturer),
      boatModel: Value(profile.model),
      fridgeCapacity: profile.fridgeCapacity,
      hasFreezer: profile.hasFreezer,
      freezerCapacity: profile.freezerCapacity,
      waterTankLiters: profile.waterTankLiters,
      isWaterTankDrinkable: profile.isWaterTankDrinkable,
      hasWatermaker: profile.hasWatermaker,
    );
    await tripDao.updateTrip(updated);
    await recalculateTrip(tripId);
    return true;
  }

  /// Aktualisiert Törn-Stammdaten (Name, Startdatum, Tage, Kapazitäten, Restaurantbesuche) und berechnet Mengen neu.
  Future<void> updateTripDetails({
    required int tripId,
    String? name,
    DateTime? startDate,
    int? daysCount,
    int? fridgeCapacity,
    bool? hasFreezer,
    int? freezerCapacity,
    int? waterTankLiters,
    bool? isWaterTankDrinkable,
    int? restaurantLunches,
    int? restaurantDinners,
    int? boatProfileId,
    String? boatName,
    String? boatManufacturer,
    String? boatModel,
    bool? hasWatermaker,
  }) async {
    final trip = await tripDao.getTripById(tripId);
    if (trip == null) return;

    final effectiveDays = daysCount ?? trip.daysCount;

    if (daysCount != null && daysCount != trip.daysCount) {
      final existingDays = await tripDao.getDaysForTrip(tripId);
      if (daysCount > existingDays.length) {
        for (int i = existingDays.length + 1; i <= daysCount; i++) {
          await tripDao.addTripDay(TripDaysCompanion.insert(
            tripId: tripId,
            dayNumber: i,
          ));
        }
      } else if (daysCount < existingDays.length) {
        final toRemove = existingDays.where((d) => d.dayNumber > daysCount);
        for (final d in toRemove) {
          await tripDao.deleteTripDay(d.id);
        }
      }
    }

    if (restaurantLunches != null || restaurantDinners != null) {
      final days = await tripDao.getDaysForTrip(tripId);
      final currentLunches = days.where((d) => d.lunchRestaurant).length;
      final currentDinners = days.where((d) => d.dinnerRestaurant).length;
      final clampedLunches = (restaurantLunches ?? currentLunches).clamp(0, effectiveDays);
      final clampedDinners = (restaurantDinners ?? currentDinners).clamp(0, effectiveDays);

      for (int i = 0; i < days.length; i++) {
        final shouldDinner = i < clampedDinners;
        final shouldLunch = i < clampedLunches;
        if (days[i].dinnerRestaurant != shouldDinner || days[i].lunchRestaurant != shouldLunch) {
          await tripDao.updateTripDay(days[i].copyWith(
            dinnerRestaurant: shouldDinner,
            lunchRestaurant: shouldLunch,
          ));
        }
      }
    }

    final updated = trip.copyWith(
      name: name ?? trip.name,
      startDate: startDate ?? trip.startDate,
      daysCount: daysCount ?? trip.daysCount,
      fridgeCapacity: fridgeCapacity ?? trip.fridgeCapacity,
      hasFreezer: hasFreezer ?? trip.hasFreezer,
      freezerCapacity: freezerCapacity ?? trip.freezerCapacity,
      waterTankLiters: waterTankLiters ?? trip.waterTankLiters,
      isWaterTankDrinkable: isWaterTankDrinkable ?? trip.isWaterTankDrinkable,
      boatProfileId: boatProfileId != null ? Value(boatProfileId) : Value(trip.boatProfileId),
      boatName: boatName != null ? Value(boatName) : Value(trip.boatName),
      boatManufacturer: boatManufacturer != null ? Value(boatManufacturer) : Value(trip.boatManufacturer),
      boatModel: boatModel != null ? Value(boatModel) : Value(trip.boatModel),
      hasWatermaker: hasWatermaker ?? trip.hasWatermaker,
    );
    await tripDao.updateTrip(updated);
    await recalculateTrip(tripId);
  }
}

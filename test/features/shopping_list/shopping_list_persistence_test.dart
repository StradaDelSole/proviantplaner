/// Tests für Offline-Persistenz, Überschreibungen, Abwahlen und Häkchen (Slice S4).
library;

import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart' show CrewMemberInput;
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

void main() {
  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late ShoppingListService shoppingListService;
  late int tripId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catFile = File('data/catalog_v0.11.json');
    final quantFile = File('data/quantities_v0.4.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catFile.readAsStringSync(),
      quantitiesJson: quantFile.readAsStringSync(),
    );

    tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
    );

    shoppingListService = ShoppingListService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
      tripService: tripService,
    );

    // Initialen Törn anlegen: 5 Erwachsene, 7 Tage, Mittelmeer
    tripId = await tripService.createTripWithCrew(
      name: 'Sommertörn Mallorca',
      startDate: DateTime(2026, 7, 1),
      daysCount: 7,
      isCharter: true,
      boatType: 'monohull',
      region: 'mediterranean',
      fridgeCapacityLiters: 90.0,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: [
        const CrewMemberInput(id: '1', name: 'Skipper Alex', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Berta', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '3', name: 'Chris', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '4', name: 'Dora (Veggie)', isAdult: true, isVegetarian: true, noAlcohol: false),
        const CrewMemberInput(id: '5', name: 'Emil (NoAlk)', isAdult: true, isVegetarian: false, noAlcohol: true),
      ],
    );
    await shoppingListService.adoptAllSuggestions(tripId);
  });

  tearDown(() async {
    await db.close();
  });

  test('S4: Überschreibungen (overriddenPackages) bleiben nach Neustart und nach Crewänderung erhalten', () async {
    // 1. Liste laden
    var listData = await shoppingListService.loadShoppingList(tripId);
    expect(listData.allItems.isNotEmpty, isTrue);

    // Einen beliebigen Artikel auswählen (z. B. Bier oder Baguette)
    final target = listData.allItems.firstWhere((it) => it.effectivePackages > 0);
    final initialCalculated = target.calculatedPackages;

    // 2. Manuell überschreiben (+ Stepper)
    final newPackages = initialCalculated + 4;
    await db.listItemDao.setOverriddenPackages(target.item.id, newPackages);

    // 3. Neu laden (Neustart simulieren)
    listData = await shoppingListService.loadShoppingList(tripId);
    var reloadedItem = listData.allItems.firstWhere((it) => it.item.id == target.item.id);
    expect(reloadedItem.effectivePackages, equals(newPackages));
    expect(reloadedItem.isOverridden, isTrue);
    expect(reloadedItem.overriddenPackages, equals(newPackages));

    // 4. Crew-Änderung durchführen (6. Person hinzufügen) -> triggert recalculateTrip
    await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Felix',
        isChild: const Value(false),
        isVegetarian: const Value(false),
        isNonDrinker: const Value(false),
      ),
    );
    await tripService.recalculateTrip(tripId);

    // 5. Nach Neuberechnung prüfen: Die Überschreibung ist IMMER NOCH newPackages!
    listData = await shoppingListService.loadShoppingList(tripId);
    reloadedItem = listData.allItems.firstWhere((it) => it.item.id == target.item.id);
    expect(reloadedItem.effectivePackages, equals(newPackages),
        reason: 'Überschriebene Packungsanzahl darf durch Crewänderung nie überschrieben werden!');
    expect(reloadedItem.isOverridden, isTrue);

    // 6. Reset ("zurücksetzen")
    await shoppingListService.resetOverride(reloadedItem);
    listData = await shoppingListService.loadShoppingList(tripId);
    final resetItem = listData.allItems.firstWhere((it) => it.item.id == target.item.id);
    expect(resetItem.isOverridden, isFalse);
    expect(resetItem.effectivePackages, equals(resetItem.calculatedPackages));
  });

  test('S4: Abwahlen (selected = false) bleiben nach Neustart und nach Crewänderung erhalten', () async {
    var listData = await shoppingListService.loadShoppingList(tripId);
    final target = listData.allItems.firstWhere((it) => it.isSelected);

    // Abwählen
    await shoppingListService.toggleVariantSelected(
      tripId: tripId,
      listItemId: target.item.id,
      isSelected: false,
    );

    // Prüfen nach Reload
    listData = await shoppingListService.loadShoppingList(tripId);
    var item = listData.allItems.firstWhere((it) => it.item.id == target.item.id);
    expect(item.isSelected, isFalse);

    // Crew-Änderung (Restaurant-Besuch umschalten)
    final days = await db.tripDao.getDaysForTrip(tripId);
    await tripService.toggleLunchRestaurant(days.first);

    // Prüfen nach Neuberechnung: Immer noch abgewählt
    listData = await shoppingListService.loadShoppingList(tripId);
    item = listData.allItems.firstWhere((it) => it.item.id == target.item.id);
    expect(item.isSelected, isFalse,
        reason: 'Abgewählte Varianten müssen nach Crew-/Restaurant-Änderung abgewählt bleiben.');
  });

  test('S4: Häkchen im Einkaufsmodus (isBought) bleiben persistent in SQLite erhalten', () async {
    var listData = await shoppingListService.loadShoppingList(tripId);
    final target = listData.allItems.firstWhere((it) => it.effectivePackages > 0);
    final stop = listData.stops.first;

    // Häkchen setzen
    await shoppingListService.toggleBought(
      tripId: tripId,
      listItemId: target.item.id,
      shoppingStopId: stop.id,
      isBought: true,
    );

    // Neu laden
    listData = await shoppingListService.loadShoppingList(tripId);
    var item = listData.allItems.firstWhere((it) => it.item.id == target.item.id);
    expect(item.isBoughtAtStop(stop.id), isTrue);

    // Häkchen entfernen
    await shoppingListService.toggleBought(
      tripId: tripId,
      listItemId: target.item.id,
      shoppingStopId: stop.id,
      isBought: false,
    );

    listData = await shoppingListService.loadShoppingList(tripId);
    item = listData.allItems.firstWhere((it) => it.item.id == target.item.id);
    expect(item.isBoughtAtStop(stop.id), isFalse);
  });

  test('S4: Stopp-Zuordnung teilt Mengen auf und respektiert Summen-Constraint', () async {
    // Zweiter Stopp anlegen
    final stop2Id = await tripService.addShoppingStop(tripId: tripId, name: 'Hvar Supermarkt', dayNumber: 4);

    var listData = await shoppingListService.loadShoppingList(tripId);
    final target = listData.allItems.firstWhere((it) => it.effectivePackages >= 4);
    final total = target.effectivePackages;

    // 2 Packungen auf Stopp 2 verteilen
    await shoppingListService.allocateToStop(
      tripId: tripId,
      listItemId: target.item.id,
      shoppingStopId: stop2Id,
      packages: 2,
    );

    // Verbleibende Restmenge für Stopp 1 prüfen
    final unallocated = await db.listItemDao.getUnallocatedPackages(target.item.id);
    expect(unallocated, equals(total - 2));

    // Versuch einer Überbelegung (Gesamtmenge überschritten) muss Exception werfen
    expect(
      () => shoppingListService.allocateToStop(
        tripId: tripId,
        listItemId: target.item.id,
        shoppingStopId: stop2Id,
        packages: total + 1,
      ),
      throwsA(isA<AllocationExceededException>()),
    );
  });

  test('S4: Eigene Positionen (isCustom) bleiben nach Neuberechnung erhalten', () async {
    final customId = await shoppingListService.addCustomItem(
      CustomItemInput(
        tripId: tripId,
        name: 'Spezial-Gewürz',
        quantity: 2.0,
        unit: 'Dose',
        department: 'trockenware',
      ),
    );
    expect(customId, isPositive);

    var listData = await shoppingListService.loadShoppingList(tripId);
    final customItem = listData.allItems.firstWhere((it) => it.isCustom && it.name == 'Spezial-Gewürz');
    expect(customItem.effectivePackages, equals(2));
    expect(customItem.unit, equals('Dose'));

    // Neuberechnung triggern
    await tripService.recalculateTrip(tripId);

    // Prüfen, dass die eigene Position noch da ist
    listData = await shoppingListService.loadShoppingList(tripId);
    final retained = listData.allItems.firstWhere((it) => it.isCustom && it.name == 'Spezial-Gewürz');
    expect(retained.name, equals('Spezial-Gewürz'));
    expect(retained.effectivePackages, equals(2));
  });

  test('S4: Einlagerungs-Checkliste filtert nach storage_hints und speichert Erledigung', () async {
    final checklist = await shoppingListService.loadStorageChecklist(tripId);
    expect(checklist.isNotEmpty, isTrue);

    final firstEntry = checklist.first;
    expect(firstEntry.explanation.isNotEmpty, isTrue);
    expect(firstEntry.affectedItems.isNotEmpty, isTrue);

    // Als eingelagert abhaken
    await shoppingListService.toggleStorageHint(firstEntry, true);

    // Neu laden
    final reloadedChecklist = await shoppingListService.loadStorageChecklist(tripId);
    final updatedEntry = reloadedChecklist.firstWhere((e) => e.hintKey == firstEntry.hintKey);
    expect(updatedEntry.isCompleted, isTrue);
  });
}

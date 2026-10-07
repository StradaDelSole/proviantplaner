/// Tests für das neue Listenkonzept (Slice FB1-B / FEEDBACK_R1 Punkte 5 & 7).
///
/// Abnahmekriterien:
/// 1. neue Liste ist leer (0 übernommene Positionen, Vorschläge berechnet)
/// 2. "Alle Vorschläge übernehmen" übernimmt genau die default_selected-Varianten
/// 3. übernommene Mengen ändern sich bei Crewänderung nicht, Vorschläge schon
/// 4. jede Variante (auch default_selected: false) übernehmbar
/// 5. Einkaufsmodus eines Stopps zeigt exakt alle Positionen der Liste mit Menge > 0 des Stopps (Vergleich Position für Position)
library;

import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart'
    show CrewMemberInput;
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
    final quantFile = File('data/quantities_v0.5.json');
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

    tripId = await tripService.createTripWithCrew(
      name: 'Dänische Südsee FB1-B',
      startDate: DateTime(2026, 8, 1),
      daysCount: 7,
      isCharter: true,
      boatType: 'monohull',
      region: 'cool',
      fridgeCapacityLiters: 60.0,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: [
        const CrewMemberInput(
          id: '1',
          name: 'Skipper Jens',
          isAdult: true,
          isVegetarian: false,
          noAlcohol: false,
        ),
        const CrewMemberInput(
          id: '2',
          name: 'Maren',
          isAdult: true,
          isVegetarian: false,
          noAlcohol: false,
        ),
        const CrewMemberInput(
          id: '3',
          name: 'Lukas',
          isAdult: true,
          isVegetarian: true,
          noAlcohol: true,
        ),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('FB1-B Neues Listenkonzept Abnahmetests', () {
    test('1. neue Liste ist leer: 0 Positionen auf der Vorratsliste, Vorschläge berechnet', () async {
      final data = await shoppingListService.loadShoppingList(tripId);

      // Keine Katalogposition ist übernommen
      final adoptedItems = data.allItems.where((i) => i.isAdopted).toList();
      expect(adoptedItems, isEmpty, reason: 'Neuer Törn darf keine übernommenen Positionen haben');

      // Keine Position steht auf der Einkaufsliste
      final onListItems = data.allItems.where((i) => i.isOnList).toList();
      expect(onListItems, isEmpty, reason: 'isOnList muss für alle Katalogelemente initial false sein');

      // Alle effektiven Packungszahlen sind 0
      final nonZeroEffective = data.allItems.where((i) => i.effectivePackages > 0).toList();
      expect(nonZeroEffective, isEmpty, reason: 'effectivePackages muss initial 0 sein');

      // Aber Vorschläge (calculatedPackages) sind für Standard-Varianten vorhanden
      final withSuggestions = data.allItems.where((i) => i.calculatedPackages > 0).toList();
      expect(withSuggestions, isNotEmpty, reason: 'Vorschläge müssen berechnet und vorhanden sein');

      // Stichprobe: Butter hat Vorschlag > 0, aber effectivePackages == 0
      final butter = data.allItems.firstWhere((i) => i.id == 'butter_std');
      expect(butter.isAdopted, isFalse);
      expect(butter.effectivePackages, 0);
      expect(butter.calculatedPackages, greaterThan(0));
      expect(butter.suggestionDisplay, contains('Vorschlag:'));
    });

    test('2. "Alle Vorschläge übernehmen" übernimmt genau die default_selected-Varianten', () async {
      final catalog = catalogRepo.catalog!;
      final expectedDefaultSelectedIds = catalog.variants
          .where((v) => v.defaultSelected)
          .map((v) => v.id)
          .toSet();
      final expectedNotDefaultSelectedIds = catalog.variants
          .where((v) => !v.defaultSelected)
          .map((v) => v.id)
          .toSet();

      expect(expectedDefaultSelectedIds, isNotEmpty);
      expect(expectedNotDefaultSelectedIds, isNotEmpty);

      // Alle Vorschläge gesamt übernehmen
      await shoppingListService.adoptAllSuggestions(tripId);

      final data = await shoppingListService.loadShoppingList(tripId);

      // Jede default_selected Variante muss nun übernommen sein
      for (final id in expectedDefaultSelectedIds) {
        final item = data.allItems.firstWhere((i) => i.id == id);
        expect(
          item.isAdopted,
          isTrue,
          reason: 'Variante $id (default_selected: true) muss übernommen sein',
        );
        expect(
          item.effectivePackages,
          equals(item.calculatedPackages),
          reason: 'Variante $id muss effektive Packungen gleich Vorschlag haben',
        );
      }

      // Jede default_selected: false Variante darf NICHT übernommen sein
      for (final id in expectedNotDefaultSelectedIds) {
        final item = data.allItems.firstWhere((i) => i.id == id);
        expect(
          item.isAdopted,
          isFalse,
          reason: 'Variante $id (default_selected: false) darf nicht übernommen sein',
        );
        expect(
          item.effectivePackages,
          0,
          reason: 'Variante $id darf keine Packungen auf der Liste haben',
        );
      }
    });

    test('3. übernommene Mengen ändern sich bei Crewänderung nicht, Vorschläge schon', () async {
      // 1. Positionen übernehmen
      await shoppingListService.adoptAllSuggestions(tripId);
      final initialData = await shoppingListService.loadShoppingList(tripId);

      final butterInitial = initialData.allItems.firstWhere((i) => i.id == 'butter_std');
      final initialEffective = butterInitial.effectivePackages;
      final initialCalculated = butterInitial.calculatedPackages;
      expect(initialEffective, greaterThan(0));

      // Nutzer passt eine Menge manuell an
      await shoppingListService.setPackages(butterInitial, initialEffective + 3);
      final modifiedData = await shoppingListService.loadShoppingList(tripId);
      final butterModified = modifiedData.allItems.firstWhere((i) => i.id == 'butter_std');
      final userSetQuantity = butterModified.effectivePackages;
      expect(userSetQuantity, equals(initialEffective + 3));

      // Eine weitere Variante bleibt auf dem initial übernommenen Vorschlagswert
      final wasserInitial = initialData.allItems.firstWhere((i) => i.id == 'water_5l');
      final wasserInitialEffective = wasserInitial.effectivePackages;

      // 2. Crewänderung: 3 weitere Personen hinzufügen
      for (var j = 1; j <= 3; j++) {
        await db.tripDao.addCrewMember(
          CrewMembersCompanion.insert(
            tripId: tripId,
            name: 'Gast $j',
            isChild: const Value(false),
            isVegetarian: const Value(false),
            isNonDrinker: const Value(false),
          ),
        );
      }

      await tripService.recalculateTrip(tripId);

      // 3. Prüfen: Übernommene Mengen bleiben exakt unverändert!
      final afterCrewChange = await shoppingListService.loadShoppingList(tripId);

      final butterAfter = afterCrewChange.allItems.firstWhere((i) => i.id == 'butter_std');
      expect(
        butterAfter.effectivePackages,
        equals(userSetQuantity),
        reason: 'Vom Nutzer gesetzte Menge darf sich bei Crewänderung nicht ändern',
      );
      expect(
        butterAfter.calculatedPackages,
        greaterThan(initialCalculated),
        reason: 'Der berechnete Vorschlag muss bei größerer Crew ansteigen',
      );
      final wasserAfter = afterCrewChange.allItems.firstWhere((i) => i.id == 'water_5l');
      expect(
        wasserAfter.effectivePackages,
        equals(wasserInitialEffective),
        reason: 'Übernommene Menge ohne Überschreibung gehört dem Nutzer und bleibt stabil',
      );
      expect(
        wasserAfter.calculatedPackages,
        greaterThan(wasserInitial.calculatedPackages),
        reason: 'Vorschlag für Wasser muss für 6 Personen größer sein als für 3',
      );
      expect(wasserAfter.hasSuggestionDifference, isTrue);
    });

    test('4. jede Variante (auch default_selected: false) ist übernehmbar', () async {
      final catalog = catalogRepo.catalog!;
      final nonDefaultVariant = catalog.variants.firstWhere((v) => !v.defaultSelected);

      final initialData = await shoppingListService.loadShoppingList(tripId);
      final item = initialData.allItems.firstWhere((i) => i.id == nonDefaultVariant.id);
      expect(item.isAdopted, isFalse);
      expect(item.isOnList, isFalse);

      // Einzeln über "+ übernehmen" adoptieren
      await shoppingListService.adoptItem(
        tripId: tripId,
        listItemId: item.item.id,
      );

      final updatedData = await shoppingListService.loadShoppingList(tripId);
      final adoptedItem = updatedData.allItems.firstWhere((i) => i.id == nonDefaultVariant.id);

      expect(adoptedItem.isAdopted, isTrue);
      expect(adoptedItem.isOnList, isTrue);
      expect(adoptedItem.effectivePackages, greaterThan(0));

      // Wieder abwählen / entfernen
      await shoppingListService.unadoptItem(
        tripId: tripId,
        listItemId: adoptedItem.item.id,
      );

      final removedData = await shoppingListService.loadShoppingList(tripId);
      final removedItem = removedData.allItems.firstWhere((i) => i.id == nonDefaultVariant.id);
      expect(removedItem.isAdopted, isFalse);
      expect(removedItem.isOnList, isFalse);
    });

    test('5. Einkaufsmodus zeigt exakt die Listenpositionen des Stopps (Vergleich Position für Position)', () async {
      // 1. Vorschläge übernehmen
      await shoppingListService.adoptAllSuggestions(tripId);

      // 2. Zweiter Einkaufsstopp anlegen
      final stop2Id = await tripService.addShoppingStop(
        tripId: tripId,
        dayNumber: 4,
        name: 'Supermarkt Svendborg',
      );

      // 3. Eigene Position hinzufügen
      final customItemId = await shoppingListService.addCustomItem(
        CustomItemInput(
          tripId: tripId,
          name: 'Spezielle Bootsseife',
          unit: 'Flasche',
          quantity: 2.0,
          department: 'drogerie',
          shoppingStopId: stop2Id,
        ),
      );
      expect(customItemId, greaterThan(0));

      var data = await shoppingListService.loadShoppingList(tripId);
      final stop1 = data.stops.first;
      final stop2 = data.stops.firstWhere((s) => s.id == stop2Id);

      // 4. Ein Item teilweise auf Stopp 2 allozieren
      final apfelItem = data.allItems.firstWhere((i) => i.id == 'apples');
      expect(apfelItem.effectivePackages, greaterThanOrEqualTo(2));
      await shoppingListService.allocateToStop(
        tripId: tripId,
        listItemId: apfelItem.item.id,
        shoppingStopId: stop2Id,
        packages: 1,
      );

      data = await shoppingListService.loadShoppingList(tripId);

      // Berechne erwartete Positionen für Stopp 1:
      // Exakt alle Positionen der Liste (isOnList == true) mit packagesAtStop(stop1) > 0
      final expectedStop1Items = data.allItems.where((it) {
        if (!it.isOnList) return false;
        final totalOtherAlloc = it.allocationsByStop.entries
            .where((e) => e.key != stop1.id)
            .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
        final count = it.packagesAtStop(
          stop1.id,
          isFirstStop: true,
          totalOtherAllocated: totalOtherAlloc,
        );
        return count > 0;
      }).toList();

      // Berechne erwartete Positionen für Stopp 2:
      // Exakt alle Positionen der Liste (isOnList == true) mit packagesAtStop(stop2) > 0
      final expectedStop2Items = data.allItems.where((it) {
        if (!it.isOnList) return false;
        final totalOtherAlloc = it.allocationsByStop.entries
            .where((e) => e.key != stop2.id)
            .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
        final count = it.packagesAtStop(
          stop2.id,
          isFirstStop: false,
          totalOtherAllocated: totalOtherAlloc,
        );
        return count > 0;
      }).toList();

      // Verifikation Stopp 2: Enthält genau 'apples' (1 Pck.) und 'Spezielle Bootsseife' (2 Pck.)
      expect(expectedStop2Items.length, 2);
      expect(expectedStop2Items.any((i) => i.id == 'apples'), isTrue);
      expect(expectedStop2Items.any((i) => i.name == 'Spezielle Bootsseife'), isTrue);

      // Position für Position Vergleich:
      // Kein unübernommenes Item darf im Einkaufsmodus von Stopp 1 oder Stopp 2 sein
      for (final it in expectedStop1Items) {
        expect(it.isOnList, isTrue);
        expect(it.effectivePackages, greaterThan(0));
      }
      for (final it in expectedStop2Items) {
        expect(it.isOnList, isTrue);
        expect(it.effectivePackages, greaterThan(0));
      }

      // Verifikation: Nicht-übernommene Items erscheinen in keinem Stopp
      final unadopted = data.allItems.where((i) => !i.isAdopted && !i.isCustom).toList();
      for (final un in unadopted) {
        expect(expectedStop1Items.contains(un), isFalse);
        expect(expectedStop2Items.contains(un), isFalse);
      }
    });

    test('6. "Vorschläge dieser Kategorie übernehmen" übernimmt nur Vorschläge der gewählten Kategorie', () async {
      final initialData = await shoppingListService.loadShoppingList(tripId);
      expect(initialData.allItems.where((i) => i.isOnList), isEmpty);

      // Nur Vorschläge für die Kategorie 'fruehstueck' übernehmen
      await shoppingListService.adoptCategorySuggestions(
        tripId: tripId,
        categoryId: 'fruehstueck',
      );

      final data = await shoppingListService.loadShoppingList(tripId);

      // Alle auf der Liste befindlichen Items müssen zur Kategorie 'fruehstueck' gehören
      final onList = data.allItems.where((i) => i.isOnList).toList();
      expect(onList, isNotEmpty);

      for (final item in onList) {
        expect(
          item.categoryId,
          'fruehstueck',
          reason: 'Item ${item.name} muss zu Kategorie fruehstueck gehören',
        );
        expect(item.isAdopted, isTrue);
      }

      // Items anderer Kategorien (z. B. Wasser, Obst) sind unberührt geblieben
      final wasser = data.allItems.firstWhere((i) => i.id == 'water_5l');
      expect(wasser.isAdopted, isFalse);
      expect(wasser.isOnList, isFalse);
    });
  });
}

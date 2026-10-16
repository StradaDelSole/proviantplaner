/// PIVOT1: Assisted List Core – Abnahmetests (Issue #10)
///
/// Verbindliche Prinzipien aus `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
/// und `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`:
/// 1. Der Skipper baut die Liste. Provy macht sie vollständig, realistisch und bordtauglich.
/// 2. Ein neuer Törn beginnt mit leerer / such-orientierter Liste (0 übernommene Positionen).
/// 3. Search-First: Prominente Produktsuche + "+ Eigene Position".
/// 4. Suche findet Varianten über Teilstring (z. B. "kä", "pesto", "tofu", "wasser").
/// 5. Kompaktes Bottom Sheet: Variante → Packungsgröße (Chips) → Anzahl (−/Zahl/+) → Auf die Liste.
/// 6. Zeilen-Tap öffnet Edit-Sheet mit gleicher Logik + Entfernen-Möglichkeit.
/// 7. Assistenzklassen:
///    - Needs-based: Richtwert berechnet und angezeigt (z. B. Trinkwasser).
///    - Guided: Richtwert als Orientierung (z. B. Brot, Butter, Nudeln).
///    - Preference-based: KEINE automatische Crew×Tage-Mengenberechnung (z. B. Pesto, Tofu).
/// 8. Mengen-Stabilität: Manuell gewählte / übernommene Mengen werden bei Crew- oder Dauer-Änderungen nicht überschrieben.
/// 9. Einkaufsmodus-Isolation: Nur tatsächlich übernommene Positionen (oder eigene) erscheinen im Einkaufsmodus.
library;

import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/assist_type.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/add_or_edit_item_sheet.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/catalog_search_delegate.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/empty_shopping_list_view.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_mode_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/custom_item_sheet.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/item_row_widget.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late ShoppingListService shoppingListService;
  late int defaultTripId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();

    final catFile = File('data/catalog_v0.11.json');
    final quantFile = File('data/quantities_v0.7.json');
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

    defaultTripId = await tripService.createTripWithCrew(
      name: 'Kornaten Törn PIVOT1',
      startDate: DateTime(2026, 9, 1),
      daysCount: 7,
      isCharter: true,
      boatType: 'monohull',
      region: 'mediterranean',
      fridgeCapacityLiters: 90.0,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: [
        const CrewMemberInput(id: '1', name: 'Skipper Markus', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Laura', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '3', name: 'Felix', isAdult: true, isVegetarian: true, noAlcohol: false),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildAppWithOverrides({required Widget home, Locale locale = const Locale('de')}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWithValue(shoppingListService),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  group('PIVOT1: Assisted List Core Abnahmetests', () {
    testWidgets('1. Neuer Törn ist leer (Search-First): 0 übernommene Posten & Leerstadium angezeigt', (tester) async {
      // 1. Prüfe Datenzustand: Keine Position ist übernommen
      final data = await shoppingListService.loadShoppingList(defaultTripId);
      final adoptedItems = data.allItems.where((i) => i.isAdopted).toList();
      final onListItems = data.allItems.where((i) => i.isOnList).toList();

      expect(adoptedItems, isEmpty, reason: 'Neuer Törn darf keine übernommenen Positionen haben');
      expect(onListItems, isEmpty, reason: 'isOnList muss initial false sein');

      // 2. Prüfe UI-Darstellung: ShoppingListScreen rendert standardmäßig nach Abteilung
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAppWithOverrides(home: ShoppingListScreen(tripId: defaultTripId)));
      await tester.pumpAndSettle();

      // EmptyShoppingListView muss sichtbar sein
      expect(find.byType(EmptyShoppingListView), findsOneWidget);
      expect(find.textContaining('Vorratsliste ist noch leer'), findsOneWidget);
      expect(find.textContaining('Suche nach Artikeln'), findsOneWidget);
      expect(find.textContaining('Produkte suchen'), findsOneWidget);
      expect(find.textContaining('Eigene Position'), findsOneWidget);

      // 3. Umschalten auf Kategorie-Sicht
      await tester.tap(find.byIcon(Icons.category_outlined));
      await tester.pumpAndSettle();

      // Auch in Kategorie-Sicht ist der Search-First Banner sichtbar
      expect(find.textContaining('Vorratsliste ist noch leer'), findsOneWidget);
    });

    test('2. Katalogsuche mit Teilstrings findet Varianten (kä, pesto, tofu, wasser)', () async {
      final data = await shoppingListService.loadShoppingList(defaultTripId);
      final delegate = CatalogSearchDelegate(data: data);

      // Teilstring "kä" -> findet Käse (z. B. kaese_hart, kaese_schnitt)
      final cheeseResults = delegate.filterItems('kä');
      expect(cheeseResults, isNotEmpty);
      expect(cheeseResults.any((i) => i.id.contains('kaese') || i.name.toLowerCase().contains('käse')), isTrue);

      // Teilstring "pesto" -> findet Pesto
      final pestoResults = delegate.filterItems('pesto');
      expect(pestoResults, isNotEmpty);
      expect(pestoResults.any((i) => i.id.contains('pesto')), isTrue);

      // Teilstring "tofu" -> findet Tofu
      final tofuResults = delegate.filterItems('tofu');
      expect(tofuResults, isNotEmpty);
      expect(tofuResults.any((i) => i.id.contains('tofu')), isTrue);

      // Teilstring "wasser" -> findet Trinkwasser
      final waterResults = delegate.filterItems('wasser');
      expect(waterResults, isNotEmpty);
      expect(waterResults.any((i) => i.id.contains('water') || i.name.toLowerCase().contains('wasser')), isTrue);
    });

    testWidgets('3. Variante -> Packungsgröße Chips -> Stepper -> Auf die Liste', (tester) async {
      final data = await shoppingListService.loadShoppingList(defaultTripId);
      final spaghettiItem = data.allItems.firstWhere((i) => i.id == 'spaghetti');

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAppWithOverrides(
        home: Scaffold(
          body: AddOrEditItemSheet(
            data: data,
            item: spaghettiItem,
            isAdding: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Prüfe Header mit Variantenname und Abteilungsbadge
      expect(find.text(spaghettiItem.name), findsOneWidget);
      expect(find.text('Trockenware'), findsOneWidget);

      // Packungsgrößen-Chips sichtbar
      expect(find.byType(ChoiceChip), findsWidgets);

      // Stepper: Erhöhe auf 3 Packungen
      final plusButton = find.widgetWithIcon(IconButton, Icons.add);
      expect(plusButton, findsOneWidget);
      await tester.tap(plusButton);
      await tester.pumpAndSettle();
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      // CTA "Auf die Liste" tippen
      final addButton = find.byKey(const ValueKey('sheet_primary_action_btn'));
      expect(addButton, findsOneWidget);
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Überprüfe Persistenz in DB
      final updatedData = await shoppingListService.loadShoppingList(defaultTripId);
      final adoptedSpaghetti = updatedData.allItems.firstWhere((i) => i.id == 'spaghetti');
      expect(adoptedSpaghetti.isAdopted, isTrue);
      expect(adoptedSpaghetti.isOnList, isTrue);
      expect(adoptedSpaghetti.effectivePackages, greaterThanOrEqualTo(2));
    });

    testWidgets('4. Zeilen-Tap öffnet Edit-Sheet -> Menge ändern und Speichern oder Entfernen', (tester) async {
      // Vorbereitung: 1 Posten auf der Liste
      final initialData = await shoppingListService.loadShoppingList(defaultTripId);
      final butterItem = initialData.allItems.firstWhere((i) => i.id == 'butter_std');
      await shoppingListService.adoptItem(tripId: defaultTripId, listItemId: butterItem.item.id, packages: 2);

      final dataWithItem = await shoppingListService.loadShoppingList(defaultTripId);
      final adoptedButter = dataWithItem.allItems.firstWhere((i) => i.id == 'butter_std');
      expect(adoptedButter.isOnList, isTrue);

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Öffne Edit-Sheet für den existierenden Posten
      await tester.pumpWidget(buildAppWithOverrides(
        home: Scaffold(
          body: AddOrEditItemSheet(
            data: dataWithItem,
            item: adoptedButter,
            isAdding: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Button "Von Liste entfernen" vorhanden
      final removeButtonFinder = find.byKey(const ValueKey('sheet_remove_btn'));
      await tester.ensureVisible(removeButtonFinder);
      await tester.pumpAndSettle();
      expect(removeButtonFinder, findsOneWidget);

      // Button "Speichern" vorhanden
      final saveButtonFinder = find.byKey(const ValueKey('sheet_primary_action_btn'));
      expect(saveButtonFinder, findsOneWidget);

      // Erhöhe um 1 und speichere
      final plusButton = find.widgetWithIcon(IconButton, Icons.add);
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      await tester.ensureVisible(saveButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      var reloadedData = await shoppingListService.loadShoppingList(defaultTripId);
      var reloadedButter = reloadedData.allItems.firstWhere((i) => i.id == 'butter_std');
      expect(reloadedButter.effectivePackages, 3);

      // Nun erneut öffnen und "Von Liste entfernen" tippen
      await tester.pumpWidget(buildAppWithOverrides(
        home: Scaffold(
          body: AddOrEditItemSheet(
            data: reloadedData,
            item: reloadedButter,
            isAdding: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final removeBtn2 = find.byKey(const ValueKey('sheet_remove_btn'));
      await tester.ensureVisible(removeBtn2);
      await tester.pumpAndSettle();
      await tester.tap(removeBtn2);
      await tester.pumpAndSettle();

      reloadedData = await shoppingListService.loadShoppingList(defaultTripId);
      reloadedButter = reloadedData.allItems.firstWhere((i) => i.id == 'butter_std');
      expect(reloadedButter.isAdopted, isFalse);
      expect(reloadedButter.isOnList, isFalse);
      expect(reloadedButter.effectivePackages, 0);
    });

    test('5. Pesto Regressionstest (5 Personen, 14 Tage): Keine automatische 14-Gläser-Menge, berechnet 0', () async {
      // 5 Personen, 14 Tage Törn anlegen
      final pestoTripId = await tripService.createTripWithCrew(
        name: 'Pesto Test 14 Tage',
        startDate: DateTime(2026, 7, 10),
        daysCount: 14,
        isCharter: true,
        boatType: 'monohull',
        region: 'mediterranean',
        fridgeCapacityLiters: 90.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: List.generate(
          5,
          (idx) => CrewMemberInput(id: '$idx', name: 'Crew $idx', isAdult: true, isVegetarian: false, noAlcohol: false),
        ),
      );

      final data = await shoppingListService.loadShoppingList(pestoTripId);
      final pesto = data.allItems.firstWhere((i) => i.id == 'pesto');

      // Assistenzklasse ist preferenceBased
      expect(pesto.assistType, equals(AssistType.preferenceBased));

      // Automatischer Vorschlag ist 0 (NICHT 14 Gläser!)
      expect(pesto.calculatedPackages, 0, reason: 'Pesto darf bei PIVOT1 keine automatische Bedarfsmenge haben');
      expect(pesto.calculatedQuantity, 0.0);
      expect(pesto.isOnList, isFalse);

      // Nutzer wählt 1 Glas manuell
      await shoppingListService.adoptItem(tripId: pestoTripId, listItemId: pesto.item.id, packages: 1);

      final updated = await shoppingListService.loadShoppingList(pestoTripId);
      final adoptedPesto = updated.allItems.firstWhere((i) => i.id == 'pesto');
      expect(adoptedPesto.isOnList, isTrue);
      expect(adoptedPesto.effectivePackages, 1, reason: 'Gewählte 1 Packung bleibt exakt 1 Packung');
    });

    test('6. Tofu Regressionstest: Vegetarische Crew -> Tofu hat keine automatische Crew-Menge (berechnet 0)', () async {
      final data = await shoppingListService.loadShoppingList(defaultTripId);
      final tofu = data.allItems.firstWhere((i) => i.id == 'tofu');

      expect(tofu.assistType, equals(AssistType.preferenceBased));
      expect(tofu.calculatedPackages, 0, reason: 'Tofu darf nicht automatisch berechnet werden');
      expect(tofu.isOnList, isFalse);
    });

    testWidgets('7. Trinkwasser Needs-Based: Richtwert wird berechnet, angezeigt und vom Nutzer gewählt', (tester) async {
      final data = await shoppingListService.loadShoppingList(defaultTripId);
      final water = data.allItems.firstWhere((i) => i.id == 'water_5l' || i.id == 'water_15');

      expect(water.assistType, equals(AssistType.needsBased));
      expect(water.calculatedQuantity, greaterThan(0.0));

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAppWithOverrides(
        home: Scaffold(
          body: AddOrEditItemSheet(
            data: data,
            item: water,
            isAdding: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Provy Richtwert-Hinweis wird angezeigt
      expect(find.textContaining('Provy-Richtwert'), findsOneWidget);

      // Nutzer fügt weitere Packungen hinzu
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pumpAndSettle();

      final addBtnFinder = find.byKey(const ValueKey('sheet_primary_action_btn'));
      await tester.ensureVisible(addBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      final updated = await shoppingListService.loadShoppingList(defaultTripId);
      final adoptedWater = updated.allItems.firstWhere((i) => i.id == water.id);
      expect(adoptedWater.isOnList, isTrue);
      expect(adoptedWater.effectivePackages, greaterThanOrEqualTo(1));
    });

    test('8. Mengen-Stabilität: Crew- und Dauer-Änderungen überschreiben übernommene Posten nicht', () async {
      // 1. Posten übernehmen und Menge manuell auf 5 setzen
      final data = await shoppingListService.loadShoppingList(defaultTripId);
      final bread = data.allItems.firstWhere((i) => i.id == 'toast_bread' || i.id.contains('bread'));
      await shoppingListService.adoptItem(tripId: defaultTripId, listItemId: bread.item.id, packages: 5);

      final beforeChange = await shoppingListService.loadShoppingList(defaultTripId);
      final breadBefore = beforeChange.allItems.firstWhere((i) => i.id == bread.id);
      expect(breadBefore.effectivePackages, 5);

      // 2. Dauer ändern von 7 auf 14 Tage
      final currentTrip = (await db.tripDao.getTripById(defaultTripId))!;
      await db.tripDao.updateTrip(currentTrip.copyWith(daysCount: 14));

      // 3. Crew vergrößern (+2 Personen)
      await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
        tripId: defaultTripId,
        name: 'Zusatz 1',
        isChild: const Value(false),
      ));
      await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
        tripId: defaultTripId,
        name: 'Zusatz 2',
        isChild: const Value(false),
      ));

      // 4. Neu laden und prüfen: Die vom Nutzer gewählten 5 Packungen bleiben unverändert!
      final afterChange = await shoppingListService.loadShoppingList(defaultTripId);
      final breadAfter = afterChange.allItems.firstWhere((i) => i.id == bread.id);
      expect(breadAfter.effectivePackages, 5, reason: 'Manuell gesetzte Packungszahl muss 5 bleiben');
      expect(breadAfter.isOverridden, isTrue);
    });

    test('9. Einkaufsmodus-Isolation: Nur tatsächlich übernommene Positionen des Stopps erscheinen', () async {
      var data = await shoppingListService.loadShoppingList(defaultTripId);
      final stop1 = data.stops.first;

      // 1. Initial sind 0 Positionen auf der Vorratsliste
      final initialStopItems = data.allItems.where((it) {
        if (!it.isOnList) return false;
        final totalOtherAlloc = it.allocationsByStop.entries
            .where((e) => e.key != stop1.id)
            .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
        final count = it.packagesAtStop(stop1.id, isFirstStop: true, totalOtherAllocated: totalOtherAlloc);
        return count > 0;
      }).toList();
      expect(initialStopItems, isEmpty, reason: 'Leere Liste darf 0 Posten im Einkaufsmodus haben');

      // 2. Genau zwei Positionen übernehmen
      final butter = data.allItems.firstWhere((i) => i.id == 'butter_std');
      final salt = data.allItems.firstWhere((i) => i.id == 'salt_table' || i.id.contains('salt'));

      await shoppingListService.adoptItem(tripId: defaultTripId, listItemId: butter.item.id, packages: 2);
      await shoppingListService.adoptItem(tripId: defaultTripId, listItemId: salt.item.id, packages: 1);

      data = await shoppingListService.loadShoppingList(defaultTripId);
      final updatedStopItems = data.allItems.where((it) {
        if (!it.isOnList) return false;
        final totalOtherAlloc = it.allocationsByStop.entries
            .where((e) => e.key != stop1.id)
            .fold<int>(0, (sum, e) => sum + e.value.allocatedPackages);
        final count = it.packagesAtStop(stop1.id, isFirstStop: true, totalOtherAllocated: totalOtherAlloc);
        return count > 0;
      }).toList();

      expect(updatedStopItems.length, 2, reason: 'Exakt die 2 übernommenen Artikel müssen im Einkaufsmodus sein');
      expect(updatedStopItems.any((i) => i.id == butter.id), isTrue);
      expect(updatedStopItems.any((i) => i.id == salt.id), isTrue);
    });

    test('10. Kataloggetriebene Assist-Klassifikation (DATA1): Alle 47 Gruppen und 232 Varianten besitzen getypten AssistType', () {
      final catalog = catalogRepo.catalog!;
      expect(catalog.version, '0.11');
      expect(catalog.groups.length, 47);
      expect(catalog.variants.length, 232);

      // Alle 47 Gruppen besitzen strikt getypten AssistType
      for (final g in catalog.groups) {
        expect([AssistType.needsBased, AssistType.guided, AssistType.preferenceBased], contains(g.assist));
      }

      // Alle 232 Varianten besitzen auflösbaren effektiven AssistType
      for (final v in catalog.variants) {
        final eff = catalog.getEffectiveAssist(v);
        expect([AssistType.needsBased, AssistType.guided, AssistType.preferenceBased], contains(eff));
      }
    });

    test('11. Preference- & Guided-Regressionen: Snacks, Aufstriche, Pesto, Tofu, Saucen, Käse & Spirituosen berechnen 0 Richtwert; Bier/Wein & Wasser bleiben erhalten', () async {
      final data = await shoppingListService.loadShoppingList(defaultTripId);

      // 1. Water: needsBased mit positivem Richtwert
      final water = data.allItems.firstWhere((i) => i.id == 'water_15' || i.id.contains('water'));
      expect(water.assistType, equals(AssistType.needsBased));
      expect(water.calculatedPackages, greaterThan(0), reason: 'Trinkwasser muss needs-based berechnet werden');

      // 2. Savory snack: chips -> preferenceBased (0 Richtwert)
      final chips = data.allItems.firstWhere((i) => i.id == 'chips');
      expect(chips.assistType, equals(AssistType.preferenceBased));
      expect(chips.calculatedPackages, 0, reason: 'Snacks dürfen keine automatische Bedarfsmenge haben');
      expect(chips.calculatedQuantity, 0.0);

      // 3. Sweet spread: jam_strawberry -> preferenceBased (0 Richtwert)
      final jam = data.allItems.firstWhere((i) => i.id == 'jam_strawberry');
      expect(jam.assistType, equals(AssistType.preferenceBased));
      expect(jam.calculatedPackages, 0, reason: 'Süße Aufstriche dürfen keine automatische Bedarfsmenge haben');
      expect(jam.calculatedQuantity, 0.0);

      // 4. Spirituosen: rum -> preferenceBased (0 Richtwert)
      final rum = data.allItems.firstWhere((i) => i.id == 'rum');
      expect(rum.assistType, equals(AssistType.preferenceBased));
      expect(rum.calculatedPackages, 0, reason: 'Spirituosen dürfen keine automatische Bedarfsmenge haben');
      expect(rum.calculatedQuantity, 0.0);

      // 5. Pesto: sauces_pasta Variant Override -> preferenceBased (0 Richtwert)
      final pesto = data.allItems.firstWhere((i) => i.id == 'pesto');
      expect(pesto.assistType, equals(AssistType.preferenceBased));
      expect(pesto.calculatedPackages, 0, reason: 'Pesto darf keine automatische Bedarfsmenge haben');
      expect(pesto.calculatedQuantity, 0.0);

      // 6. Tofu: veg_protein Variant Override -> preferenceBased (0 Richtwert)
      final tofu = data.allItems.firstWhere((i) => i.id == 'tofu');
      expect(tofu.assistType, equals(AssistType.preferenceBased));
      expect(tofu.calculatedPackages, 0, reason: 'Tofu darf keine automatische Bedarfsmenge haben');
      expect(tofu.calculatedQuantity, 0.0);

      // 7. Käse-Präferenzartikel: feta -> preferenceBased (0 Richtwert)
      final feta = data.allItems.firstWhere((i) => i.id == 'feta');
      expect(feta.assistType, equals(AssistType.preferenceBased));
      expect(feta.calculatedPackages, 0, reason: 'Präferenzkäse darf keine automatische Bedarfsmenge haben');
      expect(feta.calculatedQuantity, 0.0);

      // 8. Spezielle Würzsauce: bbq_sauce -> preferenceBased (0 Richtwert)
      final bbqSauce = data.allItems.firstWhere((i) => i.id == 'bbq_sauce');
      expect(bbqSauce.assistType, equals(AssistType.preferenceBased));
      expect(bbqSauce.calculatedPackages, 0, reason: 'Spezialsaucen dürfen keine automatische Bedarfsmenge haben');
      expect(bbqSauce.calculatedQuantity, 0.0);

      // 9. Abgrenzung Guided: Bier & Wein bleiben guided, da Bedarfsformel nach Trinkgewohnheiten (crewDrinking) greift
      final beer = data.allItems.firstWhere((i) => i.id.contains('beer'));
      expect(beer.assistType, equals(AssistType.guided),
          reason: 'Bier bleibt guided, da über Crew-Trinkgewohnheiten Richtwerte berechnet werden');
      expect(beer.calculatedPackages, greaterThan(0));

      final wine = data.allItems.firstWhere((i) => i.id.contains('wine'));
      expect(wine.assistType, equals(AssistType.guided),
          reason: 'Wein bleibt guided, da über Crew-Trinkgewohnheiten Richtwerte berechnet werden');
      expect(wine.calculatedPackages, greaterThan(0));
    });

    testWidgets('12. Kein UI-Bypass: Sowohl Zeilen-Tap als auch Add-Button öffnen AddOrEditItemSheet und adoptieren nicht still', (tester) async {
      final data = await shoppingListService.loadShoppingList(defaultTripId);
      final oatsItem = data.allItems.firstWhere((i) => i.id == 'oats_rolled' || i.id.contains('oats'));
      expect(oatsItem.isOnList, isFalse);
      expect(oatsItem.isAdopted, isFalse);

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Render die Item-Row isoliert im Navigator
      await tester.pumpWidget(buildAppWithOverrides(
        home: Scaffold(
          body: ShoppingListItemRow(
            data: data,
            item: oatsItem,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // 1. Klick auf den sichtbaren Add-Button ("+")
      final addBtnFinder = find.byKey(ValueKey('item_add_btn_${oatsItem.item.id}'));
      expect(addBtnFinder, findsOneWidget);
      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      // Öffnet das AddOrEditItemSheet (isAdding: true)
      expect(find.byType(AddOrEditItemSheet), findsOneWidget);
      expect(find.byKey(const ValueKey('sheet_primary_action_btn')), findsOneWidget);

      // In der DB wurde der Posten noch NICHT übernommen (kein stiller Bypass!)
      var dbItem = (await db.listItemDao.getListItemsForTrip(defaultTripId))
          .firstWhere((it) => it.id == oatsItem.item.id);
      expect(dbItem.isAdopted, isFalse, reason: 'Tippen auf Add-Button darf nicht sofort still adoptieren');

      // Schließe das Sheet ohne Speichern
      Navigator.of(tester.element(find.byType(AddOrEditItemSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(AddOrEditItemSheet), findsNothing);

      // 2. Klick auf die gesamte Zeile
      final rowTapFinder = find.byKey(ValueKey('item_tap_${oatsItem.item.id}'));
      expect(rowTapFinder, findsOneWidget);
      await tester.tap(rowTapFinder);
      await tester.pumpAndSettle();

      // Öffnet ebenfalls das AddOrEditItemSheet
      expect(find.byType(AddOrEditItemSheet), findsOneWidget);

      // In der DB weiterhin nicht übernommen
      dbItem = (await db.listItemDao.getListItemsForTrip(defaultTripId))
          .firstWhere((it) => it.id == oatsItem.item.id);
      expect(dbItem.isAdopted, isFalse, reason: 'Tippen auf Zeile darf nicht sofort still adoptieren');
    });

    testWidgets('13. Reale Search/Add UI-Journey: Suche -> Treffer -> Sheet -> Packung & Stepper -> Liste -> DB-Persistenz', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Starte auf dem echten ShoppingListScreen
      await tester.pumpWidget(buildAppWithOverrides(
        home: ShoppingListScreen(tripId: defaultTripId),
      ));
      await tester.pumpAndSettle();

      // Im Empty State ist der Suchbutton sichtbar
      final searchBtn = find.byKey(const ValueKey('empty_search_btn'));
      expect(searchBtn, findsOneWidget);
      await tester.tap(searchBtn);
      await tester.pumpAndSettle();

      // Suchleiste ist aktiv
      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'pesto');
      await tester.pumpAndSettle();

      // Ergebnis "Pesto" in der Suchliste antippen
      final pestoResult = find.widgetWithText(ListTile, 'Pesto');
      expect(pestoResult, findsOneWidget);
      await tester.tap(pestoResult);
      await tester.pumpAndSettle();

      // AddOrEditItemSheet hat sich geöffnet
      expect(find.byType(AddOrEditItemSheet), findsOneWidget);

      // Packungsgröße wählen: Anderes Gebinde als Standard 190 g wählen (z. B. 250 g)
      final chip250 = find.widgetWithText(ChoiceChip, '250 g');
      expect(chip250, findsOneWidget);
      await tester.tap(chip250);
      await tester.pumpAndSettle();

      // Stepper: 2 Gläser wählen (bei Preference startet Menge bei 1)
      final plusBtn = find.widgetWithIcon(IconButton, Icons.add);
      expect(plusBtn, findsOneWidget);
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      // "Auf die Liste" tippen
      final saveBtn = find.byKey(const ValueKey('sheet_primary_action_btn'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Zurück auf dem ShoppingListScreen: Empty State ist verschwunden
      expect(find.byType(EmptyShoppingListView), findsNothing);
      // Pesto ist auf der Liste sichtbar
      expect(find.text('Pesto'), findsOneWidget);
      expect(find.byType(ShoppingListItemRow), findsOneWidget);

      // DB-Persistenz prüfen: Packungsanzahl UND gewählte Gebindegröße persistiert
      final refreshed = await shoppingListService.loadShoppingList(defaultTripId);
      final persistedPesto = refreshed.allItems.firstWhere((i) => i.id == 'pesto');
      expect(persistedPesto.isOnList, isTrue);
      expect(persistedPesto.isAdopted, isTrue);
      expect(persistedPesto.effectivePackages, 2);
      expect(persistedPesto.customPackageSize, 250.0);
      expect(persistedPesto.effectivePackSize, 250.0);
    });

    test('14. Mengen-Stabilität bei echter Neuberechnung (TripService): Preference, Custom & Overridden Guided überleben Dauer & Crew-Änderung', () async {
      // 1. Preference item mit expliziter Menge adoptieren (Pesto: 2 Gläser)
      final initialData = await shoppingListService.loadShoppingList(defaultTripId);
      final pesto = initialData.allItems.firstWhere((i) => i.id == 'pesto');
      await shoppingListService.adoptItem(tripId: defaultTripId, listItemId: pesto.item.id, packages: 2);

      // 2. Guided item mit manuellem Override adoptieren (Toastbrot: 5 Packungen)
      final bread = initialData.allItems.firstWhere((i) => i.id == 'toast_bread' || i.id.contains('bread'));
      await shoppingListService.adoptItem(tripId: defaultTripId, listItemId: bread.item.id, packages: 5);

      // 3. Custom item anlegen (Bio-Kaffee: 3 Packungen)
      await shoppingListService.addCustomItem(
        CustomItemInput(
          tripId: defaultTripId,
          name: 'Bio-Kaffee Crema',
          department: 'getraenke',
          quantity: 3,
          unit: 'Pkg',
        ),
      );

      // Daten vor Neuberechnung prüfen
      var beforeRecalc = await shoppingListService.loadShoppingList(defaultTripId);
      expect(beforeRecalc.allItems.firstWhere((i) => i.id == 'pesto').effectivePackages, 2);
      expect(beforeRecalc.allItems.firstWhere((i) => i.id == bread.id).effectivePackages, 5);
      expect(beforeRecalc.allItems.firstWhere((i) => i.name == 'Bio-Kaffee Crema').effectivePackages, 3);

      // 4. Dauer ändern über den echten Produktionspfad `tripService.updateTripDetails()` (führt recalculateTrip aus)
      await tripService.updateTripDetails(
        tripId: defaultTripId,
        daysCount: 14,
      );

      // 5. Crew erweitern (+2 Personen) und Neuberechnung ausführen
      await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
        tripId: defaultTripId,
        name: 'Zusatz 1',
        isChild: const Value(false),
      ));
      await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
        tripId: defaultTripId,
        name: 'Zusatz 2',
        isChild: const Value(false),
      ));
      await tripService.recalculateTrip(defaultTripId);

      // 6. Nach echter Neuberechnung prüfen: Alle 3 Positionen behalten exakt ihre Nutzerwunschmengen!
      final afterRecalc = await shoppingListService.loadShoppingList(defaultTripId);

      final pestoAfter = afterRecalc.allItems.firstWhere((i) => i.id == 'pesto');
      expect(pestoAfter.isOnList, isTrue);
      expect(pestoAfter.effectivePackages, 2, reason: 'Preference-Menge (Pesto 2 Gläser) muss Neuberechnung überleben');

      final breadAfter = afterRecalc.allItems.firstWhere((i) => i.id == bread.id);
      expect(breadAfter.isOnList, isTrue);
      expect(breadAfter.effectivePackages, 5, reason: 'Überschriebene Guided-Menge (Brot 5 Pkg) muss Neuberechnung überleben');

      final coffeeAfter = afterRecalc.allItems.firstWhere((i) => i.name == 'Bio-Kaffee Crema');
      expect(coffeeAfter.isOnList, isTrue);
      expect(coffeeAfter.effectivePackages, 3, reason: 'Custom Item (Kaffee 3 Pkg) muss Neuberechnung überleben');
    });

    testWidgets('15. ShoppingModeScreen: Reale Bildschirm-Isolation zeigt nur übernommene & eigene Artikel', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Posten vorbereiten: 1 Katalog-Posten übernommen, 1 Custom Item angelegt, Rest unadoptiert
      final initialData = await shoppingListService.loadShoppingList(defaultTripId);
      final spaghetti = initialData.allItems.firstWhere((i) => i.id == 'spaghetti');
      await shoppingListService.adoptItem(tripId: defaultTripId, listItemId: spaghetti.item.id, packages: 2);

      await shoppingListService.addCustomItem(
        CustomItemInput(
          tripId: defaultTripId,
          name: 'Bord-Gin Flasche',
          department: 'getraenke',
          quantity: 1,
          unit: 'Flasche',
        ),
      );

      final stopId = initialData.stops.first.id;

      // 2. Rendere den echten ShoppingModeScreen
      await tester.pumpWidget(buildAppWithOverrides(
        home: ShoppingModeScreen(tripId: defaultTripId, stopId: stopId),
      ));
      await tester.pumpAndSettle();

      // 3. Übernommener Katalogartikel & Custom Item sind sichtbar
      expect(find.textContaining('Spaghetti'), findsOneWidget);
      expect(find.textContaining('Bord-Gin Flasche'), findsOneWidget);

      // 4. Nicht übernommene Katalog-Kandidaten (z. B. Butter, Salz, Milch) sind NICHT im Einkaufsmodus sichtbar
      expect(find.textContaining('Butter'), findsNothing);
      expect(find.textContaining('Salz'), findsNothing);
      expect(find.textContaining('Vollmilch'), findsNothing);
    });

    testWidgets('16. Reale No-Result -> Custom Item UI-Journey: Suche ohne Treffer -> Button -> CustomItemSheet -> Speichern -> DB-Persistenz', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Starte auf dem echten ShoppingListScreen
      await tester.pumpWidget(buildAppWithOverrides(
        home: ShoppingListScreen(tripId: defaultTripId),
      ));
      await tester.pumpAndSettle();

      // 2. Suche über Empty-State-Button öffnen
      final searchBtn = find.byKey(const ValueKey('empty_search_btn'));
      expect(searchBtn, findsOneWidget);
      await tester.tap(searchBtn);
      await tester.pumpAndSettle();

      // 3. Einen Suchbegriff eingeben, der garantiert keine Katalogtreffer hat
      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'Fantasie-Kekse XYZ');
      await tester.pumpAndSettle();

      // 4. No-Results Hinweis & Button "Als eigene Position anlegen" sichtbar
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      final addCustomBtn = find.byKey(const ValueKey('no_results_custom_item_btn'));
      expect(addCustomBtn, findsOneWidget);

      // 5. Button antippen
      await tester.tap(addCustomBtn);
      await tester.pumpAndSettle();

      // 6. CustomItemSheet ist über den sicheren Parent-Context/Post-Frame-Pfad geöffnet
      expect(find.byType(CustomItemSheet), findsOneWidget);

      // 7. Eigene Position speichern
      final saveBtn = find.widgetWithText(FilledButton, 'Speichern');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // 8. Zurück auf der Vorratsliste: Empty State verschwunden, Custom Item sichtbar
      expect(find.byType(EmptyShoppingListView), findsNothing);
      expect(find.text('Fantasie-Kekse XYZ'), findsOneWidget);

      // 9. SQLite-Persistenz verifizieren
      final dataAfter = await shoppingListService.loadShoppingList(defaultTripId);
      final customItem = dataAfter.allItems.firstWhere((i) => i.name == 'Fantasie-Kekse XYZ');
      expect(customItem.isCustom, isTrue);
      expect(customItem.isOnList, isTrue);
      expect(customItem.effectivePackages, 1);
      expect(customItem.assistType, equals(AssistType.guided));
    });

    test('17. DATA1 Amendment (Finding B & C): Catalog Items erhalten kataloggetriebenen AssistType; Custom Items erhalten explizit AssistType.guided ohne Namensheuristik', () async {
      // Lege Custom Items mit Namen an, die früher Heuristiken ausgelöst hätten ("water", "pesto")
      await shoppingListService.addCustomItem(
        CustomItemInput(
          tripId: defaultTripId,
          name: 'water special reserve',
          department: 'getraenke',
          quantity: 2,
          unit: 'Flaschen',
        ),
      );
      await shoppingListService.addCustomItem(
        CustomItemInput(
          tripId: defaultTripId,
          name: 'pesto genovese extra',
          department: 'konserven',
          quantity: 1,
          unit: 'Glas',
        ),
      );

      final data = await shoppingListService.loadShoppingList(defaultTripId);
      final catalog = catalogRepo.catalog!;

      // 1. Alle Katalog-Items in ShoppingListItemView stimmen exakt mit catalog.getEffectiveAssist(variant) überein
      final catalogItems = data.allItems.where((i) => !i.isCustom).toList();
      expect(catalogItems.length, equals(232));
      for (final item in catalogItems) {
        expect(item.variant, isNotNull);
        expect(
          item.assistType,
          equals(catalog.getEffectiveAssist(item.variant!)),
          reason: 'Katalog-Item ${item.id} muss exakt den kataloggetriebenen AssistType tragen',
        );
      }

      // 2. Alle Custom-Items erhalten explizit AssistType.guided an der Konstruktionsgrenze (_buildCustomItemView),
      // ohne Ableitung aus Name, ID oder Kategorie.
      final customItems = data.allItems.where((i) => i.isCustom).toList();
      expect(customItems.length, equals(2));
      for (final custom in customItems) {
        expect(
          custom.assistType,
          equals(AssistType.guided),
          reason: 'Custom Item "${custom.name}" muss explizit AssistType.guided erhalten',
        );
      }
    });
  });
}

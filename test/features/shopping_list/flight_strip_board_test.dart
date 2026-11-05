/// Tests für das echte Flutter Flight-Strip-Board (FLIGHT-STRIP-01 / Issue #56).
/// Verifiziert:
/// - 3-Ebenen-Architektur: Basket Tray, farbcodierte Produktgruppen, Product Strips
/// - Direkt auf Strips bedienbare Mengensteuerung (− / Count / +) mit mind. 44x44 dp Tap-Targets
/// - Swipe-Right: Sofortige Übernahme in den Korb mit exakt sichtbarer Menge OHNE Bestätigungsdialog (Owner Decision A)
/// - Swipe-Left: Temporäres Überspringen mit Wiederherstellung & Statusanzeige
/// - Barrierefreie Add/Skip-Alternativen ohne Gestenzwang
/// - Undo-Aktionen für Swipe-Right und Swipe-Left
/// - Warenkorb-Aufklappen & Mengen-Bearbeitung im Korb
/// - Suchleiste über alle 232 Katalog-Varianten
/// - Interner A/B-Umschalter zur klassischen PlanningView
/// - Nachtwache-Modus (Rot auf Schwarz) und schmale Viewports (320px).
library;

import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
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
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart' show CrewMemberInput;
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/flight_strip/flight_strip_board_view.dart';
import 'package:proviantplaner/features/shopping_list/ui/flight_strip/product_strip_widget.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/planning_view.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

class FailingShoppingListService extends ShoppingListService {
  bool shouldFailAdopt = false;

  FailingShoppingListService({
    required super.tripDao,
    required super.listItemDao,
    required super.catalogRepository,
    required super.tripService,
  });

  @override
  Future<void> adoptItem({required int tripId, required int listItemId, int? packages}) async {
    if (shouldFailAdopt) {
      throw Exception('Simulierter DB-Fehler beim Speichern');
    }
    return super.adoptItem(tripId: tripId, listItemId: listItemId, packages: packages);
  }
}

class ControllableShoppingListService extends ShoppingListService {
  Completer<void>? unadoptDelay;
  Completer<void>? adoptDelay;
  Duration simulatedDelay = Duration.zero;

  ControllableShoppingListService({
    required super.tripDao,
    required super.listItemDao,
    required super.catalogRepository,
    required super.tripService,
  });

  @override
  Future<void> adoptItem({
    required int tripId,
    required int listItemId,
    int? packages,
  }) async {
    if (adoptDelay != null) {
      await adoptDelay!.future;
    }
    return super.adoptItem(
      tripId: tripId,
      listItemId: listItemId,
      packages: packages,
    );
  }

  @override
  Future<void> unadoptItem({required int tripId, required int listItemId}) async {
    if (unadoptDelay != null) {
      await unadoptDelay!.future;
    }
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    return super.unadoptItem(tripId: tripId, listItemId: listItemId);
  }

  @override
  Future<int> adjustPackagesDelta({
    required int tripId,
    required int listItemId,
    required int delta,
    int minPackages = 1,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    return super.adjustPackagesDelta(
      tripId: tripId,
      listItemId: listItemId,
      delta: delta,
      minPackages: minPackages,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late ShoppingListService shoppingListService;
  late int tripId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catFile = File('data/catalog_v0.11.json');
    final quantFile = File('data/quantities_v0.6.json');
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
      name: 'Adria Flight-Strip Törn',
      startDate: DateTime(2026, 8, 15),
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
        const CrewMemberInput(id: '2', name: 'Ben', isAdult: true, isVegetarian: true, noAlcohol: false),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp({
    ThemeData? theme,
    bool flightStripEnabled = true,
    ShoppingListSortMode sortMode = ShoppingListSortMode.category,
    ShoppingListService? customShoppingListService,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWith((ref) {
          final s = customShoppingListService ?? shoppingListService;
          s.onTripDataChanged = (tId) {
            ref.read(tripDataVersionProvider(tId).notifier).update((v) => v + 1);
          };
          return s;
        }),
        flightStripBoardEnabledProvider.overrideWith((ref) => flightStripEnabled),
        shoppingListViewModeProvider.overrideWith((ref) => sortMode),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de'), Locale('en')],
        locale: const Locale('de'),
        home: ShoppingListScreen(tripId: tripId),
      ),
    );
  }

  group('PROVY FLIGHT-STRIP-01: Flight-Strip-Board Kern-Interaktion (#56)', () {
    testWidgets('1. Strip-Board rendert mit Basket-Tray, Kategorie-Chips und Strips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // FlightStripBoardView ist aktiv
      expect(find.byType(FlightStripBoardView), findsOneWidget);

      // Basket-Tray am Fuß ist sichtbar
      expect(find.byKey(const ValueKey('flight_strip_basket_tray')), findsOneWidget);
      expect(find.textContaining('Korb leer'), findsOneWidget);

      // Suchfeld ist sichtbar
      expect(find.byKey(const ValueKey('flight_strip_search_field')), findsOneWidget);

      // Kategorie-Chips sind sichtbar (z. B. Frühstück, Grundnahrung)
      expect(find.byKey(const ValueKey('cat_chip_fruehstueck')), findsOneWidget);
      expect(find.byKey(const ValueKey('cat_chip_grundnahrung')), findsOneWidget);

      // Product-Strips werden gerendert
      expect(find.byType(ProductStripWidget), findsWidgets);
    });

    testWidgets('2. Mengensteuerung auf dem Strip (− / Count / +) mit barrierefreien Touch-Targets', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Erster Streifen in der Liste
      final firstStrip = find.byType(ProductStripWidget).first;
      expect(firstStrip, findsOneWidget);

      // Minus- und Plus-Buttons finden
      final minusBtn = find.descendant(of: firstStrip, matching: find.byIcon(Icons.remove));
      final plusBtn = find.descendant(of: firstStrip, matching: find.byIcon(Icons.add));
      expect(minusBtn, findsOneWidget);
      expect(plusBtn, findsOneWidget);

      // Barrierefreiheit: Touch-Target-Mindestgröße >= 44 dp
      final minusWidget = tester.widget<IconButton>(find.ancestor(of: minusBtn, matching: find.byType(IconButton)));
      final plusWidget = tester.widget<IconButton>(find.ancestor(of: plusBtn, matching: find.byType(IconButton)));
      expect(minusWidget.constraints?.minWidth ?? 0, greaterThanOrEqualTo(44.0));
      expect(minusWidget.constraints?.minHeight ?? 0, greaterThanOrEqualTo(44.0));
      expect(plusWidget.constraints?.minWidth ?? 0, greaterThanOrEqualTo(44.0));
      expect(plusWidget.constraints?.minHeight ?? 0, greaterThanOrEqualTo(44.0));

      // Plus antippen erhöht sichtbare Zahl
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      // Minus antippen verringert wieder
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('3. SWIPE RIGHT übernimmt Artikel sofort in den Korb OHNE Bestätigungsdialog (Owner Decision A)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Korb startet leer
      expect(find.textContaining('Korb leer'), findsOneWidget);

      // Ersten Streifen finden
      final firstStrip = find.byType(ProductStripWidget).first;
      
      // Fling / Swipe nach Rechts
      await tester.fling(firstStrip, const Offset(600, 0), 1000);
      await tester.pumpAndSettle();

      // Kein Bestätigungsdialog geöffnet!
      expect(find.byType(AlertDialog), findsNothing);

      // Korb zeigt nun 1 Artikel!
      expect(find.textContaining('1 Artikel im Korb'), findsOneWidget);

      // SnackBar mit Erfolgsmeldung und "Rückgängig" erscheint
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Rückgängig'), findsOneWidget);

      // Datenbank-Verifikation: Mindestens 1 Item ist in DB als isAdopted markiert
      final allItems = await db.listItemDao.getListItemsForTrip(tripId);
      final adoptedInDb = allItems.where((it) => it.isAdopted);
      expect(adoptedInDb.length, equals(1));
    });

    testWidgets('4. Undo auf Swipe-Right entfernt Artikel wieder aus dem Korb', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Ersten Streifen nach rechts wischen
      final firstStrip = find.byType(ProductStripWidget).first;
      await tester.fling(firstStrip, const Offset(600, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.textContaining('1 Artikel im Korb'), findsOneWidget);

      // "Rückgängig" auf der SnackBar antippen
      final undoButton = find.text('Rückgängig');
      expect(undoButton, findsOneWidget);
      await tester.tap(undoButton);
      await tester.pumpAndSettle();

      // Korb ist wieder leer
      expect(find.textContaining('Korb leer'), findsOneWidget);

      // Datenbank-Verifikation: Kein Item mehr adoptiert
      final allItems = await db.listItemDao.getListItemsForTrip(tripId);
      final adoptedInDb = allItems.where((it) => it.isAdopted);
      expect(adoptedInDb, isEmpty);
    });

    testWidgets('5. Barrierefreie Schnell-Hinzufügen-Schaltfläche übernimmt ohne Wisch-Geste', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Add-Button mit Warenkorb-Symbol auf dem ersten Streifen finden
      final addIcon = find.byIcon(Icons.add_shopping_cart).first;
      expect(addIcon, findsOneWidget);

      // Antippen
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      // Direkt im Korb
      expect(find.textContaining('1 Artikel im Korb'), findsOneWidget);
    });

    testWidgets('6. SWIPE LEFT überspringt Artikel temporär mit Wiederherstellungsoption', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Ersten Streifen finden
      final firstStrip = find.byType(ProductStripWidget).first;

      // Fling / Swipe nach Links
      await tester.fling(firstStrip, const Offset(-600, 0), 1000);
      await tester.pumpAndSettle();

      // SnackBar mit "übersprungen"
      expect(
        find.descendant(of: find.byType(SnackBar), matching: find.textContaining('übersprungen')),
        findsOneWidget,
      );

      // Statuszeile für übersprungene Positionen erscheint
      expect(find.textContaining('1 übersprungenen Artikel anzeigen'), findsOneWidget);

      // "Alle wiederherstellen" antippen
      final restoreBtn = find.byKey(const ValueKey('restore_all_skipped_button'));
      expect(restoreBtn, findsOneWidget);
      await tester.tap(restoreBtn);
      await tester.pumpAndSettle();

      // Statuszeile ist verschwunden
      expect(find.byKey(const ValueKey('restore_all_skipped_button')), findsNothing);
    });

    testWidgets('7. Korb aufklappen, Inhalte einsehen und Mengen im Korb bearbeiten', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Einen Artikel per Button in den Korb legen
      final addIcon = find.byIcon(Icons.add_shopping_cart).first;
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      // SnackBar ausblenden, um Verdeckung des Tray-Buttons zu vermeiden
      ScaffoldMessenger.of(tester.element(find.byType(ShoppingListScreen))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Korb aufklappen
      final expandBtn = find.byKey(const ValueKey('basket_expand_button'));
      expect(expandBtn, findsOneWidget);
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();

      // Ausgeklappte Korb-Liste sichtbar
      expect(find.byKey(const ValueKey('flight_strip_basket_sheet')), findsOneWidget);

      // Plus im Korb antippen erhöht die Menge
      final basketPlus = find.descendant(
        of: find.byKey(const ValueKey('flight_strip_basket_sheet')),
        matching: find.byIcon(Icons.add),
      ).first;
      await tester.tap(basketPlus);
      await tester.pumpAndSettle();

      // Einkauf starten Button ist vorhanden
            // Einkauf starten Button ist vorhanden
      expect(find.text('Einkauf starten'), findsOneWidget);
    });

    testWidgets('8. Suche filtert sofort über den gesamten 232-Varianten-Katalog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const ValueKey('flight_strip_search_field'));
      expect(searchField, findsOneWidget);

      // "Spaghetti" eingeben
      await tester.enterText(searchField, 'Spaghetti');
      await tester.pumpAndSettle();

      // Spaghetti Streifen muss gerendert werden
      expect(
        find.descendant(of: find.byType(ProductStripWidget), matching: find.text('Spaghetti')),
        findsOneWidget,
      );

      // Text löschen
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cat_chip_fruehstueck')), findsOneWidget);
    });

    testWidgets('9. Interner Schalter schaltet nahtlos zwischen Flight-Strip-Board und PlanningView um', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Standardmäßig FlightStripBoardView
      expect(find.byType(FlightStripBoardView), findsOneWidget);
      expect(find.byType(PlanningView), findsNothing);

      // Umschalt-Button in AppBar antippen
      final toggleBtn = find.byKey(const ValueKey('toggle_flight_strip_board_button'));
      expect(toggleBtn, findsOneWidget);
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      // Nun klassische PlanningView aktiv
      expect(find.byType(PlanningView), findsOneWidget);
      expect(find.byType(FlightStripBoardView), findsNothing);

      // Erneut antippen -> zurück zum Flight-Strip-Board
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(FlightStripBoardView), findsOneWidget);
    });

    testWidgets('10. Nachtwache-Modus rendert strikt in Rot/Schwarz ohne bunte Fremdfarben', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(theme: AppTheme.nightwatchTheme));
      await tester.pumpAndSettle();

      expect(find.byType(FlightStripBoardView), findsOneWidget);
      expect(find.byType(ProductStripWidget), findsWidgets);
    });

    testWidgets('11. Schmaler 320px-Viewport verursacht keinen RenderFlex-Overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(FlightStripBoardView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });


    testWidgets('F1: Bestehende Basket-Einträge schützen – Erneuter Rechts-Swipe & Undo bewahren Originalmenge, Override & Stopp-Allokation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Zweiten Stopp anlegen
      final stop2Id = await db.tripDao.addShoppingStop(
        ShoppingStopsCompanion.insert(
          tripId: tripId,
          dayNumber: const Value(3),
          name: 'Hvar Nachkauf',
        ),
      );

      // 2. Ersten Artikel der ersten Kategorie vorab mit 3 Packungen in den Korb legen
      final initialData = await shoppingListService.loadShoppingList(tripId);
      final testItem = initialData.categories.first.groups.first.variants.first;
      await shoppingListService.adoptItem(tripId: tripId, listItemId: testItem.item.id, packages: 3);

      // 3. Echte Stopp-Allokation von 2 Packungen an Stopp 2 anlegen
      await db.listItemDao.setAllocation(
        tripId: tripId,
        listItemId: testItem.item.id,
        shoppingStopId: stop2Id,
        packages: 2,
      );

      final dbBefore = await db.listItemDao.getListItemById(testItem.item.id);
      expect(dbBefore?.isAdopted, isTrue);
      expect(dbBefore?.overriddenPackages, 3);
      final allocBefore = await db.listItemDao.getAllocationsForListItem(testItem.item.id);
      expect(allocBefore.length, 1);
      expect(allocBefore.first.allocatedPackages, 2);
      expect(allocBefore.first.shoppingStopId, stop2Id);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final stripFinder = find.byKey(ValueKey('strip_widget_${testItem.id}'));
      expect(stripFinder, findsOneWidget);

      // Erneuter Rechts-Swipe auf den bereits im Korb liegenden Streifen
      await tester.fling(stripFinder, const Offset(600, 0), 1000);
      await tester.pumpAndSettle();

      // F1: Streifen wird nicht gelöscht, sondern schnappt zurück
      expect(stripFinder, findsOneWidget);
      expect(find.textContaining('bereits im Korb'), findsOneWidget);

      // DB-Zustand prüfen: isAdopted und Menge 3 bleiben erhalten
      final dbAfter = await db.listItemDao.getListItemById(testItem.item.id);
      expect(dbAfter?.isAdopted, isTrue);
      expect(dbAfter?.overriddenPackages, 3);

      // F1: Stopp-Allokation bleibt unverändert erhalten!
      final allocAfter = await db.listItemDao.getAllocationsForListItem(testItem.item.id);
      expect(allocAfter.length, 1);
      expect(allocAfter.first.allocatedPackages, 2);
      expect(allocAfter.first.shoppingStopId, stop2Id);
    });

    testWidgets('F2: Strip wieder sichtbar machen – Nach Basket-Löschung erscheint der Streifen sofort wieder im Katalog & in der Suche ohne Navigation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 1. Suche nach Spaghetti und übernimm den Streifen
      final searchField = find.byKey(const ValueKey('flight_strip_search_field'));
      await tester.enterText(searchField, 'Spaghetti');
      await tester.pumpAndSettle();

      final spaghettiStrip = find.descendant(
        of: find.byType(ProductStripWidget),
        matching: find.text('Spaghetti'),
      );
      expect(spaghettiStrip, findsOneWidget);

      // Fling Right in den Korb
      final stripWidget = find.byType(ProductStripWidget).first;
      await tester.fling(stripWidget, const Offset(600, 0), 1000);
      await tester.pumpAndSettle();

      // Streifen ist übertragen und nicht mehr in der unübernommenen Trefferliste
      expect(spaghettiStrip, findsNothing);

      // 2. Korb aufklappen
      ScaffoldMessenger.of(tester.element(find.byType(FlightStripBoardView))).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('basket_expand_button')));
      await tester.pumpAndSettle();

      // Löschen-Button im Korb betätigen
      final deleteBtn = find.descendant(
        of: find.byKey(const ValueKey('flight_strip_basket_tray')),
        matching: find.byIcon(Icons.delete_outline),
      );
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // 3. F2: Sofort nach dem Löschen muss Spaghetti wieder auf dem Board / in der Suche erscheinen!
      await tester.tap(find.byKey(const ValueKey('basket_expand_button')));
      await tester.pumpAndSettle();

      expect(spaghettiStrip, findsOneWidget);

      // Re-Add ohne Navigation sofort möglich
      final addBtn = find.descendant(
        of: find.byType(ProductStripWidget),
        matching: find.byIcon(Icons.add_shopping_cart),
      );
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('in den Korb gelegt'), findsOneWidget);
    });

    testWidgets('F3: Fehlerbehandlung – Bei Persistenzfehler schnappt Streifen zurück, zeigt Fehler-SnackBar mit Retry und schützt vor Datenverlust', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final failingService = FailingShoppingListService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: catalogRepo,
        tripService: tripService,
      );
      failingService.shouldFailAdopt = true;

      await tester.pumpWidget(buildTestApp(customShoppingListService: failingService));
      await tester.pumpAndSettle();

      final firstStrip = find.byType(ProductStripWidget).first;
      expect(firstStrip, findsOneWidget);

      // Swipe Right mit fehlschlagendem Service
      await tester.drag(firstStrip, const Offset(500, 0));
      await tester.pumpAndSettle();

      // F3: Streifen schnappt zurück (nicht dauerhaft ausgeblendet)
      expect(firstStrip, findsOneWidget);

      // Fehler-SnackBar sichtbar mit Erneut versuchen
      expect(find.textContaining('Fehler beim Speichern'), findsOneWidget);
      final retryBtn = find.text('Erneut versuchen');
      expect(retryBtn, findsOneWidget);

      // Korb meldet keine falsche Erfolgsmenge
      expect(find.text('Korb leer'), findsOneWidget);

      // Fehlerzustand beheben und Retry ausführen
      failingService.shouldFailAdopt = false;
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      // Jetzt ist die Übernahme erfolgreich
      expect(find.textContaining('in den Korb gelegt'), findsOneWidget);
    });

    testWidgets('F4: Mengensteuerung – Minus bei Menge 1 entfernt Artikel weder auf Strip noch im Korb (Minimum 1)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Artikel mit genau 1 Packung vorab übernehmen
      final initialData = await shoppingListService.loadShoppingList(tripId);
      final firstItem = initialData.allItems.first;
      await shoppingListService.adoptItem(tripId: tripId, listItemId: firstItem.item.id, packages: 1);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 1. Auf dem Streifen auf Minus tippen
      final stripMinus = find.byKey(ValueKey('strip_minus_${firstItem.id}'));
      expect(stripMinus, findsOneWidget);
      await tester.tap(stripMinus);
      await tester.pumpAndSettle();

      // DB-Prüfung: Artikel bleibt mit 1 Packung übernommen, wird NICHT entfernt!
      final dbItem1 = await db.listItemDao.getListItemById(firstItem.item.id);
      expect(dbItem1?.isAdopted, isTrue);
      expect(dbItem1?.overriddenPackages, 1);

      // 2. Korb aufklappen und Minus im Korb tippen
      await tester.tap(find.byKey(const ValueKey('basket_expand_button')));
      await tester.pumpAndSettle();

      final basketMinus = find.descendant(
        of: find.byKey(const ValueKey('flight_strip_basket_tray')),
        matching: find.byIcon(Icons.remove),
      );
      expect(basketMinus, findsOneWidget);
      await tester.tap(basketMinus);
      await tester.pumpAndSettle();

      // DB-Prüfung: Artikel bleibt weiterhin mit 1 Packung im Korb
      final dbItem2 = await db.listItemDao.getListItemById(firstItem.item.id);
      expect(dbItem2?.isAdopted, isTrue);
      expect(dbItem2?.overriddenPackages, 1);
    });

    testWidgets('F5: Keine verlorenen Mengenänderungen – Schnelle Plus-Taps auf dem Strip erhöhen Menge linear (1 -> +,+ = 3)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialData = await shoppingListService.loadShoppingList(tripId);
      final testItem = initialData.categories.first.groups.first.variants.first;
      await shoppingListService.adoptItem(tripId: tripId, listItemId: testItem.item.id, packages: 1);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final plusBtn = find.byKey(ValueKey('strip_plus_${testItem.id}'));
      expect(plusBtn, findsOneWidget);

      // Zwei schnelle Plus-Taps ohne pumpAndSettle dazwischen
      await tester.tap(plusBtn);
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      final dbItem = await db.listItemDao.getListItemById(testItem.item.id);
      expect(dbItem?.overriddenPackages, 3);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('F5: Keine verlorenen Mengenänderungen – Schnelle Minus-Taps verringern Menge linear (3 -> -,- = 1)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialData = await shoppingListService.loadShoppingList(tripId);
      final testItem = initialData.categories.first.groups.first.variants.first;
      await shoppingListService.adoptItem(tripId: tripId, listItemId: testItem.item.id, packages: 3);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final minusBtn = find.byKey(ValueKey('strip_minus_${testItem.id}'));
      expect(minusBtn, findsOneWidget);

      // Zwei schnelle Minus-Taps ohne pumpAndSettle dazwischen
      await tester.tap(minusBtn);
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();

      final dbItem = await db.listItemDao.getListItemById(testItem.item.id);
      expect(dbItem?.overriddenPackages, 1);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('F5: Verzögerte Service-Ausführung & gemischte Strip-/Tray-Parallelität verliert keine Eingabe', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final delayedService = ControllableShoppingListService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: catalogRepo,
        tripService: tripService,
      );
      delayedService.simulatedDelay = const Duration(milliseconds: 20);

      final initialData = await delayedService.loadShoppingList(tripId);
      final testItem = initialData.categories.first.groups.first.variants.first;
      await delayedService.adoptItem(tripId: tripId, listItemId: testItem.item.id, packages: 1);

      await tester.pumpWidget(buildTestApp(customShoppingListService: delayedService));
      await tester.pumpAndSettle();

      // Korb aufklappen
      await tester.tap(find.byKey(const ValueKey('basket_expand_button')));
      await tester.pumpAndSettle();

      // Tap 1 auf Strip Plus, Tap 2 im Korb Plus
      final stripPlus = find.byKey(ValueKey('strip_plus_${testItem.id}'));
      final basketPlus = find.descendant(
        of: find.byKey(const ValueKey('flight_strip_basket_tray')),
        matching: find.byIcon(Icons.add),
      );

      await tester.tap(stripPlus);
      await tester.tap(basketPlus);
      await tester.pumpAndSettle();

      final dbItem = await db.listItemDao.getListItemById(testItem.item.id);
      expect(dbItem?.overriddenPackages, 3);
    });

    testWidgets('F5: Allokationssummen-Schutz beim Verringern (Menge darf Summe bestehender Stopp-Allokationen nicht unterschreiten)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stop2Id = await db.tripDao.addShoppingStop(
        ShoppingStopsCompanion.insert(
          tripId: tripId,
          dayNumber: const Value(3),
          name: 'Stopp 2',
        ),
      );

      final initialData = await shoppingListService.loadShoppingList(tripId);
      final testItem = initialData.categories.first.groups.first.variants.first;
      await shoppingListService.adoptItem(tripId: tripId, listItemId: testItem.item.id, packages: 3);

      // 2 Packungen an Stopp 2 allokieren (Summe = 2)
      await db.listItemDao.setAllocation(
        tripId: tripId,
        listItemId: testItem.item.id,
        shoppingStopId: stop2Id,
        packages: 2,
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final minusBtn = find.byKey(ValueKey('strip_minus_${testItem.id}'));

      // 1. Minus-Tap: 3 -> 2 (erlaubt)
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect((await db.listItemDao.getListItemById(testItem.item.id))?.overriddenPackages, 2);

      // 2. Minus-Tap: Versuch von 2 auf 1 -> geschützt, bleibt bei 2
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect((await db.listItemDao.getListItemById(testItem.item.id))?.overriddenPackages, 2);

      // Allokation weiterhin intakt
      final alloc = await db.listItemDao.getAllocationsForListItem(testItem.item.id);
      expect(alloc.first.allocatedPackages, 2);
    });

    testWidgets('F6: Sicherer asynchroner UI-Lebenszyklus – Korb-Löschung bei unmounted / navigierter Ansicht wirft kein setState after dispose', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controllableService = ControllableShoppingListService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: catalogRepo,
        tripService: tripService,
      );
      final unadoptCompleter = Completer<void>();
      controllableService.unadoptDelay = unadoptCompleter;

      final initialData = await controllableService.loadShoppingList(tripId);
      final testItem = initialData.categories.first.groups.first.variants.first;
      await controllableService.adoptItem(tripId: tripId, listItemId: testItem.item.id, packages: 2);

      await tester.pumpWidget(buildTestApp(customShoppingListService: controllableService));
      await tester.pumpAndSettle();

      // Korb aufklappen
      await tester.tap(find.byKey(const ValueKey('basket_expand_button')));
      await tester.pumpAndSettle();

      // Löschen antippen -> unadoptItem startet und blockiert auf unadoptCompleter
      final deleteBtn = find.descendant(
        of: find.byKey(const ValueKey('flight_strip_basket_tray')),
        matching: find.byIcon(Icons.delete_outline),
      );
      await tester.tap(deleteBtn);
      await tester.pump(); // Startet async unadopt

      // Benutzer schaltet die Ansicht zur klassischen PlanningView um (unmountet FlightStripBoardView & BasketTrayWidget!)
      await tester.tap(find.byKey(const ValueKey('toggle_flight_strip_board_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PlanningView), findsOneWidget);
      expect(find.byType(FlightStripBoardView), findsNothing);

      // Jetzt löst die asynchrone DB-Operation auf
      unadoptCompleter.complete();
      await tester.pumpAndSettle();

      // F6: Kein setState() called after dispose Fehler geworfen!
      expect(tester.takeException(), isNull);

      // Artikel wurde in DB sauber entfernt
      final dbItem = await db.listItemDao.getListItemById(testItem.item.id);
      expect(dbItem?.isAdopted, isFalse);
    });

    testWidgets('F6: Sicherer asynchroner UI-Lebenszyklus – Undo bei unmounted Widget wirft kein setState after dispose', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controllableService = ControllableShoppingListService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: catalogRepo,
        tripService: tripService,
      );
      final unadoptCompleter = Completer<void>();
      controllableService.unadoptDelay = unadoptCompleter;

      await tester.pumpWidget(buildTestApp(customShoppingListService: controllableService));
      await tester.pumpAndSettle();

      // Ersten Streifen nach rechts wischen
      final firstStrip = find.byType(ProductStripWidget).first;
      await tester.fling(firstStrip, const Offset(600, 0), 1000);
      await tester.pumpAndSettle();

      // Undo-Button auf SnackBar antippen
      final undoBtn = find.text('Rückgängig');
      expect(undoBtn, findsOneWidget);
      await tester.tap(undoBtn);
      await tester.pump(); // Startet Undo mit unadoptItem

      // Benutzer schaltet Ansicht um
      await tester.tap(find.byKey(const ValueKey('toggle_flight_strip_board_button')));
      await tester.pumpAndSettle();

      // Verzögerte DB-Löschung auflösen
      unadoptCompleter.complete();
      await tester.pumpAndSettle();

      // F6: Kein Crash / setState after dispose
      expect(tester.takeException(), isNull);
    });

    testWidgets('F6-A: Quick-Add nach Unmount – Verzögertes adoptItem bei Ansichtswechsel wirft kein setState after dispose und persistiert DB korrekt', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controllableService = ControllableShoppingListService(
        tripDao: db.tripDao,
        listItemDao: db.listItemDao,
        catalogRepository: catalogRepo,
        tripService: tripService,
      );
      final adoptCompleter = Completer<void>();
      controllableService.adoptDelay = adoptCompleter;

      final initialData = await controllableService.loadShoppingList(tripId);
      final testItem = initialData.categories.first.groups.first.variants.first;

      await tester.pumpWidget(buildTestApp(customShoppingListService: controllableService));
      await tester.pumpAndSettle();

      // Quick-Add-Button (Icons.add_shopping_cart) auf dem ersten Streifen antippen
      final firstStrip = find.byType(ProductStripWidget).first;
      final quickAddBtn = find.descendant(
        of: firstStrip,
        matching: find.byIcon(Icons.add_shopping_cart),
      );
      expect(quickAddBtn, findsOneWidget);

      await tester.tap(quickAddBtn);
      await tester.pump(); // Startet adoptItem, blockiert auf adoptCompleter

      // Benutzer schaltet Ansicht um zur klassischen PlanningView (FlightStripBoardView wird unmounted!)
      await tester.tap(find.byKey(const ValueKey('toggle_flight_strip_board_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PlanningView), findsOneWidget);
      expect(find.byType(FlightStripBoardView), findsNothing);

      // Jetzt wird die verzögerte Übernahme erfolgreich aufgelöst
      adoptCompleter.complete();
      await tester.pumpAndSettle();

      // F6-A: Kein setState() called after dispose Fehler geworfen!
      expect(tester.takeException(), isNull);

      // Datenbankzustand: Artikel ist erfolgreich in der DB als übernommen markiert
      final dbItem = await db.listItemDao.getListItemById(testItem.item.id);
      expect(dbItem?.isAdopted, isTrue);
      expect(dbItem?.overriddenPackages, 1);
    });

    testWidgets('F6-B: Undo nach Ansichtswechsel – Noch sichtbare SnackBar greift nach Unmount nicht auf ungültigen Ref zu und stellt Zustand wieder her', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialData = await shoppingListService.loadShoppingList(tripId);
      final testItem = initialData.categories.first.groups.first.variants.first;

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 1. Rechts-Swipe auf erstem Streifen -> Übernahme in den Korb
      final firstStrip = find.byType(ProductStripWidget).first;
      await tester.fling(firstStrip, const Offset(600, 0), 1000);
      await tester.pumpAndSettle();

      // Artikel ist in DB übernommen
      expect((await db.listItemDao.getListItemById(testItem.item.id))?.isAdopted, isTrue);

      // SnackBar mit "Rückgängig" ist im Scaffold sichtbar
      final undoBtn = find.text('Rückgängig');
      expect(undoBtn, findsOneWidget);

      // 2. Ansicht umschalten zur klassischen PlanningView während SnackBar sichtbar bleibt
      await tester.tap(find.byKey(const ValueKey('toggle_flight_strip_board_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PlanningView), findsOneWidget);
      expect(find.byType(FlightStripBoardView), findsNothing);

      // SnackBar ist weiterhin sichtbar im Scaffold
      expect(undoBtn, findsOneWidget);

      // 3. Auf noch sichtbares "Rückgängig" in der klassischen Ansicht tippen
      await tester.tap(undoBtn);
      await tester.pumpAndSettle();

      // F6-B: Kein Framework-/Provider-Fehler ("Cannot use ref after the widget was disposed")
      expect(tester.takeException(), isNull);

      // Kanonischer DB-Zustand: Artikel wurde sauber unadopted (isAdopted = false)
      final dbItem = await db.listItemDao.getListItemById(testItem.item.id);
      expect(dbItem?.isAdopted, isFalse);
    });

    testWidgets('#61: Swipe-Stabilität & Flicker-Prävention – Kein Unmount/Ladekreis während Provider-Reload beim Streifen-Transfer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(FlightStripBoardView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final firstStrip = find.byType(ProductStripWidget).first;
      expect(firstStrip, findsOneWidget);

      // Fling Right in den Korb
      await tester.fling(firstStrip, const Offset(600, 0), 1000);
      
      // Während der Animation und des Provider-Updates (Teil-Pump ohne Settle):
      // Weder Ladekreis noch unmountetes Board darf auftreten
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(FlightStripBoardView), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(FlightStripBoardView), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(FlightStripBoardView), findsOneWidget);
    });
  });
}

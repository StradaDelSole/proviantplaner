import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/more/ui/more_screen.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/flight_strip/flight_strip_board_view.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/shopping_view.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/ui/trip_overview_screen.dart';
import 'package:proviantplaner/features/welcome/data/welcome_storage.dart';
import 'package:proviantplaner/features/welcome/ui/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late KittyService kittyService;
  late DeliveryOrderService deliveryOrderService;
  late ShoppingListService shoppingListService;
  late MemoryWelcomeStorage memoryWelcomeStorage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catalogFile = File('data/catalog_v0.11.json');
    final quantitiesFile = File('data/quantities_v0.6.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catalogFile.readAsStringSync(),
      quantitiesJson: quantitiesFile.readAsStringSync(),
    );

    tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
    );
    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );
    deliveryOrderService = DeliveryOrderService();
    shoppingListService = ShoppingListService(
      listItemDao: db.listItemDao,
      tripDao: db.tripDao,
      catalogRepository: catalogRepo,
      tripService: tripService,
    );
    memoryWelcomeStorage = MemoryWelcomeStorage(initialSeen: true);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createTestTrip({int days = 7}) async {
    return await tripService.createTripWithCrew(
      name: 'Sommertörn UX Recovery',
      startDate: DateTime.now(),
      daysCount: days,
      isCharter: true,
      boatType: 'monohull',
      region: 'mediterranean_summer',
      fridgeCapacityLiters: 120,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: const [
        CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        CrewMemberInput(id: '2', name: 'Co-Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
      ],
    );
  }

  Widget buildTestApp({
    required GoRouter router,
    WelcomeStorage? welcomeStorage,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        kittyServiceProvider.overrideWithValue(kittyService),
        deliveryOrderServiceProvider.overrideWithValue(deliveryOrderService),
        shoppingListServiceProvider.overrideWithValue(shoppingListService),
        welcomeStorageProvider.overrideWithValue(welcomeStorage ?? memoryWelcomeStorage),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de')],
        locale: const Locale('de'),
      ),
    );
  }

  group('PROVY UX-RECOVERY-INTEGRATED-01 Verification Suite', () {
    testWidgets('1. Vorratsliste startet in Abteilungsansicht (PIVOT1 Decision 16); 1-Klick-Wechsel auf Flight-Strip-Board (Pixel 7 Pro 412x915)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createTestTrip();

      final router = GoRouter(
        initialLocation: '/trips/$tripId/shopping-list',
        routes: [
          GoRoute(
            path: '/trips/:id/shopping-list',
            builder: (_, state) => ShoppingListScreen(tripId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      // 1. Vorratsliste startet standardmäßig nach Supermarkt-Abteilung (PIVOT1 Decision 16)
      expect(find.byType(ShoppingView), findsOneWidget);
      expect(find.byType(FlightStripBoardView), findsNothing);

      // 2. Ein-Klick-Umschaltung auf Flight-Strip-Board via AppBar-Button
      final toggleBtn = find.byKey(const ValueKey('toggle_flight_strip_board_button'));
      expect(toggleBtn, findsOneWidget);
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      // Flight-Strip-Board ist direkt mit Board, Basket Tray und Farb-Kategorien sichtbar
      expect(find.byType(FlightStripBoardView), findsOneWidget);
      expect(find.byKey(const ValueKey('flight_strip_search_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('flight_strip_basket_tray')), findsOneWidget);
      expect(find.byKey(const ValueKey('cat_chip_fruehstueck')), findsOneWidget);

      // 3. Umschaltung über SegmentedButton zurück auf Abteilung und wieder auf Kategorie
      await tester.tap(find.descendant(
        of: find.byType(SegmentedButton<ShoppingListSortMode>),
        matching: find.byIcon(Icons.storefront_outlined),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(ShoppingView), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(SegmentedButton<ShoppingListSortMode>),
        matching: find.byIcon(Icons.category_outlined),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(FlightStripBoardView), findsOneWidget);
    });

    testWidgets('2. Scrollstabilität der Vorratsliste: 40+ Produkte, Adoptionen in Listenmitte, kein Sprung, kein Fullscreen-Reload', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createTestTrip();

      final router = GoRouter(
        initialLocation: '/trips/$tripId/shopping-list',
        routes: [
          GoRoute(
            path: '/trips/:id/shopping-list',
            builder: (_, state) => ShoppingListScreen(tripId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      // Auf Flight-Strip-Board wechseln
      await tester.tap(find.byIcon(Icons.category_outlined));
      await tester.pumpAndSettle();

      final listFinder = find.byKey(PageStorageKey<String>('flight_strip_list_view_$tripId'));
      final scrollableFinder = find.descendant(of: listFinder, matching: find.byType(Scrollable));

      // In die Mitte scrollen (mindestens 400px herunterscrollen)
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      final offsetBefore = tester.state<ScrollableState>(scrollableFinder).position.pixels;
      expect(offsetBefore, greaterThan(300));

      // 5 sichtbare Schnell-Übernehmen-Buttons finden und nacheinander übernehmen
      final addButtons = find.byTooltip('In den Korb legen');
      expect(addButtons, findsWidgets);

      for (int i = 0; i < 5; i++) {
        final currentAddButtons = find.byTooltip('In den Korb legen');
        if (currentAddButtons.evaluate().isNotEmpty) {
          await tester.tap(currentAddButtons.first);
          await tester.pumpAndSettle();
        }
      }

      // Scrollposition bleibt stabil im relevanten Bereich, kein Sprung auf 0
      final offsetAfter = tester.state<ScrollableState>(scrollableFinder).position.pixels;
      expect(offsetAfter, greaterThan(150), reason: 'Scroll position must not reset to top');

      // Kein Fullscreen-Ladeindikator
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Korb enthält jetzt Artikel
      final adoptedCount = await db.listItemDao.getListItemsForTrip(tripId);
      final adoptedInDb = adoptedCount.where((it) => it.isAdopted).length;
      expect(adoptedInDb, greaterThanOrEqualTo(3));
    });

    testWidgets('3. Beide Swipe-Richtungen & Schnell-Übernehmen auf Flight-Strip', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createTestTrip();

      final router = GoRouter(
        initialLocation: '/trips/$tripId/shopping-list',
        routes: [
          GoRoute(
            path: '/trips/:id/shopping-list',
            builder: (_, state) => ShoppingListScreen(tripId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      // Auf Flight-Strip-Board wechseln
      await tester.tap(find.byIcon(Icons.category_outlined));
      await tester.pumpAndSettle();

      final firstDismissible = find.byType(Dismissible).first;

      // Swipe Right -> Übernehmen
      await tester.drag(firstDismissible, const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Rückgängig'), findsOneWidget);

      // Schnell-Übernehmen Button beim nächsten sichtbaren Strip
      final quickAddBtn = find.byTooltip('In den Korb legen').first;
      await tester.tap(quickAddBtn);
      await tester.pumpAndSettle();

      expect(find.text('Rückgängig'), findsOneWidget);

      // Swipe Left auf 3. Strip -> Überspringen
      final thirdDismissible = find.byType(Dismissible).first;
      await tester.drag(thirdDismissible, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('toggle_skipped_button')), findsOneWidget);
    });

    testWidgets('4. Crew-Scrollstabilität: Hinzufügen im Edit-Sheet springt nicht nach oben', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createTestTrip();

      final router = GoRouter(
        initialLocation: '/trips/$tripId',
        routes: [
          GoRoute(
            path: '/trips/:id',
            builder: (_, state) => TripOverviewScreen(tripId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      // Edit Sheet öffnen
      await tester.tap(find.byTooltip('Törn bearbeiten'));
      await tester.pumpAndSettle();

      final sheetScrollable = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      ).first;

      final addCrewBtn = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byIcon(Icons.person_add_outlined),
      );

      await tester.scrollUntilVisible(addCrewBtn, 100, scrollable: sheetScrollable);
      await tester.pumpAndSettle();

      final offsetBefore = tester.state<ScrollableState>(sheetScrollable).position.pixels;
      expect(offsetBefore, greaterThan(150));

      // Person hinzufügen
      await tester.tap(addCrewBtn);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Daniel');
      await tester.tap(find.text('Speichern').last);
      await tester.pumpAndSettle();

      final offsetAfter = tester.state<ScrollableState>(sheetScrollable).position.pixels;
      expect(offsetAfter, greaterThanOrEqualTo(offsetBefore - 20),
          reason: 'Scroll position in edit sheet must remain at the crew section');

      // Neuer Crew-Name ist in der Datenbank persistiert
      final crewInDb = await db.tripDao.getCrewForTrip(tripId);
      expect(crewInDb.any((c) => c.name == 'Daniel'), isTrue);
    });

    testWidgets('5. Welcome Screen Preview: Menüeintrag in MoreScreen öffnet Vorschau nichtdestruktiv (weder Close noch CTA schreiben Storage)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createTestTrip();

      final router = GoRouter(
        initialLocation: '/more',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const StartScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (_, __) => const MoreScreen(),
          ),
          GoRoute(
            path: '/welcome',
            builder: (_, state) => WelcomeScreen(
              isPreview: state.uri.queryParameters['preview'] == 'true',
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      expect(memoryWelcomeStorage.writeCalls, equals(0));

      // Menüeintrag "Welcome erneut ansehen" vorhanden
      final welcomeTile = find.byKey(const ValueKey('more_welcome_preview_tile'));
      await tester.scrollUntilVisible(welcomeTile, 300);
      expect(welcomeTile, findsOneWidget);

      // --- Exit 1: Close-Button oben rechts ---
      await tester.tap(welcomeTile);
      await tester.pumpAndSettle();

      // Welcome Screen ist geöffnet mit PROVY Branding
      expect(find.text('PROVY'), findsOneWidget);
      expect(find.text('Smarter planen. Leichter segeln.'), findsOneWidget);

      final closeBtn = find.byKey(const ValueKey('welcome_preview_close_button'));
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Wieder auf MoreScreen
      expect(find.byType(MoreScreen), findsOneWidget);
      // Keine Schreibzugriffe auf WelcomeStorage
      expect(memoryWelcomeStorage.writeCalls, equals(0));

      // --- Exit 2: Primärer CTA "Los geht's" in der Vorschau ---
      await tester.tap(welcomeTile);
      await tester.pumpAndSettle();

      final ctaBtn = find.byKey(const ValueKey('welcome_get_started_button'));
      expect(ctaBtn, findsOneWidget);

      await tester.tap(ctaBtn);
      await tester.pumpAndSettle();

      // Kehrt zurück auf MoreScreen ohne zu schreiben
      expect(find.byType(MoreScreen), findsOneWidget);
      expect(memoryWelcomeStorage.writeCalls, equals(0),
          reason: 'Preview CTA must never write to WelcomeStorage');

      // Bestehende Törndaten in DB unberührt
      final trip = await db.tripDao.getTripById(tripId);
      expect(trip, isNotNull);
      final crew = await db.tripDao.getCrewForTrip(tripId);
      expect(crew.length, equals(2));
    });
  });
}

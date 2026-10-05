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
import 'package:proviantplaner/features/kitty/ui/kitty_screen.dart';
import 'package:proviantplaner/features/kitty/ui/settlement_screen.dart';
import 'package:proviantplaner/features/more/ui/more_screen.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_mode_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/storage_checklist_screen.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';
import 'package:proviantplaner/features/trip/ui/trip_overview_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_timeline_screen.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late KittyService kittyService;
  late DeliveryOrderService deliveryOrderService;
  late ShoppingListService shoppingListService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catalogFile = File('data/catalog_v0.9.json');
    final quantitiesFile = File('data/quantities_v0.5.json');
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
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildAppWithRouter({
    required GoRouter router,
    Locale locale = const Locale('de'),
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        kittyServiceProvider.overrideWithValue(kittyService),
        deliveryOrderServiceProvider.overrideWithValue(deliveryOrderService),
        shoppingListServiceProvider.overrideWithValue(shoppingListService),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('de'),
          Locale('en'),
          Locale('es'),
          Locale('fr'),
          Locale('hr'),
          Locale('pt'),
        ],
        locale: locale,
      ),
    );
  }

  GoRouter createTestRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const StartScreen(),
        ),
        GoRoute(
          path: '/trips/:id',
          builder: (_, state) => TripOverviewScreen(tripId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/trips/:id/timeline',
          builder: (_, state) => TripTimelineScreen(tripId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/trips/:id/shopping-list',
          builder: (_, state) => ShoppingListScreen(tripId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/trips/:id/shop/:stopId',
          builder: (_, state) => ShoppingModeScreen(
            tripId: int.parse(state.pathParameters['id']!),
            stopId: int.parse(state.pathParameters['stopId']!),
          ),
        ),
        GoRoute(
          path: '/trips/:id/storage',
          builder: (_, state) => StorageChecklistScreen(tripId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/trips/:id/kitty',
          builder: (_, state) => KittyScreen(tripId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/trips/:id/kitty/settlement',
          builder: (_, state) => SettlementScreen(tripId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/more',
          builder: (_, __) => const MoreScreen(),
        ),
        GoRoute(
          path: '/trips/:id/more',
          builder: (_, state) => MoreScreen(tripId: int.parse(state.pathParameters['id']!)),
        ),
      ],
    );
  }

  Future<int> createSampleTrip({
    String name = 'Test Törn',
    int daysCount = 7,
  }) async {
    final tripId = await tripService.createTripWithCrew(
      name: name,
      startDate: DateTime.now().add(const Duration(days: 1)),
      daysCount: daysCount,
      crewMembers: const [
        CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        CrewMemberInput(id: '2', name: 'Co-Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
      ],
    );
    final crew = await db.tripDao.getCrewForTrip(tripId);
    if (crew.isNotEmpty) {
      await db.tripDao.setTripTreasurer(tripId, crew.first.id);
    }
    return tripId;
  }

  group('FIX-A Journey- & Routing-Tests', () {
    testWidgets('Journey 1: TripOverviewScreen -> ShoppingList -> Back -> TripOverviewScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip();
      final router = createTestRouter(initialLocation: '/trips/$tripId');

      await tester.pumpWidget(buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(TripOverviewScreen), findsOneWidget);

      // Tap on "Liste bearbeiten"
      final editListButton = find.text('Liste bearbeiten');
      expect(editListButton, findsOneWidget);
      await tester.tap(editListButton);
      await tester.pumpAndSettle();

      // We are now on ShoppingListScreen
      expect(find.byType(ShoppingListScreen), findsOneWidget);

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Back on TripOverviewScreen
      expect(find.byType(TripOverviewScreen), findsOneWidget);
      expect(find.byType(ShoppingListScreen), findsNothing);
    });

    testWidgets('Journey 2: TripOverviewScreen -> KittyScreen -> Action -> Back -> TripOverviewScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip();
      final router = createTestRouter(initialLocation: '/trips/$tripId');

      await tester.pumpWidget(buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(TripOverviewScreen), findsOneWidget);

      // Open Kitty
      final kittyButton = find.widgetWithText(FilledButton, 'Bordkasse öffnen');
      expect(kittyButton, findsOneWidget);
      await tester.tap(kittyButton);
      await tester.pumpAndSettle();

      // We are on KittyScreen
      expect(find.byType(KittyScreen), findsOneWidget);

      // Switch segment to "Einzahlungen"
      final depositTab = find.textContaining('Einzahlungen');
      if (depositTab.evaluate().isNotEmpty) {
        await tester.tap(depositTab.first);
        await tester.pumpAndSettle();
      }

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Back cleanly on TripOverviewScreen
      expect(find.byType(TripOverviewScreen), findsOneWidget);
      expect(find.byType(KittyScreen), findsNothing);
    });

    testWidgets('Journey 3: Shopping -> Unbought items "Später" -> Create target stop -> Verify allocations & no inflation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip();

      // Adopt an item so it is on the list
      final listData = await shoppingListService.loadShoppingList(tripId);
      final firstItem = listData.allItems.first;
      await shoppingListService.adoptItem(tripId: tripId, listItemId: firstItem.item.id);
      final adoptedList = await shoppingListService.loadShoppingList(tripId);
      final adoptedItem = adoptedList.allItems.firstWhere((it) => it.item.id == firstItem.item.id);

      final stops = await db.tripDao.getShoppingStopsForTrip(tripId);
      final initialStop = stops.first;

      final router = createTestRouter(initialLocation: '/trips/$tripId/shop/${initialStop.id}');
      await tester.pumpWidget(buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingModeScreen), findsOneWidget);

      // Finish shopping without checking items (unbought item left)
      final finishButton = find.widgetWithText(FilledButton, 'Fertig eingekauft');
      expect(finishButton, findsOneWidget);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      // Unbought dialog appears
      expect(find.text('Offene Posten'), findsOneWidget);

      // Tap "Merken"
      final postponeButton = find.text('Merken');
      expect(postponeButton, findsOneWidget);
      await tester.tap(postponeButton);
      await tester.pumpAndSettle();

      // Since NO later stop exists, the follow-up stop dialog must appear!
      expect(find.text('Folgestopp anlegen'), findsOneWidget);

      // Tap "Stopp anlegen & verschieben"
      final createAndMoveButton = find.text('Stopp anlegen & verschieben');
      expect(createAndMoveButton, findsOneWidget);
      await tester.tap(createAndMoveButton);
      await tester.pumpAndSettle();

      // Verify SnackBar notice appears
      expect(find.textContaining('verschoben'), findsOneWidget);

      // Verify that a new stop was created
      final updatedStops = await db.tripDao.getShoppingStopsForTrip(tripId);
      expect(updatedStops.length, equals(2));

      // Verify item quantity is NOT inflated
      final updatedList = await shoppingListService.loadShoppingList(tripId);
      final updatedItem = updatedList.allItems.firstWhere((it) => it.item.id == firstItem.item.id);
      expect(updatedItem.effectivePackages, equals(adoptedItem.effectivePackages));
    });

    testWidgets('Journey 4: ShoppingMode (all checked) -> StorageChecklist (all checked) -> Land on Overview in underway phase', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip();
      final listData = await shoppingListService.loadShoppingList(tripId);
      final firstItem = listData.allItems.first;
      await shoppingListService.adoptItem(tripId: tripId, listItemId: firstItem.item.id);

      final stops = await db.tripDao.getShoppingStopsForTrip(tripId);
      final initialStop = stops.first;

      final router = createTestRouter(initialLocation: '/trips/$tripId/shop/${initialStop.id}');
      await tester.pumpWidget(buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      // Check the item
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Tap finish shopping
      final finishButton = find.widgetWithText(FilledButton, 'Fertig eingekauft');
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      // Prompt storage dialog
      expect(find.text('Fertig eingekauft!'), findsOneWidget);
      final storeNowButton = find.text('Jetzt einlagern');
      expect(storeNowButton, findsOneWidget);
      await tester.tap(storeNowButton);
      await tester.pumpAndSettle();

      // Now on StorageChecklistScreen
      expect(find.byType(StorageChecklistScreen), findsOneWidget);

      // Check first storage item if any
      final storageCheckbox = find.byType(Checkbox);
      if (storageCheckbox.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(storageCheckbox.first, 100, scrollable: find.byType(Scrollable).first);
        await tester.tap(storageCheckbox.first);
        await tester.pumpAndSettle();
      }

      // Tap complete storage
      final completeStorageButton = find.widgetWithText(FilledButton, 'Einlagerung abschließen');
      expect(completeStorageButton, findsOneWidget);
      await tester.tap(completeStorageButton);
      await tester.pumpAndSettle();

      // Lands on TripOverviewScreen
      expect(find.byType(TripOverviewScreen), findsOneWidget);

      // Phase is now underway
      final trip = await db.tripDao.getTripById(tripId);
      expect(trip!.phase, equals(TripPhase.underway));
    });

    testWidgets('Journey 5: TripOverviewScreen -> Settlement -> Back -> TripOverviewScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip();
      final router = createTestRouter(initialLocation: '/trips/$tripId');

      await tester.pumpWidget(buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      // Settle button in Overview
      final settleButton = find.widgetWithText(FilledButton, 'Abrechnen');
      expect(settleButton, findsOneWidget);
      await tester.tap(settleButton);
      await tester.pumpAndSettle();

      // On SettlementScreen
      expect(find.byType(SettlementScreen), findsOneWidget);

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Back on TripOverviewScreen
      expect(find.byType(TripOverviewScreen), findsOneWidget);
    });

    testWidgets('Journey 6: Trip Edit -> restaurant lunches/dinners steppers & clamping', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip(daysCount: 7);
      final router = createTestRouter(initialLocation: '/trips/$tripId');

      await tester.pumpWidget(buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      // Open Edit Dialog
      final editIcon = find.byTooltip('Törn bearbeiten');
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Verify restaurant steppers exist under Mahlzeiten
      final mealsTitle = find.text('Mahlzeiten & Restaurant');
      await tester.scrollUntilVisible(mealsTitle, 100, scrollable: find.byType(Scrollable).last);
      expect(mealsTitle, findsOneWidget);
      expect(find.text('Mittagessen im Restaurant'), findsOneWidget);
      expect(find.text('Abendessen im Restaurant'), findsOneWidget);

      // Increment lunch count twice
      final addIcons = find.byIcon(Icons.add_circle_outline);
      // Index 0 is daysCount, index 1 is lunchCount, index 2 is dinnerCount
      expect(addIcons, findsNWidgets(3));
      await tester.tap(addIcons.at(1)); // lunch++
      await tester.pumpAndSettle();
      await tester.tap(addIcons.at(1)); // lunch++
      await tester.pumpAndSettle();
      await tester.tap(addIcons.at(2)); // dinner++
      await tester.pumpAndSettle();

      // Save
      final saveButton = find.text('Speichern');
      await tester.scrollUntilVisible(saveButton, 100, scrollable: find.byType(Scrollable).last);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify in DB
      final days = await db.tripDao.getDaysForTrip(tripId);
      final lunches = days.where((d) => d.lunchRestaurant).length;
      final dinners = days.where((d) => d.dinnerRestaurant).length;
      expect(lunches, equals(2));
      expect(dinners, equals(1));

      // Test clamping: reduce days to 1 via updateTripDetails directly
      await tripService.updateTripDetails(
        tripId: tripId,
        daysCount: 1,
        restaurantLunches: 5,
        restaurantDinners: 5,
      );
      final clampedDays = await db.tripDao.getDaysForTrip(tripId);
      expect(clampedDays.length, equals(1));
      expect(clampedDays.where((d) => d.lunchRestaurant).length, equals(1));
      expect(clampedDays.where((d) => d.dinnerRestaurant).length, equals(1));
    });

    testWidgets('Journey 7: Shopping stops CRUD & initial stop protected', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip();
      final router = createTestRouter(initialLocation: '/trips/$tripId');

      await tester.pumpWidget(buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      // Initial stop exists and does NOT have a delete button
      final initialStops = await db.tripDao.getShoppingStopsForTrip(tripId);
      expect(initialStops.length, equals(1));
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // Add stop
      final addStopButton = find.text('+ Einkaufsstopp hinzufügen');
      expect(addStopButton, findsOneWidget);
      await tester.tap(addStopButton);
      await tester.pumpAndSettle();

      final addDialogButton = find.widgetWithText(FilledButton, 'Speichern');
      expect(addDialogButton, findsOneWidget);
      await tester.tap(addDialogButton);
      await tester.pumpAndSettle();

      // Now 2 stops exist
      final twoStops = await db.tripDao.getShoppingStopsForTrip(tripId);
      expect(twoStops.length, equals(2));

      // Delete icon is only on the second stop
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Delete the second stop
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm delete dialog
      expect(find.text('Einkaufsstopp löschen'), findsOneWidget);
      final deleteConfirm = find.widgetWithText(FilledButton, 'Löschen');
      await tester.tap(deleteConfirm);
      await tester.pumpAndSettle();

      // Second stop is deleted, initial stop remains
      final finalStops = await db.tripDao.getShoppingStopsForTrip(tripId);
      expect(finalStops.length, equals(1));
      expect(finalStops.first.isInitial, isTrue);
    });
  });

  group('Findings A & C: Localization & Settings Hardening', () {
    testWidgets('Finding A: TripOverviewScreen in English has zero German residue strings', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip();
      final router = createTestRouter(initialLocation: '/trips/$tripId');

      await tester.pumpWidget(buildAppWithRouter(router: router, locale: const Locale('en')));
      await tester.pumpAndSettle();

      // English titles must be present
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Underway / Crew Fund'), findsOneWidget);
      expect(find.text('Settle up'), findsWidgets);

      // German residue strings must be absent
      expect(find.textContaining('Kühl- & Wasserkapazitäten'), findsNothing);
      expect(find.textContaining('Tage im Törnverlauf'), findsNothing);
      expect(find.textContaining('Ausgleichszahlungen'), findsNothing);
      expect(find.textContaining('Fehler:'), findsNothing);
      expect(find.textContaining('Mindestens eine Person'), findsNothing);
      expect(find.textContaining('Als Lieferung anlegen'), findsNothing);
      expect(find.textContaining('Lieferdetails anpassen'), findsNothing);
      expect(find.textContaining('Einkaufsstopp'), findsNothing);
    });

    testWidgets('Finding C & A: MoreScreen in English has no German residue, language is info-only, no saved package sizes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = createTestRouter(initialLocation: '/more');

      await tester.pumpWidget(buildAppWithRouter(router: router, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);

      // Verify Language tile exists and is info-only (onTap is null, no chevron)
      final languageTileFinder = find.widgetWithText(ListTile, 'Language');
      expect(languageTileFinder, findsOneWidget);
      final languageTile = tester.widget<ListTile>(languageTileFinder);
      expect(languageTile.onTap, isNull);
      expect(
        find.descendant(of: languageTileFinder, matching: find.byIcon(Icons.chevron_right)),
        findsNothing,
      );

      // Verify "Gemerkte Packungsgrößen" is NOT in settings
      expect(find.textContaining('Gemerkte Packungsgrößen'), findsNothing);
      expect(find.textContaining('Saved package sizes'), findsNothing);

      // Verify no German residue strings
      expect(find.textContaining('Einstellungen'), findsNothing);
      expect(find.textContaining('Rechtliches & Info'), findsNothing);
      expect(find.textContaining('Nachtwache-Design'), findsNothing);
      expect(find.textContaining('Meine Bezahldaten'), findsNothing);
      expect(find.textContaining('Gespeicherte Lieferanten'), findsNothing);
      expect(find.textContaining('Fehler:'), findsNothing);
      expect(find.text('MITGLIED'), findsNothing);
    });

    testWidgets('Finding A (Spanish): TripOverviewScreen renders Spanish strings without German residue', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await createSampleTrip();
      final router = createTestRouter(initialLocation: '/trips/$tripId');

      await tester.pumpWidget(buildAppWithRouter(router: router, locale: const Locale('es')));
      await tester.pumpAndSettle();

      // Spanish strings present
      expect(find.text('Lista'), findsOneWidget);
      expect(find.textContaining('parada de compras'), findsOneWidget);

      // German residue strings absent
      expect(find.textContaining('Kühl- & Wasserkapazitäten'), findsNothing);
      expect(find.textContaining('Tage im Törnverlauf'), findsNothing);
      expect(find.textContaining('Ausgleichszahlungen'), findsNothing);
      expect(find.textContaining('Fehler:'), findsNothing);
    });
  });
}

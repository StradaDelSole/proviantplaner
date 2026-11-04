import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/native.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/database/tables.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/more/ui/more_screen.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/data/supplier_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/catalog_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/assist_type.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/item_row_widget.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/ui/trip_overview_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late ShoppingListService shoppingListService;
  late KittyService kittyService;
  late DeliveryOrderService deliveryOrderService;
  late SupplierService supplierService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catalogFile = File('data/catalog_v0.11.json');
    final quantitiesFile = File('data/quantities_v0.4.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catalogFile.readAsStringSync(),
      quantitiesJson: quantitiesFile.readAsStringSync(),
    );

    tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
    );

    shoppingListService = ShoppingListService(
      listItemDao: db.listItemDao,
      tripDao: db.tripDao,
      catalogRepository: catalogRepo,
      tripService: tripService,
    );

    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );

    deliveryOrderService = DeliveryOrderService();
    supplierService = SupplierService();
  });

  tearDown(() async {
    await db.close();
  });

  Widget createTestApp({
    required GoRouter router,
    Locale locale = const Locale('de'),
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWithValue(shoppingListService),
        kittyServiceProvider.overrideWithValue(kittyService),
        deliveryOrderServiceProvider.overrideWithValue(deliveryOrderService),
        supplierServiceProvider.overrideWithValue(supplierService),
        ...overrides,
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
        ],
        locale: locale,
      ),
    );
  }

  group('QA-RAPID-01 Android UX Regression Suite', () {
    // -------------------------------------------------------------------------
    // #48 — More screen navigation trap
    // -------------------------------------------------------------------------
    testWidgets('#48: StartScreen pushes /more and MoreScreen back button pops back to StartScreen', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const StartScreen()),
          GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
        ],
      );

      await tester.pumpWidget(createTestApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MoreScreen), findsNothing);

      // Tap settings button (pushes /more)
      final settingsBtn = find.byTooltip('Einstellungen');
      expect(settingsBtn, findsOneWidget);
      await tester.tap(settingsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);

      // Tap the leading back button in MoreScreen
      final backBtn = find.byTooltip('Zurück zur Übersicht');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Successfully returns to StartScreen without restarting or losing state
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MoreScreen), findsNothing);
    });

    testWidgets('#48: MoreScreen deep-link with empty stack navigates back to root via handleBack', (tester) async {
      final router = GoRouter(
        initialLocation: '/more',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const StartScreen()),
          GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
        ],
      );

      await tester.pumpWidget(createTestApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);

      // Tap leading back button with empty stack -> should route to '/'
      final backBtn = find.byTooltip('Zurück zur Übersicht');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(MoreScreen), findsNothing);
    });

    // -------------------------------------------------------------------------
    // #53 — Days in Detail Overflow in TripOverviewScreen
    // -------------------------------------------------------------------------
    testWidgets('#53: TripOverviewScreen days in detail renders cleanly on Pixel 7 Pro (412x915)', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await tripService.createTripWithCrew(
        name: 'Pixel 7 Pro Test',
        startDate: DateTime.now(),
        daysCount: 3,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final router = GoRouter(
        initialLocation: '/trips/$tripId',
        routes: [
          GoRoute(
            path: '/trips/:id',
            builder: (_, state) => TripOverviewScreen(tripId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(TripOverviewScreen), findsOneWidget);

      // Scroll to "Tage im Detail" and expand
      final daysTileFinder = find.text('Tage im Detail');
      await tester.scrollUntilVisible(daysTileFinder, 300);
      await tester.tap(daysTileFinder);
      await tester.pumpAndSettle();

      // Both FilterChips are visible and usable without overflow
      expect(find.text('Mittags Restaurant'), findsWidgets);
      expect(find.text('Abends Restaurant'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('#53: Day tile with Wrap handles extreme narrow 320px width and 1.5x font scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('de')],
          locale: const Locale('de'),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 400),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: const Text('Tag 1 · Split'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Mittags Restaurant'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                        FilterChip(
                          label: const Text('Abends Restaurant'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mittags Restaurant'), findsOneWidget);
      expect(find.text('Abends Restaurant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // #55 — False bread refrigeration (ShoppingListItemView.isCooled)
    // -------------------------------------------------------------------------
    test('#55: isCooled correctly distinguishes genuine chill requirements from short shelf life', () {
      const dummyItem = ListItem(
        id: 1,
        tripId: 1,
        catalogId: 'test',
        isCustom: false,
        selected: true,
        share: 1.0,
        calculatedQuantity: 1.0,
        calculatedPackages: 1,
        checkState: CheckItemState.available,
        isAdopted: true,
      );

      ShoppingListItemView createItem({
        required CatalogVariant variant,
        required int shelfLifeDays,
        List<String> storageHints = const [],
      }) {
        return ShoppingListItemView(
          item: dummyItem,
          variant: variant,
          id: variant.id,
          name: variant.nameDe,
          unit: 'Packung',
          department: CatalogDepartment.backwaren,
          categoryId: 'bread',
          calculatedPackages: 1,
          overriddenPackages: null,
          calculatedQuantity: 1.0,
          customPackageSize: 1.0,
          isSelected: true,
          share: 1.0,
          isCustom: false,
          shelfLifeDays: shelfLifeDays,
          storageHints: storageHints,
          allocationsByStop: const {},
          assistType: AssistType.guided,
        );
      }

      const pack = PackInfo(size: 1.0, unit: 'Stück');

      // Baguette: shelf life 1 day, chill: none -> NOT cooled
      final baguette = createItem(
        variant: const CatalogVariant(
          id: 'baguette',
          group: 'bread',
          nameDe: 'Baguette',
          pack: pack,
          shelfLifeDays: 1,
          buyFreshUnderway: true,
          department: CatalogDepartment.backwaren,
          defaultSelected: true,
          chill: ChillRequirement.none,
        ),
        shelfLifeDays: 1,
      );
      expect(baguette.isCooled, isFalse);
      expect(baguette.isFrozen, isFalse);

      // Brötchen: shelf life 1 day, chill: none -> NOT cooled
      final rolls = createItem(
        variant: const CatalogVariant(
          id: 'rolls',
          group: 'bread',
          nameDe: 'Brötchen',
          pack: pack,
          shelfLifeDays: 1,
          buyFreshUnderway: true,
          department: CatalogDepartment.backwaren,
          defaultSelected: true,
          chill: ChillRequirement.none,
        ),
        shelfLifeDays: 1,
      );
      expect(rolls.isCooled, isFalse);

      // Weißbrot: shelf life 3 days, chill: none -> NOT cooled
      final whiteBread = createItem(
        variant: const CatalogVariant(
          id: 'white_bread',
          group: 'bread',
          nameDe: 'Weißbrot',
          pack: pack,
          shelfLifeDays: 3,
          buyFreshUnderway: false,
          department: CatalogDepartment.backwaren,
          defaultSelected: true,
          chill: ChillRequirement.none,
        ),
        shelfLifeDays: 3,
      );
      expect(whiteBread.isCooled, isFalse);

      // Fresh Milk: shelf life 7 days, chill: fridge -> COOLED
      final milk = createItem(
        variant: const CatalogVariant(
          id: 'fresh_milk',
          group: 'dairy',
          nameDe: 'Frische Milch',
          pack: pack,
          shelfLifeDays: 7,
          buyFreshUnderway: false,
          department: CatalogDepartment.molkerei,
          defaultSelected: true,
          chill: ChillRequirement.fridge,
        ),
        shelfLifeDays: 7,
      );
      expect(milk.isCooled, isTrue);
      expect(milk.isFrozen, isFalse);

      // Butter: shelf life 21 days, chill: fridge -> COOLED
      final butter = createItem(
        variant: const CatalogVariant(
          id: 'butter',
          group: 'dairy',
          nameDe: 'Butter',
          pack: pack,
          shelfLifeDays: 21,
          buyFreshUnderway: false,
          department: CatalogDepartment.molkerei,
          defaultSelected: true,
          chill: ChillRequirement.fridge,
        ),
        shelfLifeDays: 21,
      );
      expect(butter.isCooled, isTrue);

      // Fresh meat: shelf life 3 days, chill: fridge -> COOLED
      final freshMeat = createItem(
        variant: const CatalogVariant(
          id: 'fresh_meat',
          group: 'meat',
          nameDe: 'Frisches Fleisch',
          pack: pack,
          shelfLifeDays: 3,
          buyFreshUnderway: false,
          department: CatalogDepartment.fleischFisch,
          defaultSelected: true,
          chill: ChillRequirement.fridge,
        ),
        shelfLifeDays: 3,
      );
      expect(freshMeat.isCooled, isTrue);

      // Frozen fish: chill: freezer -> NOT fridge cooled, IS frozen
      final frozenFish = createItem(
        variant: const CatalogVariant(
          id: 'frozen_fish',
          group: 'frozen',
          nameDe: 'TK Fisch',
          pack: pack,
          shelfLifeDays: 90,
          buyFreshUnderway: false,
          department: CatalogDepartment.fleischFisch,
          defaultSelected: true,
          chill: ChillRequirement.freezer,
        ),
        shelfLifeDays: 90,
      );
      expect(frozenFish.isCooled, isFalse);
      expect(frozenFish.isFrozen, isTrue);

      // Custom item with cool_first storage hint -> COOLED
      final customCoolItem = createItem(
        variant: const CatalogVariant(
          id: 'custom_cool',
          group: 'other',
          nameDe: 'Kühlware',
          pack: pack,
          shelfLifeDays: 5,
          buyFreshUnderway: false,
          department: CatalogDepartment.fleischFisch,
          defaultSelected: false,
          chill: ChillRequirement.none,
        ),
        shelfLifeDays: 5,
        storageHints: ['cool_first'],
      );
      expect(customCoolItem.isCooled, isTrue);
    });

    testWidgets('#55: ShoppingListItemRow does NOT show needsCooling warning for Baguette even on 0L fridge boat', (tester) async {
      final tripId = await tripService.createTripWithCrew(
        name: 'No Fridge Boat',
        startDate: DateTime.now(),
        daysCount: 7,
        fridgeCapacityLiters: 0.0, // Boat without fridge!
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final trip = (await db.tripDao.getTripById(tripId))!;

      const pack = PackInfo(size: 1.0, unit: 'Stück');
      const dummyItem = ListItem(
        id: 1,
        tripId: 1,
        catalogId: 'bread_baguette',
        isCustom: false,
        selected: true,
        share: 1.0,
        calculatedQuantity: 2.0,
        calculatedPackages: 2,
        checkState: CheckItemState.available,
        isAdopted: true,
      );

      const baguetteView = ShoppingListItemView(
        item: dummyItem,
        variant: CatalogVariant(
          id: 'bread_baguette',
          group: 'bread',
          nameDe: 'Baguette',
          pack: pack,
          shelfLifeDays: 1,
          buyFreshUnderway: true,
          department: CatalogDepartment.backwaren,
          defaultSelected: true,
          chill: ChillRequirement.none,
        ),
        id: 'bread_baguette',
        name: 'Baguette',
        unit: 'Stück',
        department: CatalogDepartment.backwaren,
        categoryId: 'bread',
        calculatedPackages: 2,
        overriddenPackages: null,
        calculatedQuantity: 2.0,
        customPackageSize: 1.0,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 1,
        storageHints: [],
        allocationsByStop: {},
        assistType: AssistType.guided,
      );

      const milkView = ShoppingListItemView(
        item: dummyItem,
        variant: CatalogVariant(
          id: 'milk_fresh',
          group: 'dairy',
          nameDe: 'Frische Vollmilch',
          pack: pack,
          shelfLifeDays: 7,
          buyFreshUnderway: false,
          department: CatalogDepartment.molkerei,
          defaultSelected: true,
          chill: ChillRequirement.fridge,
        ),
        id: 'milk_fresh',
        name: 'Frische Vollmilch',
        unit: 'l',
        department: CatalogDepartment.molkerei,
        categoryId: 'dairy',
        calculatedPackages: 3,
        overriddenPackages: null,
        calculatedQuantity: 3.0,
        customPackageSize: 1.0,
        isSelected: true,
        share: 1.0,
        isCustom: false,
        shelfLifeDays: 7,
        storageHints: [],
        allocationsByStop: {},
        assistType: AssistType.guided,
      );

      final mockData = TripShoppingListData(
        trip: trip,
        stops: const [],
        allItems: const [baguetteView, milkView],
        categories: const [],
        departments: const [],
      );

      // Render Baguette inside ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(catalogRepo),
            tripServiceProvider.overrideWithValue(tripService),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('de')],
            locale: const Locale('de'),
            home: Scaffold(
              body: ShoppingListItemRow(
                item: baguetteView,
                data: mockData,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Baguette must NOT show "braucht Kühlung"
      expect(find.text('braucht Kühlung'), findsNothing);

      // Render Milk inside ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(catalogRepo),
            tripServiceProvider.overrideWithValue(tripService),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('de')],
            locale: const Locale('de'),
            home: Scaffold(
              body: ShoppingListItemRow(
                item: milkView,
                data: mockData,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Milk DOES show "braucht Kühlung" on a 0L fridge boat
      expect(find.text('braucht Kühlung'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // #52 — Fresh trip form identity and date defaults
    // -------------------------------------------------------------------------
    testWidgets('#52: TripWizardScreen starts empty and blocks submit until name and date are chosen', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          router: GoRouter(
            initialLocation: '/trips/new',
            routes: [
              GoRoute(path: '/trips/new', builder: (_, __) => const TripWizardScreen()),
              GoRoute(path: '/trips/:id', builder: (_, state) => Text('Trip ${state.pathParameters['id']}')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: Name is empty, placeholder is visible, Date is unselected
      expect(find.text('Törn Kroatien'), findsNothing);
      expect(find.text('z. B. Sommerurlaub, Törn Kroatien'), findsOneWidget);
      expect(find.text('Datum auswählen'), findsOneWidget);

      final submitButton = find.byKey(const Key('wizard_submit_trip_button'));
      expect(submitButton, findsOneWidget);

      // 2. Submit with empty name -> blocked with validation SnackBar
      await tester.tap(submitButton);
      await tester.pump();
      expect(find.text('Bitte gib einen Törnnamen ein.'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(submitButton)).clearSnackBars();
      await tester.pumpAndSettle();

      // 3. Enter name, but leave date unselected -> blocked with validation SnackBar
      await tester.enterText(find.byType(TextField).first, 'Dalmatien 2026');
      await tester.pumpAndSettle();

      await tester.tap(submitButton);
      await tester.pump();
      expect(find.text('Bitte wähle ein Startdatum aus.'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(submitButton)).clearSnackBars();
      await tester.pumpAndSettle();

      // 4. Select date via DatePickerDialog
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Datum auswählen'), findsNothing);

      // 5. Submit valid trip -> creates trip and navigates
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.byType(TripWizardScreen), findsNothing);
      expect(find.textContaining('Trip '), findsOneWidget);

      final allTrips = await db.tripDao.getAllTrips();
      expect(allTrips.length, equals(1));
      expect(allTrips.first.name, equals('Dalmatien 2026'));
      expect(allTrips.first.daysCount, equals(7)); // explicitly kept 7 days default
    });

    // -------------------------------------------------------------------------
    // #47 — Duplicate 'Add Supplier' controls in MoreScreen
    // -------------------------------------------------------------------------
    testWidgets('#47: MoreScreen supplier bottom sheet has exactly one Add button in empty state', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          router: GoRouter(
            initialLocation: '/more',
            routes: [
              GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Gespeicherte Lieferanten" list tile
      final supplierTile = find.widgetWithText(ListTile, 'Gespeicherte Lieferanten');
      expect(supplierTile, findsOneWidget);
      await tester.tap(supplierTile);
      await tester.pumpAndSettle();

      // Verify bottom sheet is displayed
      expect(find.text('Noch keine Lieferanten gespeichert.'), findsOneWidget);

      // Verify exactly ONE Add Supplier button exists in the sheet (bottom bar)
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify NO add button in AppBar actions
      expect(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.add)), findsNothing);
    });

    testWidgets('#47: MoreScreen supplier bottom sheet has exactly one Add button in populated state', (tester) async {
      // Save one supplier first
      await supplierService.saveSupplier(
        const SupplierProfile(
          id: 'sup_1',
          name: 'Marina Kornati Provisioning',
          marina: 'Biograd',
          phone: '+385 123 456',
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          router: GoRouter(
            initialLocation: '/more',
            routes: [
              GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Gespeicherte Lieferanten" list tile
      final supplierTile = find.widgetWithText(ListTile, 'Gespeicherte Lieferanten');
      expect(supplierTile, findsOneWidget);
      await tester.tap(supplierTile);
      await tester.pumpAndSettle();

      expect(find.text('Marina Kornati Provisioning'), findsOneWidget);

      // Verify exactly ONE Add Supplier button exists across the sheet (bottom bar)
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify NO add button in AppBar actions
      expect(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.add)), findsNothing);
    });
  });
}

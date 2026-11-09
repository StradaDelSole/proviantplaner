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
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
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
  late KittyService kittyService;
  late DeliveryOrderService deliveryOrderService;
  late ShoppingListService shoppingListService;

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
  });

  tearDown(() async {
    await db.close();
  });

  group('UX-C Crew Scroll Reproduction Tests', () {
    testWidgets('TripWizardScreen: adding crew member preserves or resets scroll position?', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(catalogRepo),
            tripServiceProvider.overrideWithValue(tripService),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('de')],
            locale: Locale('de'),
            home: TripWizardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      final addCrewBtn = find.byIcon(Icons.person_add);

      await tester.scrollUntilVisible(addCrewBtn, 100, scrollable: scrollable);
      await tester.pumpAndSettle();

      final offsetBefore = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(offsetBefore, greaterThan(100));

      // Tap add crew
      await tester.tap(addCrewBtn);
      await tester.pumpAndSettle();

      // Enter name in dialog
      await tester.enterText(find.byType(TextField).last, 'Bob');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      final offsetAfter = tester.state<ScrollableState>(scrollable).position.pixels;
      debugPrint('>>> Wizard Scroll Offset before: $offsetBefore, after: $offsetAfter');
    });

    testWidgets('TripOverviewScreen Edit Trip Sheet: adding crew member preserves or resets scroll position?', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await tripService.createTripWithCrew(
        name: 'Sommertörn',
        startDate: DateTime.now(),
        daysCount: 7,
        isCharter: true,
        boatType: 'monohull',
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
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

      await tester.pumpWidget(
        ProviderScope(
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
            supportedLocales: const [Locale('de')],
            locale: const Locale('de'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Edit Trip dialog
      final editTripBtn = find.byTooltip('Törn bearbeiten');
      await tester.tap(editTripBtn);
      await tester.pumpAndSettle();

      // Find DraggableScrollableSheet
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      final addCrewInSheet = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byIcon(Icons.person_add_outlined),
      );
      final sheetScrollable = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      ).first;

      await tester.scrollUntilVisible(addCrewInSheet, 100, scrollable: sheetScrollable);
      await tester.pumpAndSettle();

      final offsetBefore = tester.state<ScrollableState>(sheetScrollable).position.pixels;
      debugPrint('>>> Edit Sheet Scroll Offset before: $offsetBefore');
      expect(offsetBefore, greaterThan(100));

      // Tap add crew
      await tester.tap(addCrewInSheet);
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextField).last, 'Charlie');
      await tester.tap(find.text('Speichern').last);
      await tester.pumpAndSettle();

      final offsetAfter = tester.state<ScrollableState>(sheetScrollable).position.pixels;
      debugPrint('>>> Edit Sheet Scroll Offset after: $offsetAfter');
    });
  });
}

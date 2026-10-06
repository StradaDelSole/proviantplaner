/// PIVOT3-B: Acceptance-Tests für Setup Integration & Water Logic (Issue #25, #4, #5, #6).
/// Testet:
/// 1. Vier kanonische Wasserlogik-Fälle + Reserve nie 0 (Issue #5)
/// 2. Crew-Größe: Start mit 1, Minimum 1, kein Clamp auf 5, TripOverview-Schutz (Issue #4)
/// 3. Setup-Integration: Boot vor Crew, aktives Profil auswählen, neues Profil anlegen,
///    One-Off Boot, Override ohne Profilmutation, Profiledit ohne Trip-Mutation,
///    explizites Resync, Archiv-Filterung, Watermaker-Persistenz & Recalculation (Issue #6).
library;

import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:proviantplaner/features/trip/data/boat_profile_service.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/ui/trip_overview_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late BoatProfileService boatProfileService;
  late TripService tripService;
  late ShoppingListService shoppingListService;
  late KittyService kittyService;
  late DeliveryOrderService deliveryOrderService;

  CrewMemberInput testMember(String name) => CrewMemberInput(
        id: name.toLowerCase().replaceAll(' ', '_'),
        name: name,
        isAdult: true,
        isVegetarian: false,
        noAlcohol: false,
      );

  QuantityCalculationInput createWaterInput({
    required int daysCount,
    required List<CrewMemberInput> crewMembers,
    int waterTankLiters = 0,
    bool isWaterTankDrinkable = false,
    bool hasWatermaker = false,
  }) {
    return QuantityCalculationInput(
      daysCount: daysCount,
      crewMembers: crewMembers,
      fridgeCapacityLiters: 100,
      waterTankLiters: waterTankLiters.toDouble(),
      isWaterTankDrinkable: isWaterTankDrinkable,
      hasWatermaker: hasWatermaker,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      tripDays: const [],
    );
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    boatProfileService = BoatProfileService(boatProfileDao: db.boatProfileDao);

    catalogRepo = CatalogRepository();
    final catFile = File('data/catalog_v0.10.json');
    final quantFile = File('data/quantities_v0.6.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catFile.readAsStringSync(),
      quantitiesJson: quantFile.readAsStringSync(),
    );

    tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
      boatProfileDao: db.boatProfileDao,
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
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp({
    required Widget home,
    GoRouter? router,
  }) {
    final scope = ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        boatProfileServiceProvider.overrideWithValue(boatProfileService),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWithValue(shoppingListService),
        kittyServiceProvider.overrideWithValue(kittyService),
        deliveryOrderServiceProvider.overrideWithValue(deliveryOrderService),
      ],
      child: router != null
          ? MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('de')],
              locale: const Locale('de'),
            )
          : MaterialApp(
              home: home,
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
    return scope;
  }

  group('PIVOT3-B: 1. Wasserlogik & Watermaker-Formel (Quantity Engine)', () {
    test('Fall 1: Kein Tank, kein Watermaker -> voller errechneter Bedarf', () {
      final engine = QuantityEngine(catalog: catalogRepo.catalog!, quantities: catalogRepo.quantities!);
      final crew = [testMember('Alice'), testMember('Bob')];

      // 2 Personen, 7 Tage = 14 Personentage
      final input = createWaterInput(
        daysCount: 7,
        crewMembers: crew,
        waterTankLiters: 0,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
      );

      final result = engine.calculateTrip(input);
      final waterGroup = result.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterGroup.rawGroupNeed, greaterThan(0));
      final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
      expect(totalPackages, greaterThan(0));
    });

    test('Fall 2: Trinkbarer Tank, kein Watermaker -> Tank reduziert Bedarf bis Notreserve', () {
      final engine = QuantityEngine(catalog: catalogRepo.catalog!, quantities: catalogRepo.quantities!);
      final crew = [testMember('Alice'), testMember('Bob')];

      // Großer trinkbarer Tank deckt Routinebedarf ab
      final input = createWaterInput(
        daysCount: 7,
        crewMembers: crew,
        waterTankLiters: 500,
        isWaterTankDrinkable: true,
        hasWatermaker: false,
      );

      final result = engine.calculateTrip(input);
      final waterGroup = result.groupResults.firstWhere((g) => g.groupId == 'water');
      // minReserve in quantities_v0.6 für still_water ist 1.5 L/Person total = 3.0 L für 2 Personen
      expect(waterGroup.rawGroupNeed, equals(3.0));
      final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
      expect(totalPackages, greaterThan(0));
    });

    test('Fall 3: Nicht trinkbarer Tank + Watermaker -> Routinebedarf ersetzt, Notreserve bleibt', () {
      final engine = QuantityEngine(catalog: catalogRepo.catalog!, quantities: catalogRepo.quantities!);
      final crew = [testMember('Alice'), testMember('Bob')];

      final input = createWaterInput(
        daysCount: 7,
        crewMembers: crew,
        waterTankLiters: 300,
        isWaterTankDrinkable: false,
        hasWatermaker: true,
      );

      final result = engine.calculateTrip(input);
      final waterGroup = result.groupResults.firstWhere((g) => g.groupId == 'water');
      // Notreserve bleibt geschützt: 2 Personen * 1.5 L = 3.0 L
      expect(waterGroup.rawGroupNeed, equals(3.0));
      final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
      expect(totalPackages, greaterThan(0));
    });

    test('Fall 4: Trinkbarer Tank + Watermaker -> Routinebedarf ersetzt, Notreserve bleibt', () {
      final engine = QuantityEngine(catalog: catalogRepo.catalog!, quantities: catalogRepo.quantities!);
      final crew = [testMember('Alice'), testMember('Bob')];

      final input = createWaterInput(
        daysCount: 7,
        crewMembers: crew,
        waterTankLiters: 300,
        isWaterTankDrinkable: true,
        hasWatermaker: true,
      );

      final result = engine.calculateTrip(input);
      final waterGroup = result.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterGroup.rawGroupNeed, equals(3.0));
      final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
      expect(totalPackages, greaterThan(0));
    });

    test('Fall 5: Nicht trinkbarer Tank allein reduziert Trinkwasserbedarf NICHT', () {
      final engine = QuantityEngine(catalog: catalogRepo.catalog!, quantities: catalogRepo.quantities!);
      final crew = [testMember('Alice'), testMember('Bob')];

      final inputNoTank = createWaterInput(
        daysCount: 7,
        crewMembers: crew,
        waterTankLiters: 0,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
      );

      final inputNonDrinkableTank = createWaterInput(
        daysCount: 7,
        crewMembers: crew,
        waterTankLiters: 500,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
      );

      final resultNoTank = engine.calculateTrip(inputNoTank);
      final resultNonDrinkable = engine.calculateTrip(inputNonDrinkableTank);

      final waterNoTank = resultNoTank.groupResults.firstWhere((g) => g.groupId == 'water');
      final waterNonDrinkable = resultNonDrinkable.groupResults.firstWhere((g) => g.groupId == 'water');

      expect(waterNonDrinkable.rawGroupNeed, equals(waterNoTank.rawGroupNeed));
    });

    test('Reservewasser ist NIE 0 durch Watermaker allein', () {
      final engine = QuantityEngine(catalog: catalogRepo.catalog!, quantities: catalogRepo.quantities!);

      for (final crewSize in [1, 2, 4, 8]) {
        final crew = List.generate(crewSize, (i) => testMember('Member $i'));
        for (final days in [3, 7, 14]) {
          final input = createWaterInput(
            daysCount: days,
            crewMembers: crew,
            waterTankLiters: 0,
            isWaterTankDrinkable: false,
            hasWatermaker: true,
          );
          final result = engine.calculateTrip(input);
          final waterGroup = result.groupResults.firstWhere((g) => g.groupId == 'water');
          expect(waterGroup.rawGroupNeed, greaterThan(0), reason: 'Reserve darf nie 0 sein für $crewSize Crew, $days Tage');
          final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
          expect(totalPackages, greaterThan(0));
        }
      }
    });
  });

  group('PIVOT3-B: 2. Crew-Größe & Schutzuntergrenze (Issue #4)', () {
    testWidgets('Wizard startet standardmäßig mit Crewgröße 1 (Issue #4)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(home: const TripWizardScreen()));
      await tester.pumpAndSettle();

      // Sektion 3 zeigt "3. Crew (1)"
      expect(find.text('3. Crew (1)'), findsOneWidget);
      // Genau 1 Standard-Crewmitglied "Skipper"
      expect(find.text('Skipper'), findsOneWidget);
      // Nicht 5 Platzhalter!
      expect(find.text('Crew 2'), findsNothing);
      expect(find.text('Crew 5'), findsNothing);
    });

    testWidgets('Letztes verbleibendes Crewmitglied kann im Wizard nicht gelöscht werden (Minimum = 1)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(home: const TripWizardScreen()));
      await tester.pumpAndSettle();

      // Delete-Icon für das einzige Mitglied ist deaktiviert (onPressed == null)
      final deleteIcons = find.byIcon(Icons.delete_outline);
      expect(deleteIcons, findsOneWidget);
      final iconButton = tester.widget<IconButton>(find.ancestor(of: deleteIcons, matching: find.byType(IconButton)));
      expect(iconButton.onPressed, isNull);
    });

    test('Crew-Größen 1, 2, 4, 5 und 8 werden ohne Clamp auf 5 persistiert', () async {
      for (final size in [1, 2, 4, 5, 8]) {
        final crew = List.generate(size, (i) => testMember('P_${size}_$i'));
        final tripId = await tripService.createTripWithCrew(
          name: 'Trip $size',
          startDate: DateTime(2026, 6, 1),
          daysCount: 7,
          crewMembers: crew,
        );

        final persistedCrew = await db.tripDao.getCrewForTrip(tripId);
        expect(persistedCrew.length, equals(size), reason: 'Crewgröße $size muss exakt persistiert werden');
      }
    });

    testWidgets('Letztes Crewmitglied kann im TripOverview nicht gelöscht werden (Schutzuntergrenze)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tripId = await tripService.createTripWithCrew(
        name: 'Solo Trip',
        startDate: DateTime(2026, 6, 1),
        daysCount: 7,
        crewMembers: [testMember('Solo Skipper')],
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

      await tester.pumpWidget(buildTestApp(home: const SizedBox(), router: router));
      await tester.pumpAndSettle();

      // Open Edit Dialog
      final editIcon = find.byTooltip('Törn bearbeiten');
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Scroll to Solo Skipper in Edit BottomSheet
      final soloSkipper = find.text('Solo Skipper');
      await tester.scrollUntilVisible(soloSkipper, 100, scrollable: find.byType(Scrollable).last);
      expect(soloSkipper, findsOneWidget);

      // Attempt to delete the only member
      final deleteMemberIcon = find.byIcon(Icons.delete_outline);
      expect(deleteMemberIcon, findsOneWidget);
      await tester.tap(deleteMemberIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // SnackBar with warning is displayed
      expect(find.text('Mindestens eine Person muss an Bord bleiben.'), findsOneWidget);

      // Member still exists in DB
      final crew = await db.tripDao.getCrewForTrip(tripId);
      expect(crew.length, equals(1));
    });
  });

  group('PIVOT3-B: 3. Setup Integration & Bootsprofil-Lifecycle (Issue #6)', () {
    testWidgets('Real UI Journey: Vorhandenes Profil im Wizard auswählen -> Trip hat boatProfileId & Snapshot', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Profil anlegen
      final profileId = await boatProfileService.createProfile(
        name: 'SY Windrose',
        manufacturer: 'Dufour',
        model: '460 Grand Large',
        fridgeCapacity: 160,
        hasFreezer: true,
        freezerCapacity: 40,
        waterTankLiters: 530,
        isWaterTankDrinkable: true,
        hasWatermaker: true,
      );

      final router = GoRouter(
        initialLocation: '/trips/new',
        routes: [
          GoRoute(path: '/trips/new', builder: (_, __) => const TripWizardScreen()),
          GoRoute(path: '/trips/:id', builder: (_, state) => TripOverviewScreen(tripId: int.parse(state.pathParameters['id']!))),
        ],
      );

      await tester.pumpWidget(buildTestApp(home: const SizedBox(), router: router));
      await tester.pumpAndSettle();

      // Profil im Dropdown auswählen
      final dropdown = find.byType(DropdownButtonFormField<int?>);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final profileOption = find.text('SY Windrose (460 Grand Large)').last;
      await tester.tap(profileOption);
      await tester.pumpAndSettle();

      // Trip erstellen
      final createButton = find.byKey(const Key('wizard_submit_trip_button'));
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Trip in DB prüfen
      final allTrips = await db.tripDao.getAllTrips();
      expect(allTrips.length, equals(1));
      final trip = allTrips.first;
      expect(trip.boatProfileId, equals(profileId));
      expect(trip.boatName, equals('SY Windrose'));
      expect(trip.boatManufacturer, equals('Dufour'));
      expect(trip.boatModel, equals('460 Grand Large'));
      expect(trip.fridgeCapacity, equals(160));
      expect(trip.hasFreezer, isTrue);
      expect(trip.freezerCapacity, equals(40));
      expect(trip.waterTankLiters, equals(530));
      expect(trip.isWaterTankDrinkable, isTrue);
      expect(trip.hasWatermaker, isTrue);
    });

    testWidgets('Real UI Journey: Neues Profil direkt aus Wizard-Dialog anlegen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/trips/new',
        routes: [
          GoRoute(path: '/trips/new', builder: (_, __) => const TripWizardScreen()),
          GoRoute(path: '/trips/:id', builder: (_, state) => TripOverviewScreen(tripId: int.parse(state.pathParameters['id']!))),
        ],
      );

      await tester.pumpWidget(buildTestApp(home: const SizedBox(), router: router));
      await tester.pumpAndSettle();

      // Tap "Neues Bootsprofil anlegen"
      final newProfileButton = find.text('Neues Bootsprofil anlegen');
      expect(newProfileButton, findsOneWidget);
      await tester.tap(newProfileButton);
      await tester.pumpAndSettle();

      // Im Dialog Felder ausfüllen
      final nameField = find.widgetWithText(TextFormField, 'Bootsname *');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Bavaria Cruiser 37');

      final watermakerSwitch = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(SwitchListTile, 'Watermaker an Bord vorhanden'),
      );
      expect(watermakerSwitch, findsOneWidget);
      await tester.tap(watermakerSwitch);
      await tester.pumpAndSettle();

      // Speichern im Dialog
      final saveDialogButton = find.widgetWithText(FilledButton, 'Speichern');
      await tester.tap(saveDialogButton);
      await tester.pumpAndSettle();

      // Prüfen: Profil in DB angelegt
      final profiles = await boatProfileService.getActiveProfiles();
      expect(profiles.length, equals(1));
      expect(profiles.first.name, equals('Bavaria Cruiser 37'));
      expect(profiles.first.hasWatermaker, isTrue);

      // Trip erstellen
      final createButton = find.byKey(const Key('wizard_submit_trip_button'));
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      final allTrips = await db.tripDao.getAllTrips();
      expect(allTrips.length, equals(1));
      expect(allTrips.first.boatProfileId, equals(profiles.first.id));
      expect(allTrips.first.hasWatermaker, isTrue);
    });

    test('One-off Bootswerte ohne gespeichertes Profil persistieren Snapshot ohne boatProfileId', () async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Charter One-Off',
        startDate: DateTime(2026, 7, 1),
        daysCount: 7,
        crewMembers: [testMember('Skipper')],
        boatName: 'Charter Bavaria',
        boatManufacturer: 'Bavaria',
        boatModel: 'Cruiser 46',
        fridgeCapacityLiters: 110,
        hasFreezer: true,
        freezerCapacityLiters: 25,
        waterTankLiters: 360,
        isWaterTankDrinkable: true,
        hasWatermaker: true,
        boatProfileId: null,
      );

      final trip = await db.tripDao.getTripById(tripId);
      expect(trip, isNotNull);
      expect(trip!.boatProfileId, isNull);
      expect(trip.boatName, equals('Charter Bavaria'));
      expect(trip.boatManufacturer, equals('Bavaria'));
      expect(trip.boatModel, equals('Cruiser 46'));
      expect(trip.fridgeCapacity, equals(110));
      expect(trip.hasFreezer, isTrue);
      expect(trip.freezerCapacity, equals(25));
      expect(trip.waterTankLiters, equals(360));
      expect(trip.isWaterTankDrinkable, isTrue);
      expect(trip.hasWatermaker, isTrue);
    });

    test('Trip-Override mutiert gespeichertes Bootsprofil NICHT', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Original Boat',
        manufacturer: 'Jeanneau',
        model: 'Sun Fast 3300',
        fridgeCapacity: 60,
        waterTankLiters: 100,
        hasWatermaker: false,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Overridden Trip',
        startDate: DateTime(2026, 8, 1),
        daysCount: 7,
        crewMembers: [testMember('Skipper')],
        boatProfileId: profileId,
        fridgeCapacityLiters: 80, // Override
        hasWatermaker: true, // Override
      );

      // Trip hat die Override-Werte
      final trip = await db.tripDao.getTripById(tripId);
      expect(trip!.fridgeCapacity, equals(80));
      expect(trip.hasWatermaker, isTrue);

      // Profil in der Datenbank ist unverändert!
      final profile = await boatProfileService.getProfileById(profileId);
      expect(profile!.fridgeCapacity, equals(60));
      expect(profile.hasWatermaker, isFalse);
    });

    test('Profil-Änderung ändert bestehenden Trip-Snapshot NICHT', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Stable Boat',
        manufacturer: 'Beneteau',
        model: 'Oceanis 38',
        fridgeCapacity: 130,
        waterTankLiters: 330,
        hasWatermaker: false,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Past Trip',
        startDate: DateTime(2026, 5, 1),
        daysCount: 7,
        crewMembers: [testMember('Skipper')],
        boatProfileId: profileId,
      );

      // Profil nachträglich ändern
      final profile = await boatProfileService.getProfileById(profileId);
      await boatProfileService.updateProfile(profile!.copyWith(
        fridgeCapacity: 200,
        hasWatermaker: true,
      ));

      // Trip-Snapshot ist unverändert!
      final trip = await db.tripDao.getTripById(tripId);
      expect(trip!.fridgeCapacity, equals(130));
      expect(trip.hasWatermaker, isFalse);
    });

    test('Explizites Resync aktualisiert den Trip-Snapshot aus dem Bootsprofil', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Resync Boat',
        manufacturer: 'Hanse',
        model: '418',
        fridgeCapacity: 100,
        waterTankLiters: 300,
        hasWatermaker: false,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Resync Trip',
        startDate: DateTime(2026, 9, 1),
        daysCount: 7,
        crewMembers: [testMember('Skipper')],
        boatProfileId: profileId,
      );

      // Profil im Hafen modernisiert (Watermaker eingebaut, neuer Kühlschrank)
      final profile = await boatProfileService.getProfileById(profileId);
      await boatProfileService.updateProfile(profile!.copyWith(
        fridgeCapacity: 140,
        hasWatermaker: true,
      ));

      // Expliziter Resync-Aufruf
      final success = await tripService.resyncTripBoatProfile(tripId);
      expect(success, isTrue);

      // Trip-Snapshot hat nun die aktualisierten Werte
      final resyncedTrip = await db.tripDao.getTripById(tripId);
      expect(resyncedTrip!.fridgeCapacity, equals(140));
      expect(resyncedTrip.hasWatermaker, isTrue);
    });

    testWidgets('Archivierte Bootsprofile werden im Wizard-Selector nicht angeboten', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1 aktives Profil, 1 archiviertes Profil
      await boatProfileService.createProfile(
        name: 'Aktives Boot',
        manufacturer: 'Bavaria',
        fridgeCapacity: 100,
        waterTankLiters: 200,
      );

      final archivedId = await boatProfileService.createProfile(
        name: 'Altes Archiv-Boot',
        manufacturer: 'Bavaria',
        fridgeCapacity: 80,
        waterTankLiters: 150,
      );
      await boatProfileService.archiveProfile(archivedId);

      await tester.pumpWidget(buildTestApp(home: const TripWizardScreen()));
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButtonFormField<int?>);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      expect(find.text('Aktives Boot').last, findsOneWidget);
      expect(find.text('Altes Archiv-Boot'), findsNothing);
    });

    test('Watermaker-Toggle auf Trip persistiert hasWatermaker und berechnet Mengen neu', () async {
      // Törn mit trinkbarem 400L Tank, OHNE Watermaker
      final tripId = await tripService.createTripWithCrew(
        name: 'Water Test Trip',
        startDate: DateTime(2026, 7, 1),
        daysCount: 7,
        crewMembers: [testMember('Alice'), testMember('Bob')],
        waterTankLiters: 400,
        isWaterTankDrinkable: true,
        hasWatermaker: false,
      );

      // Törn-Details aktualisieren: Watermaker AN
      await tripService.updateTripDetails(
        tripId: tripId,
        hasWatermaker: true,
      );

      final trip = await db.tripDao.getTripById(tripId);
      expect(trip!.hasWatermaker, isTrue);

      // Prüfen, dass Shopping-List Items für Wasser vorhanden sind und Notreserve widerspiegeln
      final items = await db.listItemDao.getListItemsForTrip(tripId);
      final waterItems = items.where((i) => i.catalogId == 'water_5l' || i.catalogId == 'water_15' || i.catalogId == 'sparkling');
      expect(waterItems, isNotEmpty);
      final totalPackages = waterItems.fold<int>(0, (sum, i) => sum + i.calculatedPackages);
      expect(totalPackages, greaterThan(0));
    });
  });
}

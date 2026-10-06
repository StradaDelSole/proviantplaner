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
import 'package:drift/drift.dart' show Value;
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
      // Warmes Klima, 2 Erwachsene, 7 Tage: 2.5 L * 2 Personen * 7 Tage = 35.0 L
      expect(waterGroup.rawGroupNeed, closeTo(35.0, 1e-6));
      final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
      // 35.0 L split 50/50: 17.5 L (5L -> 4 Pack = 20.0 L) + 17.5 L (1.5L -> 10 Pack = 15.0 L mit Gruppenausgleich) = 14 Packungen
      expect(totalPackages, equals(14));
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
      expect(waterGroup.rawGroupNeed, closeTo(3.0, 1e-6));
      final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
      // 3.0 L wird durch Gruppenausgleich mit 1x 5L (5.0 L >= 3.0 L) vollständig abgedeckt -> 1 Packung
      expect(totalPackages, equals(1));
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
      expect(waterGroup.rawGroupNeed, closeTo(3.0, 1e-6));
      final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
      expect(totalPackages, equals(1));
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
      expect(waterGroup.rawGroupNeed, closeTo(3.0, 1e-6));
      final totalPackages = waterGroup.variantResults.fold<int>(0, (sum, v) => sum + v.calculatedPackages);
      expect(totalPackages, equals(1));
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

      expect(waterNoTank.rawGroupNeed, closeTo(35.0, 1e-6));
      expect(waterNonDrinkable.rawGroupNeed, closeTo(35.0, 1e-6));
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
          final expectedReserve = 1.5 * crewSize;
          expect(waterGroup.rawGroupNeed, closeTo(expectedReserve, 1e-6),
              reason: 'Reserve muss 1.5 L * $crewSize = $expectedReserve L sein für $crewSize Crew, $days Tage');
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

    test('Deterministische Crew-Recalculation: Vergrößern und Verkleinern der Crew verändert persistierte Mengen auf feste Erwartungswerte', () async {
      // 1. Ausgangszustand: Trip mit 1 Person ('Alice'), 7 Tage, warmes Klima, kein Tank, kein Watermaker
      final tripId = await tripService.createTripWithCrew(
        name: 'Crew Recalc Trip',
        startDate: DateTime(2026, 7, 1),
        daysCount: 7,
        crewMembers: [testMember('Alice')],
        waterTankLiters: 0,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
      );

      // Erwartungswert bei 1 Person:
      // Wasserbedarf: 2.5 L * 1 Person * 7 Tage = 17.5 L
      // Bei 50/50 Split auf water_5l (Pack 5L) und water_15 (Pack 1.5L):
      // water_5l: 8.75 L -> ceil(8.75 / 5.0) = 2 Packungen
      // water_15: 8.75 L -> ceil(8.75 / 1.5) = 6 Packungen
      var items = await db.listItemDao.getListItemsForTrip(tripId);
      var item5l = items.firstWhere((i) => i.catalogId == 'water_5l');
      var item15 = items.firstWhere((i) => i.catalogId == 'water_15');
      expect(item5l.calculatedQuantity, closeTo(8.75, 1e-6));
      expect(item5l.calculatedPackages, equals(2));
      expect(item15.calculatedQuantity, closeTo(8.75, 1e-6));
      // Mit Gruppenausgleich: 2x 5L (10.0L) + 5x 1.5L (7.5L) = exakt 17.5L Bedarf gedeckt
      expect(item15.calculatedPackages, equals(5));

      // 2. Crew vergrößern: 3 Mitglieder über den echten Produktionspfad hinzufügen (Alice + Bob, Charlie, Dana -> 4 Personen)
      await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Bob',
      ));
      await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Charlie',
      ));
      final danaId = await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Dana',
      ));

      // Reale Recalculation über TripService
      await tripService.recalculateTrip(tripId);

      // Erwartungswert bei 4 Personen:
      // Wasserbedarf: 2.5 L * 4 Personen * 7 Tage = 70.0 L
      // water_5l (50%): 35.0 L -> ceil(35.0 / 5.0) = 7 Packungen
      // water_15 (50%): 35.0 L -> ceil(35.0 / 1.5) = 24 Packungen
      items = await db.listItemDao.getListItemsForTrip(tripId);
      item5l = items.firstWhere((i) => i.catalogId == 'water_5l');
      item15 = items.firstWhere((i) => i.catalogId == 'water_15');
      expect(item5l.calculatedQuantity, closeTo(35.0, 1e-6));
      expect(item5l.calculatedPackages, equals(7));
      expect(item15.calculatedQuantity, closeTo(35.0, 1e-6));
      expect(item15.calculatedPackages, equals(24));

      // 3. Crew wieder verkleinern: Dana löschen (-> 3 Personen)
      await db.tripDao.deleteCrewMember(danaId);
      await tripService.recalculateTrip(tripId);

      // Erwartungswert bei 3 Personen:
      // Wasserbedarf: 2.5 L * 3 Personen * 7 Tage = 52.5 L
      // water_5l (50%): 26.25 L -> ceil(26.25 / 5.0) = 6 Packungen
      // water_15 (50%): 26.25 L -> mit Gruppenausgleich (6x 5L = 30L + 15x 1.5L = 22.5L -> 52.5L exakt) = 15 Packungen
      items = await db.listItemDao.getListItemsForTrip(tripId);
      item5l = items.firstWhere((i) => i.catalogId == 'water_5l');
      item15 = items.firstWhere((i) => i.catalogId == 'water_15');
      expect(item5l.calculatedQuantity, closeTo(26.25, 1e-6));
      expect(item5l.calculatedPackages, equals(6));
      expect(item15.calculatedQuantity, closeTo(26.25, 1e-6));
      expect(item15.calculatedPackages, equals(15));
    });

    test('PIVOT1-Stabilität: Manuelle User-Overrides und isAdopted-Status überleben Crew-Recalculation stabil', () async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Stability Trip',
        startDate: DateTime(2026, 7, 1),
        daysCount: 7,
        crewMembers: [testMember('Alice'), testMember('Bob')],
        waterTankLiters: 0,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
      );

      // Vorräte laden
      var items = await db.listItemDao.getListItemsForTrip(tripId);
      final waterItem = items.firstWhere((i) => i.catalogId == 'water_5l');
      final pestoItem = items.firstWhere((i) => i.catalogId == 'pesto');

      // Nutzer-Zustände setzen (PIVOT1):
      // 1. water_5l manuell auf 10 Packungen überschreiben
      await db.listItemDao.updateListItem(waterItem.copyWith(
        overriddenPackages: const Value(10),
      ));
      // 2. pesto auf isAdopted = true und 3 Packungen setzen
      await db.listItemDao.updateListItem(pestoItem.copyWith(
        isAdopted: true,
        overriddenPackages: const Value(3),
      ));

      // Crew vergrößern von 2 auf 5 Personen über echten Produktionspfad
      for (final name in ['Charlie', 'Dana', 'Eve']) {
        await db.tripDao.addCrewMember(CrewMembersCompanion.insert(
          tripId: tripId,
          name: name,
        ));
      }

      // Recalculation über echten Produktionspfad
      await tripService.recalculateTrip(tripId);

      // Verifizieren:
      items = await db.listItemDao.getListItemsForTrip(tripId);
      final updatedWater = items.firstWhere((i) => i.catalogId == 'water_5l');
      final updatedPesto = items.firstWhere((i) => i.catalogId == 'pesto');

      // water_5l: calculatedQuantity stieg (5 Personen * 2.5 L * 7 * 0.5 = 43.75 L)
      expect(updatedWater.calculatedQuantity, closeTo(43.75, 1e-6));
      // ABER overriddenPackages bleibt strikt 10!
      expect(updatedWater.overriddenPackages, equals(10));

      // pesto: isAdopted bleibt strikt true und overriddenPackages bleibt 3!
      expect(updatedPesto.isAdopted, isTrue);
      expect(updatedPesto.overriddenPackages, equals(3));

      // Crew wieder reduzieren auf 1 Person
      final allCrew = await db.tripDao.getCrewForTrip(tripId);
      for (final m in allCrew.skip(1)) {
        await db.tripDao.deleteCrewMember(m.id);
      }
      await tripService.recalculateTrip(tripId);

      items = await db.listItemDao.getListItemsForTrip(tripId);
      final finalWater = items.firstWhere((i) => i.catalogId == 'water_5l');
      final finalPesto = items.firstWhere((i) => i.catalogId == 'pesto');

      // calculatedQuantity sank wieder auf 8.75 L
      expect(finalWater.calculatedQuantity, closeTo(8.75, 1e-6));
      // overriddenPackages bleibt weiterhin strikt 10!
      expect(finalWater.overriddenPackages, equals(10));
      // pesto bleibt weiterhin isAdopted mit 3 Packungen!
      expect(finalPesto.isAdopted, isTrue);
      expect(finalPesto.overriddenPackages, equals(3));
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

    testWidgets('Real UI Journey: Trip-Snapshot Hersteller und Modell leeren leert Snapshot in Drift und mutiert BoatProfile NICHT', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. BoatProfile anlegen
      final profileId = await boatProfileService.createProfile(
        name: 'Oceanis 40.1',
        manufacturer: 'Beneteau',
        model: '40.1',
        fridgeCapacity: 120,
        waterTankLiters: 350,
      );

      // 2. Trip mit verknüpftem Profil anlegen
      final tripId = await tripService.createTripWithCrew(
        name: 'Sommertörn',
        startDate: DateTime(2026, 7, 1),
        daysCount: 7,
        crewMembers: [testMember('Skipper')],
        boatProfileId: profileId,
      );

      // Vorab prüfen: Snapshot enthält Hersteller & Modell
      final initialTrip = await db.tripDao.getTripById(tripId);
      expect(initialTrip!.boatManufacturer, equals('Beneteau'));
      expect(initialTrip.boatModel, equals('40.1'));

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

      // 3. TripOverview öffnen -> Törn bearbeiten öffnen
      final editIcon = find.byTooltip('Törn bearbeiten');
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // 4. Hersteller und Modell über die tatsächlichen Textfelder leeren
      final manufacturerField = find.widgetWithText(TextField, 'Beneteau');
      await tester.ensureVisible(manufacturerField);
      await tester.pumpAndSettle();
      expect(manufacturerField, findsOneWidget);
      await tester.enterText(manufacturerField, '');

      final modelField = find.widgetWithText(TextField, '40.1');
      await tester.ensureVisible(modelField);
      await tester.pumpAndSettle();
      expect(modelField, findsOneWidget);
      await tester.enterText(modelField, '');

      // 5. Speichern
      final saveBtn = find.widgetWithText(FilledButton, 'Speichern');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // 6. Trip aus Drift neu laden und beweisen, dass die Trip-Snapshot-Felder geleert wurden
      final updatedTrip = await db.tripDao.getTripById(tripId);
      expect(updatedTrip!.boatManufacturer, isNull);
      expect(updatedTrip.boatModel, isNull);
      // Profilverknüpfung bleibt intakt
      expect(updatedTrip.boatProfileId, equals(profileId));

      // 7. BoatProfile aus Drift laden und beweisen, dass dessen Hersteller/Modell unverändert geblieben sind
      final sourceProfile = await boatProfileService.getProfileById(profileId);
      expect(sourceProfile!.manufacturer, equals('Beneteau'));
      expect(sourceProfile.model, equals('40.1'));
    });

    testWidgets('Real UI Journey: Watermaker-Switch im Törn-Edit betätigen -> hasWatermaker true & Trinkwasser entspricht Notreserve', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Trip mit 2 Personen, 7 Tage, warmes Klima, OHNE Tank, OHNE Watermaker
      final tripId = await tripService.createTripWithCrew(
        name: 'Watermaker UI Trip',
        startDate: DateTime(2026, 7, 1),
        daysCount: 7,
        crewMembers: [testMember('Alice'), testMember('Bob')],
        waterTankLiters: 0,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
      );

      // Vorab: 35.0 L Trinkwasser (16 Packungen)
      var items = await db.listItemDao.getListItemsForTrip(tripId);
      var waterItems = items.where((i) => i.catalogId == 'water_5l' || i.catalogId == 'water_15' || i.catalogId == 'sparkling');
      var totalQuantity = waterItems.fold<double>(0.0, (sum, i) => sum + i.calculatedQuantity);
      expect(totalQuantity, closeTo(35.0, 1e-6));

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

      // TripOverview öffnen -> Törn bearbeiten öffnen
      final editIcon = find.byTooltip('Törn bearbeiten');
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Watermaker-Switch über die tatsächliche UI betätigen
      final watermakerSwitch = find.widgetWithText(SwitchListTile, 'Watermaker an Bord vorhanden', skipOffstage: false);
      await tester.scrollUntilVisible(watermakerSwitch, 50, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      expect(watermakerSwitch, findsOneWidget);
      await tester.tap(watermakerSwitch);
      await tester.pumpAndSettle();

      // Speichern
      final saveBtn = find.widgetWithText(FilledButton, 'Speichern', skipOffstage: false);
      await tester.scrollUntilVisible(saveBtn, 50, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Trip aus Drift neu laden
      final reloadedTrip = await db.tripDao.getTripById(tripId);
      expect(reloadedTrip!.hasWatermaker, isTrue);

      // Beweisen: neu berechnete Trinkwassermenge entspricht Notreserve (1.5 L * 2 Personen = 3.0 L)
      items = await db.listItemDao.getListItemsForTrip(tripId);
      waterItems = items.where((i) => i.catalogId == 'water_5l' || i.catalogId == 'water_15' || i.catalogId == 'sparkling');
      totalQuantity = waterItems.fold<double>(0.0, (sum, i) => sum + i.calculatedQuantity);
      expect(totalQuantity, closeTo(3.0, 1e-6));
      final totalPackages = waterItems.fold<int>(0, (sum, i) => sum + i.calculatedPackages);
      // 3.0 L Notreserve wird durch Gruppenausgleich mit 1x 5L gedeckt
      expect(totalPackages, equals(1));
    });

    testWidgets('Real UI Journey: Aus Bootsprofil aktualisieren über Button & Bestätigungsdialog synchronisiert Snapshot', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. BoatProfile anlegen
      final profileId = await boatProfileService.createProfile(
        name: 'Hanse 418',
        manufacturer: 'Hanse',
        model: '418',
        fridgeCapacity: 100,
        waterTankLiters: 300,
        hasWatermaker: false,
      );

      // 2. Verknüpften Trip anlegen
      final tripId = await tripService.createTripWithCrew(
        name: 'Hanse Trip',
        startDate: DateTime(2026, 9, 1),
        daysCount: 7,
        crewMembers: [testMember('Skipper')],
        boatProfileId: profileId,
      );

      // 3. BoatProfile nachträglich ändern (Kühlschrank und Watermaker)
      final profile = await boatProfileService.getProfileById(profileId);
      await boatProfileService.updateProfile(profile!.copyWith(
        fridgeCapacity: 160,
        hasWatermaker: true,
      ));

      // 4. Zuerst beweisen, dass der Trip-Snapshot dadurch NICHT automatisch geändert wurde
      final tripBefore = await db.tripDao.getTripById(tripId);
      expect(tripBefore!.fridgeCapacity, equals(100));
      expect(tripBefore.hasWatermaker, isFalse);

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

      // 5. TripOverview öffnen -> Törn bearbeiten öffnen
      final editIcon = find.byTooltip('Törn bearbeiten');
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // 6. Die tatsächliche sichtbare Aktion 'Aus Bootsprofil aktualisieren' antippen
      final resyncBtn = find.text('Aus Bootsprofil aktualisieren');
      await tester.scrollUntilVisible(resyncBtn, 50, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      expect(resyncBtn, findsOneWidget);
      await tester.tap(resyncBtn);
      await tester.pumpAndSettle();

      // 7. Bestätigungsdialog über die UI bestätigen
      expect(find.text('Möchtest du die Bootsdaten des Törns wirklich aus dem Bootsprofil aktualisieren? Manuelle Änderungen am Törn werden überschrieben.'), findsOneWidget);
      final confirmBtn = find.descendant(of: find.byType(AlertDialog), matching: find.text('Speichern'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // 8. Trip aus Drift neu laden und beweisen, dass der Snapshot jetzt die neuen Profilwerte enthält
      final resyncedTrip = await db.tripDao.getTripById(tripId);
      expect(resyncedTrip!.fridgeCapacity, equals(160));
      expect(resyncedTrip.hasWatermaker, isTrue);
    });
  });
}

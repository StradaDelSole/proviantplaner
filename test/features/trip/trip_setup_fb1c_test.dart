import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/ui/trip_timeline_screen.dart';
import 'package:proviantplaner/features/trip/ui/widgets/day_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catFile = File('data/catalog_v0.9.json');
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
  });

  tearDown(() async {
    await db.close();
  });

  group('FB1-C Abnahmetests: Grenzwerte Törn-Setup', () {
    test('Törnlänge 1 Tag und 180 Tage werden fehlerfrei angelegt', () async {
      // 1. Randfall: Minimaldauer 1 Tag
      final tripId1 = await tripService.createTripWithCrew(
        name: 'Törn 1 Tag',
        startDate: DateTime.now(),
        daysCount: 1,
        isCharter: true,
        boatType: 'monohull',
        climate: 'warm',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final trip1 = await db.tripDao.getTripById(tripId1);
      final days1 = await db.tripDao.getDaysForTrip(tripId1);
      expect(trip1?.daysCount, 1);
      expect(days1.length, 1);

      // 2. Randfall: Maximaldauer 180 Tage
      final tripId180 = await tripService.createTripWithCrew(
        name: 'Törn 180 Tage',
        startDate: DateTime.now(),
        daysCount: 180,
        isCharter: false,
        boatType: 'catamaran',
        climate: 'cool',
        fridgeCapacityLiters: 150,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final trip180 = await db.tripDao.getTripById(tripId180);
      final days180 = await db.tripDao.getDaysForTrip(tripId180);
      expect(trip180?.daysCount, 180);
      expect(days180.length, 180);
    });

    test('Kühlkapazität 0 l (kein Kühlschrank) wird korrekt gespeichert', () async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Törn ohne Kühlschrank',
        startDate: DateTime.now(),
        daysCount: 7,
        isCharter: true,
        boatType: 'monohull',
        climate: 'warm',
        fridgeCapacityLiters: 0.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final trip = await db.tripDao.getTripById(tripId);
      expect(trip?.fridgeCapacity, 0);
    });
  });

  group('FB1-C Abnahmetests: Wassermengen je Klimastufe & Altdaten-Migration', () {
    test('Wassermengen entsprechen exakt den Klimastufen (cool=2.0l, warm=2.5l, hot=3.5l)', () {
      final engine = QuantityEngine(
        catalog: catalogRepo.catalog!,
        quantities: catalogRepo.quantities!,
      );

      const crew = [
        CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        CrewMemberInput(id: '2', name: 'Gast', isAdult: true, isVegetarian: false, noAlcohol: false),
      ];

      final days = List.generate(3, (i) => TripDayInput(dayNumber: i + 1, isLunchRestaurant: false, isEveningRestaurant: false));

      // 1. Klimastufe cool: 2.0 l / Person / Tag
      // 2 Erwachsene, 3 Tage: 2 * 3 * 2.0 = 12.0 l
      final inputCool = QuantityCalculationInput(
        daysCount: 3,
        tripDays: days,
        crewMembers: crew,
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        climate: 'cool',
      );
      final resultCool = engine.calculateTrip(inputCool);
      final waterCool = resultCool.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterCool.rawGroupNeed, closeTo(12.0, 1e-9));

      // 2. Klimastufe warm: 2.5 l / Person / Tag
      // 2 Erwachsene, 3 Tage: 2 * 3 * 2.5 = 15.0 l
      final inputWarm = QuantityCalculationInput(
        daysCount: 3,
        tripDays: days,
        crewMembers: crew,
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        climate: 'warm',
      );
      final resultWarm = engine.calculateTrip(inputWarm);
      final waterWarm = resultWarm.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterWarm.rawGroupNeed, closeTo(15.0, 1e-9));

      // 3. Klimastufe hot: 3.5 l / Person / Tag
      // 2 Erwachsene, 3 Tage: 2 * 3 * 3.5 = 21.0 l
      final inputHot = QuantityCalculationInput(
        daysCount: 3,
        tripDays: days,
        crewMembers: crew,
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        climate: 'hot',
      );
      final resultHot = engine.calculateTrip(inputHot);
      final waterHot = resultHot.groupResults.firstWhere((g) => g.groupId == 'water');
      expect(waterHot.rawGroupNeed, closeTo(21.0, 1e-9));
    });

    test('Alte Revierwerte (temperate, mediterranean_summer, hot_or_remote) berechnen korrekt', () {
      final engine = QuantityEngine(
        catalog: catalogRepo.catalog!,
        quantities: catalogRepo.quantities!,
      );

      const crew = [
        CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
      ];
      final days = [const TripDayInput(dayNumber: 1, isLunchRestaurant: false, isEveningRestaurant: false)];

      // Altes Revier temperate -> cool (2.0 l)
      final inputLegacyCool = QuantityCalculationInput(
        daysCount: 1,
        tripDays: days,
        crewMembers: crew,
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        region: 'temperate',
      );
      final resultLegacyCool = engine.calculateTrip(inputLegacyCool);
      expect(resultLegacyCool.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(2.0, 1e-9));

      // Altes Revier mediterranean_summer -> warm (2.5 l)
      final inputLegacyWarm = QuantityCalculationInput(
        daysCount: 1,
        tripDays: days,
        crewMembers: crew,
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        region: 'mediterranean_summer',
      );
      final resultLegacyWarm = engine.calculateTrip(inputLegacyWarm);
      expect(resultLegacyWarm.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(2.5, 1e-9));

      // Altes Revier hot_or_remote -> hot (3.5 l)
      final inputLegacyHot = QuantityCalculationInput(
        daysCount: 1,
        tripDays: days,
        crewMembers: crew,
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        region: 'hot_or_remote',
      );
      final resultLegacyHot = engine.calculateTrip(inputLegacyHot);
      expect(resultLegacyHot.groupResults.firstWhere((g) => g.groupId == 'water').rawGroupNeed, closeTo(3.5, 1e-9));
    });

    test('Einlagerungs-Checkliste ist bei hot standardmäßig aktiv, bei cool/warm nicht', () async {
      final tripIdHot = await tripService.createTripWithCrew(
        name: 'Heißer Törn',
        startDate: DateTime.now(),
        daysCount: 7,
        isCharter: true,
        boatType: 'monohull',
        climate: 'hot',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );
      final tripHot = await db.tripDao.getTripById(tripIdHot);
      expect(tripHot?.hasStorageChecklist, isTrue);

      final tripIdCool = await tripService.createTripWithCrew(
        name: 'Kühler Törn',
        startDate: DateTime.now(),
        daysCount: 7,
        isCharter: true,
        boatType: 'monohull',
        climate: 'cool',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );
      final tripCool = await db.tripDao.getTripById(tripIdCool);
      expect(tripCool?.hasStorageChecklist, isFalse);
    });
  });

  group('FB1-C Abnahmetests: Tagesleiste Wochengruppierung ab 28 Tagen', () {
    testWidgets('Tagesleiste zeigt flache Liste bei weniger als 28 Tagen (z.B. 14 Tage)', (tester) async {
      final tripId = await tripService.createTripWithCrew(
        name: '14-Tage-Törn',
        startDate: DateTime.now(),
        daysCount: 14,
        isCharter: true,
        boatType: 'monohull',
        climate: 'warm',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(catalogRepo),
          tripServiceProvider.overrideWithValue(tripService),
          activeTripIdProvider.overrideWith((ref) => tripId),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TripTimelineScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bei 14 Tagen: keine Wochen-ExpansionTiles vorhanden, sondern 14 DayCards
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(DayCard), findsNWidgets(14));
    });

    testWidgets('Tagesleiste gruppiert ab 28 Tagen nach Wochen (z.B. 28 Tage = 4 Wochen)', (tester) async {
      final tripId = await tripService.createTripWithCrew(
        name: '28-Tage-Törn',
        startDate: DateTime.now(),
        daysCount: 28,
        isCharter: true,
        boatType: 'monohull',
        climate: 'warm',
        fridgeCapacityLiters: 100,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(catalogRepo),
          tripServiceProvider.overrideWithValue(tripService),
          activeTripIdProvider.overrideWith((ref) => tripId),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TripTimelineScreen(tripId: tripId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bei 28 Tagen: genau 4 Wochen-ExpansionTiles
      expect(find.byType(ExpansionTile), findsNWidgets(4));
      expect(find.text('Woche 1 (Tag 1–7)'), findsOneWidget);
      expect(find.text('Woche 2 (Tag 8–14)'), findsOneWidget);
      expect(find.text('Woche 3 (Tag 15–21)'), findsOneWidget);
      expect(find.text('Woche 4 (Tag 22–28)'), findsOneWidget);
    });
  });
}

import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

void main() {
  late AppDatabase database;
  late CatalogRepository catalogRepo;
  late TripService tripService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catalogFile = File('data/catalog_v0.8.json');
    final quantitiesFile = File('data/quantities_v0.4.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catalogFile.readAsStringSync(),
      quantitiesJson: quantitiesFile.readAsStringSync(),
    );

    tripService = TripService(
      tripDao: database.tripDao,
      listItemDao: database.listItemDao,
      catalogRepository: catalogRepo,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Slice S3: Törn anlegen und Törnverlauf Tests', () {
    test('S3 Abnahmekriterium 1: 5-Personen-Törn anlegen mit Crew-Profilen', () async {
      final crew = [
        const CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Co-Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '3', name: 'Gast 1', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '4', name: 'Veggie', isAdult: true, isVegetarian: true, noAlcohol: false),
        const CrewMemberInput(id: '5', name: 'Sober', isAdult: true, isVegetarian: false, noAlcohol: true),
      ];

      final tripId = await tripService.createTripWithCrew(
        name: 'Sommertörn Dalmatien',
        startDate: DateTime.now(),
        daysCount: 7,
        isCharter: true,
        boatType: 'monohull',
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 120.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: crew,
      );

      expect(tripId, greaterThan(0));

      final trip = await database.tripDao.getTripById(tripId);
      expect(trip, isNotNull);
      expect(trip!.name, 'Sommertörn Dalmatien');
      expect(trip.daysCount, 7);

      final days = await database.tripDao.getDaysForTrip(tripId);
      expect(days.length, 7);
      expect(days.first.dayNumber, 1);
      expect(days.last.dayNumber, 7);

      final crewDb = await database.tripDao.getCrewForTrip(tripId);
      expect(crewDb.length, 5);
      expect(crewDb.where((c) => c.isVegetarian).length, 1);
      expect(crewDb.where((c) => c.isNonDrinker).length, 1);

      final stops = await database.tripDao.getShoppingStopsForTrip(tripId);
      expect(stops.length, 1);
      expect(stops.first.isInitial, isTrue);

      final items = await database.listItemDao.getListItemsForTrip(tripId);
      expect(items, isNotEmpty);
    });

    test('S3 Abnahmekriterium 2: Tagesleiste ist ohne Pflichtangaben nutzbar', () async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Kurztörn',
        startDate: DateTime.now(),
        daysCount: 3,
        isCharter: true,
        boatType: 'monohull',
        region: 'baltic',
        fridgeCapacityLiters: 80.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: [
          const CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final days = await database.tripDao.getDaysForTrip(tripId);
      for (final day in days) {
        expect(day.portName, isNull);
        expect(day.dayType, isNull);
      }

      await tripService.updateDayInfo(days.first, portName: 'Kornati Ankerbucht');
      final updatedDays = await database.tripDao.getDaysForTrip(tripId);
      expect(updatedDays.first.portName, 'Kornati Ankerbucht');
    });

    test('S3 Abnahmekriterium 3: Änderungen an Restaurant-Schaltern ändern Mengen sofort (außer überschriebene)', () async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Genießer-Törn',
        startDate: DateTime.now(),
        daysCount: 7,
        isCharter: true,
        boatType: 'monohull',
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: [
          const CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
          const CrewMemberInput(id: '2', name: 'Gast', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final days = await database.tripDao.getDaysForTrip(tripId);
      final itemsInitial = await database.listItemDao.getListItemsForTrip(tripId);
      final zucchiniInitial = itemsInitial.firstWhere((i) => i.catalogId == 'zucchini');
      final initialQuantity = zucchiniInitial.calculatedQuantity;
      expect(initialQuantity, greaterThan(0));

      // 1. Restaurant-Abend umschalten auf Tag 1
      await tripService.toggleEveningRestaurant(days[0]);

      final itemsAfter1Toggle = await database.listItemDao.getListItemsForTrip(tripId);
      final zucchiniAfterToggle = itemsAfter1Toggle.firstWhere((i) => i.catalogId == 'zucchini');
      expect(zucchiniAfterToggle.calculatedQuantity, lessThan(initialQuantity));

      // 2. Manuelle Überschreibung auf 10 Packungen setzen
      await database.listItemDao.updateListItem(
        zucchiniAfterToggle.copyWith(overriddenPackages: const Value(10)),
      );

      // 3. Weiteren Restaurant-Abend umschalten auf Tag 2
      await tripService.toggleEveningRestaurant(days[1]);

      final itemsAfter2Toggles = await database.listItemDao.getListItemsForTrip(tripId);
      final zucchiniFinal = itemsAfter2Toggles.firstWhere((i) => i.catalogId == 'zucchini');

      // Berechnete Menge hat sich weiter verringert
      expect(zucchiniFinal.calculatedQuantity, lessThan(zucchiniAfterToggle.calculatedQuantity));
      // Manuell überschriebene Packungszahl bleibt strikt 10!
      expect(zucchiniFinal.overriddenPackages, 10);
    });

    test('S3 Abnahmekriterium 4: Einkaufsstopps anlegen, umbenennen, löschen (erster Stopp geschützt)', () async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Stopps-Test',
        startDate: DateTime.now(),
        daysCount: 5,
        isCharter: true,
        boatType: 'monohull',
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: [
          const CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final stopsInitial = await database.tripDao.getShoppingStopsForTrip(tripId);
      expect(stopsInitial.length, 1);
      final initialStop = stopsInitial.first;
      expect(initialStop.isInitial, isTrue);

      // Ersten Stopp löschen versuchen -> muss fehlschlagen
      final deleteInitialResult = await tripService.deleteShoppingStop(initialStop.id);
      expect(deleteInitialResult, isFalse);
      expect((await database.tripDao.getShoppingStopsForTrip(tripId)).length, 1);

      // Weiteren Stopp hinzufügen
      final stop2Id = await tripService.addShoppingStop(tripId: tripId, name: 'Hafen-Supermarkt', dayNumber: 3);
      expect(stop2Id, greaterThan(0));

      var stops = await database.tripDao.getShoppingStopsForTrip(tripId);
      expect(stops.length, 2);
      final stop2 = stops.firstWhere((s) => s.id == stop2Id);
      expect(stop2.name, 'Hafen-Supermarkt');
      expect(stop2.isInitial, isFalse);

      // Stopp 2 umbenennen
      await tripService.updateShoppingStop(stop2.copyWith(name: 'Großmarkt Split'));
      stops = await database.tripDao.getShoppingStopsForTrip(tripId);
      expect(stops.firstWhere((s) => s.id == stop2Id).name, 'Großmarkt Split');

      // Stopp 2 löschen -> muss gelingen
      final deleteStop2Result = await tripService.deleteShoppingStop(stop2Id);
      expect(deleteStop2Result, isTrue);
      expect((await database.tripDao.getShoppingStopsForTrip(tripId)).length, 1);
    });
  });
}

/// PIVOT3-A: Acceptance-Tests für Boat Profile Foundation (Issue #24).
/// Testet Drift Schema v7, BoatProfiles CRUD, Snapshot-Semantik, Resync und Backward-Compatibility.
library;

import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/trip/data/boat_profile_service.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart' show CrewMemberInput;

void main() {
  late AppDatabase db;
  late BoatProfileService boatProfileService;
  late TripService tripService;
  late CatalogRepository catalogRepo;

  CrewMemberInput testMember(String name) => CrewMemberInput(
        id: name.toLowerCase().replaceAll(' ', '_'),
        name: name,
        isAdult: true,
        isVegetarian: false,
        noAlcohol: false,
      );

  setUp(() async {
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
  });

  tearDown(() async {
    await db.close();
  });

  group('PIVOT3-A Acceptance Tests: Boat Profile Foundation', () {
    test('1. BoatProfile anlegen und lesen', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Bavaria C45',
        manufacturer: 'Bavaria Yachts',
        model: 'C45 Style',
        fridgeCapacity: 120,
        hasFreezer: true,
        freezerCapacity: 30,
        waterTankLiters: 450,
        isWaterTankDrinkable: true,
        hasWatermaker: true,
      );

      expect(profileId, isPositive);

      final profile = await boatProfileService.getProfileById(profileId);
      expect(profile, isNotNull);
      expect(profile!.id, equals(profileId));
      expect(profile.name, equals('Bavaria C45'));
      expect(profile.manufacturer, equals('Bavaria Yachts'));
      expect(profile.model, equals('C45 Style'));
      expect(profile.fridgeCapacity, equals(120));
      expect(profile.hasFreezer, isTrue);
      expect(profile.freezerCapacity, equals(30));
      expect(profile.waterTankLiters, equals(450));
      expect(profile.isWaterTankDrinkable, isTrue);
      expect(profile.hasWatermaker, isTrue);
      expect(profile.isArchived, isFalse);
      expect(profile.createdAt, isNotNull);
    });

    test('2. BoatProfile aktualisieren', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Oceanis 40.1',
        manufacturer: 'Beneteau',
        model: 'Oceanis 40.1',
        fridgeCapacity: 100,
        waterTankLiters: 300,
      );

      final profile = await boatProfileService.getProfileById(profileId);
      expect(profile, isNotNull);

      final updated = profile!.copyWith(
        fridgeCapacity: 150,
        model: const Value('Oceanis 40.1 Limited Edition'),
        hasWatermaker: true,
      );

      final ok = await boatProfileService.updateProfile(updated);
      expect(ok, isTrue);

      final reloaded = await boatProfileService.getProfileById(profileId);
      expect(reloaded!.fridgeCapacity, equals(150));
      expect(reloaded.model, equals('Oceanis 40.1 Limited Edition'));
      expect(reloaded.hasWatermaker, isTrue);
    });

    test('3. Profil archivieren und de-archivieren', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Sun Odyssey 440',
      );

      var profile = await boatProfileService.getProfileById(profileId);
      expect(profile!.isArchived, isFalse);

      final archiveOk = await boatProfileService.archiveProfile(profileId, archive: true);
      expect(archiveOk, isTrue);

      profile = await boatProfileService.getProfileById(profileId);
      expect(profile!.isArchived, isTrue);

      final unarchiveOk = await boatProfileService.archiveProfile(profileId, archive: false);
      expect(unarchiveOk, isTrue);

      profile = await boatProfileService.getProfileById(profileId);
      expect(profile!.isArchived, isFalse);
    });

    test('4. getActiveProfiles liefert archivierte Profile nicht', () async {
      final activeId1 = await boatProfileService.createProfile(name: 'Boot Aktiv 1');
      final activeId2 = await boatProfileService.createProfile(name: 'Boot Aktiv 2');
      final archivedId = await boatProfileService.createProfile(name: 'Boot Alt');

      await boatProfileService.archiveProfile(archivedId, archive: true);

      final activeProfiles = await boatProfileService.getActiveProfiles();
      final activeIds = activeProfiles.map((p) => p.id).toList();

      expect(activeIds, containsAll([activeId1, activeId2]));
      expect(activeIds, isNot(contains(archivedId)));

      final allProfiles = await boatProfileService.getAllProfiles(includeArchived: true);
      final allIds = allProfiles.map((p) => p.id).toList();
      expect(allIds, containsAll([activeId1, activeId2, archivedId]));
    });

    test('5. Profil löschen', () async {
      final profileId = await boatProfileService.createProfile(name: 'Einmal-Boot');
      expect(await boatProfileService.getProfileById(profileId), isNotNull);

      final deleteCount = await boatProfileService.deleteProfile(profileId);
      expect(deleteCount, equals(1));

      expect(await boatProfileService.getProfileById(profileId), isNull);
    });

    test('6. Profil -> neuer Trip kopiert alle Snapshot-Felder autonom', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Hanse 458',
        manufacturer: 'HanseYachts',
        model: '458',
        fridgeCapacity: 130,
        hasFreezer: true,
        freezerCapacity: 20,
        waterTankLiters: 450,
        isWaterTankDrinkable: true,
        hasWatermaker: true,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Dänische Südsee 2026',
        startDate: DateTime(2026, 7, 10),
        daysCount: 7,
        boatProfileId: profileId,
        crewMembers: [testMember('Skipper Tim')],
      );

      final trip = await db.tripDao.getTripById(tripId);
      expect(trip, isNotNull);
      expect(trip!.boatProfileId, equals(profileId));
      expect(trip.boatName, equals('Hanse 458'));
      expect(trip.boatManufacturer, equals('HanseYachts'));
      expect(trip.boatModel, equals('458'));
      expect(trip.fridgeCapacity, equals(130));
      expect(trip.hasFreezer, isTrue);
      expect(trip.freezerCapacity, equals(20));
      expect(trip.waterTankLiters, equals(450));
      expect(trip.isWaterTankDrinkable, isTrue);
      expect(trip.hasWatermaker, isTrue);
    });

    test('7. Profiländerung verändert bestehenden Trip NICHT (Snapshot-Semantik)', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Dufour 460',
        manufacturer: 'Dufour',
        model: 'Grand Large',
        fridgeCapacity: 140,
        hasFreezer: false,
        freezerCapacity: 0,
        waterTankLiters: 530,
        isWaterTankDrinkable: false,
        hasWatermaker: false,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Kroatien Sommer 2026',
        startDate: DateTime(2026, 8, 1),
        daysCount: 7,
        boatProfileId: profileId,
        crewMembers: [testMember('Skipper Lisa')],
      );

      final profileBefore = await boatProfileService.getProfileById(profileId);
      final ok = await boatProfileService.updateProfile(profileBefore!.copyWith(
        name: 'Dufour 460 Modified',
        manufacturer: const Value('New Dufour'),
        fridgeCapacity: 250,
        hasFreezer: true,
        freezerCapacity: 50,
        waterTankLiters: 600,
        isWaterTankDrinkable: true,
        hasWatermaker: true,
      ));
      expect(ok, isTrue);

      // Bestehender Trip muss völlig unberührt bleiben
      final tripAfter = await db.tripDao.getTripById(tripId);
      expect(tripAfter, isNotNull);
      expect(tripAfter!.boatProfileId, equals(profileId));
      expect(tripAfter.boatName, equals('Dufour 460'));
      expect(tripAfter.boatManufacturer, equals('Dufour'));
      expect(tripAfter.fridgeCapacity, equals(140));
      expect(tripAfter.hasFreezer, isFalse);
      expect(tripAfter.freezerCapacity, equals(0));
      expect(tripAfter.waterTankLiters, equals(530));
      expect(tripAfter.isWaterTankDrinkable, isFalse);
      expect(tripAfter.hasWatermaker, isFalse);
    });

    test('8. Ein danach neu erzeugter Trip übernimmt die geänderten Profilwerte', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Elan Impression 45',
        fridgeCapacity: 110,
        hasWatermaker: false,
      );

      final trip1Id = await tripService.createTripWithCrew(
        name: 'Früher Törn',
        startDate: DateTime(2026, 5, 1),
        daysCount: 7,
        boatProfileId: profileId,
        crewMembers: [testMember('Skipper 1')],
      );

      // Profil updaten
      final profile = await boatProfileService.getProfileById(profileId);
      await boatProfileService.updateProfile(profile!.copyWith(
        name: 'Elan Impression 45 Refit',
        fridgeCapacity: 180,
        hasWatermaker: true,
      ));

      // Zweiter Trip
      final trip2Id = await tripService.createTripWithCrew(
        name: 'Späterer Törn',
        startDate: DateTime(2026, 9, 1),
        daysCount: 7,
        boatProfileId: profileId,
        crewMembers: [testMember('Skipper 2')],
      );

      final trip1 = await db.tripDao.getTripById(trip1Id);
      final trip2 = await db.tripDao.getTripById(trip2Id);

      expect(trip1!.boatName, equals('Elan Impression 45'));
      expect(trip1.fridgeCapacity, equals(110));
      expect(trip1.hasWatermaker, isFalse);

      expect(trip2!.boatName, equals('Elan Impression 45 Refit'));
      expect(trip2.fridgeCapacity, equals(180));
      expect(trip2.hasWatermaker, isTrue);
    });

    test('9. Explizites resyncTripBoatProfile aktualisiert den bestehenden Trip', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Bavaria 40',
        fridgeCapacity: 100,
        waterTankLiters: 300,
        hasWatermaker: false,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Korfu Rund',
        startDate: DateTime(2026, 6, 1),
        daysCount: 7,
        boatProfileId: profileId,
        crewMembers: [testMember('Alex')],
      );

      // Profil umbauen (z. B. Watermaker nachgerüstet)
      final profile = await boatProfileService.getProfileById(profileId);
      await boatProfileService.updateProfile(profile!.copyWith(
        name: 'Bavaria 40 Blue',
        fridgeCapacity: 140,
        waterTankLiters: 400,
        hasWatermaker: true,
      ));

      // Vor Resync: alter Stand
      var trip = await db.tripDao.getTripById(tripId);
      expect(trip!.boatName, equals('Bavaria 40'));
      expect(trip.fridgeCapacity, equals(100));
      expect(trip.hasWatermaker, isFalse);

      // Expliziter Resync
      final resyncOk = await tripService.resyncTripBoatProfile(tripId);
      expect(resyncOk, isTrue);

      // Nach Resync: neuer Stand im Trip-Snapshot
      trip = await db.tripDao.getTripById(tripId);
      expect(trip!.boatName, equals('Bavaria 40 Blue'));
      expect(trip.fridgeCapacity, equals(140));
      expect(trip.waterTankLiters, equals(400));
      expect(trip.hasWatermaker, isTrue);
    });

    test('10. Resync stößt Neuberechnung an und erhält persistierte Datensätze', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Bavaria Cruiser 46',
        fridgeCapacity: 120,
        waterTankLiters: 360,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Kykladen Wind',
        startDate: DateTime(2026, 7, 1),
        daysCount: 7,
        boatProfileId: profileId,
        crewMembers: [testMember('Skipper Jan'), testMember('Crew Mia')],
      );

      // ListItem anlegen
      final itemId = await db.listItemDao.addListItem(
        ListItemsCompanion.insert(
          tripId: tripId,
          catalogId: 'wasser_still',
          calculatedPackages: const Value(12),
          calculatedQuantity: const Value(18.0),
          selected: const Value(true),
        ),
      );
      expect(itemId, isPositive);

      // Profil ändern und Resync ausführen
      final profile = await boatProfileService.getProfileById(profileId);
      await boatProfileService.updateProfile(profile!.copyWith(
        fridgeCapacity: 160,
        hasWatermaker: true,
      ));

      final resyncOk = await tripService.resyncTripBoatProfile(tripId);
      expect(resyncOk, isTrue);

      // Verifizieren: Trip ist aktualisiert
      final trip = await db.tripDao.getTripById(tripId);
      expect(trip!.fridgeCapacity, equals(160));
      expect(trip.hasWatermaker, isTrue);

      // Verifizieren: Items und Relationen existieren weiterhin
      final items = await db.listItemDao.getListItemsForTrip(tripId);
      expect(items, isNotEmpty);
      expect(items.any((i) => i.id == itemId), isTrue);
    });

    test('11. Hard-Delete des Profils setzt trip.boatProfileId über SQLite-FK auf null', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Charter Katamaran',
        manufacturer: 'Fountaine Pajot',
        model: 'Lucia 40',
        fridgeCapacity: 200,
        hasWatermaker: true,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Mallorca Cruise',
        startDate: DateTime(2026, 9, 10),
        daysCount: 7,
        boatProfileId: profileId,
        crewMembers: [testMember('Skipper David')],
      );

      var trip = await db.tripDao.getTripById(tripId);
      expect(trip!.boatProfileId, equals(profileId));

      // Physisches Löschen des Profils in SQLite
      final deleted = await boatProfileService.deleteProfile(profileId);
      expect(deleted, equals(1));
      expect(await boatProfileService.getProfileById(profileId), isNull);

      // SQLite foreign key constraint ON DELETE SET NULL greift
      trip = await db.tripDao.getTripById(tripId);
      expect(trip!.boatProfileId, isNull);
    });

    test('12. Bei Profil-Löschung bleiben sämtliche Snapshot-Werte des Trips erhalten', () async {
      final profileId = await boatProfileService.createProfile(
        name: 'Swan 54',
        manufacturer: 'Nautor Swan',
        model: '54',
        fridgeCapacity: 180,
        hasFreezer: true,
        freezerCapacity: 45,
        waterTankLiters: 600,
        isWaterTankDrinkable: true,
        hasWatermaker: true,
      );

      final tripId = await tripService.createTripWithCrew(
        name: 'Rolex Swan Cup',
        startDate: DateTime(2026, 9, 20),
        daysCount: 7,
        boatProfileId: profileId,
        crewMembers: [testMember('Pekka')],
      );

      // Profil löschen
      await boatProfileService.deleteProfile(profileId);

      // Alle Snapshot-Werte müssen unverändert auf dem Trip verbleiben
      final trip = await db.tripDao.getTripById(tripId);
      expect(trip, isNotNull);
      expect(trip!.boatProfileId, isNull);
      expect(trip.boatName, equals('Swan 54'));
      expect(trip.boatManufacturer, equals('Nautor Swan'));
      expect(trip.boatModel, equals('54'));
      expect(trip.fridgeCapacity, equals(180));
      expect(trip.hasFreezer, isTrue);
      expect(trip.freezerCapacity, equals(45));
      expect(trip.waterTankLiters, equals(600));
      expect(trip.isWaterTankDrinkable, isTrue);
      expect(trip.hasWatermaker, isTrue);
    });

    test('13. Trip-Erstellung ohne Bootsprofil funktioniert rückwärtskompatibel', () async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Klassischer Törn manuell',
        startDate: DateTime(2026, 10, 1),
        daysCount: 7,
        fridgeCapacityLiters: 95.0,
        hasFreezer: true,
        freezerCapacityLiters: 15.0,
        waterTankLiters: 200.0,
        isWaterTankDrinkable: true,
        crewMembers: [testMember('Skipper Anna')],
      );

      final trip = await db.tripDao.getTripById(tripId);
      expect(trip, isNotNull);
      expect(trip!.name, equals('Klassischer Törn manuell'));
      expect(trip.boatProfileId, isNull);
      expect(trip.boatName, isNull);
      expect(trip.boatManufacturer, isNull);
      expect(trip.boatModel, isNull);
      expect(trip.fridgeCapacity, equals(95));
      expect(trip.hasFreezer, isTrue);
      expect(trip.freezerCapacity, equals(15));
      expect(trip.waterTankLiters, equals(200));
      expect(trip.isWaterTankDrinkable, isTrue);
      expect(trip.hasWatermaker, isFalse);
    });
  });
}


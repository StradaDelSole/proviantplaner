/// Tests für Datensicherung und Wiederherstellung über BackupCoordinator und HullqBackupService (Slice S8).
/// Verifiziert die transaktionssichere Sicherung aller 8 Entitäten und die vollständige Wiederherstellung.
library;

import 'dart:convert';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/hullq_backup_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

void main() {
  late AppDatabase db;
  late MockHullqAuthService authService;
  late MockHullqBackupService backupService;
  late BackupCoordinator coordinator;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    authService = MockHullqAuthService();
    backupService = MockHullqBackupService();
    coordinator = BackupCoordinator(
      db: db,
      backupService: backupService,
      authService: authService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedCompleteTrip(AppDatabase targetDb, String tripName) async {
    final tripId = await targetDb.tripDao.createTrip(
      TripsCompanion.insert(
        name: tripName,
        startDate: DateTime(2026, 9, 1),
        daysCount: const Value(7),
        region: const Value('mediterranean'),
        isCharter: const Value(true),
        boatType: const Value('mono'),
        fridgeCapacity: const Value(110),
        appetite: const Value(CrewAppetite.normal),
        reserveDays: const Value('few_days'),
        drinkingHabit: const Value(CrewDrinking.normal),
        hasStorageChecklist: const Value(true),
        phase: const Value(TripPhase.shopping),
        isArchived: const Value(false),
        currency: const Value('EUR'),
        kittyModel: const Value(KittyModel.sharedKitty),
      ),
    );

    // Stop 2 anlegen (Stop 1 wird automatisch angelegt)
    final stop2Id = await targetDb.tripDao.addShoppingStop(
      ShoppingStopsCompanion.insert(
        tripId: tripId,
        name: 'Zadar Hafenbäcker',
        dayNumber: const Value(2),
        isInitial: const Value(false),
      ),
    );

    // Crew-Mitglied anlegen
    final memberId = await targetDb.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Skipper Markus',
        isSkipperFree: const Value(true),
        skipperFreeScope: const Value('all'),
      ),
    );

    // ListItem anlegen
    final itemId = await targetDb.listItemDao.addListItem(
      ListItemsCompanion.insert(
        tripId: tripId,
        catalogId: 'brot_weissbrot',
        calculatedPackages: const Value(3),
        calculatedQuantity: const Value(1500.0),
        selected: const Value(true),
      ),
    );

    // ListItemAllocation anlegen
    await targetDb.listItemDao.setAllocation(
      tripId: tripId,
      listItemId: itemId,
      shoppingStopId: stop2Id,
      packages: 2,
    );

    // Ausgabe anlegen
    await targetDb.expenseDao.addExpense(
      ExpensesCompanion.insert(
        tripId: tripId,
        note: const Value('Bäcker Zadar'),
        amount: 14.50,
        currency: const Value('EUR'),
        category: ExpenseCategory.provisions,
        paidByCrewMemberId: Value(memberId),
        isPaidFromKitty: const Value(false),
      ),
    );

    // Einzahlung in Bordkasse anlegen
    await targetDb.expenseDao.addKittyPayment(
      KittyPaymentsCompanion.insert(
        tripId: tripId,
        crewMemberId: memberId,
        amount: 100.0,
      ),
    );

    return tripId;
  }

  group('Slice S8: Sicherung und Wiederherstellung Tests', () {
    test('Sicherung erfordert HullQ-Mitgliedschaft (Trial wirft StateError)', () async {
      // Nicht angemeldet (Trial)
      expect(
        () => coordinator.createBackup(),
        throwsStateError,
      );
    });

    test('Wiederherstellung erfordert HullQ-Mitgliedschaft (Trial wirft StateError)', () async {
      expect(
        () => coordinator.restoreBackup(),
        throwsStateError,
      );
    });

    test('Sicherung speichert alle 8 Entitäten vollständig als JSON', () async {
      await authService.loginWithEmail('sailor@hullq.com', newsletterOptIn: false);
      final tripId = await seedCompleteTrip(db, 'Kornaten Törn');

      final success = await coordinator.createBackup();
      expect(success, isTrue);

      final hasBackup = await coordinator.hasBackup();
      expect(hasBackup, isTrue);

      final timestamp = await backupService.getLastBackupTimestamp();
      expect(timestamp, isNotNull);

      final rawData = await backupService.restoreData();
      expect(rawData, isNotNull);

      final decoded = jsonDecode(rawData!) as Map<String, dynamic>;
      expect(decoded['version'], equals(2));
      expect(decoded['boatProfiles'], isNotNull);
      final trips = decoded['trips'] as List<dynamic>;
      expect(trips.length, equals(1));

      final tripData = trips.first as Map<String, dynamic>;
      expect(tripData['trip']['name'], equals('Kornaten Törn'));
      expect(tripData['trip']['id'], equals(tripId));
      expect((tripData['days'] as List).length, equals(7));
      expect((tripData['crew'] as List).length, equals(1));
      expect((tripData['stops'] as List).length, equals(2));
      expect((tripData['items'] as List).length, equals(1));
      expect((tripData['allocations'] as List).length, equals(1));
      expect((tripData['expenses'] as List).length, equals(1));
      expect((tripData['payments'] as List).length, equals(1));
    });

    test('S8 Abnahmekriterium: Neuinstallation plus Login stellt alle Törns wieder her (Mock)', () async {
      // 1. Törn auf Originalgerät erstellen und sichern
      await authService.loginWithEmail('skipper@hullq.com', newsletterOptIn: true);
      await seedCompleteTrip(db, 'Kroatien 2026');
      final backupOk = await coordinator.createBackup();
      expect(backupOk, isTrue);

      // 2. Simulation: Neuinstallation (Neue, leere Datenbank, neues Gerät)
      final newDeviceDb = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => newDeviceDb.close());

      // Vor Login / Wiederherstellung: Keine Törns in der neuen Datenbank
      final initialTrips = await newDeviceDb.tripDao.getAllTrips();
      expect(initialTrips, isEmpty);

      // 3. Login auf neuem Gerät (greift auf die Cloud-Sicherung des Kontos zu)
      final newCoordinator = BackupCoordinator(
        db: newDeviceDb,
        backupService: backupService, // Teilt die verschlüsselte Cloud-Sicherung des Mock-Servers
        authService: authService,
      );

      final hasBackupOnNewDevice = await newCoordinator.hasBackup();
      expect(hasBackupOnNewDevice, isTrue);

      final restoreOk = await newCoordinator.restoreBackup();
      expect(restoreOk, isTrue);

      // 4. Verifikation: Alle Daten und Relationen sind vollständig wiederhergestellt
      final restoredTrips = await newDeviceDb.tripDao.getAllTrips();
      expect(restoredTrips.length, equals(1));
      final restoredTrip = restoredTrips.first;
      expect(restoredTrip.name, equals('Kroatien 2026'));
      expect(restoredTrip.daysCount, equals(7));
      expect(restoredTrip.kittyModel, equals(KittyModel.sharedKitty));

      // Tage prüfen
      final restoredDays = await newDeviceDb.tripDao.getDaysForTrip(restoredTrip.id);
      expect(restoredDays.length, equals(7));

      // Stopps prüfen
      final restoredStops = await newDeviceDb.tripDao.getShoppingStopsForTrip(restoredTrip.id);
      expect(restoredStops.length, equals(2));
      final customStop = restoredStops.firstWhere((s) => s.name == 'Zadar Hafenbäcker');
      expect(customStop.dayNumber, equals(2));

      // Crew prüfen
      final restoredCrew = await newDeviceDb.tripDao.getCrewForTrip(restoredTrip.id);
      expect(restoredCrew.length, equals(1));
      final restoredMember = restoredCrew.first;
      expect(restoredMember.name, equals('Skipper Markus'));
      expect(restoredMember.isSkipperFree, isTrue);

      // ListItems prüfen
      final restoredItems = await newDeviceDb.listItemDao.getListItemsForTrip(restoredTrip.id);
      expect(restoredItems.length, equals(1));
      final restoredItem = restoredItems.first;
      expect(restoredItem.catalogId, equals('brot_weissbrot'));
      expect(restoredItem.calculatedPackages, equals(3));

      // Allokationen prüfen (müssen auf die NEUEN IDs von Stop und Item zeigen)
      final restoredAllocations =
          await newDeviceDb.listItemDao.getAllocationsForListItem(restoredItem.id);
      expect(restoredAllocations.length, equals(1));
      expect(restoredAllocations.first.shoppingStopId, equals(customStop.id));
      expect(restoredAllocations.first.allocatedPackages, equals(2));

      // Ausgaben prüfen (muss auf das NEUE CrewMember zeigen)
      final restoredExpenses = await newDeviceDb.expenseDao.getExpensesForTrip(restoredTrip.id);
      expect(restoredExpenses.length, equals(1));
      expect(restoredExpenses.first.note, equals('Bäcker Zadar'));
      expect(restoredExpenses.first.amount, equals(14.50));
      expect(restoredExpenses.first.paidByCrewMemberId, equals(restoredMember.id));

      // Einzahlungen prüfen (muss auf das NEUE CrewMember zeigen)
      final restoredPayments = await newDeviceDb.expenseDao.getKittyPaymentsForTrip(restoredTrip.id);
      expect(restoredPayments.length, equals(1));
      expect(restoredPayments.first.amount, equals(100.0));
      expect(restoredPayments.first.crewMemberId, equals(restoredMember.id));
    });

    test('PIVOT3-A Abnahmetest: Backup v2 Export enthält vollständige BoatProfiles und Trip-Snapshots', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // Profil 1 anlegen (aktiv, nicht-default Werte)
      final p1Id = await db.boatProfileDao.createProfile(
        BoatProfilesCompanion.insert(
          name: 'Bavaria C45 Custom',
          manufacturer: const Value('Bavaria Yachts'),
          model: const Value('C45 Style'),
          fridgeCapacity: const Value(160),
          hasFreezer: const Value(true),
          freezerCapacity: const Value(35),
          waterTankLiters: const Value(480),
          isWaterTankDrinkable: const Value(true),
          hasWatermaker: const Value(true),
        ),
      );

      // Profil 2 anlegen (archiviert)
      final p2Id = await db.boatProfileDao.createProfile(
        BoatProfilesCompanion.insert(
          name: 'Altes Archivboot',
          isArchived: const Value(true),
        ),
      );

      // Trip mit Verknüpfung und Snapshots anlegen
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Sommer 2026',
          startDate: DateTime(2026, 7, 1),
          boatProfileId: Value(p1Id),
          boatName: const Value('Bavaria C45 Custom'),
          boatManufacturer: const Value('Bavaria Yachts'),
          boatModel: const Value('C45 Style'),
          fridgeCapacity: const Value(160),
          hasFreezer: const Value(true),
          freezerCapacity: const Value(35),
          waterTankLiters: const Value(480),
          isWaterTankDrinkable: const Value(true),
          hasWatermaker: const Value(true),
        ),
      );

      final success = await coordinator.createBackup();
      expect(success, isTrue);

      final rawData = await backupService.restoreData();
      expect(rawData, isNotNull);

      final decoded = jsonDecode(rawData!) as Map<String, dynamic>;
      expect(decoded['version'], equals(2));

      // Bootsprofile prüfen (beide Profile inklusive des archivierten müssen vorhanden sein)
      final profiles = decoded['boatProfiles'] as List<dynamic>;
      expect(profiles.length, equals(2));

      final p1Map = profiles.firstWhere((p) => p['name'] == 'Bavaria C45 Custom') as Map<String, dynamic>;
      expect(p1Map['id'], equals(p1Id));
      expect(p1Map['manufacturer'], equals('Bavaria Yachts'));
      expect(p1Map['model'], equals('C45 Style'));
      expect(p1Map['fridgeCapacity'], equals(160));
      expect(p1Map['hasFreezer'], isTrue);
      expect(p1Map['freezerCapacity'], equals(35));
      expect(p1Map['waterTankLiters'], equals(480));
      expect(p1Map['isWaterTankDrinkable'], isTrue);
      expect(p1Map['hasWatermaker'], isTrue);
      expect(p1Map['isArchived'], isFalse);

      final p2Map = profiles.firstWhere((p) => p['name'] == 'Altes Archivboot') as Map<String, dynamic>;
      expect(p2Map['id'], equals(p2Id));
      expect(p2Map['isArchived'], isTrue);

      // Trip-Snapshot prüfen
      final trips = decoded['trips'] as List<dynamic>;
      expect(trips.length, equals(1));
      final tripMap = (trips.first as Map<String, dynamic>)['trip'] as Map<String, dynamic>;
      expect(tripMap['id'], equals(tripId));
      expect(tripMap['boatProfileId'], equals(p1Id));
      expect(tripMap['boatName'], equals('Bavaria C45 Custom'));
      expect(tripMap['boatManufacturer'], equals('Bavaria Yachts'));
      expect(tripMap['boatModel'], equals('C45 Style'));
      expect(tripMap['fridgeCapacity'], equals(160));
      expect(tripMap['hasFreezer'], isTrue);
      expect(tripMap['freezerCapacity'], equals(35));
      expect(tripMap['waterTankLiters'], equals(480));
      expect(tripMap['isWaterTankDrinkable'], isTrue);
      expect(tripMap['hasWatermaker'], isTrue);
    });

    test('PIVOT3-A Abnahmetest: Backup v2 Restore mit nachweisbarem ID-Remapping und Entkopplung', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // Konstruiere einen v2-Payload, bei dem das Profil die alte ID 999 hat und der Trip boatProfileId 999 referenziert
      final v2Payload = jsonEncode({
        'version': 2,
        'exportedAt': '2026-10-06T12:00:00.000Z',
        'boatProfiles': [
          {
            'id': 999,
            'name': 'Swan 48 Remap',
            'manufacturer': 'Nautor Swan',
            'model': 'Swan 48',
            'fridgeCapacity': 170,
            'hasFreezer': true,
            'freezerCapacity': 40,
            'waterTankLiters': 500,
            'isWaterTankDrinkable': true,
            'hasWatermaker': true,
            'isArchived': false,
            'createdAt': '2026-10-06T10:00:00.000Z',
          }
        ],
        'trips': [
          {
            'trip': {
              'id': 777,
              'name': 'Swan Cup 2026',
              'startDate': '2026-09-01T00:00:00.000Z',
              'daysCount': 7,
              'region': 'mediterranean',
              'climate': 'warm',
              'isCharter': true,
              'boatProfileId': 999, // Referenziert alte Profil-ID 999
              'boatName': 'Swan 48 Remap',
              'boatManufacturer': 'Nautor Swan',
              'boatModel': 'Swan 48',
              'boatType': 'mono',
              'fridgeCapacity': 170,
              'hasFreezer': true,
              'freezerCapacity': 40,
              'waterTankLiters': 500,
              'isWaterTankDrinkable': true,
              'hasWatermaker': true,
              'appetite': 'normal',
              'reserveDays': 'few_days',
              'drinkingHabit': 'normal',
              'hasStorageChecklist': true,
              'phase': 'plan',
              'isArchived': false,
              'currency': 'EUR',
              'kittyModel': 'shared_kitty',
              'createdAt': '2026-10-06T10:00:00.000Z',
            },
            'days': [],
            'crew': [],
            'stops': [],
            'items': [],
            'allocations': [],
            'expenses': [],
            'payments': [],
          }
        ],
      });

      await backupService.backupData(v2Payload);

      // Neue Datenbank für sauberen Restore
      final newDeviceDb = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => newDeviceDb.close());

      final newCoordinator = BackupCoordinator(
        db: newDeviceDb,
        backupService: backupService,
        authService: authService,
      );

      final restoreOk = await newCoordinator.restoreBackup();
      expect(restoreOk, isTrue);

      // 1. Profil in neuer Datenbank prüfen
      final restoredProfiles = await newDeviceDb.boatProfileDao.getAllProfiles();
      expect(restoredProfiles.length, equals(1));
      final restoredProfile = restoredProfiles.first;
      expect(restoredProfile.name, equals('Swan 48 Remap'));
      // Die neue ID ist eine lokale SQLite-ID (1) und NICHT die alte 999
      expect(restoredProfile.id, isNot(equals(999)));

      // 2. Trip in neuer Datenbank prüfen
      final restoredTrips = await newDeviceDb.tripDao.getAllTrips();
      expect(restoredTrips.length, equals(1));
      final restoredTrip = restoredTrips.first;
      expect(restoredTrip.name, equals('Swan Cup 2026'));
      // Echtes ID-Remapping: boatProfileId zeigt auf die NEUE Profil-ID, nicht 999!
      expect(restoredTrip.boatProfileId, equals(restoredProfile.id));
      expect(restoredTrip.boatProfileId, isNot(equals(999)));

      // Snapshot-Werte sind identisch zum Backup
      expect(restoredTrip.boatName, equals('Swan 48 Remap'));
      expect(restoredTrip.fridgeCapacity, equals(170));
      expect(restoredTrip.freezerCapacity, equals(40));
      expect(restoredTrip.waterTankLiters, equals(500));
      expect(restoredTrip.hasWatermaker, isTrue);

      // 3. Entkopplung verifizieren: Profiländerung mutiert Trip nicht
      await newDeviceDb.boatProfileDao.updateProfile(
        restoredProfile.copyWith(
          fridgeCapacity: 300,
          hasWatermaker: false,
        ),
      );

      final tripAfterProfileUpdate = await (newDeviceDb.select(newDeviceDb.trips)
            ..where((t) => t.id.equals(restoredTrip.id)))
          .getSingle();
      expect(tripAfterProfileUpdate.fridgeCapacity, equals(170)); // Snapshot bleibt intakt!
      expect(tripAfterProfileUpdate.hasWatermaker, isTrue);
    });

    test('PIVOT3-A Abnahmetest: Backup v1 Restore in Schema v7 ist abwärtskompatibel mit sicheren Defaults', () async {
      await authService.loginWithEmail('legacy@provy.app', newsletterOptIn: false);

      // Echtes v1-JSON-Payload ohne 'boatProfiles' und ohne neue v7-Felder
      final v1Payload = jsonEncode({
        'version': 1,
        'exportedAt': '2026-09-01T12:00:00.000Z',
        'trips': [
          {
            'trip': {
              'id': 101,
              'name': 'Klassischer v1 Törn',
              'startDate': '2026-09-01T00:00:00.000Z',
              'daysCount': 7,
              'region': 'mediterranean',
              'climate': 'warm',
              'isCharter': true,
              'boatType': 'mono',
              'fridgeCapacity': 85,
              'hasFreezer': true,
              'freezerCapacity': 12,
              'waterTankLiters': 180,
              'isWaterTankDrinkable': true,
              'appetite': 'normal',
              'reserveDays': 'few_days',
              'drinkingHabit': 'normal',
              'hasStorageChecklist': true,
              'phase': 'plan',
              'isArchived': false,
              'currency': 'EUR',
              'kittyModel': 'shared_kitty',
              'createdAt': '2026-09-01T12:00:00.000Z',
            },
            'days': [],
            'crew': [],
            'stops': [],
            'items': [],
            'allocations': [],
            'expenses': [],
            'payments': [],
          }
        ],
      });

      await backupService.backupData(v1Payload);

      final restoreOk = await coordinator.restoreBackup();
      expect(restoreOk, isTrue);

      // Verifizieren: Trip wurde sauber importiert
      final restoredTrips = await db.tripDao.getAllTrips();
      expect(restoredTrips.length, equals(1));
      final trip = restoredTrips.first;
      expect(trip.name, equals('Klassischer v1 Törn'));
      expect(trip.fridgeCapacity, equals(85));
      expect(trip.hasFreezer, isTrue);
      expect(trip.freezerCapacity, equals(12));
      expect(trip.waterTankLiters, equals(180));
      expect(trip.isWaterTankDrinkable, isTrue);

      // Sichere Defaults für neue PIVOT3-A Felder
      expect(trip.boatProfileId, isNull);
      expect(trip.boatName, isNull);
      expect(trip.boatManufacturer, isNull);
      expect(trip.boatModel, isNull);
      expect(trip.hasWatermaker, isFalse);

      // Keine BoatProfiles erzeugt
      final profiles = await db.boatProfileDao.getAllProfiles(includeArchived: true);
      expect(profiles, isEmpty);
    });
  });
}

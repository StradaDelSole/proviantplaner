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

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';

Uint8List _createTestJpeg({int width = 10, int height = 10}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 100, 50));
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  late AppDatabase db;
  late MockHullqAuthService authService;
  late MockHullqBackupService backupService;
  late Directory tempDir;
  late ReceiptFileService receiptService;
  late BackupCoordinator coordinator;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('backup_coord_test_');
    receiptService = ReceiptFileService(docsDirProvider: () async => tempDir);
    db = AppDatabase(NativeDatabase.memory());
    authService = MockHullqAuthService();
    backupService = MockHullqBackupService();
    coordinator = BackupCoordinator(
      db: db,
      backupService: backupService,
      authService: authService,
      receiptFileService: receiptService,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
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
      expect(decoded['version'], equals(3));
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
        receiptFileService: receiptService,
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
      expect(decoded['version'], equals(3));

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
        receiptFileService: receiptService,
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

    test('Finding A: createBackup bricht mit BackupIntegrityException ab, wenn Belegdatei physisch fehlt', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);
      final tripId = await seedCompleteTrip(db, 'Fehlender Beleg Test');

      // Expense ermitteln
      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      final expenseId = expenses.first.id;

      // Beleg in DB eintragen, dessen physische Datei NICHT existiert
      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: tripId,
          expenseId: expenseId,
          fileName: 'missing_receipt.jpg',
          filePath: 'receipts/trip_$tripId/expense_$expenseId/missing_receipt.jpg',
          byteSize: const Value(1024),
          mimeType: const Value('image/jpeg'),
        ),
      );

      // Sichern muss mit BackupIntegrityException abbrechen
      expect(
        () => coordinator.createBackup(),
        throwsA(isA<BackupIntegrityException>()),
      );
    });

    test('Finding A & C: restoreBackup bricht mit BackupCorruptException ab, wenn Belegbild im Backup null oder ungültig ist', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // Payload mit Beleg, der imageBase64: null hat
      final nullImagePayload = jsonEncode({
        'version': 3,
        'exportedAt': '2026-10-17T12:00:00.000Z',
        'trips': [
          {
            'trip': {
              'id': 1,
              'name': 'Corrupt Payload Trip',
              'startDate': '2026-10-17T00:00:00.000Z',
              'daysCount': 7,
              'currency': 'EUR',
              'kittyModel': 'shared_kitty',
            },
            'days': [],
            'crew': [],
            'stops': [],
            'items': [],
            'allocations': [],
            'expenses': [
              {
                'id': 10,
                'tripId': 1,
                'amount': 25.0,
                'category': 'provisions',
                'isPaidFromKitty': true,
              }
            ],
            'payments': [],
            'receipts': [
              {
                'id': 100,
                'tripId': 1,
                'expenseId': 10,
                'fileName': 'receipt.jpg',
                'filePath': 'receipts/trip_1/expense_10/rcpt_1.jpg',
                'byteSize': 500,
                'mimeType': 'image/jpeg',
                'imageBase64': null, // Nicht zulässig!
              }
            ],
          }
        ],
      });

      await backupService.backupData(nullImagePayload);
      expect(
        () => coordinator.restoreBackup(),
        throwsA(isA<BackupCorruptException>()),
      );

      // Payload mit invaliden base64-Bytes
      final invalidBase64Payload = jsonEncode({
        'version': 3,
        'exportedAt': '2026-10-17T12:00:00.000Z',
        'trips': [
          {
            'trip': {
              'id': 1,
              'name': 'Corrupt Payload Trip 2',
              'startDate': '2026-10-17T00:00:00.000Z',
              'daysCount': 7,
              'currency': 'EUR',
              'kittyModel': 'shared_kitty',
            },
            'days': [],
            'crew': [],
            'stops': [],
            'items': [],
            'allocations': [],
            'expenses': [
              {
                'id': 10,
                'tripId': 1,
                'amount': 25.0,
                'category': 'provisions',
                'isPaidFromKitty': true,
              }
            ],
            'payments': [],
            'receipts': [
              {
                'id': 101,
                'tripId': 1,
                'expenseId': 10,
                'fileName': 'receipt.jpg',
                'filePath': 'receipts/trip_1/expense_10/rcpt_2.jpg',
                'byteSize': 500,
                'mimeType': 'image/jpeg',
                'imageBase64': '!!!not-valid-base64???',
              }
            ],
          }
        ],
      });

      await backupService.backupData(invalidBase64Payload);
      expect(
        () => coordinator.restoreBackup(),
        throwsA(isA<BackupCorruptException>()),
      );
    });

    test('Finding C: restoreBackup ist crash-sicher - Erhält bei Fehler bestehende DB und Belegdateien byte-genau', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // 1. Aktiven Törn anlegen und Belegdatei physisch speichern
      final tripId = await seedCompleteTrip(db, 'Aktiver Original-Törn');
      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      final expenseId = expenses.first.id;

      final testJpegBytes = _createTestJpeg(width: 20, height: 20);
      final processed = await receiptService.saveReceiptImage(
        tripId: tripId,
        expenseId: expenseId,
        preferredFileName: 'active_orig.jpg',
        imageBytes: testJpegBytes,
      );

      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: tripId,
          expenseId: expenseId,
          fileName: processed.fileName,
          filePath: processed.filePath,
          byteSize: Value(processed.byteSize),
          mimeType: const Value('image/jpeg'),
        ),
      );

      final originalFile = File(p.join(tempDir.path, processed.filePath));
      expect(await originalFile.exists(), isTrue);
      final savedOriginalBytes = await originalFile.readAsBytes();

      // 2. Fehlerhaften Restore-Payload bereitstellen
      final corruptPayload = jsonEncode({
        'version': 3,
        'exportedAt': '2026-10-17T12:00:00.000Z',
        'trips': [
          {
            'trip': {
              'id': 999,
              'name': 'Fehlerhafter Törn',
            },
            'expenses': [],
            'receipts': [
              {
                'id': 888,
                'tripId': 999,
                'expenseId': 777,
                'fileName': 'broken.jpg',
                'filePath': 'receipts/trip_999/broken.jpg',
                'imageBase64': null, // Verursacht Pre-flight Abbruch
              }
            ],
          }
        ],
      });
      await backupService.backupData(corruptPayload);

      // Restore ausführen - muss scheitern
      expect(
        () => coordinator.restoreBackup(),
        throwsA(isA<BackupCorruptException>()),
      );

      // 3. Verifizieren: Aktive Datenbank ist unberührt
      final trips = await db.tripDao.getAllTrips();
      expect(trips.length, equals(1));
      expect(trips.first.name, equals('Aktiver Original-Törn'));

      final receipts = await db.expenseDao.getReceiptsForExpense(expenseId);
      expect(receipts.length, equals(1));

      // 4. Verifizieren: Physische Original-Datei ist byte-genau erhalten!
      expect(await originalFile.exists(), isTrue);
      expect(await originalFile.readAsBytes(), equals(savedOriginalBytes));

      // 5. Staging-Verzeichnis ist bereinigt
      final stagingActiveDir = Directory(p.join(tempDir.path, 'receipts_staging_active'));
      expect(await stagingActiveDir.exists(), isFalse);
    });

    test('Finding F: createBackup bricht mit BackupSizeLimitExceededException ab, wenn Beleg-Budget überschritten ist', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);
      final tripId = await seedCompleteTrip(db, 'Budget Test Törn');
      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      final expenseId = expenses.first.id;

      final receiptBytes = _createTestJpeg(width: 80, height: 80);
      final processed = await receiptService.saveReceiptImage(
        tripId: tripId,
        expenseId: expenseId,
        preferredFileName: 'receipt_2kb.jpg',
        imageBytes: receiptBytes,
      );

      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: tripId,
          expenseId: expenseId,
          fileName: processed.fileName,
          filePath: processed.filePath,
          byteSize: Value(processed.byteSize),
          mimeType: const Value('image/jpeg'),
        ),
      );

      // Budget auf 50 Bytes begrenzen (Beleg hat deutlich mehr Bytes)
      expect(
        () => coordinator.createBackup(maxBackupReceiptBytes: 50),
        throwsA(isA<BackupSizeLimitExceededException>()),
      );
    });

    test('R1: restoreBackup rollt SQLite UND Dateisystem vollständig zurück, wenn ein Fehler WÄHREND der Datei-Promotion (nach erfolgreicher Preflight-Validierung) auftritt', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // 1. Einen gültigen Backup-Stand ("Cloud-Stand B") mit Beleg erzeugen
      final cloudTripId = await seedCompleteTrip(db, 'Cloud Törn B');
      final cloudExpenses = await db.expenseDao.getExpensesForTrip(cloudTripId);
      final cloudExpenseId = cloudExpenses.first.id;
      final cloudPhoto = _createTestJpeg(width: 24, height: 24);
      final cloudProcessed = await receiptService.saveReceiptImage(
        tripId: cloudTripId,
        expenseId: cloudExpenseId,
        preferredFileName: 'cloud_receipt.jpg',
        imageBytes: cloudPhoto,
      );
      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: cloudTripId,
          expenseId: cloudExpenseId,
          fileName: cloudProcessed.fileName,
          filePath: cloudProcessed.filePath,
          byteSize: Value(cloudProcessed.byteSize),
          mimeType: const Value('image/jpeg'),
        ),
      );
      expect(await coordinator.createBackup(), isTrue);

      // 2. Lokal auf dem Gerät einen komplett anderen aktiven Zustand ("Lokaler Stand A") aufbauen
      await db.delete(db.expenseReceipts).go();
      await db.delete(db.expenses).go();
      await db.delete(db.trips).go();
      final activeDir = Directory(p.join(tempDir.path, 'receipts'));
      if (await activeDir.exists()) {
        await activeDir.delete(recursive: true);
      }

      final localTripId = await seedCompleteTrip(db, 'Lokaler Original-Törn A');
      final localExpenses = await db.expenseDao.getExpensesForTrip(localTripId);
      final localExpenseId = localExpenses.first.id;
      final localPhoto = _createTestJpeg(width: 16, height: 16);
      final localProcessed = await receiptService.saveReceiptImage(
        tripId: localTripId,
        expenseId: localExpenseId,
        preferredFileName: 'local_orig_a.jpg',
        imageBytes: localPhoto,
      );
      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: localTripId,
          expenseId: localExpenseId,
          fileName: localProcessed.fileName,
          filePath: localProcessed.filePath,
          byteSize: Value(localProcessed.byteSize),
          mimeType: const Value('image/jpeg'),
        ),
      );

      final localFile = File(p.join(tempDir.path, localProcessed.filePath));
      final savedLocalBytes = await localFile.readAsBytes();

      // 3. Injiziere einen I/O-Fehler mitten in der Datei-Promotion
      // (nachdem Preflight-Validierung und alle SQLite-Inserts gelaufen sind und
      // nachdem `receipts` bereits nach `receipts_rollback` verschoben wurde!)
      receiptService.faultInjector = (op) {
        if (op == 'promoteStagedReceipts_afterBackupMove') {
          throw const FileSystemException('Simulated disk full / I/O failure during file promotion');
        }
      };

      await expectLater(
        coordinator.restoreBackup(),
        throwsA(isA<FileSystemException>()),
      );
      receiptService.faultInjector = null;

      // 4. Beweis: Weder DB noch Dateien sind auf "Cloud Törn B" gewechselt;
      // "Lokaler Original-Törn A" und seine Bilddatei sind vollständig und byte-genau erhalten!
      final remainingTrips = await db.tripDao.getAllTrips();
      expect(remainingTrips.length, equals(1));
      expect(remainingTrips.first.name, equals('Lokaler Original-Törn A'));

      final remainingReceipts = await db.expenseDao.getReceiptsForTrip(localTripId);
      expect(remainingReceipts.length, equals(1));
      expect(remainingReceipts.first.filePath, equals(localProcessed.filePath));

      expect(await localFile.exists(), isTrue);
      expect(await localFile.readAsBytes(), equals(savedLocalBytes));

      // Rollback-, Staging- und Journal-Artefakte sind sauber bereinigt
      expect(await Directory(p.join(tempDir.path, 'receipts_rollback')).exists(), isFalse);
      expect(await Directory(p.join(tempDir.path, 'receipts_staging_active')).exists(), isFalse);
      expect(await File(p.join(tempDir.path, 'restore_journal.json')).exists(), isFalse);
    });

    test('R1: Prozessabbruch / App-Neustart Recovery stellt Konsistenz wieder her (Roll-Back vor DB-Commit & Roll-Forward nach DB-Commit)', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // Ausgangszustand A aufbauen
      final tripIdA = await seedCompleteTrip(db, 'Stand A Vor Crash');
      final expensesA = await db.expenseDao.getExpensesForTrip(tripIdA);
      final processedA = await receiptService.saveReceiptImage(
        tripId: tripIdA,
        expenseId: expensesA.first.id,
        preferredFileName: 'stand_a.jpg',
        imageBytes: _createTestJpeg(width: 14, height: 14),
      );
      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: tripIdA,
          expenseId: expensesA.first.id,
          fileName: processedA.fileName,
          filePath: processedA.filePath,
          byteSize: Value(processedA.byteSize),
          mimeType: const Value('image/jpeg'),
        ),
      );
      final fileA = File(p.join(tempDir.path, processedA.filePath));
      final bytesA = await fileA.readAsBytes();

      // Fall 1: Simulierter harter Prozessabbruch NACH Datei-Promotion nach `receipts/`,
      // aber VOR SQLite-Transaktions-Commit (d.h. SQLite hat beim Neustart Stand A,
      // während Stand-A-Dateien noch in `receipts_rollback/` liegen und `restore_journal.json` auf Stand B zeigt).
      final activeDir = Directory(p.join(tempDir.path, 'receipts'));
      final rollbackDir = Directory(p.join(tempDir.path, 'receipts_rollback'));
      await activeDir.rename(rollbackDir.path);
      await activeDir.create(recursive: true);
      final fakePromotedFile = File(p.join(activeDir.path, 'trip_999', 'expense_999', 'crashed_b.jpg'));
      await fakePromotedFile.parent.create(recursive: true);
      await fakePromotedFile.writeAsBytes([1, 2, 3]);
      await receiptService.writeRestoreJournal(
        expectedReceiptPaths: ['receipts/trip_999/expense_999/crashed_b.jpg'],
      );

      // Beim App-Neustart / nächster Operation läuft recoverInterruptedRestore()
      await coordinator.recoverInterruptedRestore();

      // Beweis Fall 1: Da SQLite noch auf Stand A ist, hat Recovery `receipts_rollback`
      // automatisch nach `receipts` zurückgerollt!
      expect(await fileA.exists(), isTrue);
      expect(await fileA.readAsBytes(), equals(bytesA));
      expect(await fakePromotedFile.exists(), isFalse);
      expect(await rollbackDir.exists(), isFalse);
      expect(await File(p.join(tempDir.path, 'restore_journal.json')).exists(), isFalse);

      // Fall 2: Simulierter Prozessabbruch unmittelbar NACH erfolgreichem SQLite-Commit,
      // aber VOR `finalizeRestoreStaging()` (d.h. SQLite und `receipts/` sind bereits konsistent,
      // aber `receipts_rollback/` und `restore_journal.json` liegen noch auf der Platte).
      await rollbackDir.create(recursive: true);
      await File(p.join(rollbackDir.path, 'old_leftover.jpg')).writeAsBytes([9, 9, 9]);
      await receiptService.writeRestoreJournal(
        expectedReceiptPaths: [processedA.filePath],
      );

      await coordinator.recoverInterruptedRestore();

      // Beweis Fall 2: Da SQLite exakt mit dem Journal und den vorhandenen Dateien in `receipts/`
      // übereinstimmt, führt Recovery den Roll-Forward zu Ende und räumt `receipts_rollback` + Journal auf!
      expect(await fileA.exists(), isTrue);
      expect(await fileA.readAsBytes(), equals(bytesA));
      expect(await rollbackDir.exists(), isFalse);
      expect(await File(p.join(tempDir.path, 'restore_journal.json')).exists(), isFalse);
    });

    test('R3: restoreBackup weist verwaiste Belege (fehlende expenseId-Zuordnung), Nicht-Bild-Base64 und byteSize-Abweichungen mit BackupCorruptException zurück', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // Vorhandenen lokalen Zustand anlegen, der geschützt bleiben muss
      await seedCompleteTrip(db, 'Geschützter Lokal-Törn');

      final validJpeg = _createTestJpeg(width: 12, height: 12);
      final validB64 = base64Encode(validJpeg);

      // 1. Beleg mit expenseId 999, die in expenses nicht existiert (darf NICHT still übersprungen werden!)
      final unmappedExpensePayload = jsonEncode({
        'version': 3,
        'exportedAt': '2026-10-18T12:00:00.000Z',
        'trips': [
          {
            'trip': {
              'id': 1,
              'name': 'Unmapped Receipt Trip',
              'startDate': '2026-10-18T00:00:00.000Z',
              'daysCount': 7,
              'currency': 'EUR',
              'kittyModel': 'shared_kitty',
            },
            'expenses': [
              {
                'id': 10,
                'tripId': 1,
                'amount': 20.0,
                'category': 'provisions',
                'isPaidFromKitty': true,
              }
            ],
            'receipts': [
              {
                'id': 501,
                'tripId': 1,
                'expenseId': 999, // Existiert nicht in expenses!
                'fileName': 'orphan.jpg',
                'filePath': 'receipts/trip_1/expense_999/orphan.jpg',
                'byteSize': validJpeg.length,
                'imageBase64': validB64,
              }
            ],
          }
        ],
      });
      await backupService.backupData(unmappedExpensePayload);
      await expectLater(
        coordinator.restoreBackup(),
        throwsA(isA<BackupCorruptException>()),
      );

      // 2. Beleg mit gültigem Base64, das aber KEIN dekodierbares Bild ist (z.B. Textbytes)
      final nonImageBytes = utf8.encode('This is plain text, not a JPEG or PNG image');
      final nonImagePayload = jsonEncode({
        'version': 3,
        'exportedAt': '2026-10-18T12:00:00.000Z',
        'trips': [
          {
            'trip': {
              'id': 1,
              'name': 'Non Image Receipt Trip',
              'startDate': '2026-10-18T00:00:00.000Z',
              'daysCount': 7,
              'currency': 'EUR',
              'kittyModel': 'shared_kitty',
            },
            'expenses': [
              {
                'id': 10,
                'tripId': 1,
                'amount': 20.0,
                'category': 'provisions',
                'isPaidFromKitty': true,
              }
            ],
            'receipts': [
              {
                'id': 502,
                'tripId': 1,
                'expenseId': 10,
                'fileName': 'fake.jpg',
                'filePath': 'receipts/trip_1/expense_10/fake.jpg',
                'byteSize': nonImageBytes.length,
                'imageBase64': base64Encode(nonImageBytes),
              }
            ],
          }
        ],
      });
      await backupService.backupData(nonImagePayload);
      await expectLater(
        coordinator.restoreBackup(),
        throwsA(isA<BackupCorruptException>()),
      );

      // 3. Beleg mit gültigem Bild, dessen gespeicherte byteSize aber nicht zur tatsächlichen Datenlänge passt
      final sizeMismatchPayload = jsonEncode({
        'version': 3,
        'exportedAt': '2026-10-18T12:00:00.000Z',
        'trips': [
          {
            'trip': {
              'id': 1,
              'name': 'Size Mismatch Trip',
              'startDate': '2026-10-18T00:00:00.000Z',
              'daysCount': 7,
              'currency': 'EUR',
              'kittyModel': 'shared_kitty',
            },
            'expenses': [
              {
                'id': 10,
                'tripId': 1,
                'amount': 20.0,
                'category': 'provisions',
                'isPaidFromKitty': true,
              }
            ],
            'receipts': [
              {
                'id': 503,
                'tripId': 1,
                'expenseId': 10,
                'fileName': 'mismatch.jpg',
                'filePath': 'receipts/trip_1/expense_10/mismatch.jpg',
                'byteSize': validJpeg.length + 42, // Inkonsistente byteSize!
                'imageBase64': validB64,
              }
            ],
          }
        ],
      });
      await backupService.backupData(sizeMismatchPayload);
      await expectLater(
        coordinator.restoreBackup(),
        throwsA(isA<BackupCorruptException>()),
      );

      // Lokal geschützter Törn ist nach allen drei abgelehnten Restores unverändert vorhanden
      final localTrips = await db.tripDao.getAllTrips();
      expect(localTrips.length, equals(1));
      expect(localTrips.first.name, equals('Geschützter Lokal-Törn'));
    });

    test('Amendment 3 – Pflichttest A: finalizeRestoreStaging wirft nach erfolgreichem SQLite-Commit eine Exception -> Neuer DB-Stand und alle neuen Bilddateien bleiben erhalten, spätere Recovery bereinigt Artefakte', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // 1. Cloud-Stand B mit zwei Belegen anlegen und sichern
      final cloudTripId = await seedCompleteTrip(db, 'Neuer Cloud-Stand B');
      final cloudExpenses = await db.expenseDao.getExpensesForTrip(cloudTripId);
      final cloudExpenseId = cloudExpenses.first.id;

      final cloudBytes1 = _createTestJpeg(width: 20, height: 20);
      final cloudBytes2 = _createTestJpeg(width: 28, height: 28);

      final cloudFile1 = await receiptService.saveReceiptImage(
        tripId: cloudTripId,
        expenseId: cloudExpenseId,
        preferredFileName: 'cloud_b_1.jpg',
        imageBytes: cloudBytes1,
      );
      final cloudFile2 = await receiptService.saveReceiptImage(
        tripId: cloudTripId,
        expenseId: cloudExpenseId,
        preferredFileName: 'cloud_b_2.jpg',
        imageBytes: cloudBytes2,
      );

      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: cloudTripId,
          expenseId: cloudExpenseId,
          fileName: cloudFile1.fileName,
          filePath: cloudFile1.filePath,
          byteSize: Value(cloudFile1.byteSize),
          sortOrder: const Value(0),
          mimeType: const Value('image/jpeg'),
        ),
      );
      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: cloudTripId,
          expenseId: cloudExpenseId,
          fileName: cloudFile2.fileName,
          filePath: cloudFile2.filePath,
          byteSize: Value(cloudFile2.byteSize),
          sortOrder: const Value(1),
          mimeType: const Value('image/jpeg'),
        ),
      );

      final expectedCloudBytes1 = await File(p.join(tempDir.path, cloudFile1.filePath)).readAsBytes();
      final expectedCloudBytes2 = await File(p.join(tempDir.path, cloudFile2.filePath)).readAsBytes();

      expect(await coordinator.createBackup(), isTrue);

      // 2. Lokal auf dem Gerät einen abweichenden alten Stand A aufbauen
      await db.delete(db.expenseReceipts).go();
      await db.delete(db.expenses).go();
      await db.delete(db.trips).go();
      final activeDir = Directory(p.join(tempDir.path, 'receipts'));
      if (activeDir.existsSync()) {
        activeDir.deleteSync(recursive: true);
      }

      final oldTripId = await seedCompleteTrip(db, 'Alter Stand A');
      final oldExpenses = await db.expenseDao.getExpensesForTrip(oldTripId);
      final oldFile = await receiptService.saveReceiptImage(
        tripId: oldTripId,
        expenseId: oldExpenses.first.id,
        preferredFileName: 'old_a.jpg',
        imageBytes: _createTestJpeg(width: 10, height: 10),
      );
      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: oldTripId,
          expenseId: oldExpenses.first.id,
          fileName: oldFile.fileName,
          filePath: oldFile.filePath,
          byteSize: Value(oldFile.byteSize),
          mimeType: const Value('image/jpeg'),
        ),
      );

      // 3. Injiziere Fehler in `finalizeRestoreStaging` (erst NACH erfolgreichem SQLite-Commit!)
      receiptService.faultInjector = (op) {
        if (op == 'finalizeRestoreStaging') {
          throw const FileSystemException('Simulated failure during post-commit finalizeRestoreStaging');
        }
      };

      await expectLater(
        coordinator.restoreBackup(),
        throwsA(isA<FileSystemException>()),
      );
      receiptService.faultInjector = null;

      // 4. Beweis: Da SQLite bereits committet hat, wurden die alten Dateien NICHT wieder aktiviert!
      // Der neue Datenbankstand ("Neuer Cloud-Stand B") und sämtliche neuen Bilddateien sind vollständig erhalten!
      final tripsAfterFailedFinalize = await db.tripDao.getAllTrips();
      expect(tripsAfterFailedFinalize.length, equals(1));
      expect(tripsAfterFailedFinalize.single.name, equals('Neuer Cloud-Stand B'));

      final newTripId = tripsAfterFailedFinalize.single.id;
      final receiptsAfterFailedFinalize = await db.expenseDao.getReceiptsForTrip(newTripId);
      expect(receiptsAfterFailedFinalize.length, equals(2));

      final restoredFile1 = File(p.join(tempDir.path, receiptsAfterFailedFinalize[0].filePath));
      final restoredFile2 = File(p.join(tempDir.path, receiptsAfterFailedFinalize[1].filePath));
      expect(restoredFile1.existsSync(), isTrue);
      expect(restoredFile2.existsSync(), isTrue);
      expect(restoredFile1.readAsBytesSync(), equals(expectedCloudBytes1));
      expect(restoredFile2.readAsBytesSync(), equals(expectedCloudBytes2));

      // Alte Datei aus Stand A wurde NICHT in receipts/ zurückgeholt
      expect(File(p.join(tempDir.path, oldFile.filePath)).existsSync(), isFalse);

      // Rollback-Verzeichnis und Journal existieren noch wegen des Finalize-Fehlers
      expect(Directory(p.join(tempDir.path, 'receipts_rollback')).existsSync(), isTrue);
      expect(File(p.join(tempDir.path, 'restore_journal.json')).existsSync(), isTrue);

      // 5. Spätere Recovery bereinigt die verbleibenden Artefakte sicher (Roll-Forward),
      // während neuer DB-Stand und neue Bilddateien unversehrt bleiben.
      await coordinator.recoverInterruptedRestore();

      expect(Directory(p.join(tempDir.path, 'receipts_rollback')).existsSync(), isFalse);
      expect(File(p.join(tempDir.path, 'restore_journal.json')).existsSync(), isFalse);
      expect(restoredFile1.existsSync(), isTrue);
      expect(restoredFile2.existsSync(), isTrue);
      expect(restoredFile1.readAsBytesSync(), equals(expectedCloudBytes1));
      expect(restoredFile2.readAsBytesSync(), equals(expectedCloudBytes2));
      expect((await db.tripDao.getAllTrips()).single.name, equals('Neuer Cloud-Stand B'));
    });

    test('Amendment 3 – Finding A & B: App-Start-Recovery über appStartupRecoveryProvider ist einmalig, löst Pre-/Post-Commit-Crash auf und blockiert unklare Zustände ohne destruktive Operation', () async {
      await authService.loginWithEmail('owner@provy.app', newsletterOptIn: true);

      // Ausgangsstand aufbauen
      final tripId = await seedCompleteTrip(db, 'AppStart Recovery Törn');
      final expenses = await db.expenseDao.getExpensesForTrip(tripId);
      final processed = await receiptService.saveReceiptImage(
        tripId: tripId,
        expenseId: expenses.first.id,
        preferredFileName: 'startup.jpg',
        imageBytes: _createTestJpeg(width: 18, height: 18),
      );
      await db.expenseDao.addReceipt(
        ExpenseReceiptsCompanion.insert(
          tripId: tripId,
          expenseId: expenses.first.id,
          fileName: processed.fileName,
          filePath: processed.filePath,
          byteSize: Value(processed.byteSize),
          mimeType: const Value('image/jpeg'),
        ),
      );
      final origFile = File(p.join(tempDir.path, processed.filePath));
      final origBytes = origFile.readAsBytesSync();

      // 1. Einmalige Ausführung beim App-Start überprüfen (auch wenn mehrere Provider gelesen werden)
      final freshReceiptService1 = ReceiptFileService(docsDirProvider: () async => tempDir);
      final container1 = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          receiptFileServiceProvider.overrideWithValue(freshReceiptService1),
          hullqAuthServiceProvider.overrideWithValue(authService),
          hullqBackupServiceProvider.overrideWithValue(backupService),
        ],
      );
      addTearDown(container1.dispose);

      expect(freshReceiptService1.recoveryExecutionCount, equals(0));
      final loadedTrips = await container1.read(allTripsProvider.future);
      expect(loadedTrips.length, equals(1));
      expect(freshReceiptService1.isInitialRecoveryCompleted, isTrue);
      expect(freshReceiptService1.recoveryExecutionCount, equals(1));

      // Weitere Provider-Zugriffe innerhalb derselben App-Session führen Recovery NICHT mehrfach aus
      await container1.read(activeBoatProfilesProvider.future);
      await container1.read(tripByIdProvider(tripId).future);
      await container1.read(tripKittyDataProvider(tripId).future);
      expect(freshReceiptService1.recoveryExecutionCount, equals(1));

      // 2. App-Start nach Crash VOR SQLite-Commit (Pre-Commit):
      // Alte Dateien liegen in receipts_rollback/, Journal hat nicht-committeten Token 'uncommitted_token_99'
      final activeDir = Directory(p.join(tempDir.path, 'receipts'));
      final rollbackDir = Directory(p.join(tempDir.path, 'receipts_rollback'));
      activeDir.renameSync(rollbackDir.path);
      activeDir.createSync(recursive: true);
      final uncommittedFile = File(p.join(activeDir.path, 'trip_999', 'expense_999', 'uncommitted.jpg'));
      uncommittedFile.parent.createSync(recursive: true);
      uncommittedFile.writeAsBytesSync([7, 8, 9]);
      await freshReceiptService1.writeRestoreJournal(
        restoreToken: 'uncommitted_token_99',
        phase: 'promoting',
        previousReceiptPaths: [processed.filePath],
        expectedReceiptPaths: ['receipts/trip_999/expense_999/uncommitted.jpg'],
      );

      // Neuer App-Start (neuer ProviderContainer + frischer ReceiptFileService)
      final freshReceiptService2 = ReceiptFileService(docsDirProvider: () async => tempDir);
      final container2 = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          receiptFileServiceProvider.overrideWithValue(freshReceiptService2),
          hullqAuthServiceProvider.overrideWithValue(authService),
          hullqBackupServiceProvider.overrideWithValue(backupService),
        ],
      );
      addTearDown(container2.dispose);

      // Das Lesen von allTripsProvider triggert automatisch zuerst appStartupRecoveryProvider -> Roll-Back!
      final tripsAfterPreCommitCrash = await container2.read(allTripsProvider.future);
      expect(tripsAfterPreCommitCrash.single.name, equals('AppStart Recovery Törn'));
      expect(origFile.existsSync(), isTrue);
      expect(origFile.readAsBytesSync(), equals(origBytes));
      expect(uncommittedFile.existsSync(), isFalse);
      expect(rollbackDir.existsSync(), isFalse);
      expect(File(p.join(tempDir.path, 'restore_journal.json')).existsSync(), isFalse);

      // 3. App-Start nach Crash NACH SQLite-Commit, aber VOR Finalisierung (Post-Commit):
      // SQLite hat `_provy_restore_state` mit Token 'committed_token_100', neue Datei liegt in receipts/,
      // aber receipts_rollback/ und restore_journal.json sind noch vorhanden.
      await db.customStatement(
        'CREATE TABLE IF NOT EXISTS _provy_restore_state ('
        'id INTEGER PRIMARY KEY CHECK (id = 1), '
        'restore_token TEXT NOT NULL, '
        'committed_at TEXT NOT NULL'
        ')',
      );
      await db.customStatement(
        'INSERT OR REPLACE INTO _provy_restore_state (id, restore_token, committed_at) VALUES (1, ?, ?)',
        ['committed_token_100', DateTime.now().toIso8601String()],
      );
      rollbackDir.createSync(recursive: true);
      File(p.join(rollbackDir.path, 'stale_old.jpg')).writeAsBytesSync([1, 1, 1]);
      await freshReceiptService2.writeRestoreJournal(
        restoreToken: 'committed_token_100',
        phase: 'promoting',
        previousReceiptPaths: ['receipts/trip_1/expense_1/stale_old.jpg'],
        expectedReceiptPaths: [processed.filePath],
      );

      final freshReceiptService3 = ReceiptFileService(docsDirProvider: () async => tempDir);
      final container3 = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          receiptFileServiceProvider.overrideWithValue(freshReceiptService3),
          hullqAuthServiceProvider.overrideWithValue(authService),
          hullqBackupServiceProvider.overrideWithValue(backupService),
        ],
      );
      addTearDown(container3.dispose);

      final tripsAfterPostCommitCrash = await container3.read(allTripsProvider.future);
      expect(tripsAfterPostCommitCrash.single.name, equals('AppStart Recovery Törn'));
      expect(origFile.existsSync(), isTrue);
      expect(origFile.readAsBytesSync(), equals(origBytes));
      expect(rollbackDir.existsSync(), isFalse);
      expect(File(p.join(tempDir.path, 'restore_journal.json')).existsSync(), isFalse);

      // 4. Unklarer / nicht eindeutig sicher auflösbarer Zustand nach Crash:
      // `receipts_rollback/` existiert mit einer Datei, aber `restore_journal.json` ist korrupt.
      // Weder Roll-Back noch Roll-Forward darf blind ausgeführt werden; keine destruktive Operation!
      rollbackDir.createSync(recursive: true);
      final protectedRollbackFile = File(p.join(rollbackDir.path, 'protected_rollback.jpg'));
      protectedRollbackFile.writeAsBytesSync([4, 5, 6]);
      final corruptJournalFile = File(p.join(tempDir.path, 'restore_journal.json'));
      corruptJournalFile.writeAsStringSync('{not-valid-json');

      final freshReceiptService4 = ReceiptFileService(docsDirProvider: () async => tempDir);
      final container4 = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          receiptFileServiceProvider.overrideWithValue(freshReceiptService4),
          hullqAuthServiceProvider.overrideWithValue(authService),
          hullqBackupServiceProvider.overrideWithValue(backupService),
        ],
      );
      addTearDown(container4.dispose);

      // Sowohl App-Start-Provider als auch Daten-Provider und Services melden explizit RestoreRecoveryException
      await expectLater(
        container4.read(appStartupRecoveryProvider.future),
        throwsA(isA<RestoreRecoveryException>()),
      );
      await expectLater(
        container4.read(allTripsProvider.future),
        throwsA(isA<RestoreRecoveryException>()),
      );
      await expectLater(
        container4.read(tripKittyDataProvider(tripId).future),
        throwsA(isA<RestoreRecoveryException>()),
      );
      await expectLater(
        container4.read(backupCoordinatorProvider).createBackup(),
        throwsA(isA<RestoreRecoveryException>()),
      );

      // Keine destruktive Operation wurde ausgeführt: sowohl aktive Datei als auch Rollback-Datei sind unversehrt!
      expect(origFile.existsSync(), isTrue);
      expect(origFile.readAsBytesSync(), equals(origBytes));
      expect(protectedRollbackFile.existsSync(), isTrue);
      expect(protectedRollbackFile.readAsBytesSync(), equals([4, 5, 6]));
    });
  });
}

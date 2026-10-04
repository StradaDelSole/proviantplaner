import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/hullq_api_client.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/hullq_backup_service.dart';

/// Fake-API-Client für B2-Tests
class FakeHullqApiClient implements HullqApiClient {
  final List<Map<String, dynamic>> uploadedBackups = [];
  final Map<String, String> backupContents = {};
  bool failUpload = false;

  @override
  Future<Map<String, dynamic>> getMe(String token) async {
    return {'account': {'id': 'acc-1'}};
  }

  @override
  Future<Map<String, dynamic>> updateConsent(String token, {required bool granted, required String textVersion}) async {
    return {'success': true};
  }

  @override
  Future<void> deleteMe(String token) async {}

  @override
  Future<Map<String, dynamic>> uploadBackup(String token, {required String deviceId, required String content}) async {
    if (failUpload) {
      throw const HullqApiException(statusCode: 500, code: 'SERVER_ERROR', message: 'Upload failed');
    }
    final id = 'backup-${uploadedBackups.length + 1}';
    final metadata = {
      'id': id,
      'device_id': deviceId,
      'size': utf8.encode(content).length,
      'created_at': DateTime.now().toIso8601String(),
    };
    uploadedBackups.insert(0, metadata);
    backupContents[id] = content;
    return {'success': true, 'backup': metadata};
  }

  @override
  Future<List<Map<String, dynamic>>> getBackups(String token) async {
    return List.from(uploadedBackups);
  }

  @override
  Future<String> downloadBackup(String token, String backupId) async {
    final content = backupContents[backupId];
    if (content == null) {
      throw const HullqApiException(statusCode: 404, code: 'BACKUP_NOT_FOUND', message: 'Not found');
    }
    return content;
  }
}

/// Fake-Auth-Service für B2-Tests
class FakeHullqAuthService implements HullqAuthService {
  String? token = 'valid-jwt-token';
  HullqMembershipStatus status = HullqMembershipStatus.member;

  @override
  bool get lastNewsletterConsent => true;

  @override
  Future<HullqMembershipStatus> getMembershipStatus() async => status;

  @override
  Future<String?> getAuthToken() async => token;

  @override
  Future<String?> getUserEmail() async => 'test@example.com';

  @override
  Future<bool> loginWithEmail(String email, {required bool newsletterOptIn}) async => true;

  @override
  Future<bool> loginWithApple({required bool newsletterOptIn}) async => true;

  @override
  Future<bool> loginWithGoogle({required bool newsletterOptIn}) async => true;

  @override
  Future<void> logout() async {
    token = null;
    status = HullqMembershipStatus.trial;
  }

  @override
  Future<void> deleteAccount() async {
    token = null;
    status = HullqMembershipStatus.trial;
  }
}

void main() {
  group('B2: HttpHullqBackupService & Cloud-Sicherung', () {
    late FakeHullqApiClient apiClient;
    late FakeHullqAuthService authService;
    late HttpHullqBackupService backupService;

    setUp(() {
      apiClient = FakeHullqApiClient();
      authService = FakeHullqAuthService();
      backupService = HttpHullqBackupService(
        apiClient: apiClient,
        authService: authService,
        deviceId: 'device-test-1',
      );
    });

    test('backupData und restoreData funktionieren mit echtem API-Client', () async {
      const payload = '{"trips": [{"name": "Ostsee 2026"}]}';

      final success = await backupService.backupData(payload);
      expect(success, isTrue);
      expect(apiClient.uploadedBackups.length, 1);
      expect(apiClient.uploadedBackups.first['device_id'], 'device-test-1');

      final restored = await backupService.restoreData();
      expect(restored, payload);

      final timestamp = await backupService.getLastBackupTimestamp();
      expect(timestamp, isNotNull);
    });

    test('Nicht angemeldeter Nutzer kann weder sichern noch wiederherstellen', () async {
      authService.token = null;

      final success = await backupService.backupData('{"trips": []}');
      expect(success, isFalse);

      final restored = await backupService.restoreData();
      expect(restored, isNull);

      final timestamp = await backupService.getLastBackupTimestamp();
      expect(timestamp, isNull);
    });

    test('Serverfehler beim Upload wird sauber als false behandelt', () async {
      apiClient.failUpload = true;

      final success = await backupService.backupData('{"trips": []}');
      expect(success, isFalse);
    });
  });

  group('B2: BackupCoordinator Integration & Datenschutz (keine IBANs)', () {
    late AppDatabase db;
    late FakeHullqApiClient apiClient;
    late FakeHullqAuthService authService;
    late HttpHullqBackupService backupService;
    late BackupCoordinator coordinator;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      apiClient = FakeHullqApiClient();
      authService = FakeHullqAuthService();
      backupService = HttpHullqBackupService(
        apiClient: apiClient,
        authService: authService,
      );
      coordinator = BackupCoordinator(
        db: db,
        backupService: backupService,
        authService: authService,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Sicherung enthält alle FB2-B-Felder (Tiefkühlfach, Wassertank) und keine IBANs', () async {
      // Törn mit FB2-B Feldern anlegen
      await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'FB2 Törn',
          startDate: DateTime(2026, 7, 1),
          daysCount: const Value(7),
          fridgeCapacity: const Value(80),
          hasFreezer: const Value(true),
          freezerCapacity: const Value(15),
          waterTankLiters: const Value(120),
          isWaterTankDrinkable: const Value(true),
        ),
      );

      // Sicherung erstellen
      final created = await coordinator.createBackup();
      expect(created, isTrue);
      expect(apiClient.uploadedBackups.length, 1);

      final backupJson = apiClient.backupContents.values.first;
      final decoded = jsonDecode(backupJson) as Map<String, dynamic>;
      final tripsList = decoded['trips'] as List<dynamic>;
      expect(tripsList.length, 1);

      final tMap = (tripsList.first as Map<String, dynamic>)['trip'] as Map<String, dynamic>;
      expect(tMap['name'], 'FB2 Törn');
      expect(tMap['hasFreezer'], isTrue);
      expect(tMap['freezerCapacity'], 15);
      expect(tMap['waterTankLiters'], 120);
      expect(tMap['isWaterTankDrinkable'], isTrue);

      // Datenschutzprüfung: Es darf kein IBAN-Feld und kein IBAN-Pattern im JSON sein
      expect(backupJson.contains('"iban"'), isFalse);
      expect(backupJson.contains('DE89'), isFalse);
      final ibanPattern = RegExp(r'[A-Z]{2}\d{2}[A-Z0-9]{11,30}');
      expect(ibanPattern.hasMatch(backupJson.replaceAll('-', '')), isFalse);

      // Wiederherstellung in neue/bereinigte Datenbank testen
      final restoreSuccess = await coordinator.restoreBackup();
      expect(restoreSuccess, isTrue);

      final restoredTrips = await db.tripDao.getAllTrips();
      expect(restoredTrips.length, 1);
      final restoredTrip = restoredTrips.first;
      expect(restoredTrip.name, 'FB2 Törn');
      expect(restoredTrip.hasFreezer, isTrue);
      expect(restoredTrip.freezerCapacity, 15);
      expect(restoredTrip.waterTankLiters, 120);
      expect(restoredTrip.isWaterTankDrinkable, isTrue);
    });
  });
}

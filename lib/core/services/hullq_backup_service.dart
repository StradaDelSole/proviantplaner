/// Interface für die HullQ-Datensicherung (nur für Mitglieder).
/// Technische Leitplanke: Anbindung nur über dieses Interface bis zur echten API.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'hullq_api_client.dart';
import 'hullq_auth_service.dart';

/// Schnittstelle für die Cloud-Datensicherung der Törns laut PRD.
abstract class HullqBackupService {
  /// Sichert den JSON-kodierten Datensatz aller Törns.
  Future<bool> backupData(String jsonData);

  /// Stellt den zuletzt gesicherten Datensatz wieder her.
  Future<String?> restoreData();

  /// Gibt den Zeitstempel der letzten erfolgreichen Sicherung zurück.
  Future<DateTime?> getLastBackupTimestamp();

  /// Löscht die gesicherten Daten (z. B. bei Konto-Löschung).
  Future<void> clearBackup();
}

/// Echte R2-Cloud-Datensicherung über das Planer-Backend (Cloudflare Worker).
class HttpHullqBackupService implements HullqBackupService {
  final HullqApiClient _apiClient;
  final HullqAuthService _authService;
  final String deviceId;

  DateTime? _cachedLastBackupTimestamp;

  HttpHullqBackupService({
    required HullqApiClient apiClient,
    required HullqAuthService authService,
    String? deviceId,
  })  : _apiClient = apiClient,
        _authService = authService,
        deviceId = deviceId ?? 'flutter-app';

  @override
  Future<bool> backupData(String jsonData) async {
    final token = await _authService.getAuthToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final res = await _apiClient.uploadBackup(
        token,
        deviceId: deviceId,
        content: jsonData,
      );
      final backup = res['backup'] as Map<String, dynamic>?;
      if (backup != null && backup['created_at'] != null) {
        _cachedLastBackupTimestamp = DateTime.tryParse(backup['created_at'] as String);
      } else {
        _cachedLastBackupTimestamp = DateTime.now();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> restoreData() async {
    final token = await _authService.getAuthToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final backups = await _apiClient.getBackups(token);
      if (backups.isEmpty) {
        return null;
      }

      final latest = backups.first;
      final latestId = latest['id'] as String;
      if (latest['created_at'] != null) {
        _cachedLastBackupTimestamp = DateTime.tryParse(latest['created_at'] as String);
      }
      return await _apiClient.downloadBackup(token, latestId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DateTime?> getLastBackupTimestamp() async {
    if (_cachedLastBackupTimestamp != null) {
      return _cachedLastBackupTimestamp;
    }

    final token = await _authService.getAuthToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final backups = await _apiClient.getBackups(token);
      if (backups.isEmpty) {
        return null;
      }
      final createdAtStr = backups.first['created_at'] as String?;
      if (createdAtStr == null || createdAtStr.isEmpty) {
        return null;
      }
      _cachedLastBackupTimestamp = DateTime.tryParse(createdAtStr);
      return _cachedLastBackupTimestamp;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearBackup() async {
    _cachedLastBackupTimestamp = null;
  }
}

/// Mock-Implementierung des [HullqBackupService] für lokale Tests und S8.
/// Speichert die Daten verschlüsselt in [FlutterSecureStorage], um echte
/// Cloud-Persistenz über App- und Datenbank-Neustarts hinweg zu simulieren.
class MockHullqBackupService implements HullqBackupService {
  final FlutterSecureStorage _storage;

  static const String keyBackupData = 'hullq_backup_data';
  static const String keyBackupTimestamp = 'hullq_backup_timestamp';

  MockHullqBackupService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<bool> backupData(String jsonData) async {
    await _storage.write(key: keyBackupData, value: jsonData);
    await _storage.write(
      key: keyBackupTimestamp,
      value: DateTime.now().toIso8601String(),
    );
    return true;
  }

  @override
  Future<String?> restoreData() async {
    return _storage.read(key: keyBackupData);
  }

  @override
  Future<DateTime?> getLastBackupTimestamp() async {
    final str = await _storage.read(key: keyBackupTimestamp);
    if (str == null || str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  @override
  Future<void> clearBackup() async {
    await _storage.delete(key: keyBackupData);
    await _storage.delete(key: keyBackupTimestamp);
  }
}
/// Interface für die HullQ-Datensicherung (nur für Mitglieder).
/// Technische Leitplanke: Anbindung nur über dieses Interface bis zur echten API.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
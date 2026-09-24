/// Interface für die HullQ-Datensicherung (nur für Mitglieder).
/// Technische Leitplanke: Anbindung nur über dieses Interface bis zur echten API.
abstract class HullqBackupService {
  Future<bool> backupData(String jsonData);
  Future<String?> restoreData();
  Future<DateTime?> getLastBackupTimestamp();
}

/// Mock-Implementierung des [HullqBackupService] für lokale Tests und Slices vor S8.
class MockHullqBackupService implements HullqBackupService {
  String? _storedData;
  DateTime? _lastBackup;

  @override
  Future<bool> backupData(String jsonData) async {
    _storedData = jsonData;
    _lastBackup = DateTime.now();
    return true;
  }

  @override
  Future<String?> restoreData() async {
    return _storedData;
  }

  @override
  Future<DateTime?> getLastBackupTimestamp() async {
    return _lastBackup;
  }
}
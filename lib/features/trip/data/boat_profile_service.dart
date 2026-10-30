/// Service für Verwaltung wiederverwendbarer Bootsprofile (PIVOT3-A).
library;

import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';

/// Verwaltet Bootsprofile (CRUD, Archivierung, Löschung).
class BoatProfileService {
  final BoatProfileDao boatProfileDao;
  final ReceiptFileService receiptFileService;

  BoatProfileService({
    required this.boatProfileDao,
    ReceiptFileService? receiptFileService,
  }) : receiptFileService = receiptFileService ?? ReceiptFileService();

  Future<void> _ensureStorageRecovered() async {
    await BackupCoordinator.recoverStorageState(
      db: boatProfileDao.attachedDatabase,
      receiptFileService: receiptFileService,
    );
  }

  /// Legt ein neues Bootsprofil an.
  Future<int> createProfile({
    required String name,
    String? manufacturer,
    String? model,
    int fridgeCapacity = 100,
    bool hasFreezer = false,
    int freezerCapacity = 0,
    int waterTankLiters = 0,
    bool isWaterTankDrinkable = false,
    bool hasWatermaker = false,
  }) async {
    await _ensureStorageRecovered();
    return boatProfileDao.createProfile(
      BoatProfilesCompanion.insert(
        name: name,
        manufacturer: Value(manufacturer),
        model: Value(model),
        fridgeCapacity: Value(fridgeCapacity),
        hasFreezer: Value(hasFreezer),
        freezerCapacity: Value(freezerCapacity),
        waterTankLiters: Value(waterTankLiters),
        isWaterTankDrinkable: Value(isWaterTankDrinkable),
        hasWatermaker: Value(hasWatermaker),
      ),
    );
  }

  /// Lädt ein Bootsprofil anhand seiner ID.
  Future<BoatProfile?> getProfileById(int id) async {
    await _ensureStorageRecovered();
    return boatProfileDao.getProfileById(id);
  }

  /// Liefert alle aktiven (nicht archivierten) Profile für die Auswahl.
  Future<List<BoatProfile>> getActiveProfiles() async {
    await _ensureStorageRecovered();
    return boatProfileDao.getAllProfiles(includeArchived: false);
  }

  /// Liefert alle Profile, optional inklusive archivierter.
  Future<List<BoatProfile>> getAllProfiles({bool includeArchived = false}) async {
    await _ensureStorageRecovered();
    return boatProfileDao.getAllProfiles(includeArchived: includeArchived);
  }

  /// Aktualisiert ein bestehendes Bootsprofil.
  Future<bool> updateProfile(BoatProfile profile) async {
    await _ensureStorageRecovered();
    return boatProfileDao.updateProfile(profile);
  }

  /// Archiviert oder de-archiviert ein Profil.
  Future<bool> archiveProfile(int id, {bool archive = true}) async {
    await _ensureStorageRecovered();
    final profile = await boatProfileDao.getProfileById(id);
    if (profile == null) return false;
    return boatProfileDao.updateProfile(profile.copyWith(isArchived: archive));
  }

  /// Löscht ein Bootsprofil.
  /// Hinweis: SQLite setzt verknüpfte trips.boatProfileId über onDelete: KeyAction.setNull auf NULL.
  /// Die Snapshot-Werte der historischen Törns bleiben dabei vollständig erhalten.
  Future<int> deleteProfile(int id) async {
    await _ensureStorageRecovered();
    return boatProfileDao.deleteProfile(id);
  }
}

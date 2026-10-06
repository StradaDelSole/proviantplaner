/// Service für Verwaltung wiederverwendbarer Bootsprofile (PIVOT3-A).
library;

import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';

/// Verwaltet Bootsprofile (CRUD, Archivierung, Löschung).
class BoatProfileService {
  final BoatProfileDao boatProfileDao;

  BoatProfileService({required this.boatProfileDao});

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
  }) {
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
  Future<BoatProfile?> getProfileById(int id) {
    return boatProfileDao.getProfileById(id);
  }

  /// Liefert alle aktiven (nicht archivierten) Profile für die Auswahl.
  Future<List<BoatProfile>> getActiveProfiles() {
    return boatProfileDao.getAllProfiles(includeArchived: false);
  }

  /// Liefert alle Profile, optional inklusive archivierter.
  Future<List<BoatProfile>> getAllProfiles({bool includeArchived = false}) {
    return boatProfileDao.getAllProfiles(includeArchived: includeArchived);
  }

  /// Aktualisiert ein bestehendes Bootsprofil.
  Future<bool> updateProfile(BoatProfile profile) {
    return boatProfileDao.updateProfile(profile);
  }

  /// Archiviert oder de-archiviert ein Profil.
  Future<bool> archiveProfile(int id, {bool archive = true}) async {
    final profile = await boatProfileDao.getProfileById(id);
    if (profile == null) return false;
    return boatProfileDao.updateProfile(profile.copyWith(isArchived: archive));
  }

  /// Löscht ein Bootsprofil.
  /// Hinweis: SQLite setzt verknüpfte trips.boatProfileId über onDelete: KeyAction.setNull auf NULL.
  /// Die Snapshot-Werte der historischen Törns bleiben dabei vollständig erhalten.
  Future<int> deleteProfile(int id) {
    return boatProfileDao.deleteProfile(id);
  }
}


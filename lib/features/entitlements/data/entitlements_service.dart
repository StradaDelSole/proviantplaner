/// Service zur Verwaltung von Berechtigungen und Törn-Freischaltungen (Slice S6).
library;

import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import '../domain/entitlements.dart';

/// Service zur Prüfung von Freischaltungen und Törn-Grenzen.
class EntitlementsService {
  final HullqAuthService authService;
  final TripDao tripDao;
  final EntitlementsManager manager;
  TripCodePass? _activePass;

  EntitlementsService({
    required this.authService,
    required this.tripDao,
    this.manager = const EntitlementsManager(),
  });

  /// Gibt den aktuell hinterlegten Törn-Pass zurück (falls vorhanden).
  TripCodePass? get activePass => _activePass;

  /// Ermittelt die aktuelle Freischaltstufe des Benutzers.
  Future<EntitlementLevel> getEntitlementLevel() async {
    final status = await authService.getMembershipStatus();
    return switch (status) {
      HullqMembershipStatus.trial => EntitlementLevel.trial,
      HullqMembershipStatus.member => EntitlementLevel.member,
      HullqMembershipStatus.pro => EntitlementLevel.pro,
    };
  }

  /// Zählt die aktuell in der Datenbank vorhandenen Törns.
  Future<int> getTripCount() async {
    final trips = await tripDao.getAllTrips();
    return trips.length;
  }

  /// Prüft, ob ein weiterer Törn angelegt werden darf.
  Future<bool> canCreateNewTrip() async {
    final level = await getEntitlementLevel();
    final count = await getTripCount();
    return manager.canCreateTrip(
      level: level,
      currentTripCount: count,
      tripPass: _activePass,
    );
  }

  /// Prüft den Zugriff auf ein bestimmtes Feature.
  Future<bool> canAccessFeature(AppFeature feature, {int? targetTripId}) async {
    final level = await getEntitlementLevel();
    final count = await getTripCount();
    return manager.canAccessFeature(
      feature: feature,
      level: level,
      currentTripCount: count,
      targetTripId: targetTripId,
      tripPass: _activePass,
    );
  }

  /// Aktiviert einen zeitlich begrenzten Törn-Pass über einen Code (v1.1 Vorbereitung).
  Future<bool> redeemTripCode(String code, {int? targetTripId}) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return false;

    // Erkennung des Codes
    if (trimmed.startsWith('PRO')) {
      _activePass = TripCodePass(
        code: trimmed,
        tripId: targetTripId,
        validUntil: DateTime.now().add(const Duration(days: 30)),
        grantedLevel: EntitlementLevel.pro,
      );
      return true;
    }

    if (trimmed.startsWith('MEMBER') || trimmed.startsWith('TOERN') || trimmed.startsWith('TRIP')) {
      _activePass = TripCodePass(
        code: trimmed,
        tripId: targetTripId,
        validUntil: DateTime.now().add(const Duration(days: 14)),
        grantedLevel: EntitlementLevel.member,
      );
      return true;
    }

    return false;
  }

  /// Entfernt den aktiven Pass.
  void clearTripPass() {
    _activePass = null;
  }
}

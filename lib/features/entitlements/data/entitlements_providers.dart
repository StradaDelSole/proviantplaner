/// Riverpod Provider für Freischaltungen und Berechtigungen (Slice S6).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import '../domain/entitlements.dart';
import 'entitlements_service.dart';

/// Provider für den HullQ-Authentifizierungsdienst (Mock bis zur echten API).
final hullqAuthServiceProvider = Provider<HullqAuthService>((ref) {
  return MockHullqAuthService();
});

/// Provider für den EntitlementsService.
final entitlementsServiceProvider = Provider<EntitlementsService>((ref) {
  final auth = ref.watch(hullqAuthServiceProvider);
  final db = ref.watch(databaseProvider);
  return EntitlementsService(
    authService: auth,
    tripDao: db.tripDao,
  );
});

/// Prüft, ob der Nutzer einen weiteren Törn anlegen darf.
final canCreateTripProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(entitlementsServiceProvider);
  return service.canCreateNewTrip();
});

/// Aktuelle Freischaltungsstufe des Nutzers (trial, member, pro).
final entitlementLevelProvider = FutureProvider<EntitlementLevel>((ref) async {
  final service = ref.watch(entitlementsServiceProvider);
  return service.getEntitlementLevel();
});

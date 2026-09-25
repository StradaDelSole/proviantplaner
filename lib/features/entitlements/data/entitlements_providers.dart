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

/// Zustand des HullQ-Authentifizierungsdienstes (Slice S7).
class AuthState {
  final HullqMembershipStatus status;
  final String? email;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.email,
    this.isLoading = false,
  });

  bool get isLoggedIn => status != HullqMembershipStatus.trial;
  bool get isMember => status == HullqMembershipStatus.member;
  bool get isPro => status == HullqMembershipStatus.pro;
}

/// StateNotifier für die HullQ-Authentifizierung.
class AuthNotifier extends StateNotifier<AuthState> {
  final HullqAuthService _authService;

  AuthNotifier(this._authService)
      : super(const AuthState(status: HullqMembershipStatus.trial, isLoading: true)) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final status = await _authService.getMembershipStatus();
    final email = await _authService.getUserEmail();
    state = AuthState(status: status, email: email, isLoading: false);
  }

  /// Aktualisiert den Zustand aus dem AuthService.
  Future<void> refresh() async {
    final status = await _authService.getMembershipStatus();
    final email = await _authService.getUserEmail();
    state = AuthState(status: status, email: email, isLoading: false);
  }

  /// Meldet mit E-Mail an.
  Future<bool> loginWithEmail(String email, {required bool newsletterOptIn}) async {
    final success = await _authService.loginWithEmail(email, newsletterOptIn: newsletterOptIn);
    if (success) {
      await refresh();
    }
    return success;
  }

  /// Meldet mit Apple an.
  Future<bool> loginWithApple({required bool newsletterOptIn}) async {
    final success = await _authService.loginWithApple(newsletterOptIn: newsletterOptIn);
    if (success) {
      await refresh();
    }
    return success;
  }

  /// Meldet mit Google an.
  Future<bool> loginWithGoogle({required bool newsletterOptIn}) async {
    final success = await _authService.loginWithGoogle(newsletterOptIn: newsletterOptIn);
    if (success) {
      await refresh();
    }
    return success;
  }

  /// Meldet den Benutzer ab.
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: HullqMembershipStatus.trial, email: null, isLoading: false);
  }

  /// Löscht das Konto und alle Anmeldedaten.
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    state = const AuthState(status: HullqMembershipStatus.trial, email: null, isLoading: false);
  }
}

/// Provider für den AuthNotifier.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = ref.watch(hullqAuthServiceProvider);
  return AuthNotifier(auth);
});

/// Aktueller Status der HullQ-Mitgliedschaft (offline-tolerant).
final authStatusProvider = Provider<HullqMembershipStatus>((ref) {
  return ref.watch(authNotifierProvider).status;
});

/// Gespeicherte E-Mail-Adresse des angemeldeten Benutzers.
final userEmailProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).email;
});

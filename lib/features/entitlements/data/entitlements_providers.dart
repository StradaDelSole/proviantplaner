/// Riverpod Provider für Freischaltungen und Berechtigungen (Slice S6 & BC-1A).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proviantplaner/core/config/feature_flags.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/auth0_adapter.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import '../domain/entitlements.dart';
import 'entitlements_service.dart';

import 'package:proviantplaner/core/services/hullq_api_client.dart';

/// Provider für den Feature-Flag zur Törn-Code-Einlöseoberfläche (v1.1).
///
/// In Version 1.0 standardmäßig deaktiviert (false).
final tripCodeFeatureFlagProvider = Provider<bool>((ref) {
  return FeatureFlags.enableTripCodePasses;
});

/// Provider für den API-Client des Planer-Backends.
final hullqApiClientProvider = Provider<HullqApiClient>((ref) {
  return HttpHullqApiClient();
});

/// Provider für den Auth0Adapter (Slice BC-1A).
final auth0AdapterProvider = Provider<Auth0Adapter>((ref) {
  return NativeAuth0Adapter();
});

/// Provider für den HullQ-Authentifizierungsdienst (Slice B1 & BC-1A: Auth0HullqAuthService).
final hullqAuthServiceProvider = Provider<HullqAuthService>((ref) {
  final apiClient = ref.watch(hullqApiClientProvider);
  final auth0Adapter = ref.watch(auth0AdapterProvider);
  return Auth0HullqAuthService(
    apiClient: apiClient,
    auth0Adapter: auth0Adapter,
  );
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

/// Zustand des HullQ-Authentifizierungsdienstes (Slice S7 & BC-1A).
class AuthState {
  final HullqMembershipStatus status;
  final String? email;
  final bool isLoading;
  final bool isAuthenticated;

  const AuthState({
    required this.status,
    this.email,
    this.isLoading = false,
    this.isAuthenticated = false,
  });

  bool get isLoggedIn => isAuthenticated || status != HullqMembershipStatus.trial;
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
    final isAuth = await _authService.isAuthenticated();
    state = AuthState(
      status: status,
      email: email,
      isLoading: false,
      isAuthenticated: isAuth,
    );
  }

  /// Aktualisiert den Zustand aus dem AuthService.
  Future<void> refresh() async {
    final status = await _authService.getMembershipStatus();
    final email = await _authService.getUserEmail();
    final isAuth = await _authService.isAuthenticated();
    state = AuthState(
      status: status,
      email: email,
      isLoading: false,
      isAuthenticated: isAuth,
    );
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
    state = const AuthState(
      status: HullqMembershipStatus.trial,
      email: null,
      isLoading: false,
      isAuthenticated: false,
    );
  }

  /// Löscht das Konto und alle Anmeldedaten.
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    state = const AuthState(
      status: HullqMembershipStatus.trial,
      email: null,
      isLoading: false,
      isAuthenticated: false,
    );
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

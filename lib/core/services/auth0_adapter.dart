/// Adapter für die native Auth0-Authentifizierung (Slice BC-1A).
library;

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/auth0_config.dart';

/// Schnittstelle für die Auth0-Authentifizierung.
///
/// Entkoppelt die native Auth0-SDK-Implementierung von der Anwendungslogik,
/// um deterministische Tests und plattformspezifische Absicherung zu ermöglichen.
abstract class Auth0Adapter {
  /// Startet den Auth0 Universal Login Flow via WebAuthentication.
  ///
  /// Gibt [Credentials] bei Erfolg zurück, oder `null` wenn der Login
  /// abgebrochen wurde (User Cancelled) oder fehlschlägt.
  Future<Credentials?> login({
    String? connection,
    String? loginHint,
    String? customScheme,
    String? audience,
    Set<String> scopes = const {
      'openid',
      'profile',
      'email',
      'offline_access',
    },
  });

  /// Führt den Auth0 Logout durch und bereinigt die Session.
  Future<void> logout({String? customScheme});

  /// Ruft gespeicherte [Credentials] aus dem CredentialsManager ab.
  Future<Credentials?> getCredentials();

  /// Erneuert die Credentials via Refresh Token.
  Future<Credentials?> renewCredentials();

  /// Prüft, ob gültige Credentials vorhanden sind.
  Future<bool> hasValidCredentials({int minTtl = 0});

  /// Löscht gespeicherte Credentials aus dem CredentialsManager.
  Future<void> clearCredentials();
}

/// Produktionsreife native Implementierung des [Auth0Adapter] mit dem offiziellen
/// auth0_flutter SDK (v2.7.x).
class NativeAuth0Adapter implements Auth0Adapter {
  final Auth0Config config;
  late final Auth0? _auth0;

  NativeAuth0Adapter({this.config = Auth0Config.standard}) {
    if (config.domain.isNotEmpty && config.clientId.isNotEmpty) {
      _auth0 = Auth0(config.domain, config.clientId);
    } else {
      _auth0 = null;
    }
  }

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<Credentials?> login({
    String? connection,
    String? loginHint,
    String? customScheme,
    String? audience,
    Set<String> scopes = const {
      'openid',
      'profile',
      'email',
      'offline_access',
    },
  }) async {
    final client = _auth0;
    if (!_isSupportedPlatform || client == null) {
      // Nicht unterstützte Plattform oder unkonfigurierter Client: fail-closed
      return null;
    }

    try {
      final Map<String, String> parameters = {};
      if (connection != null && connection.isNotEmpty) {
        parameters['connection'] = connection;
      }
      if (loginHint != null && loginHint.isNotEmpty) {
        parameters['login_hint'] = loginHint;
      }

      final scheme = defaultTargetPlatform == TargetPlatform.android
          ? (customScheme ?? config.customScheme)
          : null;

      final credentials = await client
          .webAuthentication(scheme: scheme)
          .login(
            audience: audience ?? (config.audience.isNotEmpty ? config.audience : null),
            scopes: scopes,
            parameters: parameters,
          );
      return credentials;
    } on WebAuthenticationException catch (e) {
      if (e.isUserCancelledException) {
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout({String? customScheme}) async {
    final client = _auth0;
    if (!_isSupportedPlatform || client == null) {
      return;
    }
    try {
      final scheme = defaultTargetPlatform == TargetPlatform.android
          ? (customScheme ?? config.customScheme)
          : null;
      await client.webAuthentication(scheme: scheme).logout();
    } catch (_) {
      // Best-effort remote logout
    }
    try {
      await client.credentialsManager.clearCredentials();
    } catch (_) {}
  }

  @override
  Future<Credentials?> getCredentials() async {
    final client = _auth0;
    if (!_isSupportedPlatform || client == null) return null;
    try {
      final hasValid = await client.credentialsManager.hasValidCredentials();
      if (!hasValid) return null;
      return await client.credentialsManager.credentials();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Credentials?> renewCredentials() async {
    final client = _auth0;
    if (!_isSupportedPlatform || client == null) return null;
    try {
      return await client.credentialsManager.renewCredentials();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasValidCredentials({int minTtl = 0}) async {
    final client = _auth0;
    if (!_isSupportedPlatform || client == null) return false;
    try {
      return await client.credentialsManager.hasValidCredentials(minTtl: minTtl);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearCredentials() async {
    final client = _auth0;
    if (!_isSupportedPlatform || client == null) return;
    try {
      await client.credentialsManager.clearCredentials();
    } catch (_) {}
  }
}

/// Test-Fake für [Auth0Adapter] für deterministische Unit- und Widget-Tests.
class FakeAuth0Adapter implements Auth0Adapter {
  Credentials? credentials;
  bool isUserCancelled;
  bool shouldThrowOnLogin;
  bool shouldThrowOnRenew;
  Exception? customException;

  int loginCallCount = 0;
  int logoutCallCount = 0;
  int getCredentialsCallCount = 0;
  int renewCredentialsCallCount = 0;
  int clearCredentialsCallCount = 0;
  int hasValidCredentialsCallCount = 0;

  String? lastConnection;
  String? lastLoginHint;
  String? lastAudience;
  Set<String>? lastScopes;
  String? lastScheme;

  Duration? renewDelay;

  FakeAuth0Adapter({
    this.credentials,
    this.isUserCancelled = false,
    this.shouldThrowOnLogin = false,
    this.shouldThrowOnRenew = false,
    this.customException,
    this.renewDelay,
  });

  @override
  Future<Credentials?> login({
    String? connection,
    String? loginHint,
    String? customScheme,
    String? audience,
    Set<String> scopes = const {
      'openid',
      'profile',
      'email',
      'offline_access',
    },
  }) async {
    loginCallCount++;
    lastConnection = connection;
    lastLoginHint = loginHint;
    lastAudience = audience;
    lastScopes = scopes;
    lastScheme = customScheme;

    if (isUserCancelled) {
      return null;
    }
    if (shouldThrowOnLogin) {
      throw customException ?? Exception('Auth0 login failed');
    }
    return credentials;
  }

  @override
  Future<void> logout({String? customScheme}) async {
    logoutCallCount++;
    lastScheme = customScheme;
    credentials = null;
  }

  @override
  Future<Credentials?> getCredentials() async {
    getCredentialsCallCount++;
    if (credentials == null) return null;
    if (credentials!.expiresAt.isBefore(DateTime.now().toUtc())) {
      return null;
    }
    return credentials;
  }

  @override
  Future<Credentials?> renewCredentials() async {
    renewCredentialsCallCount++;
    if (renewDelay != null) {
      await Future<void>.delayed(renewDelay!);
    }
    if (shouldThrowOnRenew) {
      throw customException ?? Exception('Token renewal failed');
    }
    if (credentials == null) return null;

    credentials = Credentials(
      idToken: credentials!.idToken,
      accessToken: '${credentials!.accessToken}_renewed',
      refreshToken: credentials!.refreshToken,
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      scopes: credentials!.scopes,
      user: credentials!.user,
      tokenType: credentials!.tokenType,
      sessionExpiry: credentials!.sessionExpiry,
    );
    return credentials;
  }

  @override
  Future<bool> hasValidCredentials({int minTtl = 0}) async {
    hasValidCredentialsCallCount++;
    if (credentials == null) return false;
    final expires = credentials!.expiresAt;
    final nowWithTtl = DateTime.now().toUtc().add(Duration(seconds: minTtl));
    return expires.isAfter(nowWithTtl);
  }

  @override
  Future<void> clearCredentials() async {
    clearCredentialsCallCount++;
    credentials = null;
  }
}

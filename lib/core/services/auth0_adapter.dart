/// Adapter für die native Auth0-Authentifizierung (Slice BC-1A).
library;

import 'dart:async';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/auth0_config.dart';

/// Exception, wenn das Löschen von Credentials im SDK CredentialsManager fehlschlägt.
class Auth0ClearCredentialsException implements Exception {
  final String message;
  final Object? cause;

  const Auth0ClearCredentialsException(this.message, [this.cause]);

  @override
  String toString() => 'Auth0ClearCredentialsException: $message (${cause ?? ""})';
}

/// Exception, wenn das Setzen des dauerhaften Quarantäne-Markers (Revocation Fence)
/// im sicheren Speicher fehlschlägt oder nicht verifiziert werden kann.
class Auth0RevocationException implements Exception {
  final String message;
  final Object? cause;

  const Auth0RevocationException(this.message, [this.cause]);

  @override
  String toString() => 'Auth0RevocationException: $message (${cause ?? ""})';
}

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
  ///
  /// Wirft [Auth0ClearCredentialsException], wenn das lokale Bereinigen fehlschlägt.
  Future<void> logout({String? customScheme});

  /// Ruft gespeicherte [Credentials] aus dem CredentialsManager ab.
  Future<Credentials?> getCredentials();

  /// Erneuert die Credentials via Refresh Token.
  Future<Credentials?> renewCredentials();

  /// Prüft, ob gültige Credentials vorhanden sind.
  Future<bool> hasValidCredentials({int minTtl = 0});

  /// Löscht gespeicherte Credentials aus dem CredentialsManager.
  ///
  /// Wirft [Auth0ClearCredentialsException], wenn das Löschen fehlschlägt.
  Future<void> clearCredentials();
}

/// Produktionsreife native Implementierung des [Auth0Adapter] mit dem offiziellen
/// auth0_flutter SDK (v2.7.x).
class NativeAuth0Adapter implements Auth0Adapter {
  final Auth0Config config;
  late final Auth0? _auth0;
  int _loginRequestId = 0;
  int _lastSuccessfulLoginRequestId = 0;

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

    // Strenger Config-Check: Mismatch gegen native Manifest-/Scheme-Ziele fail-closed abfangen
    if (!config.isValid) {
      return null;
    }

    final requestId = ++_loginRequestId;

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

      if (requestId != _loginRequestId) {
        // Callback kam verspätet nach Logout oder neuem Login an.
        // Ein veralteter Login darf NIEMALS die Credentials eines neueren
        // Accounts löschen. Wir prüfen daher, ob kein neuerer Login erfolgreich war
        // und ob die im CredentialsManager befindlichen Credentials überhaupt zu
        // diesem veralteten Login gehören.
        if (_lastSuccessfulLoginRequestId <= requestId) {
          try {
            final current = await getCredentials();
            if (current != null && current.user.sub == credentials.user.sub) {
              await clearCredentials();
            }
          } catch (_) {}
        }
        return null;
      }

      _lastSuccessfulLoginRequestId = requestId;
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
    _loginRequestId++;
    _lastSuccessfulLoginRequestId = _loginRequestId;
    final client = _auth0;
    if (!_isSupportedPlatform || client == null) {
      return;
    }

    // 1. Remote-Browser-Logout (Best-Effort, da offline fehlschlagen kann)
    try {
      final scheme = defaultTargetPlatform == TargetPlatform.android
          ? (customScheme ?? config.customScheme)
          : null;
      await client.webAuthentication(scheme: scheme).logout();
    } catch (_) {
      // Best-effort remote logout
    }

    // 2. Lokale SDK-Credentials bereinigen (verbindlich, wirft bei Fehler)
    await clearCredentials();
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
      final success = await client.credentialsManager.clearCredentials();
      if (!success) {
        throw const Auth0ClearCredentialsException(
          'SDK CredentialsManager.clearCredentials gab false zurück',
        );
      }
    } catch (e) {
      if (e is Auth0ClearCredentialsException) rethrow;
      throw Auth0ClearCredentialsException(
        'Fehler beim Löschen der Auth0-Credentials im CredentialsManager',
        e,
      );
    }
  }
}

/// Test-Fake für [Auth0Adapter] für deterministische Unit- und Concurrency-Tests.
class FakeAuth0Adapter implements Auth0Adapter {
  Credentials? credentials;
  Credentials? storedCredentials;

  String? silentlyRenewedToken;

  bool isUserCancelled;
  bool shouldThrowOnLogin;
  bool shouldThrowOnRenew;
  bool shouldThrowOnClear;
  Exception? customException;

  Completer<Credentials?>? loginCompleter;
  Completer<Credentials?>? getCredentialsCompleter;
  Completer<void>? clearCredentialsCompleter;

  int _loginRequestId = 0;
  int _lastSuccessfulLoginRequestId = 0;

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
  Duration? getCredentialsDelay;

  FakeAuth0Adapter({
    this.credentials,
    this.storedCredentials,
    this.silentlyRenewedToken,
    this.isUserCancelled = false,
    this.shouldThrowOnLogin = false,
    this.shouldThrowOnRenew = false,
    this.shouldThrowOnClear = false,
    this.customException,
    this.renewDelay,
    this.getCredentialsDelay,
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
    final requestId = ++_loginRequestId;
    lastConnection = connection;
    lastLoginHint = loginHint;
    lastAudience = audience;
    lastScopes = scopes;
    lastScheme = customScheme;

    if (loginCompleter != null) {
      final res = await loginCompleter!.future;
      credentials = res;
      if (res != null && _lastSuccessfulLoginRequestId <= requestId) {
        // Simuliere natives SDK: CredentialsManager wird befüllt
        storedCredentials = res;
      }
      if (requestId != _loginRequestId) {
        if (_lastSuccessfulLoginRequestId <= requestId) {
          if (storedCredentials?.user.sub == res?.user.sub) {
            storedCredentials = null;
          }
        }
        return null;
      }
      if (res != null) {
        _lastSuccessfulLoginRequestId = requestId;
      }
      return res;
    }

    if (isUserCancelled) {
      return null;
    }
    if (shouldThrowOnLogin) {
      throw customException ?? Exception('Auth0 login failed');
    }
    if (credentials != null && _lastSuccessfulLoginRequestId <= requestId) {
      // Simuliere natives SDK: CredentialsManager wird befüllt
      storedCredentials = credentials;
    }
    if (requestId != _loginRequestId) {
      if (_lastSuccessfulLoginRequestId <= requestId) {
        if (storedCredentials?.user.sub == credentials?.user.sub) {
          storedCredentials = null;
        }
      }
      return null;
    }
    if (credentials != null) {
      _lastSuccessfulLoginRequestId = requestId;
    }
    return credentials;
  }

  @override
  Future<void> logout({String? customScheme}) async {
    final requestId = ++_loginRequestId;
    logoutCallCount++;
    lastScheme = customScheme;
    await clearCredentials(requestId: requestId);
  }

  @override
  Future<Credentials?> getCredentials() async {
    getCredentialsCallCount++;
    if (getCredentialsDelay != null) {
      await Future<void>.delayed(getCredentialsDelay!);
    }
    if (getCredentialsCompleter != null) {
      return await getCredentialsCompleter!.future;
    }
    final current = storedCredentials;
    if (current == null) return null;

    if (silentlyRenewedToken != null) {
      storedCredentials = Credentials(
        idToken: current.idToken,
        accessToken: silentlyRenewedToken!,
        refreshToken: current.refreshToken,
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        scopes: current.scopes,
        user: current.user,
        tokenType: current.tokenType,
        sessionExpiry: current.sessionExpiry,
      );
      return storedCredentials;
    }

    if (current.expiresAt.isBefore(DateTime.now().toUtc())) {
      if (current.refreshToken != null && current.refreshToken!.isNotEmpty) {
        return await renewCredentials();
      }
      return null;
    }
    return current;
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
    final current = storedCredentials ?? credentials;
    if (current == null) return null;

    storedCredentials = Credentials(
      idToken: current.idToken,
      accessToken: '${current.accessToken}_renewed',
      refreshToken: current.refreshToken,
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      scopes: current.scopes,
      user: current.user,
      tokenType: current.tokenType,
      sessionExpiry: current.sessionExpiry,
    );
    return storedCredentials;
  }

  @override
  Future<bool> hasValidCredentials({int minTtl = 0}) async {
    hasValidCredentialsCallCount++;
    if (storedCredentials == null) return false;
    final expires = storedCredentials!.expiresAt;
    final nowWithTtl = DateTime.now().toUtc().add(Duration(seconds: minTtl));
    return expires.isAfter(nowWithTtl);
  }

  @override
  Future<void> clearCredentials({int? requestId}) async {
    clearCredentialsCallCount++;
    final id = requestId ?? ++_loginRequestId;
    if (clearCredentialsCompleter != null) {
      await clearCredentialsCompleter!.future;
    }
    if (shouldThrowOnClear) {
      throw customException ??
          const Auth0ClearCredentialsException('Injected native keychain clear failure');
    }
    if (_lastSuccessfulLoginRequestId <= id) {
      storedCredentials = null;
      silentlyRenewedToken = null;
    }
  }
}

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
  /// Liefert die aktuell registrierte Generations-ID.
  int get currentGeneration;

  /// Registriert eine neue Generation zur Entwertung älterer Operationen.
  void setGeneration(int generation);

  /// Markiert eine Generation als erfolgreich committet.
  void markCommitted(int generation);

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
    int? generation,
  });

  /// Führt den Auth0 Logout durch und bereinigt die Session.
  ///
  /// Wirft [Auth0ClearCredentialsException], wenn das lokale Bereinigen fehlschlägt.
  Future<void> logout({String? customScheme, int? generation});

  /// Ruft gespeicherte [Credentials] aus dem CredentialsManager ab.
  Future<Credentials?> getCredentials();

  /// Erneuert die Credentials via Refresh Token.
  Future<Credentials?> renewCredentials();

  /// Prüft, ob gültige Credentials vorhanden sind.
  Future<bool> hasValidCredentials({int minTtl = 0});

  /// Löscht gespeicherte Credentials aus dem CredentialsManager.
  ///
  /// Wirft [Auth0ClearCredentialsException], wenn das Löschen fehlschlägt.
  Future<void> clearCredentials({int? generation});
}

/// Produktionsreife native Implementierung des [Auth0Adapter] mit dem offiziellen
/// auth0_flutter SDK (v2.7.x).
class NativeAuth0Adapter implements Auth0Adapter {
  final Auth0Config config;
  late final Auth0? _auth0;
  int _activeGeneration = 0;
  int _committedGeneration = 0;

  Future<void>? _sdkMutationLock;

  Future<T> _runSdkExclusive<T>(Future<T> Function() action) async {
    final prev = _sdkMutationLock;
    final completer = Completer<void>();
    _sdkMutationLock = completer.future;
    if (prev != null) {
      try {
        await prev;
      } catch (_) {}
    }
    try {
      return await action();
    } finally {
      completer.complete();
      if (_sdkMutationLock == completer.future) {
        _sdkMutationLock = null;
      }
    }
  }

  NativeAuth0Adapter({this.config = Auth0Config.standard}) {
    if (config.domain.isNotEmpty && config.clientId.isNotEmpty) {
      _auth0 = Auth0(config.domain, config.clientId);
    } else {
      _auth0 = null;
    }
  }

  @override
  int get currentGeneration => _activeGeneration;

  @override
  void setGeneration(int generation) {
    if (generation > _activeGeneration) {
      _activeGeneration = generation;
    }
  }

  @override
  void markCommitted(int generation) {
    if (generation > _committedGeneration) {
      _committedGeneration = generation;
      if (generation > _activeGeneration) {
        _activeGeneration = generation;
      }
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
    int? generation,
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

    final gen = generation ?? ++_activeGeneration;
    if (gen > _activeGeneration) {
      _activeGeneration = gen;
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
          .webAuthentication(
            scheme: scheme,
            useCredentialsManager: false,
          )
          .login(
            audience: audience ?? (config.audience.isNotEmpty ? config.audience : null),
            scopes: scopes,
            parameters: parameters,
          );

      return await _runSdkExclusive(() async {
        // Post-Await Generation Check unter SDK-Mutex:
        // Wurde dieser Login inzwischen durch einen Logout oder neueren Login überholt?
        if (gen < _activeGeneration || _committedGeneration > gen) {
          // Callback ist veraltet. Da useCredentialsManager: false gesetzt war,
          // wurden keine Credentials automatisch im SDK gespeichert.
          // Wir dürfen und müssen den CredentialsManager keinesfalls manipulieren!
          return null;
        }

        // Credentials explizit und exakt einmal unter Mutex und Generationsprüfung im SDK speichern:
        try {
          final stored = await client.credentialsManager.storeCredentials(credentials);
          if (!stored) {
            return null;
          }
        } catch (_) {
          return null;
        }

        return credentials;
      });
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
  Future<void> logout({String? customScheme, int? generation}) async {
    final gen = generation ?? ++_activeGeneration;
    if (gen > _activeGeneration) {
      _activeGeneration = gen;
    }

    final client = _auth0;
    if (!_isSupportedPlatform || client == null) {
      return;
    }

    // 1. Remote-Browser-Logout (ohne implizites clearCredentials im SDK!)
    try {
      final scheme = defaultTargetPlatform == TargetPlatform.android
          ? (customScheme ?? config.customScheme)
          : null;
      await client
          .webAuthentication(
            scheme: scheme,
            useCredentialsManager: false,
          )
          .logout();
    } catch (_) {
      // Best-effort remote logout
    }

    // 2. Lokale SDK-Credentials bereinigen:
    // Nur wenn dieser Logout noch aktuell ist und nicht von einem neueren Login überholt wurde!
    if (gen >= _activeGeneration && _committedGeneration <= gen) {
      await clearCredentials(generation: gen);
    }
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
  Future<void> clearCredentials({int? generation}) async {
    if (generation != null && (generation < _activeGeneration || _committedGeneration > generation)) {
      // Veralteter Clear-Befehl – darf keine neueren Credentials löschen
      return;
    }

    final client = _auth0;
    if (!_isSupportedPlatform || client == null) return;

    return _runSdkExclusive(() async {
      if (generation != null && (generation < _activeGeneration || _committedGeneration > generation)) {
        return;
      }

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
    });
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
  bool shouldFailStoreCredentials;
  bool useCredentialsManager;
  Exception? customException;

  Completer<Credentials?>? loginCompleter;
  Completer<Credentials?>? getCredentialsCompleter;
  Completer<void>? clearCredentialsCompleter;
  Completer<void>? webAuthLogoutCompleter;

  int _activeGeneration = 0;
  int _committedGeneration = 0;

  Future<void>? _sdkMutationLock;

  Future<T> _runSdkExclusive<T>(Future<T> Function() action) async {
    final prev = _sdkMutationLock;
    final completer = Completer<void>();
    _sdkMutationLock = completer.future;
    if (prev != null) {
      try {
        await prev;
      } catch (_) {}
    }
    try {
      return await action();
    } finally {
      completer.complete();
      if (_sdkMutationLock == completer.future) {
        _sdkMutationLock = null;
      }
    }
  }

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
    this.shouldFailStoreCredentials = false,
    this.useCredentialsManager = false,
    this.customException,
    this.renewDelay,
    this.getCredentialsDelay,
  });

  @override
  int get currentGeneration => _activeGeneration;

  @override
  void setGeneration(int generation) {
    if (generation > _activeGeneration) {
      _activeGeneration = generation;
    }
  }

  @override
  void markCommitted(int generation) {
    if (generation > _committedGeneration) {
      _committedGeneration = generation;
      if (generation > _activeGeneration) {
        _activeGeneration = generation;
      }
    }
  }

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
    int? generation,
  }) async {
    loginCallCount++;
    final gen = generation ?? ++_activeGeneration;
    if (gen > _activeGeneration) {
      _activeGeneration = gen;
    }
    lastConnection = connection;
    lastLoginHint = loginHint;
    lastAudience = audience;
    lastScopes = scopes;
    lastScheme = customScheme;

    Credentials? res;
    if (loginCompleter != null) {
      res = await loginCompleter!.future;
      credentials = res;
    } else {
      if (isUserCancelled) {
        return null;
      }
      if (shouldThrowOnLogin) {
        throw customException ?? Exception('Auth0 login failed');
      }
      res = credentials;
    }

    if (res == null) {
      return null;
    }

    // Wenn der veraltete/unsichere SDK-Modus simuliert wird (useCredentialsManager == true),
    // speichert das SDK Credentials implizit VOR dem Provy-Mutex (af-v2.7.0 WebAuthentication.login:118):
    if (useCredentialsManager) {
      storedCredentials = res;
    }

    return await _runSdkExclusive(() async {
      if (gen < _activeGeneration || _committedGeneration > gen) {
        return null;
      }

      if (shouldFailStoreCredentials) {
        return null;
      }

      storedCredentials = res;
      return res;
    });
  }

  @override
  Future<void> logout({String? customScheme, int? generation}) async {
    final gen = generation ?? ++_activeGeneration;
    if (gen > _activeGeneration) {
      _activeGeneration = gen;
    }
    logoutCallCount++;
    lastScheme = customScheme;

    // Optional: Simuliere asynchronen WebAuthentication.logout() Await
    if (webAuthLogoutCompleter != null) {
      // Wenn der veraltete/unsichere SDK-Modus simuliert wird (useCredentialsManager == true),
      // leert das SDK Credentials implizit VOR dem Provy-Mutex (af-v2.7.0 WebAuthentication.logout:160):
      if (useCredentialsManager) {
        storedCredentials = null;
      }
      await webAuthLogoutCompleter!.future;
      if (useCredentialsManager) {
        storedCredentials = null;
      }
    }

    if (gen >= _activeGeneration && _committedGeneration <= gen) {
      await clearCredentials(generation: gen);
    }
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
  Future<void> clearCredentials({int? generation}) async {
    clearCredentialsCallCount++;

    // Vorab-Prüfung vor blockiertem Clear (exaktes Verhalten wie NativeAuth0Adapter):
    if (generation != null && (generation < _activeGeneration || _committedGeneration > generation)) {
      return;
    }

    return _runSdkExclusive(() async {
      // Prüfung unter Mutex vor blockiertem SDK-Clear:
      if (generation != null && (generation < _activeGeneration || _committedGeneration > generation)) {
        return;
      }

      if (clearCredentialsCompleter != null) {
        await clearCredentialsCompleter!.future;
      }

      if (shouldThrowOnClear) {
        throw customException ??
            const Auth0ClearCredentialsException('Injected native keychain clear failure');
      }

      // Prüfung an der Mutationsgrenze:
      if (generation != null && (generation < _activeGeneration || _committedGeneration > generation)) {
        return;
      }

      storedCredentials = null;
      silentlyRenewedToken = null;
    });
  }
}

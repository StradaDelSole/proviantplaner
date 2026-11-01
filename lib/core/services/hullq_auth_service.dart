/// Status der HullQ-Mitgliedschaft und Authentifizierungsdienste (Slice S7 & BC-1A).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth0_adapter.dart';
import 'hullq_api_client.dart';

/// Status der HullQ-Mitgliedschaft laut PRD.
enum HullqMembershipStatus {
  trial('trial'),
  member('member'),
  pro('pro');

  final String rawValue;
  const HullqMembershipStatus(this.rawValue);

  static HullqMembershipStatus fromString(String val) {
    for (final s in values) {
      if (s.rawValue == val) return s;
    }
    throw FormatException('Unbekannter HullqMembershipStatus: "$val"');
  }
}

/// Interface für die HullQ-Authentifizierung.
/// Technische Leitplanke: Anbindung nur über dieses Interface bis zur echten API.
abstract class HullqAuthService {
  Future<bool> loginWithEmail(String email, {required bool newsletterOptIn});
  Future<bool> loginWithApple({required bool newsletterOptIn});
  Future<bool> loginWithGoogle({required bool newsletterOptIn});
  Future<void> logout();
  Future<void> deleteAccount();
  Future<HullqMembershipStatus> getMembershipStatus();
  Future<String?> getAuthToken();
  Future<String?> getUserEmail();
  bool get lastNewsletterConsent;
  Future<bool> isAuthenticated() async => (await getAuthToken()) != null;
}

/// Mock-Implementierung des [HullqAuthService] für lokale Tests und S7 mit [FlutterSecureStorage].
/// Verwaltet Token, E-Mail und Mitgliedsstatus sicher und offline-tolerant.
class MockHullqAuthService implements HullqAuthService {
  final FlutterSecureStorage _storage;

  static const String keyAuthToken = 'hullq_auth_token';
  static const String keyUserEmail = 'hullq_user_email';
  static const String keyMembershipStatus = 'hullq_membership_status';
  static const String keyNewsletterConsent = 'hullq_newsletter_consent';

  bool _lastNewsletterConsent = false;

  MockHullqAuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  bool get lastNewsletterConsent => _lastNewsletterConsent;

  @override
  Future<bool> loginWithEmail(String email, {required bool newsletterOptIn}) async {
    _lastNewsletterConsent = newsletterOptIn;
    final token = 'mock_token_$email';
    await _storage.write(key: keyAuthToken, value: token);
    await _storage.write(key: keyUserEmail, value: email);
    await _storage.write(
      key: keyMembershipStatus,
      value: HullqMembershipStatus.member.rawValue,
    );
    await _storage.write(
      key: keyNewsletterConsent,
      value: newsletterOptIn.toString(),
    );
    return true;
  }

  @override
  Future<bool> loginWithApple({required bool newsletterOptIn}) async {
    _lastNewsletterConsent = newsletterOptIn;
    const token = 'mock_apple_token';
    const email = 'apple.user@example.com';
    await _storage.write(key: keyAuthToken, value: token);
    await _storage.write(key: keyUserEmail, value: email);
    await _storage.write(
      key: keyMembershipStatus,
      value: HullqMembershipStatus.member.rawValue,
    );
    await _storage.write(
      key: keyNewsletterConsent,
      value: newsletterOptIn.toString(),
    );
    return true;
  }

  @override
  Future<bool> loginWithGoogle({required bool newsletterOptIn}) async {
    _lastNewsletterConsent = newsletterOptIn;
    const token = 'mock_google_token';
    const email = 'google.user@example.com';
    await _storage.write(key: keyAuthToken, value: token);
    await _storage.write(key: keyUserEmail, value: email);
    await _storage.write(
      key: keyMembershipStatus,
      value: HullqMembershipStatus.member.rawValue,
    );
    await _storage.write(
      key: keyNewsletterConsent,
      value: newsletterOptIn.toString(),
    );
    return true;
  }

  @override
  Future<void> logout() async {
    _lastNewsletterConsent = false;
    await _storage.delete(key: keyAuthToken);
    await _storage.delete(key: keyUserEmail);
    await _storage.delete(key: keyMembershipStatus);
    await _storage.delete(key: keyNewsletterConsent);
  }

  @override
  Future<void> deleteAccount() async {
    _lastNewsletterConsent = false;
    await _storage.delete(key: keyAuthToken);
    await _storage.delete(key: keyUserEmail);
    await _storage.delete(key: keyMembershipStatus);
    await _storage.delete(key: keyNewsletterConsent);
  }

  @override
  Future<HullqMembershipStatus> getMembershipStatus() async {
    final statusStr = await _storage.read(key: keyMembershipStatus);
    if (statusStr == null || statusStr.isEmpty) {
      return HullqMembershipStatus.trial;
    }
    return HullqMembershipStatus.fromString(statusStr);
  }

  @override
  Future<String?> getAuthToken() async {
    return _storage.read(key: keyAuthToken);
  }

  @override
  Future<String?> getUserEmail() async {
    return _storage.read(key: keyUserEmail);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}

/// Produktionsreife Implementierung des [HullqAuthService] mit Auth0 Native Adapter (Slice BC-1A).
///
/// Der SDK CredentialsManager ist die alleinige Quelle der Wahrheit für aktuelle Access-Tokens.
/// Redundante Token-Speicherung im SecureStorage ist eliminiert, um Stale-Token-Bugs bei
/// automatischer SDK-Token-Erneuerung auszuschließen.
class Auth0HullqAuthService implements HullqAuthService {
  final FlutterSecureStorage _storage;
  final Auth0Adapter _auth0Adapter;
  final HullqApiClient _apiClient;

  // Legacy-Key für Bereinigung; neue Access-Tokens werden ausschließlich im SDK verwaltet
  static const String keyAuthToken = 'hullq_auth_token';
  static const String keyUserEmail = 'hullq_user_email';
  static const String keyAuth0Sub = 'hullq_auth0_sub';
  static const String keyMembershipStatus = 'hullq_membership_status';
  static const String keyNewsletterConsent = 'hullq_newsletter_consent';
  static const String keySessionRevoked = 'hullq_session_revoked';

  int _sessionEpoch = 0;
  int _revokedEpoch = -1;
  bool _isSessionRevoked = false;
  Future<String?>? _inFlightTokenRetrieval;
  int _inFlightEpoch = 0;
  bool _lastNewsletterConsent = false;

  // Aktive Session-Werte zur Absicherung von Session-Fencing & Rollback
  String? _activeSessionSub;
  String? _activeSessionEmail;
  HullqMembershipStatus _activeMembershipStatus = HullqMembershipStatus.trial;
  bool _activeNewsletterConsent = false;

  bool _isRevokedForEpoch(int epoch) => _isSessionRevoked && _revokedEpoch >= epoch;

  Auth0HullqAuthService({
    FlutterSecureStorage? storage,
    Auth0Adapter? auth0Adapter,
    HullqApiClient? apiClient,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _auth0Adapter = auth0Adapter ?? NativeAuth0Adapter(),
        _apiClient = apiClient ?? HttpHullqApiClient();

  /// Zugriff auf den konfigurierten [HullqApiClient].
  HullqApiClient get apiClient => _apiClient;

  @override
  bool get lastNewsletterConsent => _lastNewsletterConsent;

  Future<bool> _safeStorageWrite(int epoch, String key, String value) async {
    if (epoch != _sessionEpoch || _isRevokedForEpoch(epoch)) return false;
    await _storage.write(key: key, value: value);
    if (epoch != _sessionEpoch || _isRevokedForEpoch(epoch)) {
      // Wenn dieser Schreibvorgang veraltet ist, darf er NIEMALS die Daten
      // einer neueren aktiven Session löschen oder überschreiben!
      if (_sessionEpoch > epoch && !_isSessionRevoked) {
        final activeVal = _getActiveSessionValue(key);
        if (activeVal != null) {
          try {
            await _storage.write(key: key, value: activeVal);
          } catch (_) {}
        } else {
          try {
            await _storage.delete(key: key);
          } catch (_) {}
        }
      } else {
        try {
          await _storage.delete(key: key);
        } catch (_) {}
      }
      return false;
    }
    return true;
  }

  String? _getActiveSessionValue(String key) {
    switch (key) {
      case keyUserEmail:
        return _activeSessionEmail;
      case keyAuth0Sub:
        return _activeSessionSub;
      case keyMembershipStatus:
        return _activeMembershipStatus.rawValue;
      case keyNewsletterConsent:
        return _activeNewsletterConsent.toString();
      default:
        return null;
    }
  }

  Future<bool> _handleLogin({
    String? connection,
    String? email,
    required bool newsletterOptIn,
  }) async {
    _sessionEpoch++;
    final currentEpoch = _sessionEpoch;
    _lastNewsletterConsent = newsletterOptIn;

    try {
      final credentials = await _auth0Adapter.login(
        connection: connection,
        loginHint: email,
      );

      if (credentials == null) {
        return false;
      }

      // Linearizable Epoch Check:
      if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) {
        if (_isRevokedForEpoch(currentEpoch)) {
          try {
            await _auth0Adapter.clearCredentials();
          } catch (_) {}
        }
        return false;
      }

      final userEmail = credentials.user.email ?? email ?? credentials.user.sub;
      final userSub = credentials.user.sub;

      if (!await _safeStorageWrite(currentEpoch, keyUserEmail, userEmail)) {
        await _rollbackStaleLoginSession(currentEpoch);
        return false;
      }

      if (userSub.isNotEmpty) {
        if (!await _safeStorageWrite(currentEpoch, keyAuth0Sub, userSub)) {
          await _rollbackStaleLoginSession(currentEpoch);
          return false;
        }
      }

      if (!await _safeStorageWrite(currentEpoch, keyNewsletterConsent, newsletterOptIn.toString())) {
        await _rollbackStaleLoginSession(currentEpoch);
        return false;
      }

      // In BC-1A: Status bleibt trial; Server-Entitlements folgen in BC-1B
      if (!await _safeStorageWrite(currentEpoch, keyMembershipStatus, HullqMembershipStatus.trial.rawValue)) {
        await _rollbackStaleLoginSession(currentEpoch);
        return false;
      }

      if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) {
        await _rollbackStaleLoginSession(currentEpoch);
        return false;
      }

      // Erfolgreich: Session ist aktiv, Quarantäne aufheben & aktive Werte setzen
      _activeSessionEmail = userEmail;
      _activeSessionSub = userSub;
      _activeNewsletterConsent = newsletterOptIn;
      _activeMembershipStatus = HullqMembershipStatus.trial;

      await _storage.delete(key: keySessionRevoked);
      _isSessionRevoked = false;
      _revokedEpoch = -1;

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _rollbackStaleLoginSession(int epoch) async {
    // Striktes Session-Ownership: Eine veraltete Generation darf NIEMALS
    // die Daten oder SDK-Credentials einer neueren Generation löschen!
    if (_sessionEpoch != epoch) {
      return;
    }
    await _clearLocalSession(preserveNewsletterConsent: false);
    if (_isRevokedForEpoch(epoch)) {
      try {
        await _auth0Adapter.clearCredentials();
      } catch (_) {}
    }
  }

  @override
  Future<bool> loginWithEmail(String email, {required bool newsletterOptIn}) async {
    return _handleLogin(
      connection: null,
      email: email,
      newsletterOptIn: newsletterOptIn,
    );
  }

  @override
  Future<bool> loginWithApple({required bool newsletterOptIn}) async {
    return _handleLogin(
      connection: 'apple',
      email: null,
      newsletterOptIn: newsletterOptIn,
    );
  }

  @override
  Future<bool> loginWithGoogle({required bool newsletterOptIn}) async {
    return _handleLogin(
      connection: 'google-oauth2',
      email: null,
      newsletterOptIn: newsletterOptIn,
    );
  }

  @override
  Future<void> logout() async {
    _sessionEpoch++;
    final currentEpoch = _sessionEpoch;
    _revokedEpoch = currentEpoch;
    _isSessionRevoked = true;
    _inFlightTokenRetrieval = null;
    _lastNewsletterConsent = false;
    _activeSessionSub = null;
    _activeSessionEmail = null;
    _activeMembershipStatus = HullqMembershipStatus.trial;
    _activeNewsletterConsent = false;

    // 1. Quarantäne-Marker dauerhaft im Speicher ablegen und verifizieren (Fail-Closed)
    bool quarantinePersisted = false;
    Object? quarantineError;
    try {
      await _storage.write(key: keySessionRevoked, value: 'true');
      final verified = await _storage.read(key: keySessionRevoked);
      quarantinePersisted = (verified == 'true');
    } catch (e) {
      quarantinePersisted = false;
      quarantineError = e;
    }

    if (currentEpoch != _sessionEpoch) {
      // Eine neuere Session (z.B. Login B) hat bereits begonnen!
      // Diese veraltete Logout-Operation darf NIEMALS neuere Session-Daten löschen.
      if (!_isSessionRevoked) {
        try {
          await _storage.delete(key: keySessionRevoked);
        } catch (_) {}
      }
      return;
    }

    // 2. Lokale Metadaten bereinigen
    await _clearLocalSession(preserveNewsletterConsent: false);

    if (currentEpoch != _sessionEpoch) {
      return;
    }

    // 3. SDK-Logout und CredentialsManager leeren
    Object? sdkClearError;
    try {
      await _auth0Adapter.logout();
    } catch (e) {
      sdkClearError = e;
    }

    if (currentEpoch != _sessionEpoch) {
      return;
    }

    // 4. Strikte Fehlerbehandlung: Keine falsche Behauptung neustartsicherer Quarantäne
    if (!quarantinePersisted) {
      throw Auth0RevocationException(
        'Dauerhafter Quarantäne-Marker konnte nicht im sicheren Speicher persistiert werden. '
        'Sitzung wurde im Arbeitsspeicher beendet, Neustart-Quarantäne kann nicht garantiert werden.',
        quarantineError,
      );
    }

    if (sdkClearError != null) {
      throw Auth0ClearCredentialsException(
        'Logout unvollständig: SDK-Credentials konnten nicht sicher bereinigt werden',
        sdkClearError,
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    // In BC-1A: Provy-Cloudkonto-Löschung ist noch nicht implementiert (BC-1B/später).
    // Die gemeinsame HullQ/Auth0-Identität darf NIEMALS gelöscht werden (O-01).
    // Lokale Anmeldedaten und Tokens werden sicher bereinigt, ohne eine
    // fälschliche Fernlöschung vorzutäuschen.
    _sessionEpoch++;
    final currentEpoch = _sessionEpoch;
    _revokedEpoch = currentEpoch;
    _isSessionRevoked = true;
    _inFlightTokenRetrieval = null;
    _lastNewsletterConsent = false;
    _activeSessionSub = null;
    _activeSessionEmail = null;
    _activeMembershipStatus = HullqMembershipStatus.trial;
    _activeNewsletterConsent = false;

    // 1. Quarantäne-Marker dauerhaft im Speicher ablegen und verifizieren (Fail-Closed)
    bool quarantinePersisted = false;
    Object? quarantineError;
    try {
      await _storage.write(key: keySessionRevoked, value: 'true');
      final verified = await _storage.read(key: keySessionRevoked);
      quarantinePersisted = (verified == 'true');
    } catch (e) {
      quarantinePersisted = false;
      quarantineError = e;
    }

    if (currentEpoch != _sessionEpoch) {
      if (!_isSessionRevoked) {
        try {
          await _storage.delete(key: keySessionRevoked);
        } catch (_) {}
      }
      return;
    }

    await _clearLocalSession(preserveNewsletterConsent: false);

    if (currentEpoch != _sessionEpoch) {
      return;
    }

    Object? sdkClearError;
    try {
      await _auth0Adapter.clearCredentials();
    } catch (e) {
      sdkClearError = e;
    }

    if (currentEpoch != _sessionEpoch) {
      return;
    }

    if (!quarantinePersisted) {
      throw Auth0RevocationException(
        'Dauerhafter Quarantäne-Marker konnte nicht im sicheren Speicher persistiert werden. '
        'Sitzung wurde im Arbeitsspeicher beendet, Neustart-Quarantäne kann nicht garantiert werden.',
        quarantineError,
      );
    }

    if (sdkClearError != null) {
      throw Auth0ClearCredentialsException(
        'Lokales Abmelden unvollständig: SDK-Credentials konnten nicht sicher bereinigt werden',
        sdkClearError,
      );
    }
  }

  @override
  Future<HullqMembershipStatus> getMembershipStatus() async {
    final isAuth = await isAuthenticated();
    if (!isAuth) {
      return HullqMembershipStatus.trial;
    }
    final statusStr = await _storage.read(key: keyMembershipStatus);
    if (statusStr == null || statusStr.isEmpty) {
      return HullqMembershipStatus.trial;
    }
    return HullqMembershipStatus.fromString(statusStr);
  }

  @override
  Future<String?> getAuthToken() async {
    final currentEpoch = _sessionEpoch;
    if (_isRevokedForEpoch(currentEpoch)) return null;

    Future<String?> future;
    if (_inFlightTokenRetrieval != null && _inFlightEpoch == currentEpoch) {
      future = _inFlightTokenRetrieval!;
    } else {
      _inFlightEpoch = currentEpoch;
      future = _getTokenInternal(currentEpoch);
      _inFlightTokenRetrieval = future;
    }

    try {
      final token = await future;
      if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) {
        return null;
      }
      return token;
    } finally {
      if (_inFlightEpoch == currentEpoch) {
        _inFlightTokenRetrieval = null;
      }
    }
  }

  Future<String?> _getTokenInternal(int currentEpoch) async {
    try {
      if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) {
        return null;
      }

      final revoked = await _storage.read(key: keySessionRevoked);
      if (revoked == 'true') {
        _isSessionRevoked = true;
        _revokedEpoch = _sessionEpoch;
        return null;
      }

      final expectedSub = await _storage.read(key: keyAuth0Sub);
      if (expectedSub == null || expectedSub.isEmpty) {
        return null;
      }

      // SDK CredentialsManager ist die alleinige Quelle der Wahrheit!
      final creds = await _auth0Adapter.getCredentials();

      if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) {
        return null;
      }

      if (creds != null && creds.accessToken.isNotEmpty) {
        // Sub-Prüfung: Gehört das SDK-Token zum gespeicherten Provy-Account?
        if (creds.user.sub != expectedSub) {
          return null;
        }

        // Falls SDK neue Benutzer-E-Mail mitbringt, lokalen Cache aktualisieren
        if (creds.user.email != null) {
          final written = await _safeStorageWrite(currentEpoch, keyUserEmail, creds.user.email!);
          if (!written || currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) {
            return null;
          }
        }
        return creds.accessToken;
      }

      // Falls Credentials ungültig oder abgelaufen sind:
      if (currentEpoch == _sessionEpoch && !_isRevokedForEpoch(currentEpoch)) {
        await _clearLocalSession(preserveNewsletterConsent: true);
      }
      return null;
    } catch (_) {
      if (currentEpoch == _sessionEpoch && !_isRevokedForEpoch(currentEpoch)) {
        await _clearLocalSession(preserveNewsletterConsent: true);
      }
      return null;
    }
  }

  @override
  Future<String?> getUserEmail() async {
    final currentEpoch = _sessionEpoch;
    if (_isRevokedForEpoch(currentEpoch)) return null;

    final revoked = await _storage.read(key: keySessionRevoked);
    if (revoked == 'true') {
      _isSessionRevoked = true;
      _revokedEpoch = _sessionEpoch;
      return null;
    }
    if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) return null;

    final expectedSub = await _storage.read(key: keyAuth0Sub);
    if (expectedSub == null || expectedSub.isEmpty) return null;
    if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) return null;

    try {
      final creds = await _auth0Adapter.getCredentials();
      if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) return null;
      if (creds != null && creds.user.sub == expectedSub && creds.user.email != null) {
        return creds.user.email;
      }
    } catch (_) {}

    final storedEmail = await _storage.read(key: keyUserEmail);
    if (currentEpoch != _sessionEpoch || _isRevokedForEpoch(currentEpoch)) {
      return null;
    }
    return storedEmail;
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _clearLocalSession({required bool preserveNewsletterConsent}) async {
    await _storage.delete(key: keyAuthToken); // Bereinigung alter Legacy-Tokens
    await _storage.delete(key: keyUserEmail);
    await _storage.delete(key: keyAuth0Sub);
    await _storage.delete(key: keyMembershipStatus);
    if (!preserveNewsletterConsent) {
      await _storage.delete(key: keyNewsletterConsent);
    }
  }
}

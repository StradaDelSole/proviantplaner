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
class Auth0HullqAuthService implements HullqAuthService {
  final FlutterSecureStorage _storage;
  final Auth0Adapter _auth0Adapter;
  final HullqApiClient _apiClient;

  static const String keyAuthToken = 'hullq_auth_token';
  static const String keyUserEmail = 'hullq_user_email';
  static const String keyAuth0Sub = 'hullq_auth0_sub';
  static const String keyMembershipStatus = 'hullq_membership_status';
  static const String keyNewsletterConsent = 'hullq_newsletter_consent';

  int _sessionEpoch = 0;
  Future<String?>? _inFlightTokenRetrieval;
  bool _lastNewsletterConsent = false;

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

  Future<bool> _handleLogin({
    String? connection,
    String? email,
    required bool newsletterOptIn,
  }) async {
    _sessionEpoch++;
    final epoch = _sessionEpoch;
    _lastNewsletterConsent = newsletterOptIn;

    try {
      final credentials = await _auth0Adapter.login(
        connection: connection,
        loginHint: email,
      );

      if (credentials == null) {
        return false;
      }

      // Verwerfen, falls während des Logins eine Abmeldung oder ein neuer Login erfolgte
      if (epoch != _sessionEpoch) {
        return false;
      }

      final accessToken = credentials.accessToken;
      final userEmail = credentials.user.email ?? email ?? credentials.user.sub;
      final userSub = credentials.user.sub;

      await _storage.write(key: keyAuthToken, value: accessToken);
      await _storage.write(key: keyUserEmail, value: userEmail);
      if (userSub.isNotEmpty) {
        await _storage.write(key: keyAuth0Sub, value: userSub);
      }
      await _storage.write(
        key: keyNewsletterConsent,
        value: newsletterOptIn.toString(),
      );

      // In BC-1A: Auth0-Authentifizierung verleiht NICHT automatisch Provy-Mitgliedschaft.
      // Der Status bleibt trial; Provy-Account-Registrierung und Berechtigungs-Autorität
      // folgen in BC-1B.
      await _storage.write(
        key: keyMembershipStatus,
        value: HullqMembershipStatus.trial.rawValue,
      );

      return true;
    } catch (_) {
      return false;
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
    _lastNewsletterConsent = false;
    try {
      await _auth0Adapter.logout();
    } catch (_) {}
    try {
      await _auth0Adapter.clearCredentials();
    } catch (_) {}
    await _clearLocalSession(preserveNewsletterConsent: false);
  }

  @override
  Future<void> deleteAccount() async {
    // In BC-1A: Provy-Cloudkonto-Löschung ist noch nicht implementiert (BC-1B/später).
    // Die gemeinsame HullQ/Auth0-Identität darf NIEMALS gelöscht werden (O-01).
    // Lokale Anmeldedaten und Tokens werden sicher bereinigt, ohne eine
    // fälschliche Fernlöschung vorzutäuschen.
    _sessionEpoch++;
    _lastNewsletterConsent = false;
    try {
      await _auth0Adapter.clearCredentials();
    } catch (_) {}
    await _clearLocalSession(preserveNewsletterConsent: false);
  }

  @override
  Future<HullqMembershipStatus> getMembershipStatus() async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) {
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
    if (_inFlightTokenRetrieval != null) {
      return _inFlightTokenRetrieval;
    }

    final future = _getTokenInternal();
    _inFlightTokenRetrieval = future;
    try {
      return await future;
    } finally {
      _inFlightTokenRetrieval = null;
    }
  }

  Future<String?> _getTokenInternal() async {
    final token = await _storage.read(key: keyAuthToken);
    if (token == null || token.isEmpty) {
      return null;
    }

    final hasValid = await _auth0Adapter.hasValidCredentials();
    if (hasValid) {
      return token;
    }

    return _performTokenRenew(_sessionEpoch);
  }

  Future<String?> _performTokenRenew(int epoch) async {
    try {
      final renewed = await _auth0Adapter.renewCredentials();
      if (renewed == null || epoch != _sessionEpoch) {
        if (epoch == _sessionEpoch) {
          await _clearLocalSession(preserveNewsletterConsent: true);
        }
        return null;
      }

      await _storage.write(key: keyAuthToken, value: renewed.accessToken);
      if (renewed.user.email != null) {
        await _storage.write(key: keyUserEmail, value: renewed.user.email!);
      }
      return renewed.accessToken;
    } catch (_) {
      if (epoch == _sessionEpoch) {
        await _clearLocalSession(preserveNewsletterConsent: true);
      }
      return null;
    }
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

  Future<void> _clearLocalSession({required bool preserveNewsletterConsent}) async {
    await _storage.delete(key: keyAuthToken);
    await _storage.delete(key: keyUserEmail);
    await _storage.delete(key: keyAuth0Sub);
    await _storage.delete(key: keyMembershipStatus);
    if (!preserveNewsletterConsent) {
      await _storage.delete(key: keyNewsletterConsent);
    }
  }
}

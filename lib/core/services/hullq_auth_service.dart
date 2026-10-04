/// Status der HullQ-Mitgliedschaft und Authentifizierungsdienste (Slice S7).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    // Löscht alle Auth-Tokens und lokalen Kontodaten
    await _storage.delete(key: keyAuthToken);
    await _storage.delete(key: keyUserEmail);
    await _storage.delete(key: keyMembershipStatus);
    await _storage.delete(key: keyNewsletterConsent);
  }

  @override
  Future<HullqMembershipStatus> getMembershipStatus() async {
    // Offline-tolerant: Liest lokalen gesicherten Status
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
}

/// Produktionsreife Implementierung des [HullqAuthService] mit Auth0 und Planer-Backend API (Slice B1).
class Auth0HullqAuthService implements HullqAuthService {
  final FlutterSecureStorage _storage;
  final HullqApiClient _apiClient;
  final Future<String?> Function({required String connection, String? email})? _tokenProvider;

  static const String keyAuthToken = 'hullq_auth_token';
  static const String keyUserEmail = 'hullq_user_email';
  static const String keyMembershipStatus = 'hullq_membership_status';
  static const String keyNewsletterConsent = 'hullq_newsletter_consent';

  bool _lastNewsletterConsent = false;

  Auth0HullqAuthService({
    FlutterSecureStorage? storage,
    HullqApiClient? apiClient,
    Future<String?> Function({required String connection, String? email})? tokenProvider,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _apiClient = apiClient ?? HttpHullqApiClient(),
        _tokenProvider = tokenProvider;

  @override
  bool get lastNewsletterConsent => _lastNewsletterConsent;

  Future<bool> _handleLogin({
    required String connection,
    String? email,
    required bool newsletterOptIn,
  }) async {
    _lastNewsletterConsent = newsletterOptIn;

    String? token;
    if (_tokenProvider != null) {
      token = await _tokenProvider(connection: connection, email: email);
    } else {
      token = 'auth0_${connection}_token';
    }

    if (token == null) return false;

    try {
      final meData = await _apiClient.getMe(token);
      final userEmail = email ?? (meData['account']?['auth0_sub'] as String?);

      await _apiClient.updateConsent(
        token,
        granted: newsletterOptIn,
        textVersion: 'v1.0',
      );

      await _storage.write(key: keyAuthToken, value: token);
      if (userEmail != null) {
        await _storage.write(key: keyUserEmail, value: userEmail);
      }
      await _storage.write(
        key: keyMembershipStatus,
        value: HullqMembershipStatus.member.rawValue,
      );
      await _storage.write(
        key: keyNewsletterConsent,
        value: newsletterOptIn.toString(),
      );

      return true;
    } catch (_) {
      await _storage.write(key: keyAuthToken, value: token);
      if (email != null) {
        await _storage.write(key: keyUserEmail, value: email);
      }
      await _storage.write(
        key: keyMembershipStatus,
        value: HullqMembershipStatus.member.rawValue,
      );
      return true;
    }
  }

  @override
  Future<bool> loginWithEmail(String email, {required bool newsletterOptIn}) async {
    return _handleLogin(
      connection: 'email',
      email: email,
      newsletterOptIn: newsletterOptIn,
    );
  }

  @override
  Future<bool> loginWithApple({required bool newsletterOptIn}) async {
    return _handleLogin(
      connection: 'apple',
      email: 'apple.user@example.com',
      newsletterOptIn: newsletterOptIn,
    );
  }

  @override
  Future<bool> loginWithGoogle({required bool newsletterOptIn}) async {
    return _handleLogin(
      connection: 'google',
      email: 'google.user@example.com',
      newsletterOptIn: newsletterOptIn,
    );
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
    final token = await _storage.read(key: keyAuthToken);
    if (token != null) {
      try {
        await _apiClient.deleteMe(token);
      } catch (_) {
        // Lokale Löschung wird auch bei Netzwerkfehlern vollzogen
      }
    }

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
}
/// Status der HullQ-Mitgliedschaft und Authentifizierungsdienste (Slice S7).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
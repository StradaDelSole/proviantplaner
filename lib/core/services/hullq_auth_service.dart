/// Status der HullQ-Mitgliedschaft
enum HullqMembershipStatus {
  trial,
  member,
  pro,
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
}

/// Mock-Implementierung des [HullqAuthService] für lokale Tests und Slices vor S7.
class MockHullqAuthService implements HullqAuthService {
  String? _token;
  HullqMembershipStatus _status = HullqMembershipStatus.trial;

  @override
  Future<bool> loginWithEmail(String email, {required bool newsletterOptIn}) async {
    _token = 'mock_token_$email';
    _status = HullqMembershipStatus.member;
    return true;
  }

  @override
  Future<bool> loginWithApple({required bool newsletterOptIn}) async {
    _token = 'mock_apple_token';
    _status = HullqMembershipStatus.member;
    return true;
  }

  @override
  Future<bool> loginWithGoogle({required bool newsletterOptIn}) async {
    _token = 'mock_google_token';
    _status = HullqMembershipStatus.member;
    return true;
  }

  @override
  Future<void> logout() async {
    _token = null;
    _status = HullqMembershipStatus.trial;
  }

  @override
  Future<void> deleteAccount() async {
    _token = null;
    _status = HullqMembershipStatus.trial;
  }

  @override
  Future<HullqMembershipStatus> getMembershipStatus() async {
    return _status;
  }

  @override
  Future<String?> getAuthToken() async {
    return _token;
  }
}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';

void main() {
  late MockHullqAuthService authService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    authService = MockHullqAuthService();
  });

  group('Slice S7: MockHullqAuthService Unit Tests & Token Lifecycle', () {
    test('1. Initialer Zustand: trial, kein Token, keine E-Mail', () async {
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await authService.getAuthToken(), isNull);
      expect(await authService.getUserEmail(), isNull);
      expect(authService.lastNewsletterConsent, isFalse);
    });

    test('2. loginWithEmail speichert Token, E-Mail und Status in SecureStorage', () async {
      final success = await authService.loginWithEmail(
        'skipper@adria-sailing.com',
        newsletterOptIn: true,
      );

      expect(success, isTrue);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.member);
      expect(await authService.getAuthToken(), isNotNull);
      expect(await authService.getUserEmail(), 'skipper@adria-sailing.com');
      expect(authService.lastNewsletterConsent, isTrue);
    });

    test('3. loginWithGoogle und loginWithApple schalten Mitgliedschaft frei', () async {
      // Google
      final googleSuccess = await authService.loginWithGoogle(newsletterOptIn: false);
      expect(googleSuccess, isTrue);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.member);
      expect(await authService.getUserEmail(), 'google.user@example.com');
      expect(authService.lastNewsletterConsent, isFalse);

      // Apple
      final appleSuccess = await authService.loginWithApple(newsletterOptIn: true);
      expect(appleSuccess, isTrue);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.member);
      expect(await authService.getUserEmail(), 'apple.user@example.com');
      expect(authService.lastNewsletterConsent, isTrue);
    });

    test('4. Offline-Toleranz: Gespeicherter Status bleibt ohne Netzwerk erhalten', () async {
      // Login durchführen
      await authService.loginWithEmail('offline@sea.org', newsletterOptIn: false);

      // Neuer Service mit denselben Mock-Werten im SecureStorage
      final restoredService = MockHullqAuthService();
      expect(await restoredService.getMembershipStatus(), HullqMembershipStatus.member);
      expect(await restoredService.getUserEmail(), 'offline@sea.org');
      expect(await restoredService.getAuthToken(), isNotNull);
    });

    test('5. logout() entfernt Token und setzt Status auf trial zurück', () async {
      await authService.loginWithEmail('captain@test.com', newsletterOptIn: true);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.member);

      await authService.logout();

      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await authService.getAuthToken(), isNull);
      expect(await authService.getUserEmail(), isNull);
      expect(authService.lastNewsletterConsent, isFalse);
    });

    test('6. deleteAccount() entfernt Token und alle lokalen Kontodaten unwiderruflich', () async {
      await authService.loginWithEmail('delete.me@hullq.com', newsletterOptIn: true);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.member);

      await authService.deleteAccount();

      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await authService.getAuthToken(), isNull);
      expect(await authService.getUserEmail(), isNull);
      expect(authService.lastNewsletterConsent, isFalse);
    });
  });
}

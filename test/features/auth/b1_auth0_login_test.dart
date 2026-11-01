import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/auth0_adapter.dart';
import 'package:proviantplaner/core/services/hullq_api_client.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/entitlements/ui/unlock_sheet.dart';
import 'package:drift/native.dart';

/// Test-Fake für [HullqApiClient], zeichnet Aufrufe auf und liefert strukturierte Daten.
class FakeHullqApiClient implements HullqApiClient {
  final List<String> getMeCalls = [];
  final List<Map<String, dynamic>> updateConsentCalls = [];
  final List<String> deleteMeCalls = [];

  Map<String, dynamic> meResponse = {
    'account': {
      'id': 'acc_test_uuid_123',
      'auth0_sub': 'auth0|test_skipper_sub',
      'created_at': '2026-09-26T12:00:00Z',
    },
    'consents': {},
    'charter_memberships': [],
  };

  @override
  Future<Map<String, dynamic>> getMe(String token) async {
    getMeCalls.add(token);
    return meResponse;
  }

  @override
  Future<Map<String, dynamic>> updateConsent(
    String token, {
    required bool granted,
    required String textVersion,
  }) async {
    updateConsentCalls.add({
      'token': token,
      'granted': granted,
      'textVersion': textVersion,
    });
    return {
      'success': true,
      'consent': {
        'type': 'boat_market_news',
        'granted': granted,
        'text_version': textVersion,
      },
    };
  }

  @override
  Future<void> deleteMe(String token) async {
    deleteMeCalls.add(token);
  }

  @override
  Future<Map<String, dynamic>> uploadBackup(String token, {required String deviceId, required String content}) async {
    return {'success': true, 'backup': {'id': 'test-b1-backup'}};
  }

  @override
  Future<List<Map<String, dynamic>>> getBackups(String token) async {
    return [];
  }

  @override
  Future<String> downloadBackup(String token, String backupId) async {
    return '{}';
  }
}

void main() {
  late FlutterSecureStorage storage;
  late FakeHullqApiClient fakeApiClient;
  late FakeAuth0Adapter fakeAuth0Adapter;
  late Auth0HullqAuthService authService;
  late AppDatabase db;

  const fakeJwtToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6InRlc3Qta2V5In0.eyJzdWIiOiJhdXRoMHxza2lwcGVyIn0.fake_sig';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    fakeApiClient = FakeHullqApiClient();
    fakeAuth0Adapter = FakeAuth0Adapter(
      credentials: Credentials(
        idToken: fakeJwtToken,
        accessToken: fakeJwtToken,
        user: const UserProfile(
          sub: 'auth0|skipper',
          email: 'skipper@adria-sailing.com',
        ),
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 2)),
        scopes: const {'openid', 'profile', 'email', 'offline_access'},
        tokenType: 'Bearer',
      ),
    );
    authService = Auth0HullqAuthService(
      storage: storage,
      auth0Adapter: fakeAuth0Adapter,
      apiClient: fakeApiClient,
    );
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Slice B1 / BC-1A: Auth0HullqAuthService Unit Tests & Negative Contract Guard', () {
    test('1. Login ruft KEIN GET /v1/me ab, sendet kein Consent an Backend und setzt Status auf trial (BC-1A)', () async {
      final success = await authService.loginWithGoogle(newsletterOptIn: true);

      expect(success, isTrue);
      // BC-1A Invariante: Kein automatisches GET /v1/me, um Account-Auferstehung zu verhindern
      expect(fakeApiClient.getMeCalls, isEmpty);

      // BC-1A Invariante: Keine Übermittlung an Backend ohne existierenden Provy-Account
      expect(fakeApiClient.updateConsentCalls, isEmpty);

      // Gespeichert in FlutterSecureStorage
      final savedToken = await storage.read(key: Auth0HullqAuthService.keyAuthToken);
      expect(savedToken, fakeJwtToken);
      final savedEmail = await storage.read(key: Auth0HullqAuthService.keyUserEmail);
      expect(savedEmail, 'skipper@adria-sailing.com');

      // BC-1A Invariante: Auth0 Login verleiht NICHT automatisch Mitgliedschaft
      final status = await authService.getMembershipStatus();
      expect(status, HullqMembershipStatus.trial);
      expect(await authService.isAuthenticated(), isTrue);
      expect(authService.lastNewsletterConsent, isTrue);
    });

    test('2. Login ohne Einwilligung speichert lastNewsletterConsent=false und sendet kein Backend-Call', () async {
      final success = await authService.loginWithEmail('skipper@example.com', newsletterOptIn: false);

      expect(success, isTrue);
      expect(fakeApiClient.updateConsentCalls, isEmpty);
      expect(fakeApiClient.getMeCalls, isEmpty);
      expect(authService.lastNewsletterConsent, isFalse);
    });

    test('3. deleteAccount bereinigt lokalen Speicher und ruft in BC-1A KEIN ungeschütztes Backend-DELETE auf (O-01)', () async {
      // Zuerst anmelden
      await authService.loginWithApple(newsletterOptIn: false);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNotNull);

      // Konto löschen
      await authService.deleteAccount();

      // BC-1A Invariante: Kein ungeschütztes Backend-DELETE und HullQ-Auth0 Identität bleibt bestehen
      expect(fakeApiClient.deleteMeCalls, isEmpty);

      // Lokaler Speicher vollständig geleert
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);
      expect(await storage.read(key: Auth0HullqAuthService.keyUserEmail), isNull);
      expect(await storage.read(key: Auth0HullqAuthService.keyMembershipStatus), isNull);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await authService.isAuthenticated(), isFalse);
    });

    test('4. logout bereinigt Tokens ohne Backend-Löschung', () async {
      await authService.loginWithGoogle(newsletterOptIn: false);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNotNull);

      await authService.logout();

      expect(fakeApiClient.deleteMeCalls, isEmpty);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await authService.isAuthenticated(), isFalse);
    });
  });

  group('Slice B1 / BC-1A: Widget-Tests für UnlockSheet mit Auth0 & Checkbox', () {
    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          hullqAuthServiceProvider.overrideWithValue(authService),
          auth0AdapterProvider.overrideWithValue(fakeAuth0Adapter),
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('de'), Locale('en')],
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: UnlockSheet()),
        ),
      );
    }

    testWidgets('5. Checkbox ist beim Öffnen strikt unmarkiert (false, GEMINI.md Regel)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('6. Anmeldeklick mit Checkbox übergibt optIn=true lokal ohne vorzeitigen Backend-Call', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Checkbox anklicken
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final checkedBox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkedBox.value, isTrue);

      // Google-Login Button anklicken
      final googleBtn = find.text('Mit Google fortfahren');
      expect(googleBtn, findsOneWidget);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      // Verifizieren, dass Einwilligung lokal registriert, aber noch kein unregistrierter Backend-Call abgesetzt wurde
      expect(authService.lastNewsletterConsent, isTrue);
      expect(fakeApiClient.updateConsentCalls, isEmpty);
      expect(fakeApiClient.getMeCalls, isEmpty);
    });
  });
}

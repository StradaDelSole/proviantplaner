import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
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
  late Auth0HullqAuthService authService;
  late AppDatabase db;

  const fakeJwtToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6InRlc3Qta2V5In0.eyJzdWIiOiJhdXRoMHxza2lwcGVyIn0.fake_sig';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    fakeApiClient = FakeHullqApiClient();
    authService = Auth0HullqAuthService(
      storage: storage,
      apiClient: fakeApiClient,
      tokenProvider: ({required String connection, String? email}) async => fakeJwtToken,
    );
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Slice B1: Auth0HullqAuthService Unit Tests & Backend API Integration', () {
    test('1. Login ruft GET /v1/me ab, setzt Einwilligung mit Textversion "v1.0" und sichert Token', () async {
      final success = await authService.loginWithGoogle(newsletterOptIn: true);

      expect(success, isTrue);
      // GET /v1/me wurde mit dem Auth0-Token aufgerufen
      expect(fakeApiClient.getMeCalls, contains(fakeJwtToken));

      // PUT /v1/consents/boat-market-news wurde mit granted=true und textVersion='v1.0' aufgerufen
      expect(fakeApiClient.updateConsentCalls.length, 1);
      expect(fakeApiClient.updateConsentCalls.first['token'], fakeJwtToken);
      expect(fakeApiClient.updateConsentCalls.first['granted'], isTrue);
      expect(fakeApiClient.updateConsentCalls.first['textVersion'], 'v1.0');

      // Gespeichert in FlutterSecureStorage
      final savedToken = await storage.read(key: Auth0HullqAuthService.keyAuthToken);
      expect(savedToken, fakeJwtToken);
      final status = await authService.getMembershipStatus();
      expect(status, HullqMembershipStatus.member);
    });

    test('2. Login ohne Einwilligung sendet granted=false mit Textversion "v1.0"', () async {
      final success = await authService.loginWithEmail('skipper@example.com', newsletterOptIn: false);

      expect(success, isTrue);
      expect(fakeApiClient.updateConsentCalls.length, 1);
      expect(fakeApiClient.updateConsentCalls.first['granted'], isFalse);
      expect(fakeApiClient.updateConsentCalls.first['textVersion'], 'v1.0');
    });

    test('3. deleteAccount ruft DELETE /v1/me mit Token auf und bereinigt lokalen Speicher', () async {
      // Zuerst anmelden
      await authService.loginWithApple(newsletterOptIn: false);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNotNull);

      // Konto löschen
      await authService.deleteAccount();

      // Backend DELETE /v1/me aufgerufen
      expect(fakeApiClient.deleteMeCalls, contains(fakeJwtToken));

      // Lokaler Speicher vollständig geleert
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);
      expect(await storage.read(key: Auth0HullqAuthService.keyUserEmail), isNull);
      expect(await storage.read(key: Auth0HullqAuthService.keyMembershipStatus), isNull);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
    });

    test('4. logout bereinigt Tokens ohne Backend-Löschung', () async {
      await authService.loginWithGoogle(newsletterOptIn: false);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNotNull);

      await authService.logout();

      expect(fakeApiClient.deleteMeCalls, isEmpty);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
    });
  });

  group('Slice B1: Widget-Tests für UnlockSheet mit Auth0 & Checkbox', () {
    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          hullqAuthServiceProvider.overrideWithValue(authService),
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

    testWidgets('6. Anmeldeklick mit Checkbox ruft Auth0 & Backend mit optIn=true auf', (tester) async {
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

      // Verifizieren, dass Einwilligung mit granted=true übermittelt wurde
      expect(fakeApiClient.updateConsentCalls.length, 1);
      expect(fakeApiClient.updateConsentCalls.first['granted'], isTrue);
      expect(fakeApiClient.updateConsentCalls.first['textVersion'], 'v1.0');
    });
  });
}

import 'dart:async';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/config/auth0_config.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/auth0_adapter.dart';
import 'package:proviantplaner/core/services/hullq_api_client.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_service.dart';
import 'package:drift/native.dart';

/// Test-Fake für [HullqApiClient], zeichnet Aufrufe auf.
class TrackingHullqApiClient implements HullqApiClient {
  final List<String> getMeCalls = [];
  final List<Map<String, dynamic>> updateConsentCalls = [];
  final List<String> deleteMeCalls = [];

  bool simulateNetworkError = false;

  @override
  Future<Map<String, dynamic>> getMe(String token) async {
    if (simulateNetworkError) throw Exception('500 Internal Server Error');
    getMeCalls.add(token);
    return {'account': {'id': 'acc_1'}};
  }

  @override
  Future<Map<String, dynamic>> updateConsent(
    String token, {
    required bool granted,
    required String textVersion,
  }) async {
    if (simulateNetworkError) throw Exception('503 Service Unavailable');
    updateConsentCalls.add({
      'token': token,
      'granted': granted,
      'textVersion': textVersion,
    });
    return {'success': true};
  }

  @override
  Future<void> deleteMe(String token) async {
    if (simulateNetworkError) throw Exception('404 Not Found');
    deleteMeCalls.add(token);
  }

  @override
  Future<Map<String, dynamic>> uploadBackup(String token, {required String deviceId, required String content}) async {
    return {'success': true};
  }

  @override
  Future<List<Map<String, dynamic>>> getBackups(String token) async => [];

  @override
  Future<String> downloadBackup(String token, String backupId) async => '{}';
}

void main() {
  late FlutterSecureStorage storage;
  late TrackingHullqApiClient fakeApiClient;
  late FakeAuth0Adapter fakeAuth0Adapter;
  late Auth0HullqAuthService authService;
  late AppDatabase db;

  Credentials buildCredentials({
    String sub = 'auth0|test_skipper_1',
    String email = 'skipper@adria-sailing.com',
    String accessToken = 'access_token_valid_123',
    String idToken = 'id_token_valid_123',
    DateTime? expiresAt,
  }) {
    return Credentials(
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: 'refresh_token_abc',
      expiresAt: expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 1)),
      scopes: const {'openid', 'profile', 'email', 'offline_access'},
      user: UserProfile(sub: sub, email: email),
      tokenType: 'Bearer',
    );
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    fakeApiClient = TrackingHullqApiClient();
    fakeAuth0Adapter = FakeAuth0Adapter(credentials: buildCredentials());
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

  group('BC-1A: Mandatory Negative and Concurrency Tests (A01–A08)', () {
    test('A01: Nicht konfigurierter Client / Abgebrochener SDK-Login (User Cancelled)', () async {
      // 1. User bricht Auth0 Web-Login ab
      fakeAuth0Adapter.isUserCancelled = true;
      final resultCancelled = await authService.loginWithGoogle(newsletterOptIn: false);

      expect(resultCancelled, isFalse, reason: 'Abbruch darf nicht als Erfolg gewertet werden');
      expect(await authService.getAuthToken(), isNull);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await authService.isAuthenticated(), isFalse);

      // 2. Unkonfigurierter Client (leere Client-ID)
      final unconfiguredAdapter = NativeAuth0Adapter(
        config: const Auth0Config(clientId: '', domain: ''),
      );
      final unconfiguredService = Auth0HullqAuthService(
        storage: storage,
        auth0Adapter: unconfiguredAdapter,
        apiClient: fakeApiClient,
      );

      final resultUnconfigured = await unconfiguredService.loginWithEmail(
        'test@hullq.com',
        newsletterOptIn: false,
      );
      expect(resultUnconfigured, isFalse, reason: 'Unkonfigurierter Client muss fail-closed fehlschlagen');
      expect(await unconfiguredService.getAuthToken(), isNull);

      // 3. SDK wirft Exception beim Login
      fakeAuth0Adapter.isUserCancelled = false;
      fakeAuth0Adapter.shouldThrowOnLogin = true;
      final resultException = await authService.loginWithApple(newsletterOptIn: false);
      expect(resultException, isFalse);
      expect(await authService.getAuthToken(), isNull);
    });

    test('A02: SDK Credentials valide, API offline/500 -> Authentifizierung getrennt von Mitgliedschaft', () async {
      fakeApiClient.simulateNetworkError = true;

      final success = await authService.loginWithGoogle(newsletterOptIn: true);
      expect(success, isTrue);

      // BC-1A Invariante: Kein vorzeitiger GET /v1/me Aufruf (verhindert Account-Auferstehung)
      expect(fakeApiClient.getMeCalls, isEmpty);
      // BC-1A Invariante: Kein updateConsent an Backend ohne Provy-Account
      expect(fakeApiClient.updateConsentCalls, isEmpty);

      // Auth0 Authentifizierung ist wahrheitsgemäß gespeichert
      expect(await authService.isAuthenticated(), isTrue);
      expect(await authService.getAuthToken(), 'access_token_valid_123');
      expect(await authService.getUserEmail(), 'skipper@adria-sailing.com');

      // Aber Provy Mitgliedschaft bleibt trial (Entkopplung BC-1A vs BC-1B)
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);
    });

    test('A03: Token abgelaufen, Refresh-Fehlschlag, App-Neustart -> Kein Stale-Token-Zugriff', () async {
      // 1. Zuerst mit abgelaufenem Token anmelden
      final expiredCreds = buildCredentials(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );
      fakeAuth0Adapter.credentials = expiredCreds;
      await authService.loginWithEmail('captain@sea.org', newsletterOptIn: false);

      // 2. Token-Refresh schlägt fehl
      fakeAuth0Adapter.shouldThrowOnRenew = true;

      // 3. getAuthToken() versucht Erneuerung, scheitert und purgt den abgelaufenen Token
      final token = await authService.getAuthToken();
      expect(token, isNull, reason: 'Abgelaufener Token darf bei Refresh-Fehlschlag nicht zurückgegeben werden');
      expect(await authService.isAuthenticated(), isFalse);
      expect(await authService.getMembershipStatus(), HullqMembershipStatus.trial);

      // 4. App-Neustart simulieren: Neuer Service auf bestehendem Speicher
      final restartedService = Auth0HullqAuthService(
        storage: storage,
        auth0Adapter: fakeAuth0Adapter,
        apiClient: fakeApiClient,
      );
      expect(await restartedService.getAuthToken(), isNull);
      expect(await restartedService.isAuthenticated(), isFalse);
      expect(await restartedService.getMembershipStatus(), HullqMembershipStatus.trial);
    });

    test('A04: Concurrency: Logout während Refresh, Doppel-Refresh & Account-Wechsel', () async {
      // Teil 1: Logout während laufendem Refresh
      final expiredCreds = buildCredentials(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );
      fakeAuth0Adapter.credentials = expiredCreds;
      fakeAuth0Adapter.renewDelay = const Duration(milliseconds: 50);

      await authService.loginWithGoogle(newsletterOptIn: false);

      // Refresh anstoßen (asynchron)
      final refreshFuture = authService.getAuthToken();

      // Parallel abmelden
      await authService.logout();

      final resultAfterLogout = await refreshFuture;
      expect(resultAfterLogout, isNull, reason: 'Token aus Refresh darf nach Logout nicht persistiert oder zurückgegeben werden');
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);

      // Teil 2: Zwei gleichzeitige Token-Refreshes (Single-Flight Koordination)
      fakeAuth0Adapter.renewDelay = const Duration(milliseconds: 30);
      fakeAuth0Adapter.credentials = expiredCreds;
      await authService.loginWithEmail('singleflight@test.com', newsletterOptIn: false);
      fakeAuth0Adapter.renewCredentialsCallCount = 0;

      final future1 = authService.getAuthToken();
      final future2 = authService.getAuthToken();

      final tokens = await Future.wait([future1, future2]);
      expect(tokens[0], isNotNull);
      expect(tokens[0], tokens[1], reason: 'Beide Aufrufe müssen denselben erneuerten Token erhalten');
      expect(fakeAuth0Adapter.renewCredentialsCallCount, 1, reason: 'Refresh muss single-flight koordiniert sein');

      // Teil 3: Account-Wechsel: Account A -> Account B
      fakeAuth0Adapter.renewDelay = null;
      fakeAuth0Adapter.credentials = buildCredentials(
        sub: 'auth0|account_a',
        email: 'user_a@hullq.com',
        accessToken: 'token_account_a',
      );
      await authService.loginWithGoogle(newsletterOptIn: false);
      expect(await authService.getAuthToken(), 'token_account_a');
      expect(await authService.getUserEmail(), 'user_a@hullq.com');

      fakeAuth0Adapter.credentials = buildCredentials(
        sub: 'auth0|account_b',
        email: 'user_b@hullq.com',
        accessToken: 'token_account_b',
      );
      await authService.loginWithGoogle(newsletterOptIn: false);
      expect(await authService.getAuthToken(), 'token_account_b');
      expect(await authService.getUserEmail(), 'user_b@hullq.com');
      // Redundante Token-Kopie im Speicher ist eliminiert (Finding B)
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);
    });

    test('A05: Newsletter Opt-In Genauigkeit (false, true, keine unaufgeforderte Übermittlung)', () async {
      // 1. Login mit Opt-In = false
      await authService.loginWithGoogle(newsletterOptIn: false);
      expect(authService.lastNewsletterConsent, isFalse);
      expect(await storage.read(key: Auth0HullqAuthService.keyNewsletterConsent), 'false');
      expect(fakeApiClient.updateConsentCalls, isEmpty);

      // 2. Login mit Opt-In = true
      await authService.loginWithApple(newsletterOptIn: true);
      expect(authService.lastNewsletterConsent, isTrue);
      expect(await storage.read(key: Auth0HullqAuthService.keyNewsletterConsent), 'true');
      expect(fakeApiClient.updateConsentCalls, isEmpty);
    });

    test('A06: Provy Löschaktion bei unvollständigem Cloud-Endpunkt -> Keine Fake-Löschung, Auth0 bleibt erhalten', () async {
      await authService.loginWithGoogle(newsletterOptIn: true);
      expect(await authService.isAuthenticated(), isTrue);

      await authService.deleteAccount();

      // BC-1A Invariante: Kein Backend-DELETE ausgeführt
      expect(fakeApiClient.deleteMeCalls, isEmpty);
      // Lokale Session bereinigt
      expect(await authService.getAuthToken(), isNull);
      expect(await authService.getUserEmail(), isNull);
      expect(await authService.isAuthenticated(), isFalse);
      expect(fakeAuth0Adapter.clearCredentialsCallCount, greaterThanOrEqualTo(1));
    });

    test('A07: Konfiguration der Callback- und Logout-URLs & fail-closed Standard', () {
      const config = Auth0Config.standard;
      expect(config.domain, 'auth.hullq.com');
      expect(config.audience, 'https://api.planer.hullq.com');
      expect(config.customScheme, 'provy');

      // NativeAdapter mit ungültigen Parametern
      final adapter = NativeAuth0Adapter(
        config: const Auth0Config(domain: '', clientId: ''),
      );
      expect(adapter.hasValidCredentials(), completion(isFalse));
      expect(adapter.getCredentials(), completion(isNull));
    });

    test('A08: Entitlements-Entkopplung: AuthState.isLoggedIn wahr, aber isMember falsch', () async {
      final notifier = AuthNotifier(authService);
      await notifier.refresh();
      expect(notifier.state.isLoggedIn, isFalse);
      expect(notifier.state.isMember, isFalse);

      final loggedIn = await notifier.loginWithGoogle(newsletterOptIn: false);
      expect(loggedIn, isTrue);

      // AuthState Entkopplung:
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.isLoggedIn, isTrue, reason: 'Nutzer sieht, dass er bei HullQ angemeldet ist');
      expect(notifier.state.isMember, isFalse, reason: 'Auth0-Login schaltet keine Provy-Mitgliedschaft frei');
      expect(notifier.state.status, HullqMembershipStatus.trial);

      // Offline-first Trip-Regeln bleiben intakt
      final entitlements = EntitlementsService(authService: authService, tripDao: db.tripDao);
      expect(await entitlements.canCreateNewTrip(), isTrue);
    });
  });

  group('BC-1A Amendment Review Findings A–E: Rigorous Verification', () {
    test('Finding B-1: SDK CredentialsManager Silent Token Renewal (Token A -> Token B)', () async {
      final initialCreds = buildCredentials(
        sub: 'auth0|silent_renew_user',
        email: 'renew@hullq.com',
        accessToken: 'initial_token_A',
      );
      fakeAuth0Adapter.credentials = initialCreds;
      final loginSuccess = await authService.loginWithGoogle(newsletterOptIn: false);
      expect(loginSuccess, isTrue);

      // Erster Abruf liefert Token A
      expect(await authService.getAuthToken(), 'initial_token_A');
      // Verifiziere: Kein Token im SecureStorage
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);

      // Simuliere SDK-interne stumme Erneuerung im CredentialsManager
      fakeAuth0Adapter.silentlyRenewedToken = 'silently_renewed_token_B';

      // AuthService muss ohne Neuanmeldung direkt den neuen Token B liefern
      final renewedToken = await authService.getAuthToken();
      expect(renewedToken, 'silently_renewed_token_B');
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);
    });

    test('Finding B-2: App-Neustart ohne lokalen Token-Key liest direkt aus SDK', () async {
      final creds = buildCredentials(
        sub: 'auth0|restart_user',
        email: 'restart@hullq.com',
        accessToken: 'valid_sdk_token_xyz',
      );
      fakeAuth0Adapter.credentials = creds;
      await authService.loginWithApple(newsletterOptIn: true);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);

      // Simuliere App-Neustart: Neue AuthService-Instanz mit existierendem SecureStorage und CredentialsManager
      final restartedAdapter = FakeAuth0Adapter(storedCredentials: creds);
      final restartedService = Auth0HullqAuthService(
        storage: storage,
        auth0Adapter: restartedAdapter,
        apiClient: fakeApiClient,
      );

      expect(await restartedService.isAuthenticated(), isTrue);
      expect(await restartedService.getAuthToken(), 'valid_sdk_token_xyz');
      expect(await restartedService.getUserEmail(), 'restart@hullq.com');
      expect(await storage.read(key: Auth0HullqAuthService.keyAuthToken), isNull);
    });

    test('Finding C-1: Logout während laufendem Login bricht persistenten Zustand linearisierbar ab', () async {
      final creds = buildCredentials(sub: 'auth0|concurrent_login');
      fakeAuth0Adapter.loginCompleter = Completer<Credentials?>();

      // Login starten (blockiert an der Barriere)
      final loginFuture = authService.loginWithGoogle(newsletterOptIn: true);

      // Während Login läuft: Logout anstoßen
      await authService.logout();

      // Login vollenden lassen
      fakeAuth0Adapter.loginCompleter!.complete(creds);
      final loginResult = await loginFuture;

      expect(loginResult, isFalse, reason: 'Login während Logout darf nicht erfolgreich abschließen');
      expect(await authService.isAuthenticated(), isFalse);
      expect(await authService.getAuthToken(), isNull);
      expect(await authService.getUserEmail(), isNull);
      expect(await storage.read(key: Auth0HullqAuthService.keyUserEmail), isNull);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuth0Sub), isNull);
    });

    test('Finding C-2: Logout während verzögertem CredentialsManager-Read liefert null und invalidiert Single-Flight', () async {
      final creds = buildCredentials(sub: 'auth0|delayed_read');
      fakeAuth0Adapter.credentials = creds;
      await authService.loginWithGoogle(newsletterOptIn: false);

      fakeAuth0Adapter.getCredentialsCompleter = Completer<Credentials?>();

      // getAuthToken anstoßen (blockiert im Adapter)
      final tokenFuture = authService.getAuthToken();

      // Parallel abmelden
      await authService.logout();

      // Read vollenden lassen
      final completer = fakeAuth0Adapter.getCredentialsCompleter!;
      fakeAuth0Adapter.getCredentialsCompleter = null;
      completer.complete(creds);
      final tokenResult = await tokenFuture;

      expect(tokenResult, isNull, reason: 'Token-Abruf nach Logout muss null liefern');
      expect(await authService.isAuthenticated(), isFalse);
    });

    test('Finding C-3: Überlappender Account-Wechsel: Alter Login überholt durch neuen Login', () async {
      final completerA = Completer<Credentials?>();
      fakeAuth0Adapter.loginCompleter = completerA;

      // 1. Login A starten
      final loginAFuture = authService.loginWithEmail('user_a@hullq.com', newsletterOptIn: false);

      // 2. Login B startet vor Abschluss von A
      fakeAuth0Adapter.loginCompleter = null;
      fakeAuth0Adapter.credentials = buildCredentials(
        sub: 'auth0|account_b',
        email: 'user_b@hullq.com',
        accessToken: 'token_b',
      );
      final loginBSuccess = await authService.loginWithGoogle(newsletterOptIn: true);
      expect(loginBSuccess, isTrue);

      // 3. Login A vollendet nun verspätet
      completerA.complete(buildCredentials(
        sub: 'auth0|account_a',
        email: 'user_a@hullq.com',
        accessToken: 'token_a',
      ));
      final loginAResult = await loginAFuture;

      expect(loginAResult, isFalse, reason: 'Veralteter Login A muss durch Epoch-Check abgewiesen werden');
      // Endzustand muss strikt Account B sein
      expect(await authService.getAuthToken(), 'token_b');
      expect(await authService.getUserEmail(), 'user_b@hullq.com');
      expect(await storage.read(key: Auth0HullqAuthService.keyAuth0Sub), 'auth0|account_b');
    });

    test('Finding D-1: SDK clearCredentials Fehler wirft Auth0ClearCredentialsException und verhindert Reaktivierung', () async {
      await authService.loginWithGoogle(newsletterOptIn: false);
      expect(await authService.isAuthenticated(), isTrue);

      // Injiziere Hardware-/Keychain-Löschfehler
      fakeAuth0Adapter.shouldThrowOnClear = true;

      await expectLater(
        authService.logout(),
        throwsA(isA<Auth0ClearCredentialsException>()),
      );

      // Lokale Provy-Session muss trotz Exception bereinigt sein
      expect(await storage.read(key: Auth0HullqAuthService.keyUserEmail), isNull);
      expect(await storage.read(key: Auth0HullqAuthService.keyAuth0Sub), isNull);
    });

    test('Finding E-1: Auth0Config Fail-Closed Validierung und Callback-URLs', () {
      // 1. Standard-Konfiguration ist valide
      const standard = Auth0Config.standard;
      expect(standard.isValid, isTrue);
      expect(standard.domain, Auth0Config.expectedNativeDomain);
      expect(standard.customScheme, Auth0Config.expectedNativeScheme);
      expect(standard.audience, Auth0Config.expectedNativeAudience);

      // 2. Callback-URLs für iOS und Android
      expect(standard.callbackUrlFor(TargetPlatform.android), 'provy://auth.hullq.com/android/com.hullq.proviantplaner/callback');
      expect(standard.callbackUrlFor(TargetPlatform.iOS), 'com.hullq.proviantplaner://auth.hullq.com/ios/com.hullq.proviantplaner/callback');

      // 3. Fail-Closed bei Mismatch
      const invalidDomain = Auth0Config(
        clientId: 'provy-app-client-id',
        domain: 'malicious.attacker.com',
        customScheme: 'provy',
      );
      expect(invalidDomain.isValid, isFalse);

      const invalidScheme = Auth0Config(
        clientId: 'provy-app-client-id',
        domain: 'auth.hullq.com',
        customScheme: 'http',
      );
      expect(invalidScheme.isValid, isFalse);

      const emptyClientId = Auth0Config(
        clientId: '',
        domain: 'auth.hullq.com',
        customScheme: 'provy',
      );
      expect(emptyClientId.isValid, isFalse);

      // NativeAdapter mit invalider Config schlägt sofort fail-closed fehl
      final invalidAdapter = NativeAuth0Adapter(config: invalidDomain);
      expect(invalidAdapter.login(), completion(isNull));
    });
  });
}


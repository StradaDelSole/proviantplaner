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

/// Mock-Speicher mit konfigurierbaren Barrieren fuer deterministische Nebenlaeufigkeitstests.
class BarrierSecureStorage extends FlutterSecureStorage {
  Completer<void>? writeBarrier;
  Completer<void>? onBarrierReached;
  Completer<void>? readBarrier;
  String? pausedKey;
  String? pausedReadKey;
  Set<String> throwOnWriteKeys = {};

  BarrierSecureStorage() : super();

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (throwOnWriteKeys.contains(key)) {
      throw Exception('Simulierter Speicherfehler beim Schreiben von $key');
    }
    if (writeBarrier != null && (pausedKey == null || key == pausedKey)) {
      final barrier = writeBarrier;
      writeBarrier = null;
      pausedKey = null;
      onBarrierReached?.complete();
      await barrier!.future;
    }
    await super.write(
      key: key,
      value: value,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      mOptions: mOptions,
      wOptions: wOptions,
      webOptions: webOptions,
    );
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (readBarrier != null && (pausedReadKey == null || key == pausedReadKey)) {
      await readBarrier!.future;
    }
    return super.read(
      key: key,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      mOptions: mOptions,
      wOptions: wOptions,
      webOptions: webOptions,
    );
  }
}

void main() {
  late BarrierSecureStorage storage;
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
    storage = BarrierSecureStorage();
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
      expect(config.clientId, isEmpty);
      expect(config.isValid, isFalse, reason: 'Ohne Client-ID ist die Standard-Konfiguration fail-closed');

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

    test('Finding C-1: Verzögerter Write von Session A überschreibt oder löscht niemals neuere Session B', () async {
      // 1. Barriere für Session A beim Schreiben von keyUserEmail setzen
      final barrierA = Completer<void>();
      final onReached = Completer<void>();
      storage.writeBarrier = barrierA;
      storage.onBarrierReached = onReached;
      storage.pausedKey = Auth0HullqAuthService.keyUserEmail;

      final credsA = buildCredentials(
        sub: 'auth0|user_a',
        email: 'user_a@hullq.com',
        accessToken: 'token_a',
      );
      fakeAuth0Adapter.credentials = credsA;

      // Login A starten (pausiert im SecureStorage-Write von keyUserEmail)
      final loginAFuture = authService.loginWithGoogle(newsletterOptIn: true);

      // Warte deterministisch, bis Login A die Storage-Barriere erreicht hat
      await onReached.future;

      // 2. Während A pausiert ist: Login B starten und vollständig abschließen
      final credsB = buildCredentials(
        sub: 'auth0|user_b',
        email: 'user_b@hullq.com',
        accessToken: 'token_b',
      );
      fakeAuth0Adapter.credentials = credsB;
      final loginBSuccess = await authService.loginWithApple(newsletterOptIn: false);
      expect(loginBSuccess, isTrue);

      // Verifiziere: Session B ist aktiv und besitzt alle Daten
      expect(await authService.isAuthenticated(), isTrue);
      expect(await authService.getAuthToken(), 'token_b');
      expect(await authService.getUserEmail(), 'user_b@hullq.com');
      expect(await storage.read(key: Auth0HullqAuthService.keyUserEmail), 'user_b@hullq.com');
      expect(await storage.read(key: Auth0HullqAuthService.keyAuth0Sub), 'auth0|user_b');
      expect(await storage.read(key: Auth0HullqAuthService.keyNewsletterConsent), 'false');

      // 3. Nun Barriere für A freigeben (A wacht auf, stellt Stale-Epoch fest)
      barrierA.complete();

      final loginAResult = await loginAFuture;
      expect(loginAResult, isFalse, reason: 'Stale Login A muss false liefern');

      // 4. Verbindliche Verifikation: Session B's Daten wurden durch A's Vollendung NICHT beschädigt oder gelöscht!
      expect(await authService.isAuthenticated(), isTrue);
      expect(await authService.getAuthToken(), 'token_b', reason: 'Usable Token von Session B muss intakt sein');
      expect(await authService.getUserEmail(), 'user_b@hullq.com', reason: 'Email von Session B muss intakt sein');
      expect(await storage.read(key: Auth0HullqAuthService.keyUserEmail), 'user_b@hullq.com');
      expect(await storage.read(key: Auth0HullqAuthService.keyAuth0Sub), 'auth0|user_b');
      expect(await storage.read(key: Auth0HullqAuthService.keyNewsletterConsent), 'false');
      expect(await storage.read(key: Auth0HullqAuthService.keyMembershipStatus), HullqMembershipStatus.trial.rawValue);
    });

    test('Finding C-1b: Veralteter Logout nach neuem Login B beschädigt niemals Session B', () async {
      // Login A
      fakeAuth0Adapter.credentials = buildCredentials(sub: 'auth0|user_a', email: 'user_a@hullq.com');
      await authService.loginWithGoogle(newsletterOptIn: false);

      // Simuliere verzögerten Logout von A (z.B. Clear-Credentials Completer)
      final clearCompleter = Completer<void>();
      fakeAuth0Adapter.clearCredentialsCompleter = clearCompleter;
      final logoutAFuture = authService.logout();

      // Während Logout von A noch läuft, startet und vollendet Login B
      final credsB = buildCredentials(sub: 'auth0|user_b', email: 'user_b@hullq.com', accessToken: 'token_b');
      fakeAuth0Adapter.credentials = credsB;
      fakeAuth0Adapter.clearCredentialsCompleter = null;
      final loginBSuccess = await authService.loginWithEmail('user_b@hullq.com', newsletterOptIn: true);
      expect(loginBSuccess, isTrue);

      // Nun vollendet der alte Logout
      clearCompleter.complete();
      try {
        await logoutAFuture;
      } catch (_) {}

      // Session B muss unbeeinträchtigt und aktiv bleiben
      expect(await authService.isAuthenticated(), isTrue);
      expect(await authService.getAuthToken(), 'token_b');
      expect(await authService.getUserEmail(), 'user_b@hullq.com');
      expect(await storage.read(key: Auth0HullqAuthService.keyAuth0Sub), 'auth0|user_b');
    });

    test('Finding C-2: Verspäteter nativer SDK-Callback von Login A löscht NIEMALS die Credentials von Login B', () async {
      final nativeStyleAdapter = FakeAuth0Adapter();
      final testService = Auth0HullqAuthService(
        storage: storage,
        auth0Adapter: nativeStyleAdapter,
        apiClient: fakeApiClient,
      );

      final callbackBarrierA = Completer<Credentials?>();
      nativeStyleAdapter.loginCompleter = callbackBarrierA;

      // 1. Login A startet (bleibt im SDK-WebAuthentication hängen)
      final loginAFuture = testService.loginWithGoogle(newsletterOptIn: false);

      // 2. Während A im Browser hängt: Login B startet und vollendet erfolgreich
      nativeStyleAdapter.loginCompleter = null;
      final credsB = buildCredentials(
        sub: 'auth0|user_b_native',
        email: 'b_native@hullq.com',
        accessToken: 'token_b_native',
      );
      nativeStyleAdapter.credentials = credsB;
      final loginBSuccess = await testService.loginWithApple(newsletterOptIn: true);
      expect(loginBSuccess, isTrue);

      // Verifiziere: CredentialsManager hält B's Credentials
      expect(nativeStyleAdapter.storedCredentials?.user.sub, 'auth0|user_b_native');
      expect(await testService.getAuthToken(), 'token_b_native');

      // 3. Nun trifft verspäteter nativer Callback von A ein (simuliert WebAuth Callback)
      final credsA = buildCredentials(
        sub: 'auth0|user_a_late',
        email: 'a_late@hullq.com',
        accessToken: 'token_a_late',
      );
      callbackBarrierA.complete(credsA);

      final resultA = await loginAFuture;
      expect(resultA, isFalse, reason: 'Verspäteter Callback A muss abgewiesen werden');

      // 4. VERBINDLICH: B's Credentials im CredentialsManager und B's Token müssen überleben!
      expect(nativeStyleAdapter.storedCredentials, isNotNull);
      expect(nativeStyleAdapter.storedCredentials?.user.sub, 'auth0|user_b_native', reason: 'A darf B niemals aus dem SDK löschen');
      expect(await testService.getAuthToken(), 'token_b_native');
      expect(await testService.getUserEmail(), 'b_native@hullq.com');
      expect(await testService.isAuthenticated(), isTrue);
    });

    test('Finding C-3: Zwei parallele getAuthToken Aufrufe während Logout -> Beide liefern null', () async {
      final creds = buildCredentials(sub: 'auth0|two_callers');
      fakeAuth0Adapter.credentials = creds;
      await authService.loginWithGoogle(newsletterOptIn: false);

      fakeAuth0Adapter.getCredentialsCompleter = Completer<Credentials?>();

      // Zwei gleichzeitige Caller starten getAuthToken()
      final future1 = authService.getAuthToken();
      final future2 = authService.getAuthToken();

      // Parallel abmelden während Token-Retrieval läuft
      await authService.logout();

      // Adapter-Read auflösen
      final completer = fakeAuth0Adapter.getCredentialsCompleter!;
      fakeAuth0Adapter.getCredentialsCompleter = null;
      completer.complete(creds);

      final results = await Future.wait([future1, future2]);

      expect(results[0], isNull, reason: 'Caller 1 muss null erhalten');
      expect(results[1], isNull, reason: 'Caller 2 (In-Flight-Joiner) darf Epoch-Check keinesfalls umgehen');
      expect(await authService.isAuthenticated(), isFalse);
    });

    test('Finding C-4: getUserEmail Post-Await Guard: Kein Stale-Email Leak bei parallelem Logout oder Account-Wechsel', () async {
      final credsA = buildCredentials(sub: 'auth0|email_user_a', email: 'user_a@hullq.com', accessToken: 'token_a');
      fakeAuth0Adapter.credentials = credsA;
      await authService.loginWithGoogle(newsletterOptIn: false);
      expect(await authService.getUserEmail(), 'user_a@hullq.com');

      // 1. Testfall: Logout während laufendem getUserEmail()
      fakeAuth0Adapter.getCredentialsDelay = const Duration(milliseconds: 30);
      final emailFuture1 = authService.getUserEmail();
      // Während getCredentials() noch wartet, abmelden
      await authService.logout();
      final emailResult1 = await emailFuture1;
      expect(emailResult1, isNull, reason: 'getUserEmail muss bei parallelem Logout sofort null liefern');

      // 2. Testfall: Account-Wechsel A -> B während laufendem getUserEmail()
      fakeAuth0Adapter.getCredentialsDelay = null;
      fakeAuth0Adapter.credentials = credsA;
      await authService.loginWithGoogle(newsletterOptIn: false);

      fakeAuth0Adapter.getCredentialsDelay = const Duration(milliseconds: 30);
      final emailFuture2 = authService.getUserEmail();

      // Während des Lesevorgangs auf User B wechseln
      fakeAuth0Adapter.getCredentialsDelay = null;
      final credsB = buildCredentials(sub: 'auth0|email_user_b', email: 'user_b@hullq.com', accessToken: 'token_b');
      fakeAuth0Adapter.credentials = credsB;
      final loginB = await authService.loginWithApple(newsletterOptIn: true);
      expect(loginB, isTrue);

      final emailResult2 = await emailFuture2;
      expect(emailResult2, isNull, reason: 'In-Flight getUserEmail von Session A darf nach Wechsel zu B niemals die alte E-Mail liefern');
      // Aktueller Aufruf liefert korrekt B
      expect(await authService.getUserEmail(), 'user_b@hullq.com');
    });

    test('Finding D-1: Fehlerhafte Quarantäne-Persistenz wirft Auth0RevocationException & ehrliche Recovery-Grenzen', () async {
      final creds = buildCredentials(
        sub: 'auth0|persist_fail_user',
        email: 'fail_persist@hullq.com',
        accessToken: 'fail_persist_token',
      );
      fakeAuth0Adapter.credentials = creds;
      await authService.loginWithGoogle(newsletterOptIn: false);
      expect(await authService.isAuthenticated(), isTrue);

      // Simuliere: Schreiben des Quarantäne-Markers schlägt fehl (Hardware-/Storage-Fehler)
      storage.throwOnWriteKeys = {Auth0HullqAuthService.keySessionRevoked};

      // logout() MUSS Auth0RevocationException werfen
      await expectLater(
        authService.logout(),
        throwsA(isA<Auth0RevocationException>()),
        reason: 'Fehlgeschlagene Quarantäne-Persistenz muss als Sicherheitsfehler geworfen werden',
      );

      // In-Memory ist die Session dennoch revidiert
      expect(await authService.isAuthenticated(), isFalse);
      expect(await authService.getAuthToken(), isNull);
      expect(await authService.getUserEmail(), isNull);

      // Simuliere Neustart nach abgestürztem/unterbrochenem Cleanup ohne Quarantäne-Marker:
      // Wenn der Marker nicht geschrieben werden konnte, kann nach einem Prozess-Kill
      // keine Neustart-Sicherheit garantiert werden -> Dieser Grenzwert wird ehrlich dokumentiert!
      storage.throwOnWriteKeys.clear();
      final freshRestartService = Auth0HullqAuthService(
        storage: storage,
        auth0Adapter: fakeAuth0Adapter,
        apiClient: fakeApiClient,
      );
      // Da _clearLocalSession trotz Quarantäne-Schreibfehler ausgeführt wurde:
      expect(await storage.read(key: Auth0HullqAuthService.keyAuth0Sub), isNull);
      expect(await freshRestartService.isAuthenticated(), isFalse);
    });

    test('Finding D-2: Erfolgreicher Quarantäne-Marker garantiert Fail-Closed auch bei fehlschlagendem SDK-Clear über Neustart', () async {
      final creds = buildCredentials(
        sub: 'auth0|failed_clear_user',
        email: 'clear_fail@hullq.com',
        accessToken: 'uncleared_access_token',
      );
      fakeAuth0Adapter.credentials = creds;
      await authService.loginWithGoogle(newsletterOptIn: false);

      // Injiziere Hardware-/Keychain-Löschfehler im SDK
      fakeAuth0Adapter.shouldThrowOnClear = true;

      await expectLater(
        authService.logout(),
        throwsA(isA<Auth0ClearCredentialsException>()),
      );

      // Quarantäne-Marker wurde erfolgreich geschrieben
      expect(await storage.read(key: Auth0HullqAuthService.keySessionRevoked), 'true');
      expect(await authService.getAuthToken(), isNull);
      expect(await authService.isAuthenticated(), isFalse);

      // Nach App-Neustart mit verbliebenen SDK-Credentials:
      final restartedService = Auth0HullqAuthService(
        storage: storage,
        auth0Adapter: fakeAuth0Adapter,
        apiClient: fakeApiClient,
      );
      expect(await restartedService.isAuthenticated(), isFalse);
      expect(await restartedService.getAuthToken(), isNull);
      expect(await restartedService.getUserEmail(), isNull);

      // Neuer Login hebt Quarantäne auf
      fakeAuth0Adapter.shouldThrowOnClear = false;
      final newCreds = buildCredentials(sub: 'auth0|fresh_new_user', email: 'fresh@hullq.com', accessToken: 'fresh_token');
      fakeAuth0Adapter.credentials = newCreds;
      expect(await restartedService.loginWithApple(newsletterOptIn: true), isTrue);
      expect(await restartedService.isAuthenticated(), isTrue);
      expect(await restartedService.getAuthToken(), 'fresh_token');
      expect(await storage.read(key: Auth0HullqAuthService.keySessionRevoked), isNull);
    });

    test('Finding E-1: Auth0Config Fail-Closed Validierung und Callback-URLs', () {
      // 1. Standard-Konfiguration ohne externe Client-ID ist ungültig (fail-closed!)
      const standard = Auth0Config.standard;
      expect(standard.clientId, isEmpty);
      expect(standard.isValid, isFalse, reason: 'Ohne reale Client-ID muss die Standard-Konfiguration fail-closed ungültig sein');
      expect(standard.domain, Auth0Config.expectedNativeDomain);
      expect(standard.customScheme, Auth0Config.expectedNativeScheme);
      expect(standard.audience, Auth0Config.expectedNativeAudience);

      // 2. Erfundene Platzhalter werden strikt abgewiesen
      const placeholderConfig = Auth0Config(
        clientId: 'provy-app-client',
        domain: 'auth.hullq.com',
        customScheme: 'provy',
      );
      expect(placeholderConfig.isValid, isFalse, reason: 'Erfundene Platzhalter-Client-IDs müssen abgewiesen werden');

      // 3. Gültige echte externe Client-ID ist valide
      const validConfig = Auth0Config(
        clientId: 'real_client_id_prod_999',
        domain: 'auth.hullq.com',
        customScheme: 'provy',
      );
      expect(validConfig.isValid, isTrue);

      // 4. Callback-URLs für iOS und Android
      expect(validConfig.callbackUrlFor(TargetPlatform.android), 'provy://auth.hullq.com/android/com.hullq.proviantplaner/callback');
      expect(validConfig.callbackUrlFor(TargetPlatform.iOS), 'com.hullq.proviantplaner://auth.hullq.com/ios/com.hullq.proviantplaner/callback');

      // 5. Fail-Closed bei ungültiger Domain oder ungültigem Scheme
      const invalidDomain = Auth0Config(
        clientId: 'real_client_id_prod_999',
        domain: 'malicious.attacker.com',
        customScheme: 'provy',
      );
      expect(invalidDomain.isValid, isFalse);

      const invalidScheme = Auth0Config(
        clientId: 'real_client_id_prod_999',
        domain: 'auth.hullq.com',
        customScheme: 'http',
      );
      expect(invalidScheme.isValid, isFalse);
    });
  });
}

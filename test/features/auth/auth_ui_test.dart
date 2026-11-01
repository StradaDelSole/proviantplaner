import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/entitlements/ui/unlock_sheet.dart';
import 'package:proviantplaner/features/more/ui/more_screen.dart';
import 'package:drift/native.dart';

void main() {
  late MockHullqAuthService mockAuth;
  late AppDatabase db;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    mockAuth = MockHullqAuthService();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        hullqAuthServiceProvider.overrideWithValue(mockAuth),
        databaseProvider.overrideWithValue(db),
        ...overrides,
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
        home: Scaffold(body: child),
      ),
    );
  }

  group('Slice S7 / BC-1A: UI-Tests für UnlockSheet, Checkbox, MoreScreen & Authentifizierungs-Status', () {
    testWidgets('1. SC-ACC-01 / Designregel 4: Einwilligungs-Checkbox ist beim Öffnen strikt unmarkiert (false)', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const UnlockSheet()),
      );
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);

      final checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, isFalse, reason: 'Einwilligungs-Checkbox darf niemals vorselektiert sein');
    });

    testWidgets('2. SC-ACC-01: Wert der Checkbox wird bei Google-Login an AuthService übergeben', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const UnlockSheet()),
      );
      await tester.pumpAndSettle();

      final checkboxTileFinder = find.byType(CheckboxListTile);
      expect(checkboxTileFinder, findsOneWidget);
      await tester.tap(checkboxTileFinder);
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      final googleBtnFinder = find.text('Mit Google fortfahren');
      expect(googleBtnFinder, findsOneWidget);
      await tester.tap(googleBtnFinder);
      await tester.pumpAndSettle();

      expect(mockAuth.lastNewsletterConsent, isTrue);
      expect(await mockAuth.getMembershipStatus(), HullqMembershipStatus.member);
    });

    testWidgets('3. SC-ACC-01 Offline-Toleranz: Bei Offline-Zustand sind Login-Buttons deaktiviert und Hinweis sichtbar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const UnlockSheet(isOffline: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anmeldung braucht eine Internetverbindung.'), findsOneWidget);

      expect(find.text('Mit Google fortfahren'), findsOneWidget);
      final googleBtn = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Mit Google fortfahren'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(googleBtn.onPressed, isNull);

      final appleBtn = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Mit Apple fortfahren'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(appleBtn.onPressed, isNull);

      final emailBtn = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Mit E-Mail fortfahren'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(emailBtn.onPressed, isNull);
    });

    testWidgets('4. SC-MORE-01: MoreScreen zeigt nicht-angemeldeten Zustand mit Freischalten-Aufforderung', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const MoreScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('HullQ-Konto'), findsOneWidget);
      expect(find.text('Nicht angemeldet'), findsOneWidget);
      expect(find.text('Kostenlos freischalten mit HullQ-Konto'), findsOneWidget);
      expect(find.text('Abmelden'), findsNothing);
    });

    testWidgets('5. Finding A: MoreScreen zeigt angemeldeten Zustand mit E-Mail, Badge, erreichbarem Abmelden und ehrlichem Lösch-Hinweis', (tester) async {
      await mockAuth.loginWithEmail('captain.ahab@sea.org', newsletterOptIn: false);

      await tester.pumpWidget(
        buildTestableWidget(const MoreScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('captain.ahab@sea.org'), findsOneWidget);
      expect(find.text('HullQ-Mitglied'), findsOneWidget);
      expect(find.text('MITGLIED'), findsOneWidget);
      expect(find.text('Abmelden'), findsOneWidget);
      expect(find.text('Lokale Anmeldedaten entfernen'), findsOneWidget);
    });

    testWidgets('6. Finding A: Lokale Anmeldedaten entfernen öffnet Dialog und zeigt ehrliche Rückmeldung ohne Fake-Cloud-Löschung', (tester) async {
      await mockAuth.loginWithEmail('sailor.delete@hullq.com', newsletterOptIn: true);

      await tester.pumpWidget(
        buildTestableWidget(const MoreScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('sailor.delete@hullq.com'), findsOneWidget);

      // Auf "Lokale Anmeldedaten entfernen" tippen
      final deleteBtnFinder = find.text('Lokale Anmeldedaten entfernen');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Ehrlicher Bestätigungsdialog: informiert über Erhalt der Identität und fehlende Server-Löschung
      expect(find.text('Lokale Anmeldedaten entfernen?'), findsOneWidget);
      expect(find.text('Lokale Daten entfernen'), findsOneWidget);

      // Bestätigen
      await tester.tap(find.text('Lokale Daten entfernen'));
      await tester.pumpAndSettle();

      // Status prüfen: lokale Session bereinigt
      expect(await mockAuth.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await mockAuth.getAuthToken(), isNull);
      expect(await mockAuth.getUserEmail(), isNull);

      // Ehrliche Snackbar: Keine fälschliche "Konto gelöscht"-Behauptung
      expect(find.text('Lokale Anmeldedaten wurden entfernt. Das Cloud-Konto wurde nicht gelöscht.'), findsOneWidget);

      // Zurück nach oben scrollen
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(find.text('Nicht angemeldet'), findsOneWidget);
      expect(find.text('Kostenlos freischalten mit HullQ-Konto'), findsOneWidget);
    });

    testWidgets('7. Finding A: Authentifizierter trial-Nutzer sieht E-Mail, ANGEMELDET-Badge und erreichbares Abmelden', (tester) async {
      // Authentifizierter Nutzer mit trial-Status (BC-1A Standard nach Auth0 Login)
      await tester.pumpWidget(
        buildTestableWidget(
          const MoreScreen(),
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _StaticAuthNotifier(
                const AuthState(
                  status: HullqMembershipStatus.trial,
                  email: 'trial.sailor@hullq.com',
                  isAuthenticated: true,
                ),
                mockAuth,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // E-Mail muss sichtbar sein
      expect(find.text('trial.sailor@hullq.com'), findsOneWidget);
      // Status-Text wahrheitsgemäß (Basis / Trial)
      expect(find.text('HullQ-Konto (Basis)'), findsOneWidget);
      // Badge zeigt ANGEMELDET (nicht fälschlich MITGLIED)
      expect(find.text('ANGEMELDET'), findsOneWidget);
      // Logout-Button MUSS sichtbar und erreichbar sein
      expect(find.text('Abmelden'), findsOneWidget);
    });

    testWidgets('8. Finding A: Legacy Member-Nutzer sieht MITGLIED-Badge und HullQ-Mitglied Subtitle', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MoreScreen(),
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _StaticAuthNotifier(
                const AuthState(
                  status: HullqMembershipStatus.member,
                  email: 'legacy.member@hullq.com',
                  isAuthenticated: true,
                ),
                mockAuth,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('legacy.member@hullq.com'), findsOneWidget);
      expect(find.text('HullQ-Mitglied'), findsOneWidget);
      expect(find.text('MITGLIED'), findsOneWidget);
      expect(find.text('Abmelden'), findsOneWidget);
    });
  });
}

class _StaticAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  final HullqAuthService _auth;

  _StaticAuthNotifier(super.state, this._auth);

  @override
  Future<void> refresh() async {}

  @override
  Future<bool> loginWithEmail(String email, {required bool newsletterOptIn}) async => true;

  @override
  Future<bool> loginWithApple({required bool newsletterOptIn}) async => true;

  @override
  Future<bool> loginWithGoogle({required bool newsletterOptIn}) async => true;

  @override
  Future<void> logout() async {
    await _auth.logout();
    state = const AuthState(status: HullqMembershipStatus.trial, email: null, isAuthenticated: false);
  }

  @override
  Future<void> deleteAccount() async {
    await _auth.deleteAccount();
    state = const AuthState(status: HullqMembershipStatus.trial, email: null, isAuthenticated: false);
  }
}

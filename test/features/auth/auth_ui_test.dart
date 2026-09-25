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

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        hullqAuthServiceProvider.overrideWithValue(mockAuth),
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
        home: Scaffold(body: child),
      ),
    );
  }

  group('Slice S7: UI-Tests für UnlockSheet, Checkbox, MoreScreen & Konto löschen', () {
    testWidgets('1. SC-ACC-01 / Designregel 4: Einwilligungs-Checkbox ist beim Öffnen strikt unmarkiert (false)', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const UnlockSheet()),
      );
      await tester.pumpAndSettle();

      // Checkbox suchen
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

      // Checkbox anhaken
      final checkboxTileFinder = find.byType(CheckboxListTile);
      expect(checkboxTileFinder, findsOneWidget);
      await tester.tap(checkboxTileFinder);
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      // Google Login betätigen
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

      // Buttons müssen deaktiviert sein
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
    });

    testWidgets('5. SC-MORE-01: MoreScreen zeigt angemeldeten Zustand mit E-Mail, Badge, Abmelden und Konto löschen', (tester) async {
      // Nutzer vorab anmelden
      await mockAuth.loginWithEmail('captain.ahab@sea.org', newsletterOptIn: false);

      await tester.pumpWidget(
        buildTestableWidget(const MoreScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('captain.ahab@sea.org'), findsOneWidget);
      expect(find.text('HullQ-Mitglied'), findsOneWidget);
      expect(find.text('MITGLIED'), findsOneWidget);
      expect(find.text('Abmelden'), findsOneWidget);
      expect(find.text('Konto löschen'), findsOneWidget);
    });

    testWidgets('6. SC-MORE-01: Konto löschen öffnet Bestätigungsdialog, entfernt Token und setzt Status auf trial zurück', (tester) async {
      await mockAuth.loginWithEmail('sailor.delete@hullq.com', newsletterOptIn: true);

      await tester.pumpWidget(
        buildTestableWidget(const MoreScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('sailor.delete@hullq.com'), findsOneWidget);

      // Auf "Konto löschen" tippen
      final deleteBtnFinder = find.text('Konto löschen');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Dialog prüfen
      expect(find.text('Konto wirklich löschen?'), findsOneWidget);
      expect(find.text('Konto endgültig löschen'), findsOneWidget);

      // Bestätigen
      await tester.tap(find.text('Konto endgültig löschen'));
      await tester.pumpAndSettle();

      // Status prüfen
      expect(await mockAuth.getMembershipStatus(), HullqMembershipStatus.trial);
      expect(await mockAuth.getAuthToken(), isNull);
      expect(await mockAuth.getUserEmail(), isNull);

      // Snackbar prüfen
      expect(find.text('Dein Konto und alle lokalen Daten wurden erfolgreich gelöscht.'), findsOneWidget);

      // Zurück nach oben scrollen, um die Kontokarte zu sehen
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();

      // Karte muss wieder auf "Nicht angemeldet" stehen
      expect(find.text('Nicht angemeldet'), findsOneWidget);
      expect(find.text('Kostenlos freischalten mit HullQ-Konto'), findsOneWidget);
    });
  });
}

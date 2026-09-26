/// Widget-Tests für den Freischalten-Dialog (SC-ACC-01) und StartScreen-Integration (Slice S6).
library;

import 'package:drift/native.dart';
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
import 'package:proviantplaner/core/theme/theme_controller.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_service.dart';
import 'package:proviantplaner/features/entitlements/ui/unlock_sheet.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';

void main() {
  late AppDatabase db;
  late MockHullqAuthService mockAuth;
  late EntitlementsService entitlementsService;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    mockAuth = MockHullqAuthService();
    entitlementsService = EntitlementsService(
      authService: mockAuth,
      tripDao: db.tripDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(
    Widget child, {
    ThemeData? theme,
    AppThemeMode themeMode = AppThemeMode.light,
    bool enableTripCode = false,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hullqAuthServiceProvider.overrideWithValue(mockAuth),
        entitlementsServiceProvider.overrideWithValue(entitlementsService),
        themeControllerProvider.overrideWith((ref) => _MockThemeController(themeMode)),
        tripCodeFeatureFlagProvider.overrideWithValue(enableTripCode),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de'), Locale('en')],
        locale: const Locale('de'),
        home: child,
      ),
    );
  }

  testWidgets('SC-ACC-01: UnlockSheet rendert Titel, Vorteile, Buttons und leere Checkbox', (tester) async {
    // 1. Hell-Modus
    await tester.pumpWidget(buildTestableWidget(const Scaffold(body: UnlockSheet())));
    await tester.pumpAndSettle();

    expect(find.text('Weiteren Törn planen'), findsOneWidget);
    expect(find.text('Unbegrenzte Törns'), findsOneWidget);
    expect(find.text('Sicherung und Wiederherstellung'), findsOneWidget);
    expect(find.text('Mehrere eigene Geräte'), findsOneWidget);

    // Negative Constraint (Designregel 4 & GEMINI.md): Checkbox IMMER initial unmarkiert!
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    final Checkbox checkbox = tester.widget(checkboxFinder);
    expect(checkbox.value, isFalse);

    // 2. Nachtwache-Modus
    await tester.pumpWidget(buildTestableWidget(
      const Scaffold(body: UnlockSheet()),
      theme: AppTheme.nightwatchTheme,
      themeMode: AppThemeMode.nightwatch,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Weiteren Törn planen'), findsOneWidget);
  });

  testWidgets('S8a / GEMINI.md Regel 10: Bei ausgeschaltetem Feature-Schalter (v1-Standard) ist keine Törn-Code-Oberfläche erreichbar', (tester) async {
    // Standard-Verhalten für v1 (Schalter ist aus):
    await tester.pumpWidget(buildTestableWidget(const Scaffold(body: UnlockSheet()), enableTripCode: false));
    await tester.pumpAndSettle();

    // Sicherstellen, dass weder Button noch Eingabefeld für Törn-Codes existieren oder sichtbar sind
    expect(find.text('Törn-Code einlösen'), findsNothing);
    expect(find.byIcon(Icons.vpn_key_outlined), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('SC-ACC-01 / v1.1: Bei aktiviertem Feature-Schalter ist Törn-Code-Einlösung erreichbar und schaltet Mitglied frei', (tester) async {
    // Törn-Code-Einlösung nur wenn Feature-Flag aktiv (für v1.1 vorbereitet)
    await tester.pumpWidget(buildTestableWidget(const Scaffold(body: UnlockSheet()), enableTripCode: true));
    await tester.pumpAndSettle();

    // Klick auf "Törn-Code einlösen"
    expect(find.text('Törn-Code einlösen'), findsOneWidget);
    await tester.tap(find.text('Törn-Code einlösen'));
    await tester.pumpAndSettle();

    // Eingabefeld sichtbar
    expect(find.byType(TextField), findsOneWidget);

    // Code eingeben und Einlösen
    await tester.enterText(find.byType(TextField), 'MEMBER-ADRIA');
    await tester.tap(find.text('Einlösen'));
    await tester.pumpAndSettle();

    expect(entitlementsService.activePass?.code, 'MEMBER-ADRIA');
  });

  testWidgets('StartScreen: Zweiter Törn im Probetörn öffnet UnlockSheet statt Setup', (tester) async {
    // 1 Törn in die DB einfügen -> Probetörn verbraucht
    await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Erster Probetörn',
        startDate: DateTime(2026, 8, 1),
      ),
    );

    await tester.pumpWidget(buildTestableWidget(const StartScreen()));
    await tester.pumpAndSettle();

    // Button zum Anlegen eines weiteren Törns drücken
    final newTripBtn = find.text('Neuen Törn anlegen');
    expect(newTripBtn, findsOneWidget);
    await tester.tap(newTripBtn);
    await tester.pumpAndSettle();

    // Prüfen: UnlockSheet (SC-ACC-01) öffnet sich
    expect(find.byType(UnlockSheet), findsOneWidget);
    expect(find.text('Weiteren Törn planen'), findsOneWidget);
  });
}

class _MockThemeController extends ThemeController {
  _MockThemeController(AppThemeMode mode) : super(_MockThemeStorage(mode.name));
}

class _MockThemeStorage implements ThemeStorage {
  final String _val;
  _MockThemeStorage(this._val);

  @override
  Future<String?> readTheme() async => _val;

  @override
  Future<void> saveTheme(String value) async {}
}

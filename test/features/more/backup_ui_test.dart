/// Widget-Tests für Sicherung und Wiederherstellung im Mehr-Screen (Slice S8).
/// Verifiziert UI-Anzeige von Sicherungsstatus, "Jetzt sichern" und Bestätigungsdialog für Restore.
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
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/hullq_backup_service.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/entitlements/data/entitlements_providers.dart';
import 'package:proviantplaner/features/more/ui/more_screen.dart';

void main() {
  late MockHullqAuthService mockAuth;
  late MockHullqBackupService mockBackup;
  late AppDatabase db;
  late BackupCoordinator coordinator;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    mockAuth = MockHullqAuthService();
    mockBackup = MockHullqBackupService();
    db = AppDatabase(NativeDatabase.memory());
    coordinator = BackupCoordinator(
      db: db,
      backupService: mockBackup,
      authService: mockAuth,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        hullqAuthServiceProvider.overrideWithValue(mockAuth),
        hullqBackupServiceProvider.overrideWithValue(mockBackup),
        backupCoordinatorProvider.overrideWithValue(coordinator),
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

  group('Slice S8: Widget-Tests für Sicherung und Wiederherstellung im MoreScreen', () {
    testWidgets('MoreScreen zeigt Status "Noch nie gesichert" für angemeldetes Mitglied ohne Backup', (tester) async {
      await mockAuth.loginWithEmail('captain@sea.com', newsletterOptIn: false);

      await tester.pumpWidget(
        buildTestableWidget(const MoreScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('captain@sea.com'), findsOneWidget);
      expect(find.text('Noch keine Sicherung vorhanden'), findsOneWidget);
      expect(find.text('Jetzt sichern'), findsOneWidget);
    });

    testWidgets('Tippen auf "Jetzt sichern" führt Sicherung durch und zeigt Erfolgsmeldung', (tester) async {
      await mockAuth.loginWithEmail('captain@sea.com', newsletterOptIn: false);

      await tester.pumpWidget(
        buildTestableWidget(const MoreScreen()),
      );
      await tester.pumpAndSettle();

      final backupBtnFinder = find.text('Jetzt sichern');
      expect(backupBtnFinder, findsOneWidget);

      await tester.tap(backupBtnFinder);
      await tester.pumpAndSettle();

      // Erfolgs-Snackbar prüfen
      expect(find.text('Sicherung erfolgreich abgeschlossen.'), findsOneWidget);

      // Zeitstempel im Service prüfen
      final timestamp = await mockBackup.getLastBackupTimestamp();
      expect(timestamp, isNotNull);
    });

    testWidgets('Tippen auf "Sicherung wiederherstellen" öffnet Bestätigungsdialog', (tester) async {
      await mockAuth.loginWithEmail('captain@sea.com', newsletterOptIn: false);
      // Vorab Sicherung anlegen, damit der Restore-Button sichtbar ist
      await coordinator.createBackup();

      await tester.pumpWidget(
        buildTestableWidget(const MoreScreen()),
      );
      await tester.pumpAndSettle();

      final restoreBtnFinder = find.text('Sicherung wiederherstellen');
      expect(restoreBtnFinder, findsOneWidget);

      await tester.tap(restoreBtnFinder);
      await tester.pumpAndSettle();

      // Dialog prüfen
      expect(find.text('Möchtest du alle Törns aus der Cloud-Sicherung wiederherstellen? Bestehende lokale Daten werden überschrieben.'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
    });
  });
}

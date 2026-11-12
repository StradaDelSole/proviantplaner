import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/welcome/data/welcome_storage.dart';
import 'package:proviantplaner/features/welcome/ui/welcome_screen.dart';
import 'package:proviantplaner/main.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('R6: Readable Branded Startup & Welcome Sequence', () {
    testWidgets('R6.1: Bestandskunde (hasSeen=true) sieht Branded Launch ca. 2s statt 0.1s-Flash und landet dann auf StartScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            allTripsProvider.overrideWith((ref) => Future.value([])),
            welcomeStorageProvider.overrideWithValue(MemoryWelcomeStorage(initialSeen: true)),
            appStartupRecoveryProvider.overrideWith((ref) async {}),
          ],
          child: const ProviantplanerApp(locale: Locale('de')),
        ),
      );

      // Direkt nach Start: Branded Launch sichtbar
      await tester.pump();
      expect(find.byKey(const Key('app_startup_recovery_loading')), findsOneWidget);
      expect(find.text('PROVY'), findsOneWidget);

      // Nach 500ms: weiterhin lesbar sichtbar (kein 0.1s-Flash!)
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('app_startup_recovery_loading')), findsOneWidget);
      expect(find.text('PROVY'), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);

      // Nach 1500ms: weiterhin sichtbar
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(const Key('app_startup_recovery_loading')), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);

      // Nach Ablauf von ~2s und Settle: StartScreen erscheint sauber
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app_startup_recovery_loading')), findsNothing);
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.text('Meine Törns'), findsOneWidget);
    });

    testWidgets('R6.2: Erststart (hasSeen=false) zeigt Branded Launch ~2s, dann WelcomeScreen der bis zur Nutzeraktion stehen bleibt', (tester) async {
      final storage = MemoryWelcomeStorage(initialSeen: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            allTripsProvider.overrideWith((ref) => Future.value([])),
            welcomeStorageProvider.overrideWithValue(storage),
            appStartupRecoveryProvider.overrideWith((ref) async {}),
          ],
          child: const ProviantplanerApp(locale: Locale('de')),
        ),
      );

      await tester.pump();
      expect(find.byKey(const Key('app_startup_recovery_loading')), findsOneWidget);

      // Nach 2s -> WelcomeScreen erscheint
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('PROVY'), findsOneWidget);

      // Auch nach weiteren 10 Sekunden ohne Aktion verschwindet WelcomeScreen NICHT automatisch
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(storage.writeCalls, equals(0));

      // Erst nach explizitem Tippen auf CTA -> StartScreen
      await tester.tap(find.byKey(const ValueKey('welcome_get_started_button')));
      await tester.pumpAndSettle();
      expect(storage.writeCalls, equals(1));
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('R6.3: Recovery-Fehler wird sofort fail-closed ohne 2s-Verzögerung angezeigt', (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            welcomeStorageProvider.overrideWithValue(MemoryWelcomeStorage(initialSeen: true)),
            appStartupRecoveryProvider.overrideWith((ref) => completer.future),
          ],
          child: const ProviantplanerApp(locale: Locale('de')),
        ),
      );

      await tester.pump();
      expect(find.byKey(const Key('app_startup_recovery_loading')), findsOneWidget);

      completer.completeError(Exception('Simulierter Recovery-Fehler'));
      await tester.pumpAndSettle();

      // Fehlerbildschirm sofort sichtbar
      expect(find.byKey(const Key('app_startup_recovery_error')), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);
    });

    testWidgets('R6.4: Reduced Motion (disableAnimations=true) schließt Startsequenz sauber ohne Hänger ab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            allTripsProvider.overrideWith((ref) => Future.value([])),
            welcomeStorageProvider.overrideWithValue(MemoryWelcomeStorage(initialSeen: true)),
            appStartupRecoveryProvider.overrideWith((ref) async {}),
          ],
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: ProviantplanerApp(locale: Locale('de')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(StartScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Tests für UX-C: Begriffe und Aufräumen (UX-Konzept v0.6 & SLICES_v0.16).
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('UX-C Abnahmekriterien Tests', () {
    // Kriterium 1: Suchtest ARB-Dateien – kein "Kitty" / "kitty"
    test('1. Suchtest ARB-Dateien: Kein "Kitty" oder "kitty" in lib/l10n/*.arb', () {
      final l10nDir = Directory('lib/l10n');
      expect(l10nDir.existsSync(), isTrue);

      final arbFiles = l10nDir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();
      expect(arbFiles, isNotEmpty);

      for (final file in arbFiles) {
        final content = file.readAsStringSync();
        final matches = RegExp(r'kitty', caseSensitive: false).allMatches(content).toList();
        expect(
          matches.isEmpty,
          isTrue,
          reason: 'Datei ${file.path} enthält verbotene Vorkommen von "kitty": ${matches.length}',
        );
      }
    });

    // Kriterium 2: Suchtest Codebase – keine alten Texte "Trip Planning", "Setup & Architektur"
    test('2. Suchtest Codebase: Keine alten Texte "Trip Planning" oder "Setup & Architektur" in lib/', () {
      final libDir = Directory('lib');
      final dartAndArbFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.arb'))
          .toList();

      for (final file in dartAndArbFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('Trip Planning'),
          isFalse,
          reason: 'Datei ${file.path} enthält verbotenen Text "Trip Planning"',
        );
        expect(
          content.contains('Setup & Architektur'),
          isFalse,
          reason: 'Datei ${file.path} enthält verbotenen Text "Setup & Architektur"',
        );
      }
    });

    // Kriterium 3: Startbildschirm-Texte in DE und EN
    testWidgets('3a. Startbildschirmtext DE: "Proviant und Bordkasse – ganz einfach"', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allTripsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('de'), Locale('en')],
            locale: const Locale('de'),
            home: const StartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Proviant und Bordkasse – ganz einfach'), findsOneWidget);
      expect(find.textContaining('Törnplanung leicht gemacht'), findsNothing);
    });

    testWidgets('3b. Startbildschirmtext EN: "Provisioning & crew fund made easy"', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allTripsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('de'), Locale('en')],
            locale: const Locale('en'),
            home: const StartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provisioning & crew fund made easy'), findsOneWidget);
      expect(find.textContaining('Trip Planning Made Easy'), findsNothing);
    });

    // Kriterium 4: Verbindliche Begriffe aus Begriffstabelle
    testWidgets('4. Verbindliche Begriffe nach Begriffstabelle in DE und EN', (tester) async {
      late AppLocalizations l10nDe;
      late AppLocalizations l10nEn;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Builder(builder: (ctx) {
            l10nDe = AppLocalizations.of(ctx)!;
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(builder: (ctx) {
            l10nEn = AppLocalizations.of(ctx)!;
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      // Gemeinsame Kasse der Crew: DE "Bordkasse", EN "Crew fund" (nicht: Kitty, Kitty account)
      expect(l10nDe.fundTitle, 'Bordkasse');
      expect(l10nEn.fundTitle, 'Crew fund');
      expect(l10nEn.fundTitle.toLowerCase(), isNot(contains('kitty')));

      // Einzahlung: DE "Einzahlung erfassen", EN "Add contribution" (nicht: Top-up, deposit)
      expect(l10nDe.fundAddDeposit, 'Einzahlung erfassen');
      expect(l10nEn.fundAddDeposit, 'Add contribution');
      expect(l10nEn.fundAddDeposit.toLowerCase(), isNot(contains('top-up')));

      // Abrechnung: DE "Abrechnung", EN "Settle up" (nicht: Settlement)
      expect(l10nEn.fundSettlementTitle, 'Settle up');
      expect(l10nEn.fundSettlementTitle.toLowerCase(), isNot(contains('settlement')));
      expect(l10nEn.exportSettlementPdf.toLowerCase(), isNot(contains('settlement')));

      // Kassenstand: EN fund balance (nicht kitty)
      expect(l10nEn.fundCurrentBalance.toLowerCase(), isNot(contains('kitty')));
      expect(l10nEn.fundBalancesEqual.toLowerCase(), isNot(contains('kitty')));
    });

    // Kriterium 5: Entfernen nicht mehr erreichbarer Bildschirme und Widgets
    test('5. Entfernte Widgets: trip_bottom_bar.dart wurde erfolgreich gelöscht', () {
      final file = File('lib/features/shopping_list/ui/widgets/trip_bottom_bar.dart');
      expect(file.existsSync(), isFalse, reason: 'trip_bottom_bar.dart sollte gelöscht sein');
    });
  });
}

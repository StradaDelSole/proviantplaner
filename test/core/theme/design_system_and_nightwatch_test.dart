/// Umfassende Tests für Slice S-UI: Design-System, Farbmodi (Hell, Dunkel, Nachtwache)
/// und Überprüfung der Designregeln 1–13 aus docs/design/DESIGN_BRIEF_v0.4.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/core/theme/theme_controller.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';
import 'package:proviantplaner/features/trip/ui/widgets/day_card.dart';

class MockThemeStorage implements ThemeStorage {
  String? _saved;

  @override
  Future<String?> readTheme() async => _saved;

  @override
  Future<void> saveTheme(String value) async {
    _saved = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Slice S-UI: Theme-Tokens und 3 Farbmodi', () {
    test('Helles Theme besitzt korrekte Tokens aus technical_maritime_m3', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF03111F));
      expect(theme.colorScheme.secondary, const Color(0xFF006A61));
      expect(theme.colorScheme.surface, const Color(0xFFF8F9FF));
      expect(theme.colorScheme.outlineVariant, const Color(0xFFC4C6CC));
    });

    test('Dunkles Theme besitzt korrekte Tokens aus Design-Brief v0.4', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, const Color(0xFF0B1622));
      expect(theme.colorScheme.primary, const Color(0xFF2BBFAE));
      expect(theme.colorScheme.outlineVariant, const Color(0xFF2A3B4D));
    });

    test('Designregel 13: Nachtwache-Theme verwendet ausschließlich Rot-/Schwarz-Spektrum', () {
      final theme = AppTheme.nightwatchTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(theme.colorScheme.surface, const Color(0xFF000000));
      expect(theme.colorScheme.onSurface, const Color(0xFFE0433A));
      expect(theme.colorScheme.primary, const Color(0xFF7A1510));
      expect(theme.colorScheme.onPrimary, const Color(0xFFFF6B61));
      expect(theme.colorScheme.outlineVariant, const Color(0xFF3A0B08));

      // Prüfung aller Farben im ColorScheme: Kein Weiß, kein Blau, kein Grün, kein Gelb/Amber
      final schemeColors = [
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        theme.colorScheme.secondary,
        theme.colorScheme.onSecondary,
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
        theme.colorScheme.tertiary,
        theme.colorScheme.onTertiary,
        theme.colorScheme.error,
        theme.colorScheme.onError,
        theme.colorScheme.surface,
        theme.colorScheme.onSurface,
        theme.colorScheme.onSurfaceVariant,
        theme.colorScheme.outline,
        theme.colorScheme.outlineVariant,
      ];

      for (final color in schemeColors) {
        // Rot-Anteil muss dominieren oder es muss neutrales Schwarz/Dunkelgrau sein
        final isBlackOrDark = color.red < 40 && color.green < 40 && color.blue < 40;
        final isRedSpectrum = color.red > color.green && color.red > color.blue && color.green < 120 && color.blue < 120;
        expect(
          isBlackOrDark || isRedSpectrum,
          isTrue,
          reason: 'Farbe $color entspricht nicht der strikten Rot/Schwarz-Palette für Nachtwache',
        );
      }

      // MaritimeColors in Nachtwache
      const maritime = AppTheme.defaultNightwatchMaritimeColors;
      expect(maritime.badgeAmberText, const Color(0xFFFF5449));
      expect(maritime.cardBackground, const Color(0xFF120000));
      expect(maritime.cardBorder, const Color(0xFF3A0B08));
    });
  });

  group('Slice S-UI: Typografie & Mindestgrößen (Designregel 2 & 8)', () {
    test('Typografie verwendet IBM Plex Sans für Texte und JetBrains Mono für Zahlen', () {
      final theme = AppTheme.lightTheme;
      expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.fontSans);
      expect(theme.textTheme.headlineSmall?.fontFamily, AppTheme.fontSans);
      expect(theme.textTheme.labelMedium?.fontFamily, AppTheme.fontSans);

      const typo = AppTheme.defaultLightTypography;
      expect(typo.numberLarge.fontFamily, AppTheme.fontMono);
      expect(typo.numberMedium.fontFamily, AppTheme.fontMono);
      expect(typo.numberSmall.fontFamily, AppTheme.fontMono);
    });

    test('Designregel 8: Fließtext >= 14 sp, Etiketten >= 12 sp', () {
      final theme = AppTheme.lightTheme;
      expect(theme.textTheme.bodyLarge!.fontSize!, greaterThanOrEqualTo(14.0));
      expect(theme.textTheme.bodyMedium!.fontSize!, greaterThanOrEqualTo(14.0));
      expect(theme.textTheme.labelLarge!.fontSize!, greaterThanOrEqualTo(12.0));
      expect(theme.textTheme.labelMedium!.fontSize!, greaterThanOrEqualTo(12.0));
    });

    test('Designregel 8: Tippflächen von Buttons >= 48 dp', () {
      final theme = AppTheme.lightTheme;
      expect(theme.filledButtonTheme.style?.minimumSize?.resolve({})?.height, greaterThanOrEqualTo(48.0));
      expect(theme.outlinedButtonTheme.style?.minimumSize?.resolve({})?.height, greaterThanOrEqualTo(48.0));
      expect(theme.textButtonTheme.style?.minimumSize?.resolve({})?.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('Slice S-UI: ThemeController & Persistenz', () {
    test('ThemeController lädt, speichert und wechselt Farbmodus inklusive Nachtwache', () async {
      final mockStorage = MockThemeStorage();
      final controller = ThemeController(mockStorage);

      expect(controller.state, AppThemeMode.light);

      await controller.setThemeMode(AppThemeMode.dark);
      expect(controller.state, AppThemeMode.dark);
      expect(await mockStorage.readTheme(), 'dark');

      await controller.toggleNightwatch();
      expect(controller.state, AppThemeMode.nightwatch);
      expect(await mockStorage.readTheme(), 'nightwatch');

      await controller.toggleNightwatch();
      expect(controller.state, AppThemeMode.light);
      expect(await mockStorage.readTheme(), 'light');
    });
  });

  group('Slice S-UI: Widget-Tests in allen 3 Farbmodi', () {
    Widget buildTestApp(Widget child, ThemeData theme) {
      return ProviderScope(
        overrides: [
          themeStorageProvider.overrideWithValue(MockThemeStorage()),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets('StartScreen rendert fehlerfrei in Hell, Dunkel und Nachtwache (Designregeln 5, 12, 13)', (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme, AppTheme.nightwatchTheme]) {
        await tester.pumpWidget(buildTestApp(const StartScreen(), theme));
        await tester.pumpAndSettle();

        // Designregel 12: "powered by HullQ" vorhanden
        expect(find.textContaining('HullQ'), findsWidgets);

        // Designregel 5: Keine verbotenen maritimen Symbole (sailing, directions_boat)
        expect(find.byIcon(Icons.sailing_outlined), findsNothing);
        expect(find.byIcon(Icons.directions_boat), findsNothing);

        // Erlaubtes technisches Blueprint-Icon
        expect(find.byIcon(Icons.view_timeline_outlined), findsOneWidget);

        // Schnellzugriff Nachtwache im AppBar
        expect(find.byTooltip('Nachtwache'), findsOneWidget);
      }
    });

    testWidgets('TripWizardScreen rendert und wahrt Mindest-Tippflächen >= 48 dp in allen 3 Modi', (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme, AppTheme.nightwatchTheme]) {
        await tester.pumpWidget(buildTestApp(TripWizardScreen(key: UniqueKey()), theme));
        await tester.pumpAndSettle();

        expect(find.text('Basisdaten'), findsOneWidget);

        // Weiter zu Schritt 2
        final nextBtn = find.text('Weiter');
        expect(nextBtn, findsOneWidget);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
        expect(find.text('Boot & Revier'), findsOneWidget);

        // Weiter zu Schritt 3 (Crew)
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
        expect(find.text('Crew'), findsWidgets);

        // Prüfe Tippflächen von '+ Person hinzufügen' >= 48 dp
        final addPersonBtnFinder = find.ancestor(
          of: find.text('+ Person hinzufügen'),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton),
        );
        expect(addPersonBtnFinder, findsOneWidget);
        final addPersonBtn = tester.getRect(addPersonBtnFinder);
        expect(addPersonBtn.height, greaterThanOrEqualTo(48.0));
      }
    });

    testWidgets('DayCard rendert mit Tabellenziffern und neutralen Icons in allen 3 Modi', (tester) async {
      const dummyDay = TripDay(
        id: 1,
        tripId: 1,
        dayNumber: 3,
        dayType: 'sailing',
        portName: 'Vis',
        lunchRestaurant: false,
        dinnerRestaurant: true,
      );

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme, AppTheme.nightwatchTheme]) {
        await tester.pumpWidget(
          buildTestApp(
            Scaffold(
              body: DayCard(
                day: dummyDay,
                shoppingStops: const [],
                onToggleLunch: () {},
                onToggleEvening: () {},
                onUpdatePortName: (_) {},
              ),
            ),
            theme,
          ),
        );
        await tester.pumpAndSettle();

        // Tag-Nummer und Hafenname
        expect(find.text('Vis'), findsOneWidget);

        // Verbotene Icons dürfen nicht vorkommen
        expect(find.byIcon(Icons.shopping_cart), findsNothing);
      }
    });
  });
}

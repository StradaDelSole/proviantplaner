import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/config/app_config.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/routing/app_router.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/welcome/data/welcome_storage.dart';
import 'package:proviantplaner/features/welcome/ui/welcome_screen.dart';

void main() {
  late AppDatabase db;
  late MemoryWelcomeStorage memoryStorage;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    memoryStorage = MemoryWelcomeStorage(initialSeen: false);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp({
    WelcomeStorage? storage,
    ThemeData? theme,
    Locale? locale,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        welcomeStorageProvider.overrideWithValue(storage ?? memoryStorage),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          disableAnimations: disableAnimations,
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              title: AppConfig.appName,
              theme: theme ?? AppTheme.lightTheme,
              locale: locale ?? const Locale('de'),
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      ),
    );
  }

  group('PROVY BRAND-WELCOME-01: Welcome-Screen (#62)', () {
    testWidgets('1. Erststart zeigt Welcome-Screen mit Branding, 3 Wegpunkten und CTA', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Welcome-Screen ist aktiv
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);

      // Wordmark "PROVY"
      expect(find.text(AppConfig.appName.toUpperCase()), findsOneWidget);

      // Deutsche Texte
      expect(find.text('Smarter planen. Leichter segeln.'), findsOneWidget);
      expect(find.text('Proviant berechnen. Crewkosten teilen. Entspannt abrechnen.'), findsOneWidget);

      // 3 Wegpunkte
      expect(find.text('01'), findsOneWidget);
      expect(find.text('Proviantplanung'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('Bordkasse'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('Abrechnung'), findsOneWidget);

      // CTA Button
      expect(find.byKey(const ValueKey('welcome_get_started_button')), findsOneWidget);
      expect(find.text("Los geht's"), findsOneWidget);
    });

    testWidgets('2. Englische Lokalisierung rendert exaktes freigegebenes Branding', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Provision smarter. Sail lighter.'), findsOneWidget);
      expect(find.text('Plan provisions. Share crew costs. Settle with ease.'), findsOneWidget);
      expect(find.text('Provision planning'), findsOneWidget);
      expect(find.text('Crew costs'), findsOneWidget);
      expect(find.text('Settlement'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('3. Tippen auf "Los geht\'s" persistiert seen-Status und navigiert zu StartScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(await memoryStorage.hasSeenWelcome(), isFalse);

      final ctaButton = find.byKey(const ValueKey('welcome_get_started_button'));
      await tester.tap(ctaButton);
      await tester.pumpAndSettle();

      // Seen-Status ist persistiert
      expect(await memoryStorage.hasSeenWelcome(), isTrue);

      // StartScreen ("Meine Törns") ist sichtbar
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('4. Folgestart mit seen=true überspringt Welcome-Screen und lädt StartScreen direkt', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final seenStorage = MemoryWelcomeStorage(initialSeen: true);
      await tester.pumpWidget(buildTestApp(storage: seenStorage));
      await tester.pumpAndSettle();

      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('5. Reduzierte Bewegung (disableAnimations=true) rendert sofort ohne Animationsverzögerung', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(disableAnimations: true));
      // Nur ein Frame pumpen, kein Settle nötig
      await tester.pump();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text("Los geht's"), findsOneWidget);
      expect(find.text('Proviantplanung'), findsOneWidget);
    });

    testWidgets('6. Nachtwache-Modus rendert strikt in Rot/Schwarz', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(theme: AppTheme.nightwatchTheme));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));

      final cta = tester.widget<FilledButton>(find.byKey(const ValueKey('welcome_get_started_button')));
      expect(cta.style?.backgroundColor?.resolve({}), equals(const Color(0xFFFF3B30)));
    });

    testWidgets('7. Schmaler 320px-Viewport verursacht keinen RenderFlex-Overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

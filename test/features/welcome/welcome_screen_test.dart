import 'dart:async';
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
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';
import 'package:proviantplaner/features/welcome/data/welcome_storage.dart';
import 'package:proviantplaner/features/welcome/ui/welcome_screen.dart';

class CompleterWelcomeStorage implements WelcomeStorage {
  final Completer<bool> readCompleter;
  final Completer<void>? writeCompleter;
  int writeCalls = 0;

  CompleterWelcomeStorage({
    required this.readCompleter,
    this.writeCompleter,
  });

  @override
  Future<bool> hasSeenWelcome() => readCompleter.future;

  @override
  Future<void> setSeenWelcome() async {
    writeCalls++;
    if (writeCompleter != null) {
      await writeCompleter!.future;
    }
  }
}

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
    String initialLocation = '/',
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        welcomeStorageProvider.overrideWithValue(storage ?? memoryStorage),
        appRouterInitialLocationProvider.overrideWithValue(initialLocation),
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
      await tester.pumpAndSettle();

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

  group('PROVY REVIEW AMENDMENT 1: Findings W1 & W2', () {
    testWidgets('W1.1: Asynchron verzögerter Welcome-Check blockiert StartScreen vollständig und zeigt WelcomeGateLoadingScreen', (tester) async {
      final readCompleter = Completer<bool>();
      final delayedStorage = CompleterWelcomeStorage(readCompleter: readCompleter);

      await tester.pumpWidget(buildTestApp(storage: delayedStorage));
      // Frame 0 pumpen
      await tester.pump();

      // W1: StartScreen darf während isLoading NIEMALS gebaut werden
      expect(find.byType(StartScreen), findsNothing);
      expect(find.text('Meine Törns'), findsNothing);
      expect(find.byKey(const Key('welcome_gate_loading')), findsOneWidget);

      // Weitere Frames pumpen: bleibt stabil im Ladezustand
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(StartScreen), findsNothing);
      expect(find.byKey(const Key('welcome_gate_loading')), findsOneWidget);

      // Nun Storage auflösen mit seen = false (Erstnutzer)
      readCompleter.complete(false);
      await tester.pumpAndSettle();

      // Nach Abschluss schaltet Router direkt auf WelcomeScreen um (kein Frame StartScreen)
      expect(find.byKey(const Key('welcome_gate_loading')), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);
    });

    testWidgets('W1.2: Asynchron verzögerter Welcome-Check mit existierendem Törn navigiert direkt zu StartScreen', (tester) async {
      // Törn vorab in der DB anlegen
      await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Vorhandener Törn',
          startDate: DateTime(2026, 9, 1),
        ),
      );

      final readCompleter = Completer<bool>();
      final delayedStorage = CompleterWelcomeStorage(readCompleter: readCompleter);

      await tester.pumpWidget(buildTestApp(storage: delayedStorage));
      await tester.pump();

      expect(find.byKey(const Key('welcome_gate_loading')), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);

      readCompleter.complete(false); // Storage selbst hatte false, aber DB hat Törns
      await tester.pumpAndSettle();

      // Bestehende Nutzer überspringen Welcome automatisch
      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.text('Vorhandener Törn'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('W1.3: Fehler beim initialen Lesen zeigt WelcomeGateErrorScreen mit wiederholbarem Retry', (tester) async {
      memoryStorage.shouldFailRead = true;

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Fehlerbildschirm sichtbar, Home gesperrt
      expect(find.byKey(const Key('welcome_gate_error')), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsNothing);

      // Fehler beheben und auf Retry tippen
      memoryStorage.shouldFailRead = false;
      await tester.tap(find.byKey(const Key('welcome_gate_retry_button')));
      await tester.pumpAndSettle();

      // Nach Retry öffnet sich der WelcomeScreen
      expect(find.byKey(const Key('welcome_gate_error')), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('W1.4: Notfall-Bypass bei Keystore-Lesefehler sperrt Nutzer nicht dauerhaft aus', (tester) async {
      memoryStorage.shouldFailRead = true;

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('welcome_gate_error')), findsOneWidget);

      // Tippen auf "Trotzdem fortfahren"
      await tester.tap(find.byKey(const Key('welcome_gate_skip_button')));
      await tester.pumpAndSettle();

      // App öffnet Startseite trotz Keystore-Lesefehler
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('W1.5: Deep-Link /trips/new wird für Erstnutzer gesperrt und leitet nach /welcome', (tester) async {
      await tester.pumpWidget(buildTestApp(initialLocation: '/trips/new'));
      await tester.pumpAndSettle();

      // Deep-Link wird abgefangen: Erstnutzer muss Welcome sehen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(TripWizardScreen), findsNothing);
    });

    testWidgets('W2.1: Speicherfehler beim CTA-Klick wird nicht als Erfolg gewertet und bietet Retry', (tester) async {
      memoryStorage.shouldFailWrite = true;

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final ctaButton = find.byKey(const ValueKey('welcome_get_started_button'));
      await tester.tap(ctaButton);
      await tester.pumpAndSettle();

      // W2: Kein Schein-Erfolg: StartScreen darf NICHT geladen werden
      expect(find.byType(StartScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(await memoryStorage.hasSeenWelcome(), isFalse);

      // Fehlermeldung in SnackBar sichtbar
      expect(find.byKey(const ValueKey('welcome_error_snackbar')), findsOneWidget);
      expect(find.text('Status konnte nicht gespeichert werden.'), findsOneWidget);

      // Fehler beheben und über SnackBar-Action wiederholen
      memoryStorage.shouldFailWrite = false;
      await tester.tap(find.byKey(const ValueKey('welcome_retry_snackbar_action')));
      await tester.pumpAndSettle();

      // Jetzt ist die Speicherung erfolgt und StartScreen wird geöffnet
      expect(await memoryStorage.hasSeenWelcome(), isTrue);
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('W2.2: Neustart-Simulation nach fehlgeschlagenem Schreibversuch liest wahrheitsgetreu seen=false', (tester) async {
      memoryStorage.shouldFailWrite = true;

      // Erster Start
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('welcome_get_started_button')));
      await tester.pumpAndSettle();

      // Simulation App-Neustart: Neuer ProviderScope auf demselben memoryStorage
      memoryStorage.shouldFailWrite = false; // Storage funktioniert wieder, enthält aber noch false
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Nach Neustart erscheint wieder WelcomeScreen (wahrheitsgetreuer persistenter Zustand)
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(StartScreen), findsNothing);
    });

    testWidgets('W2.3: Mehrfaches schnelles Tippen auf den CTA erzeugt keine konkurrierenden Schreibvorgänge', (tester) async {
      final writeCompleter = Completer<void>();
      final delayedStorage = CompleterWelcomeStorage(
        readCompleter: Completer<bool>()..complete(false),
        writeCompleter: writeCompleter,
      );

      await tester.pumpWidget(buildTestApp(storage: delayedStorage));
      await tester.pumpAndSettle();

      final ctaButton = find.byKey(const ValueKey('welcome_get_started_button'));
      
      // Schneller Doppeltipp
      await tester.tap(ctaButton);
      await tester.tap(ctaButton);
      await tester.pump();

      // Erst nach Auflösung des Completers
      writeCompleter.complete();
      await tester.pumpAndSettle();

      // writeCalls wurde exakt einmal gerufen
      expect(delayedStorage.writeCalls, equals(1));
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('W2.4: Notfall-Bypass bei dauerhaftem Schreibfehler sperrt Nutzer nicht aus', (tester) async {
      memoryStorage.shouldFailWrite = true;

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // CTA tippen -> schlägt fehl
      await tester.tap(find.byKey(const ValueKey('welcome_get_started_button')));
      await tester.pumpAndSettle();

      // "Trotzdem fortfahren" ist nun sichtbar
      expect(find.byKey(const ValueKey('welcome_continue_anyway_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('welcome_continue_anyway_button')));
      await tester.pumpAndSettle();

      // Nutzer gelangt zur Startseite
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('UX-D / W2: Vorschau-Route (/welcome?preview=true) schließt über Close-Button ohne Storage-Schreibzugriff', (tester) async {
      final storage = MemoryWelcomeStorage(initialSeen: true);
      await tester.pumpWidget(buildTestApp(storage: storage, initialLocation: '/welcome?preview=true'));
      await tester.pumpAndSettle();

      expect(find.text('PROVY'), findsOneWidget);
      final closeBtn = find.byKey(const ValueKey('welcome_preview_close_button'));
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(storage.writeCalls, equals(0),
          reason: 'Preview Close button must never write to WelcomeStorage');
      expect(find.byType(StartScreen), findsOneWidget);
    });

    testWidgets('UX-D / W2: Vorschau-Route (/welcome?preview=true) schließt über CTA ohne Storage-Schreibzugriff', (tester) async {
      final storage = MemoryWelcomeStorage(initialSeen: true);
      await tester.pumpWidget(buildTestApp(storage: storage, initialLocation: '/welcome?preview=true'));
      await tester.pumpAndSettle();

      expect(find.text('PROVY'), findsOneWidget);
      final ctaButton = find.byKey(const ValueKey('welcome_get_started_button'));
      expect(ctaButton, findsOneWidget);

      await tester.tap(ctaButton);
      await tester.pumpAndSettle();

      expect(storage.writeCalls, equals(0),
          reason: 'Preview CTA must never call setSeenWelcome()');
      expect(find.byType(StartScreen), findsOneWidget);
    });
  });
}

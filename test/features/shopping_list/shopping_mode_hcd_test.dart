/// HCD-SHOP-01: Regressionstests & Step-1-Stabilitätsverifikation (#66).
/// Prüft Scrollstabilität, Rebuild-Verhalten, Fehlerpfade und Riverpod-Semantik
/// im Einkaufsmodus (ShoppingModeScreen).
library;

import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/core/services/backup_providers.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_mode_screen.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

/// Dekorierter ShoppingListService für kontrollierte Latenzen und Fehlerpfade.
class TestShoppingListService extends ShoppingListService {
  final ShoppingListService _delegate;
  Completer<void>? reloadCompleter;
  Completer<void>? toggleCompleter;
  bool shouldFailNextToggle = false;
  bool shouldThrowNextToggle = false;
  bool shouldThrowOnLoad = false;
  int toggleCalls = 0;
  int loadCalls = 0;

  TestShoppingListService(this._delegate)
      : super(
          tripDao: _delegate.tripDao,
          listItemDao: _delegate.listItemDao,
          catalogRepository: _delegate.catalogRepository,
          tripService: _delegate.tripService,
        );

  @override
  void Function(int tripId)? get onTripDataChanged => _delegate.onTripDataChanged;

  @override
  set onTripDataChanged(void Function(int tripId)? fn) {
    _delegate.onTripDataChanged = fn;
  }

  @override
  Future<TripShoppingListData> loadShoppingList(int tripId) async {
    loadCalls++;
    if (shouldThrowOnLoad) {
      throw Exception('Transienter Verbindungsfehler');
    }
    if (loadCalls > 1 && reloadCompleter != null && !reloadCompleter!.isCompleted) {
      await reloadCompleter!.future;
    }
    return _delegate.loadShoppingList(tripId);
  }

  @override
  Future<bool> toggleBought({
    required int tripId,
    required int listItemId,
    required int shoppingStopId,
    required bool isBought,
  }) async {
    toggleCalls++;
    if (toggleCompleter != null && !toggleCompleter!.isCompleted) {
      await toggleCompleter!.future;
    }
    if (shouldThrowNextToggle) {
      shouldThrowNextToggle = false;
      throw Exception('Simulierter SQLite/Recovery-Fehler beim Kauf');
    }
    if (shouldFailNextToggle) {
      shouldFailNextToggle = false;
      return false;
    }
    return _delegate.toggleBought(
      tripId: tripId,
      listItemId: listItemId,
      shoppingStopId: shoppingStopId,
      isBought: isBought,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late ShoppingListService baseShoppingListService;
  late TestShoppingListService testShoppingListService;
  late KittyService kittyService;

  late int testTripId;
  late int testStopId;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catalogFile = File('data/catalog_v0.11.json');
    final quantitiesFile = File('data/quantities_v0.6.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catalogFile.readAsStringSync(),
      quantitiesJson: quantitiesFile.readAsStringSync(),
    );

    tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
    );

    baseShoppingListService = ShoppingListService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
      tripService: tripService,
    );
    testShoppingListService = TestShoppingListService(baseShoppingListService);

    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );

    // 1. Törn anlegen
    testTripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'HCD Shopping Trip',
        startDate: DateTime(2026, 11, 10),
        daysCount: const Value(7),
        isCharter: const Value(true),
        boatType: const Value('monohull'),
      ),
    );

    // 2. Einkaufsstopp anlegen
    testStopId = await db.tripDao.addShoppingStop(
      ShoppingStopsCompanion.insert(
        tripId: testTripId,
        name: 'Supermarkt Marina',
        dayNumber: const Value(1),
        isInitial: const Value(true),
      ),
    );

    // 3. 45 Testartikel in 3 Abteilungen direkt in In-Memory-DB anlegen
    // 15x obst_gemuese, 15x molkerei, 15x trockenware
    final departments = ['obst_gemuese', 'molkerei', 'trockenware'];
    for (int d = 0; d < departments.length; d++) {
      final dept = departments[d];
      for (int i = 1; i <= 15; i++) {
        final itemNumber = d * 15 + i;
        final itemId = await db.listItemDao.addListItem(
          ListItemsCompanion.insert(
            tripId: testTripId,
            catalogId: 'custom_${dept}_$i',
            isCustom: const Value(true),
            customName: Value('Artikel $itemNumber ($dept)'),
            customUnit: const Value('Packung'),
            customDepartment: Value(dept),
            selected: const Value(true),
            isAdopted: const Value(true),
            calculatedPackages: const Value(1),
            overriddenPackages: const Value(1),
          ),
        );

        await db.into(db.listItemAllocations).insert(
          ListItemAllocationsCompanion.insert(
            tripId: testTripId,
            listItemId: itemId,
            shoppingStopId: testStopId,
            allocatedPackages: 1,
            isBought: const Value(false),
          ),
        );
      }
    }
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget({
    required Widget child,
    ThemeData? themeOverride,
    Locale localeOverride = const Locale('de'),
    List<Override> additionalOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWith((ref) {
          testShoppingListService.onTripDataChanged = (tripId) {
            ref.read(tripDataVersionProvider(tripId).notifier).update((v) => v + 1);
          };
          return testShoppingListService;
        }),
        kittyServiceProvider.overrideWithValue(kittyService),
        appStartupRecoveryProvider.overrideWith((ref) => Future.value()),
        ...additionalOverrides,
      ],
      child: MaterialApp(
        theme: themeOverride ?? AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de'), Locale('en')],
        locale: localeOverride,
        home: child,
      ),
    );
  }

  group('HCD-SHOP-01 Schritt 1: Stabilität, Persistenzwahrheit und Lifecycle (#66)', () {
    testWidgets('S01-40-POS: 40+ Artikel, 5 Checkmarks in Folge, Scrollable-Identität, ListView stabil, Offset erhalten', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: ShoppingModeScreen(tripId: testTripId, stopId: testStopId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.textContaining('Supermarkt Marina'), findsWidgets);
      expect(find.text('0 von 45 erledigt'), findsOneWidget);

      final scrollableBefore = tester.state<ScrollableState>(find.byType(Scrollable));

      // Scrolle zu Artikel 20 in der Listenmitte
      final item20Finder = find.text('Artikel 20 (molkerei)');
      await tester.scrollUntilVisible(item20Finder, 300);
      await tester.pumpAndSettle();
      expect(item20Finder, findsOneWidget);

      final initialOffset = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      expect(initialOffset, greaterThan(300.0));
      expect(identical(tester.state<ScrollableState>(find.byType(Scrollable)), scrollableBefore), isTrue);

      final checkbox20Finder = find.descendant(
        of: find.ancestor(of: item20Finder, matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      );

      final reloadCompleter = Completer<void>();
      testShoppingListService.reloadCompleter = reloadCompleter;

      // 1. Checkbox antippen
      await tester.tap(checkbox20Finder);
      await tester.pump();

      // Kein Vollbild-Spinner während Reload!
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // ListView bleibt gemountet & ScrollableState bleibt identisch!
      expect(find.byType(ListView), findsOneWidget);
      expect(identical(tester.state<ScrollableState>(find.byType(Scrollable)), scrollableBefore), isTrue);

      // Reload abschließen
      reloadCompleter.complete();
      testShoppingListService.reloadCompleter = null;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Scrollposition bleibt stabil & ScrollableState identisch
      expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, closeTo(initialOffset, 1.0));
      expect(identical(tester.state<ScrollableState>(find.byType(Scrollable)), scrollableBefore), isTrue);
      expect(tester.widget<Checkbox>(checkbox20Finder).value, isTrue);
      expect(find.text('1 von 45 erledigt'), findsOneWidget);

      // 2. Vier weitere aufeinanderfolgende Artikel in der Mitte abhaken (Artikel 21 bis 24)
      for (int i = 21; i <= 24; i++) {
        final itemFinder = find.text('Artikel $i (molkerei)');
        await tester.scrollUntilVisible(itemFinder, 100);
        await tester.pumpAndSettle();
        final cbFinder = find.descendant(
          of: find.ancestor(of: itemFinder, matching: find.byType(ListTile)),
          matching: find.byType(Checkbox),
        );
        await tester.tap(cbFinder);
        await tester.pumpAndSettle();

        // Nach jedem Häkchen bleibt das Scrollable identisch und die ListView gemountet
        expect(identical(tester.state<ScrollableState>(find.byType(Scrollable)), scrollableBefore), isTrue);
        expect(find.byType(ListView), findsOneWidget);
        expect(tester.widget<Checkbox>(cbFinder).value, isTrue);
      }

      // Insgesamt 5 Artikel als gekauft markiert
      expect(find.text('5 von 45 erledigt'), findsOneWidget);

      // Persistierten DB-Status aller 5 Artikel verifizieren
      for (int i = 20; i <= 24; i++) {
        final allocs = await db.listItemDao.getAllocationsForListItem(i);
        final stopAlloc = allocs.firstWhere((a) => a.shoppingStopId == testStopId);
        expect(stopAlloc.isBought, isTrue, reason: 'Artikel $i muss in DB als gekauft persistiert sein');
      }
    });

    testWidgets('S01-ASYNC-INITIAL-ERROR: Initialer Ladefehler zeigt Fehlerbildschirm und erholt sich nach Retry', (tester) async {
      bool shouldThrow = true;

      await tester.pumpWidget(
        buildTestableWidget(
          additionalOverrides: [
            tripShoppingListProvider(testTripId).overrideWith((ref) async {
              ref.watch(tripDataVersionProvider(testTripId));
              if (shouldThrow) {
                throw Exception('DB nicht erreichbar');
              }
              return testShoppingListService.loadShoppingList(testTripId);
            }),
          ],
          child: ShoppingModeScreen(tripId: testTripId, stopId: testStopId),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Zeigt eigenständigen Fehlerbildschirm, NICHT generisches "Törn nicht gefunden"
      expect(find.byKey(const Key('shopping_mode_initial_error_scaffold')), findsOneWidget);
      expect(find.byKey(const Key('shopping_mode_initial_retry_button')), findsOneWidget);
      expect(find.text('Technischer Fehler'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);

      // 2. Retry auslösen: Fehlerbedingung aufheben und Wiederholen-Button drücken
      shouldThrow = false;
      await tester.tap(find.byKey(const Key('shopping_mode_initial_retry_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      // 3. Fehlerbildschirm verschwindet, ListView rendert erfolgreich mit Artikeln
      expect(find.byKey(const Key('shopping_mode_initial_error_scaffold')), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Artikel 1 (obst_gemuese)'), findsOneWidget);
      expect(find.text('0 von 45 erledigt'), findsOneWidget);
    });

    testWidgets('S01-ASYNC-RELOAD-ERROR: Reload-Fehler mit vorhandenen Daten belässt Liste und zeigt Warnbanner mit Retry', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ShoppingModeScreen(tripId: testTripId, stopId: testStopId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);

      // Wir simulieren einen Reload-Fehler bei nachfolgendem Load
      testShoppingListService.shouldThrowOnLoad = true;
      final container = ProviderScope.containerOf(tester.element(find.byType(ShoppingModeScreen)));
      container.read(tripDataVersionProvider(testTripId).notifier).update((v) => v + 1);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Liste bleibt voll sichtbar und nutzbar!
      expect(find.byType(ListView), findsOneWidget);
      // Warnbanner mit Retry erscheint
      expect(find.byKey(const Key('shopping_mode_reload_error_banner')), findsOneWidget);
      expect(find.byKey(const Key('shopping_mode_reload_retry_button')), findsOneWidget);

      // Retry behebt den Fehler, wenn Service wieder erfolgreich lädt
      testShoppingListService.shouldThrowOnLoad = false;
      await tester.tap(find.byKey(const Key('shopping_mode_reload_retry_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Warnbanner verschwindet nach erfolgreichem Reload
      expect(find.byKey(const Key('shopping_mode_reload_error_banner')), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('S01-ASYNC-MISSING-STOP: Nicht existierende Stopp-ID zeigt gezielt NotFoundScreen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ShoppingModeScreen(tripId: testTripId, stopId: 999999),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Einkaufsstopp nicht gefunden'), findsOneWidget);
    });

    testWidgets('S01-FALSE-THROW: Fehlgeschlagener Schreibvorgang behauptet keinen Erfolg und führt echten Retry aus', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: ShoppingModeScreen(tripId: testTripId, stopId: testStopId),
        ),
      );
      await tester.pumpAndSettle();

      final firstItemFinder = find.text('Artikel 1 (obst_gemuese)');
      final checkbox1Finder = find.descendant(
        of: find.ancestor(of: firstItemFinder, matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      );

      // --- TEIL A: Rückgabewert false (z.B. SQLite 0 Zeilen verändert) ---
      testShoppingListService.shouldFailNextToggle = true;
      await tester.tap(checkbox1Finder);
      await tester.pump();
      await tester.pumpAndSettle();

      // 1. SnackBar mit Retry-Aktion erscheint
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);

      // 2. Kein Scheinerfolg: Checkbox bleibt unchecked, Zähler bleibt bei 0 von 45 erledigt
      expect(tester.widget<Checkbox>(checkbox1Finder).value, isFalse);
      expect(find.text('0 von 45 erledigt'), findsOneWidget);

      // 3. Datenbank-Wahrheit: isBought bleibt false in SQLite
      var allocs1 = await db.listItemDao.getAllocationsForListItem(1);
      expect(allocs1.firstWhere((a) => a.shoppingStopId == testStopId).isBought, isFalse);

      // 4. Retry-Aktion auf der SnackBar antippen
      testShoppingListService.shouldFailNextToggle = false;
      await tester.tap(find.text('Erneut versuchen'));
      await tester.pump();
      await tester.pumpAndSettle();

      // 5. Nach erfolgreichem Retry: Checkbox ist checked, Zähler ist 1 von 45 erledigt, DB ist true!
      expect(tester.widget<Checkbox>(checkbox1Finder).value, isTrue);
      expect(find.text('1 von 45 erledigt'), findsOneWidget);
      allocs1 = await db.listItemDao.getAllocationsForListItem(1);
      expect(allocs1.firstWhere((a) => a.shoppingStopId == testStopId).isBought, isTrue);

      // --- TEIL B: Exception beim Schreibvorgang (z.B. Dateisystem-Lock / I/O-Fehler) ---
      final secondItemFinder = find.text('Artikel 2 (obst_gemuese)');
      final checkbox2Finder = find.descendant(
        of: find.ancestor(of: secondItemFinder, matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      );

      testShoppingListService.shouldThrowNextToggle = true;
      await tester.tap(checkbox2Finder);
      await tester.pump();
      await tester.pumpAndSettle();

      // 1. SnackBar mit Retry-Aktion erscheint
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);

      // 2. Kein Scheinerfolg: Checkbox 2 bleibt unchecked, Zähler bleibt bei 1 von 45 erledigt
      expect(tester.widget<Checkbox>(checkbox2Finder).value, isFalse);
      expect(find.text('1 von 45 erledigt'), findsOneWidget);

      // 3. Datenbank-Wahrheit: isBought von Artikel 2 bleibt false
      var allocs2 = await db.listItemDao.getAllocationsForListItem(2);
      expect(allocs2.firstWhere((a) => a.shoppingStopId == testStopId).isBought, isFalse);

      // 4. Retry-Aktion antippen
      testShoppingListService.shouldThrowNextToggle = false;
      await tester.tap(find.text('Erneut versuchen'));
      await tester.pump();
      await tester.pumpAndSettle();

      // 5. Nach erfolgreichem Retry: Checkbox 2 ist checked, Zähler ist 2 von 45 erledigt, DB ist true!
      expect(tester.widget<Checkbox>(checkbox2Finder).value, isTrue);
      expect(find.text('2 von 45 erledigt'), findsOneWidget);
      allocs2 = await db.listItemDao.getAllocationsForListItem(2);
      expect(allocs2.firstWhere((a) => a.shoppingStopId == testStopId).isBought, isTrue);
    });

    testWidgets('S01-RETRY-STALE-SUPERSEDED: Veralteter Retry nach manuellem Kaufen und Entkaufen kauft nicht heimlich neu', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: ShoppingModeScreen(tripId: testTripId, stopId: testStopId),
        ),
      );
      await tester.pumpAndSettle();

      final firstItemFinder = find.text('Artikel 1 (obst_gemuese)');
      final checkbox1Finder = find.descendant(
        of: find.ancestor(of: firstItemFinder, matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      );

      // 1. Initialer Fehlschlag erzeugt SnackBar mit Generation 1
      testShoppingListService.shouldFailNextToggle = true;
      await tester.tap(checkbox1Finder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final staleAction = tester.widget<SnackBarAction>(find.byType(SnackBarAction));

      // 2. Nutzer entscheidet sich um: kauft manuell erfolgreich (Gen 2)
      await tester.tap(checkbox1Finder);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox1Finder).value, isTrue);
      expect(find.text('1 von 45 erledigt'), findsOneWidget);

      // 3. Nutzer entkauft wieder manuell erfolgreich (Gen 3)
      await tester.scrollUntilVisible(firstItemFinder, 200);
      await tester.pumpAndSettle();
      await tester.tap(checkbox1Finder);
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(firstItemFinder, -200);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox1Finder).value, isFalse);
      expect(find.text('0 von 45 erledigt'), findsOneWidget);

      final callsBeforeStaleRetry = testShoppingListService.toggleCalls;

      // 4. Veralteten Retry aus Generation 1 ausführen
      staleAction.onPressed();
      await tester.pump();
      await tester.pumpAndSettle();

      // 5. Keine neue Mutation, kein heimlicher Kauf, Status bleibt bei der bewussten Nutzerentscheidung (offen)
      expect(testShoppingListService.toggleCalls, equals(callsBeforeStaleRetry));
      expect(tester.widget<Checkbox>(checkbox1Finder).value, isFalse);
      expect(find.text('0 von 45 erledigt'), findsOneWidget);
      final allocs1 = await db.listItemDao.getAllocationsForListItem(1);
      expect(allocs1.firstWhere((a) => a.shoppingStopId == testStopId).isBought, isFalse);
    });

    testWidgets('S01-RETRY-DISPOSED-LIFECYCLE: Retry nach Verlassen des Screens wirft keinen Lifecycle-Fehler', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: ShoppingModeScreen(tripId: testTripId, stopId: testStopId),
        ),
      );
      await tester.pumpAndSettle();

      final firstItemFinder = find.text('Artikel 1 (obst_gemuese)');
      final checkbox1Finder = find.descendant(
        of: find.ancestor(of: firstItemFinder, matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      );

      // 1. Fehlschlag erzeugt SnackBar
      testShoppingListService.shouldFailNextToggle = true;
      await tester.tap(checkbox1Finder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));

      // 2. Screen verlassen (ShoppingModeScreen wird disposed)
      await tester.pumpWidget(
        buildTestableWidget(
          child: const Scaffold(body: Text('Anderer Screen')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShoppingModeScreen), findsNothing);

      // 3. Veraltete Action aufrufen
      action.onPressed();
      await tester.pump();
      await tester.pumpAndSettle();

      // 4. Kein Flutter-Lifecycle-Fehler (kein setState nach dispose)
      expect(tester.takeException(), isNull);
    });

    testWidgets('S01-2TAP: Doppel-Tap auf selbe Checkbox blockiert zweiten Aufruf durch Pending-Guard', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: ShoppingModeScreen(tripId: testTripId, stopId: testStopId),
        ),
      );
      await tester.pumpAndSettle();

      final firstItemFinder = find.text('Artikel 1 (obst_gemuese)');
      final checkboxFinder = find.descendant(
        of: find.ancestor(of: firstItemFinder, matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      );

      final initialToggleCalls = testShoppingListService.toggleCalls;

      // In-flight Completer scharfschalten
      testShoppingListService.toggleCompleter = Completer<void>();

      // Erster Tap startet Toggle und setzt _pendingItemIds
      await tester.tap(checkboxFinder);
      await tester.pump();

      // Zweiter schneller Tap während in-flight
      await tester.tap(checkboxFinder, warnIfMissed: false);
      await tester.pump();

      // In-flight Operation freigeben
      testShoppingListService.toggleCompleter!.complete();
      await tester.pumpAndSettle();

      // toggleCalls darf sich nur um genau 1 erhöht haben
      expect(testShoppingListService.toggleCalls, equals(initialToggleCalls + 1));
    });

    testWidgets('S01-A11Y-DARK: Schmaler 320dp-Screen und Dark-Theme mit 1.5x Textskalierung ohne Overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          themeOverride: AppTheme.darkTheme,
          child: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: ShoppingModeScreen(tripId: 1, stopId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kein RenderFlex overflow aufgetreten
      expect(tester.takeException(), isNull);
    });

    testWidgets('S01-A11Y-NIGHTWATCH: Schmaler 320dp-Screen und echtes Nightwatch-Theme (nightwatchTheme) mit 1.5x Textskalierung ohne Overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          themeOverride: AppTheme.nightwatchTheme,
          child: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: ShoppingModeScreen(tripId: 1, stopId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kein RenderFlex overflow aufgetreten
      expect(tester.takeException(), isNull);
    });
  });
}

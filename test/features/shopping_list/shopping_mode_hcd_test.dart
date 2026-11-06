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
    testWidgets('S01-40-POS: 40+ Artikel, mid-scroll Checkmark, kein Spinner, ListView stabil, Offset erhalten', (tester) async {
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

      // Scrolle zu Artikel 20 in der Listenmitte
      final item20Finder = find.text('Artikel 20 (molkerei)');
      await tester.scrollUntilVisible(item20Finder, 300);
      await tester.pumpAndSettle();
      expect(item20Finder, findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable));
      final initialOffset = scrollableState.position.pixels;
      expect(initialOffset, greaterThan(300.0));

      final checkboxFinder = find.descendant(
        of: find.ancestor(of: item20Finder, matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      );

      final reloadCompleter = Completer<void>();
      testShoppingListService.reloadCompleter = reloadCompleter;

      // Checkbox antippen
      await tester.tap(checkboxFinder);
      await tester.pump();

      // 1. Kein Vollbild-Spinner während Reload!
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // 2. ListView bleibt gemountet!
      expect(find.byType(ListView), findsOneWidget);

      // Reload abschließen
      reloadCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 3. Scrollposition bleibt stabil
      final postReloadOffset = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      expect(postReloadOffset, closeTo(initialOffset, 1.0));
    });

    testWidgets('S01-ASYNC-INITIAL-ERROR: Initialer Ladefehler ohne Daten zeigt Fehlerbildschirm mit Retry', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          additionalOverrides: [
            tripShoppingListProvider(testTripId).overrideWith((ref) => Future.error(Exception('DB nicht erreichbar'))),
          ],
          child: ShoppingModeScreen(tripId: testTripId, stopId: testStopId),
        ),
      );
      await tester.pumpAndSettle();

      // Zeigt eigenständigen Fehlerbildschirm, NICHT generisches "Törn nicht gefunden"
      expect(find.byKey(const Key('shopping_mode_initial_error_scaffold')), findsOneWidget);
      expect(find.byKey(const Key('shopping_mode_initial_retry_button')), findsOneWidget);
      expect(find.text('Technischer Fehler'), findsOneWidget);
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

    testWidgets('S01-FALSE-THROW: Fehlgeschlagener Schreibvorgang behauptet keinen Erfolg und zeigt Fehler-SnackBar', (tester) async {
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

      // 1. Simulierter bool=false Fehlschlag
      testShoppingListService.shouldFailNextToggle = true;
      await tester.tap(checkboxFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);

      // 2. Simulierter Exception-Fehlschlag
      testShoppingListService.shouldThrowNextToggle = true;
      await tester.tap(checkboxFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
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

    testWidgets('S01-A11Y: Schmaler 320dp-Screen und Nachtwache-Modus ohne Layout-Overflow', (tester) async {
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
  });
}

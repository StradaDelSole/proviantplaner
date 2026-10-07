/// UI- und Integrationstests für FB2-B: Setup Tiefkühlfach, Wassertank, Hinweise, Router und Überlaufschutz.
library;

import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/routing/app_router.dart';
import 'package:proviantplaner/core/routing/not_found_screen.dart';
import 'package:proviantplaner/core/services/pdf_export_service.dart';
import 'package:proviantplaner/core/services/pdf_providers.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/data/supplier_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/item_row_widget.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/order_preview_sheet.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/planning_view.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late ShoppingListService shoppingListService;
  late KittyService kittyService;
  late SupplierService supplierService;
  late DeliveryOrderService deliveryOrderService;
  late PdfExportService pdfExportService;
  late int defaultTripId;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catFile = File('data/catalog_v0.11.json');
    final quantFile = File('data/quantities_v0.6.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catFile.readAsStringSync(),
      quantitiesJson: quantFile.readAsStringSync(),
    );

    tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
    );

    shoppingListService = ShoppingListService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
      tripService: tripService,
    );

    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );

    supplierService = SupplierService();
    deliveryOrderService = DeliveryOrderService();
    pdfExportService = PdfExportService();

    defaultTripId = await tripService.createTripWithCrew(
      name: 'Adria Törn 2026',
      startDate: DateTime(2026, 8, 10),
      daysCount: 7,
      isCharter: true,
      boatType: 'monohull',
      region: 'mediterranean',
      fridgeCapacityLiters: 90.0,
      hasFreezer: true,
      freezerCapacityLiters: 20.0,
      waterTankLiters: 200.0,
      isWaterTankDrinkable: true,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: [
        const CrewMemberInput(id: '1', name: 'Skipper Alex', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Ben', isAdult: true, isVegetarian: true, noAlcohol: false),
      ],
    );
    await shoppingListService.adoptAllSuggestions(defaultTripId);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildAppWithOverrides({Widget? home, ThemeData? theme, String? initialLocation}) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWithValue(shoppingListService),
        kittyServiceProvider.overrideWithValue(kittyService),
        supplierServiceProvider.overrideWithValue(supplierService),
        deliveryOrderServiceProvider.overrideWithValue(deliveryOrderService),
        pdfExportServiceProvider.overrideWithValue(pdfExportService),
      ],
    );

    if (initialLocation != null) {
      final router = container.read(appRouterProvider);
      router.go(initialLocation);
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: theme ?? AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('de'), Locale('en')],
          locale: const Locale('de'),
        ),
      );
    }

    return UncontrolledProviderScope(
      container: container,
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
        home: home,
      ),
    );
  }

  group('FB2-B: Layout & Überlaufschutz', () {
    testWidgets('FB2-B 1: Zeilenlayout überläuft nicht bei langem Produktnamen, großer Menge und textScale 2.0 (Hell, Dunkel, Nachtwache)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final realData = await shoppingListService.loadShoppingList(defaultTripId);
      final baseItem = realData.allItems.first;

      final longItem = baseItem.copyWith(
        item: baseItem.item.copyWith(
          selected: true,
          isAdopted: true,
          calculatedPackages: 9999,
          overriddenPackages: const Value(9999),
        ),
        name: 'Bio Haferflocken kernig und zart gemischt aus kontrolliert biologischem regionalem Anbau in Großpackung',
        calculatedPackages: 9999,
        overriddenPackages: 9999,
        isAdopted: true,
        isSelected: true,
        storageNotice: 'trocken lagern',
        remainderNotice: 'Rest ca. 250 g: Als Zutat für Bratlinge oder Brot verwenden',
      );

      final modifiedData = TripShoppingListData(
        trip: realData.trip,
        stops: realData.stops,
        allItems: [longItem],
        categories: realData.categories,
        departments: realData.departments,
      );

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme, AppTheme.nightwatchTheme]) {
        await tester.pumpWidget(
          buildAppWithOverrides(
            theme: theme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(
                body: ListView(
                  children: [
                    ShoppingListItemRow(
                      data: modifiedData,
                      item: longItem,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Kein RenderFlex-Überlauf bei textScaler 2.0');
        expect(find.textContaining('Bio Haferflocken kernig'), findsOneWidget);
        expect(find.text('trocken lagern'), findsOneWidget);
        expect(find.textContaining('Rest ca. 250 g'), findsOneWidget);
        expect(find.text('9999'), findsOneWidget);
      }
    });
  });

  group('FB2-B: Router & NotFoundScreen', () {
    testWidgets('FB2-B 2: Router zeigt NotFoundScreen bei fehlerhafter Route /trips/abc', (tester) async {
      await tester.pumpWidget(buildAppWithOverrides(initialLocation: '/trips/abc'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsOneWidget);
      expect(find.text('Zurück zur Übersicht'), findsOneWidget);
    });

    testWidgets('FB2-B 3: Router zeigt NotFoundScreen bei unbekannter numerischer Trip-ID (/trips/99999)', (tester) async {
      await tester.pumpWidget(buildAppWithOverrides(initialLocation: '/trips/99999'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsOneWidget);
    });

    testWidgets('FB2-B 4: Router zeigt NotFoundScreen bei unbekanntem Shopping-Stopp (/trips/1/shop/99999)', (tester) async {
      await tester.pumpWidget(buildAppWithOverrides(initialLocation: '/trips/$defaultTripId/shop/99999'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Einkaufsstopp nicht gefunden'), findsOneWidget);
    });

    testWidgets('FB2-B 5: Router zeigt NotFoundScreen bei unbekannter Timeline (/trips/99999/timeline)', (tester) async {
      await tester.pumpWidget(buildAppWithOverrides(initialLocation: '/trips/99999/timeline'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Törn nicht gefunden'), findsOneWidget);
    });
  });

  group('FB2-B: Trip-Setup Oberflaeche (Dauer, Tiefkuehlfach, Wassertank)', () {
    testWidgets('FB2-B 6: Törndauer Schnellchips und Wählrad funktionieren wie gefordert', (tester) async {
      await tester.pumpWidget(buildAppWithOverrides(home: const TripWizardScreen()));
      await tester.pumpAndSettle();

      // Schnellchip "2 Wochen" (14 Tage)
      final twoWeeksChip = find.text('2 Wochen');
      expect(twoWeeksChip, findsOneWidget);
      await tester.tap(twoWeeksChip);
      await tester.pumpAndSettle();
      expect(find.text('14'), findsWidgets);

      // Schnellchip "Wählrad..." öffnen
      final wheelChip = find.textContaining('Wählrad');
      expect(wheelChip, findsOneWidget);
      await tester.tap(wheelChip);
      await tester.pumpAndSettle();

      // CupertinoPicker BottomSheet prüfen
      expect(find.text('Törndauer wählen'), findsOneWidget);
      expect(find.byType(CupertinoPicker), findsOneWidget);

      // "Fertig" tippen
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.text('Törndauer wählen'), findsNothing);
    });

    testWidgets('FB2-B 7: Tiefkühlfach- und Wassertank-Setup persistiert in DB und erreicht Rechenlogik', (tester) async {
      await tester.pumpWidget(buildAppWithOverrides(initialLocation: '/trips/new'));
      await tester.pumpAndSettle();

      // Törnname eingeben
      await tester.enterText(find.byType(TextField).first, 'Ostsee TK Törn');
      await tester.pumpAndSettle();

      // Tiefkühlfach Schalter aktivieren
      final freezerSwitch = find.widgetWithText(SwitchListTile, 'Tiefkühlfach vorhanden');
      await tester.ensureVisible(freezerSwitch);
      expect(freezerSwitch, findsOneWidget);
      await tester.tap(freezerSwitch);
      await tester.pumpAndSettle();

      // Tiefkühlfach-Volumen Feld prüfen und um 10 l erhöhen
      expect(find.text('Tiefkühlfach-Volumen (l)'), findsOneWidget);
      final freezerRow = find.ancestor(
        of: find.text('Tiefkühlfach-Volumen (l)'),
        matching: find.byType(Row),
      ).first;
      final freezerPlus = find.descendant(
        of: freezerRow,
        matching: find.byIcon(Icons.add),
      );
      await tester.ensureVisible(freezerPlus);
      await tester.tap(freezerPlus); // +5
      await tester.tap(freezerPlus); // +5 (insgesamt 30 l)
      await tester.pumpAndSettle();

      // Wassertank an Bord: +50 l
      final tankRow = find.ancestor(
        of: find.text('Wassertank an Bord (l)'),
        matching: find.byType(Row),
      ).first;
      final tankPlus = find.descendant(
        of: tankRow,
        matching: find.byIcon(Icons.add),
      );
      await tester.ensureVisible(tankPlus);
      await tester.tap(tankPlus); // 150 + 50 = 200 l
      await tester.pumpAndSettle();

      // Switch "Tankwasser ist trinkbar" aktivieren
      final drinkableSwitch = find.widgetWithText(SwitchListTile, 'Tankwasser ist trinkbar');
      await tester.ensureVisible(drinkableSwitch);
      expect(drinkableSwitch, findsOneWidget);
      await tester.tap(drinkableSwitch);
      await tester.pumpAndSettle();

      // Person hinzufügen
      final addPersonBtn = find.text('+ Person hinzufügen');
      await tester.ensureVisible(addPersonBtn);
      await tester.tap(addPersonBtn);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Skipper Anna');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Törn erstellen
      final createButton = find.text('Törn erstellen');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // In Datenbank prüfen
      final trips = await db.tripDao.getAllTrips();
      expect(trips, isNotEmpty);
      final savedTrip = trips.firstWhere((t) => t.name == 'Ostsee TK Törn');
      expect(savedTrip.hasFreezer, isTrue);
      expect(savedTrip.freezerCapacity, 30);
      expect(savedTrip.waterTankLiters, 50);
      expect(savedTrip.isWaterTankDrinkable, isTrue);
    });
  });

  group('FB2-B: Hinweise & Gesamtgewicht/-volumen', () {
    testWidgets('FB2-B 8: Lagerhinweise und Resthinweise werden in Vorratsliste dargestellt', (tester) async {
      final realData = await shoppingListService.loadShoppingList(defaultTripId);
      final baseItem = realData.allItems.first;

      final itemWithNotices = baseItem.copyWith(
        storageNotice: 'gleich einfrieren',
        remainderNotice: 'Rest ca. 150 g: Am 2. Tag verbrauchen',
      );

      final modifiedData = TripShoppingListData(
        trip: realData.trip,
        stops: realData.stops,
        allItems: [itemWithNotices],
        categories: realData.categories,
        departments: realData.departments,
      );

      await tester.pumpWidget(
        buildAppWithOverrides(
          home: Scaffold(
            body: ShoppingListItemRow(
              data: modifiedData,
              item: itemWithNotices,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('gleich einfrieren'), findsOneWidget);
      expect(find.text('Rest ca. 150 g: Am 2. Tag verbrauchen'), findsOneWidget);
    });

    testWidgets('FB2-B 9: Gesamtgewicht und -volumen werden über der Planungsliste angezeigt', (tester) async {
      final realData = await shoppingListService.loadShoppingList(defaultTripId);

      await tester.pumpWidget(
        buildAppWithOverrides(
          home: Scaffold(
            body: PlanningView(data: realData),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner mit Gesamt: ... kg · ... l
      expect(find.textContaining('Gesamt:'), findsOneWidget);
      expect(find.textContaining('kg'), findsWidgets);
      expect(find.textContaining('l'), findsWidgets);
    });
  });

  group('FB2-B: WhatsApp Delivery Sharing', () {
    testWidgets('FB2-B 10: WhatsApp ist die erste Option beim Teilen von Lieferbestellungen', (tester) async {
      final realData = await shoppingListService.loadShoppingList(defaultTripId);
      final testStop = realData.stops.first;

      final testOrder = DeliveryOrder(
        stopId: testStop.id,
        tripId: defaultTripId,
        isDelivery: true,
        berth: 'Steg 3, Liegeplatz 12',
      );

      await tester.pumpWidget(
        buildAppWithOverrides(
          home: Scaffold(
            body: OrderPreviewSheet(
              trip: realData.trip,
              stop: testStop,
              order: testOrder,
              items: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // WhatsApp Button suchen
      final whatsAppText = find.text('Per WhatsApp senden');
      expect(whatsAppText, findsOneWidget);

      // Weitere Teilen-Optionen sind ebenfalls vorhanden
      expect(find.text('Text teilen'), findsOneWidget);
      expect(find.text('PDF teilen'), findsOneWidget);

      // WhatsApp steht vor den anderen beiden Optionen
      final whatsAppTop = tester.getTopLeft(whatsAppText).dy;
      final textShareTop = tester.getTopLeft(find.text('Text teilen')).dy;
      final pdfShareTop = tester.getTopLeft(find.text('PDF teilen')).dy;

      expect(whatsAppTop, lessThan(textShareTop));
      expect(whatsAppTop, lessThan(pdfShareTop));
    });
  });
}

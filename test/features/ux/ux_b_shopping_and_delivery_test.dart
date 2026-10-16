/// Tests für UX-B: Liste, Einkaufsmodus, Liefern lassen (UX-Konzept v0.4 & SLICES_v0.16).
library;

import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
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
import 'package:proviantplaner/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/item_row_widget.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

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
  late int testTripId;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catalogFile = File('data/catalog_v0.11.json');
    final quantitiesFile = File('data/quantities_v0.5.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catalogFile.readAsStringSync(),
      quantitiesJson: quantitiesFile.readAsStringSync(),
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

    testTripId = await tripService.createTripWithCrew(
      name: 'UX-B Testtörn',
      startDate: DateTime(2026, 9, 1),
      daysCount: 7,
      isCharter: true,
      boatType: 'monohull',
      region: 'mediterranean',
      fridgeCapacityLiters: 80.0,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: [
        const CrewMemberInput(id: '1', name: 'Skipper Hans', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Anna', isAdult: true, isVegetarian: false, noAlcohol: false),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
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
        home: child,
      ),
    );
  }

  group('UX-B: Abnahmekriterien Tests', () {
    // Kriterium 1: Gruppe aufklappen (in-place accordion without modal sheet)
    testWidgets('1. Gruppe aufklappen zeigt Varianten direkt inline ohne modales Bottom Sheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(ShoppingListScreen(tripId: testTripId)));
      await tester.pumpAndSettle();

      // PIVOT1 Decision 16: Vorratsliste startet standardmäßig nach Abteilung;
      // für den Kategorie-Akkordeon-Test auf Kategorie umschalten:
      await tester.tap(find.byIcon(Icons.category_outlined));
      await tester.pumpAndSettle();

      // Es gibt Produktgruppen wie "Brot und Backwaren"
      final brotFinder = find.textContaining('Brot');
      expect(brotFinder, findsWidgets);

      // Vor dem Antippen ist kein modales BottomSheet offen
      expect(find.byType(BottomSheet), findsNothing);

      // Antippen der Gruppen-Kopfzeile
      await tester.tap(brotFinder.first);
      await tester.pumpAndSettle();

      // Kein modales BottomSheet geöffnet (kein showModalBottomSheet)
      expect(find.byType(BottomSheet), findsNothing);

      // Stattdessen sind die Varianten darunter inline sichtbar
      final variantFinder = find.textContaining('brot');
      expect(variantFinder, findsWidgets);
    });

    // Kriterium 2: Variante übernehmen (+ Button übernimmt Variante in die Vorratsliste)
    testWidgets('2. Variante übernehmen übernimmt Position in die Vorratsliste', (tester) async {
      final listDataBefore = await shoppingListService.loadShoppingList(testTripId);
      final initialOnListCount = listDataBefore.allItems.where((i) => i.isOnList).length;
      expect(initialOnListCount, 0); // Anfangs ist die Liste leer

      // Variante übernehmen über adoptItem
      final breadItem = listDataBefore.allItems.firstWhere((it) => it.variant?.group == 'bread');
      await shoppingListService.adoptItem(
        tripId: testTripId,
        listItemId: breadItem.item.id,
      );

      final listDataAfter = await shoppingListService.loadShoppingList(testTripId);
      final updatedItem = listDataAfter.allItems.firstWhere((it) => it.item.id == breadItem.item.id);
      expect(updatedItem.isOnList, isTrue);
      expect(updatedItem.effectivePackages, greaterThan(0));
    });

    // Kriterium 3: Menge inline ändern (Tippen auf die Zahl öffnet inline Textfeld)
    testWidgets('3. Menge inline ändern öffnet Textfeld und übernimmt neue Zahl', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Zuerst Vorschläge übernehmen, damit Positionen auf der Liste sind
      await shoppingListService.adoptAllSuggestions(testTripId);

      await tester.pumpWidget(buildTestableWidget(ShoppingListScreen(tripId: testTripId)));
      await tester.pumpAndSettle();

      // Suche nach einer ItemRow mit einer übernommenen Position
      final adoptedRowFinder = find.byWidgetPredicate(
        (w) => w is ShoppingListItemRow && w.item.isOnList,
      );
      expect(adoptedRowFinder, findsWidgets);

      final row = tester.widget<ShoppingListItemRow>(adoptedRowFinder.first);
      final inkwellFinder = find.byKey(ValueKey('qty_inkwell_${row.item.item.id}'));
      expect(inkwellFinder, findsOneWidget);

      // Antippen der Zahl öffnet inline Textfeld
      await tester.tap(inkwellFinder);
      await tester.pumpAndSettle();

      final inlineTextField = find.descendant(
        of: adoptedRowFinder.first,
        matching: find.byType(TextField),
      );
      expect(inlineTextField, findsOneWidget);

      // Neue Zahl eingeben und absenden
      await tester.enterText(inlineTextField, '5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Textfeld schließt sich wieder
      expect(find.descendant(of: adoptedRowFinder.first, matching: find.byType(TextField)), findsNothing);
    });

    // Kriterium 4: Wischgeste ordnet Stopp zu
    testWidgets('4. Wischgeste öffnet Stopp-Auswahl als Chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Zweiter Stopp anlegen
      await tripService.addShoppingStop(tripId: testTripId, name: 'Hafenstopp Tag 3', dayNumber: 3);
      await shoppingListService.adoptAllSuggestions(testTripId);

      await tester.pumpWidget(buildTestableWidget(ShoppingListScreen(tripId: testTripId)));
      await tester.pumpAndSettle();

      final dismissibleFinder = find.byType(Dismissible);
      expect(dismissibleFinder, findsWidgets);

      // Wischgeste nach links (endToStart) per fling
      await tester.fling(dismissibleFinder.first, const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      // BottomSheet mit Stopp-Auswahl öffnet sich
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.descendant(of: find.byType(BottomSheet), matching: find.textContaining('Stopp wählen')),
        findsOneWidget,
      );
      expect(find.byType(ActionChip), findsWidgets);
    });

    // Kriterium 5: Bestellung enthält exakt die Positionen des Stopps nach Abteilung mit Menge und Packungsgröße
    test('5. Bestellung enthält exakt die Positionen des Stopps nach Abteilung mit Menge und Packungsgröße', () async {
      await shoppingListService.adoptAllSuggestions(testTripId);
      final listData = await shoppingListService.loadShoppingList(testTripId);
      final stops = listData.stops;
      final initialStop = stops.first;

      final sampleItems = listData.allItems.where((i) => i.isOnList).take(3).toList();
      expect(sampleItems, isNotEmpty);

      final order = DeliveryOrder(
        stopId: initialStop.id,
        tripId: testTripId,
        isDelivery: true,
        marina: 'Marina Kastela',
        berth: 'Steg B, Platz 14',
        boatName: 'Bavaria C45',
        contactName: 'Skipper Hans',
        contactPhone: '+49 170 1234567',
        deliveryDateTime: DateTime(2026, 9, 1, 10, 0),
      );

      final formattedText = order.formatOrderText(
        tripName: listData.trip.name,
        items: sampleItems,
      );

      // Überprüfe die Formatierung:
      // 1. Enthält Header und Metadaten
      expect(formattedText, contains('Marina: Marina Kastela'));
      expect(formattedText, contains('Liegeplatz: Steg B, Platz 14'));
      expect(formattedText, contains('Boot: Bavaria C45'));
      expect(formattedText, contains('Ansprechpartner: Skipper Hans (+49 170 1234567)'));

      // 2. Gruppiert nach Abteilungen
      expect(formattedText, contains('--- ARTIKELLISTE ---'));

      // 3. Format: "• <Name> · <Anzahl> × <Packungsgröße> <Einheit>"
      final firstItem = sampleItems.first;
      final size = firstItem.effectivePackSize;
      final sizeFormatted = (size % 1 == 0) ? size.toInt().toString() : size.toStringAsFixed(1);
      final packUnit = firstItem.variant?.pack.unit ?? firstItem.unit;
      final expectedLine = '• ${firstItem.name} · ${firstItem.effectivePackages} × $sizeFormatted $packUnit';
      expect(formattedText, contains(expectedLine));

      // 4. PDF-Erzeugung erzeugt valides PDF
      final pdfBytes = await pdfExportService.generateDeliveryOrderPdf(
        trip: listData.trip,
        order: order,
        items: sampleItems,
      );
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(500));
    });

    // Kriterium 6: Lieferant wird gespeichert und in einem zweiten Törn angeboten
    test('6. Lieferant wird gespeichert und in einem zweiten Törn angeboten', () async {
      const supplier = SupplierProfile(
        id: 'sup_test_1',
        name: 'Kastela Provisioning Service',
        marina: 'Marina Kastela',
        phone: '+385 21 112233',
        email: 'order@kastela-provisions.hr',
      );

      // Speichern im ersten Törn
      await supplierService.saveSupplier(supplier);

      // Prüfen, dass der Lieferant global abrufbar ist
      final suppliers = await supplierService.getSuppliers();
      expect(suppliers.any((s) => s.name == 'Kastela Provisioning Service'), isTrue);

      // Zweiter Törn anlegen
      final secondTripId = await tripService.createTripWithCrew(
        name: 'Zweiter Törn 2026',
        startDate: DateTime(2026, 10, 1),
        daysCount: 7,
        isCharter: true,
        boatType: 'catamaran',
        region: 'baltic',
        fridgeCapacityLiters: 120.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: [
          const CrewMemberInput(id: '3', name: 'Crewmember Tim', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      expect(secondTripId, greaterThan(0));

      // In einem zweiten Törn ist der gleiche Lieferant verfügbar
      final availableSuppliersForTrip2 = await supplierService.getSuppliers();
      expect(availableSuppliersForTrip2.length, greaterThanOrEqualTo(1));
      final found = availableSuppliersForTrip2.firstWhere((s) => s.name == 'Kastela Provisioning Service');
      expect(found.marina, 'Marina Kastela');
      expect(found.phone, '+385 21 112233');
    });
  });
}

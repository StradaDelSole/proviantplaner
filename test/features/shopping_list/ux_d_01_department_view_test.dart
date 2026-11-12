/// Tests für UX-D-01: Vorräte „Nach Abteilung“ – Kategorie-Color-Coding & visuelle Hierarchie (Issue #74).
library;

import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/theme/app_theme.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_providers.dart';
import 'package:proviantplaner/features/shopping_list/data/shopping_list_service.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart'
    show CrewMemberInput;
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/shopping_list_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/flight_strip/flight_strip_colors.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/add_or_edit_item_sheet.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/empty_shopping_list_view.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/item_row_widget.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/shopping_view.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late ShoppingListService shoppingListService;
  late int tripId;

  setUp(() async {
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

    tripId = await tripService.createTripWithCrew(
      name: 'UX-D-01 Test Törn',
      startDate: DateTime(2026, 8, 15),
      daysCount: 7,
      isCharter: true,
      boatType: 'monohull',
      region: 'mediterranean',
      fridgeCapacityLiters: 90.0,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: [
        const CrewMemberInput(
          id: '1',
          name: 'Skipper',
          isAdult: true,
          isVegetarian: false,
          noAlcohol: false,
        ),
        const CrewMemberInput(
          id: '2',
          name: 'Co-Skipper',
          isAdult: true,
          isVegetarian: true,
          noAlcohol: false,
        ),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildDepartmentTestApp({
    ThemeData? theme,
    List<Override> extraOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWith((ref) {
          shoppingListService.onTripDataChanged = (tId) {
            ref.read(tripDataVersionProvider(tId).notifier).update((v) => v + 1);
          };
          return shoppingListService;
        }),
        shoppingListViewModeProvider.overrideWith((ref) => ShoppingListSortMode.department),
        ...extraOverrides,
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de'), Locale('en')],
        home: ShoppingListScreen(tripId: tripId),
      ),
    );
  }

  testWidgets('1. Gemischte Kategorien in gleicher Abteilung zeigen neutrale Header und korrekte FlightStripColors-Akzente + Icons', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = await shoppingListService.loadShoppingList(tripId);
    ShoppingListDepartmentView? mixedDept;
    List<ShoppingListItemView>? mixedPair;
    for (final dept in data.departments) {
      final seenByCat = <String, ShoppingListItemView>{};
      for (final it in dept.items) {
        seenByCat.putIfAbsent(it.categoryId, () => it);
      }
      if (seenByCat.length >= 2) {
        mixedDept = dept;
        mixedPair = seenByCat.values.take(2).toList();
        break;
      }
    }

    expect(mixedPair, isNotNull);
    expect(mixedDept, isNotNull);

    for (final it in mixedPair!) {
      await shoppingListService.adoptItem(tripId: tripId, listItemId: it.item.id, packages: 2);
    }

    await tester.pumpWidget(buildDepartmentTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(ShoppingView), findsOneWidget);
    expect(find.byType(ShoppingListItemRow), findsNWidgets(2));

    // Neutraler Abteilungskopf vorhanden
    expect(
      find.byKey(ValueKey('dept_header_${mixedDept!.department.name}')),
      findsOneWidget,
    );

    // Prüfe unterschiedliche Kategorie-Farbbalken & Icons anhand FlightStripColors
    final item0 = mixedPair[0];
    final item1 = mixedPair[1];
    final accent1 = tester.widget<Container>(
      find.byKey(ValueKey('dept_row_category_accent_${item0.item.id}')),
    );
    final accent2 = tester.widget<Container>(
      find.byKey(ValueKey('dept_row_category_accent_${item1.item.id}')),
    );
    final deco1 = accent1.decoration as BoxDecoration;
    final deco2 = accent2.decoration as BoxDecoration;

    expect(
      deco1.color,
      FlightStripColors.getCategoryColor(item0.categoryId, brightness: Brightness.light),
    );
    expect(
      deco2.color,
      FlightStripColors.getCategoryColor(item1.categoryId, brightness: Brightness.light),
    );
    expect(deco1.color, isNot(equals(deco2.color)));

    final icon1 = tester.widget<Icon>(
      find.byKey(ValueKey('dept_row_category_icon_${item0.item.id}')),
    );
    final icon2 = tester.widget<Icon>(
      find.byKey(ValueKey('dept_row_category_icon_${item1.item.id}')),
    );
    expect(icon1.icon, FlightStripColors.getCategoryIcon(item0.categoryId));
    expect(icon2.icon, FlightStripColors.getCategoryIcon(item1.categoryId));
  });

  testWidgets('2. Nachtwache-Modus rendert strikt Rot auf Schwarz ohne bunte Kategorie-Palette', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = await shoppingListService.loadShoppingList(tripId);
    final item = data.allItems.first;
    await shoppingListService.adoptItem(tripId: tripId, listItemId: item.item.id, packages: 1);

    await tester.pumpWidget(buildDepartmentTestApp(theme: AppTheme.nightwatchTheme));
    await tester.pumpAndSettle();

    final accent = tester.widget<Container>(
      find.byKey(ValueKey('dept_row_category_accent_${item.item.id}')),
    );
    final deco = accent.decoration as BoxDecoration;
    expect(deco.color, const Color(0xFFFF3B30));

    final icon = tester.widget<Icon>(
      find.byKey(ValueKey('dept_row_category_icon_${item.item.id}')),
    );
    expect(icon.color, const Color(0xFFFF3B30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('3. Lange Produktnamen & schmaler 320dp-Viewport ohne harte Einzeilen-Abschneidung oder Overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longName = 'Extra langes Bio-Sauerteig-Bauernbrot mit Kürbiskernen und Meersalz 750g';
    await shoppingListService.addCustomItem(
      CustomItemInput(
        tripId: tripId,
        name: longName,
        quantity: 2,
        unit: 'Packung',
        department: 'backwaren',
        categoryId: 'fruehstueck',
      ),
    );

    await tester.pumpWidget(buildDepartmentTestApp());
    await tester.pumpAndSettle();

    final nameFinder = find.text(longName);
    expect(nameFinder, findsOneWidget);
    final nameText = tester.widget<Text>(nameFinder);
    expect(nameText.maxLines, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('4. Stop-Filter zeigt nur Artikel des gewählten Stopps und blendet leere Abteilungen aus', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stop2Id = await db.tripDao.addShoppingStop(
      ShoppingStopsCompanion.insert(
        tripId: tripId,
        dayNumber: const Value(3),
        name: 'Hvar Stopp',
      ),
    );

    final data = await shoppingListService.loadShoppingList(tripId);
    final itemA = data.allItems[0];
    final itemB = data.allItems[1];
    await shoppingListService.adoptItem(tripId: tripId, listItemId: itemA.item.id, packages: 2);
    await shoppingListService.adoptItem(tripId: tripId, listItemId: itemB.item.id, packages: 3);
    await shoppingListService.allocateToStop(
      tripId: tripId,
      listItemId: itemB.item.id,
      shoppingStopId: stop2Id,
      packages: 3,
    );

    await tester.pumpWidget(
      buildDepartmentTestApp(
        extraOverrides: [
          selectedStopFilterProvider.overrideWith((ref) => stop2Id),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('item_tap_${itemB.item.id}')), findsOneWidget);
    expect(find.byKey(ValueKey('item_tap_${itemA.item.id}')), findsNothing);
  });

  testWidgets('5. Leere Liste zeigt EmptyShoppingListView', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildDepartmentTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(EmptyShoppingListView), findsOneWidget);
    expect(find.byType(ShoppingListItemRow), findsNothing);
  });

  testWidgets('6. Mengensteuerung (+ / -), Detail-Sheet-Tap und Rebuild-Scrollstabilität bleiben intakt', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = await shoppingListService.loadShoppingList(tripId);
    for (final it in data.allItems.take(25)) {
      await shoppingListService.adoptItem(tripId: tripId, listItemId: it.item.id, packages: 2);
    }

    await tester.pumpWidget(buildDepartmentTestApp());
    await tester.pumpAndSettle();

    // Nach unten scrollen
    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);
    await tester.drag(listFinder, const Offset(0, -600));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final offsetBefore = scrollable.position.pixels;
    expect(offsetBefore, greaterThan(200));

    // Sichtbaren "+"-Button auf einer Zeile antippen
    final plusButtons = find.byIcon(Icons.add).hitTestable();
    expect(plusButtons, findsWidgets);
    await tester.tap(plusButtons.first);
    await tester.pumpAndSettle();

    // Scrollposition bleibt nach Rebuild stabil
    final offsetAfter = tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    expect(offsetAfter, closeTo(offsetBefore, 5.0));

    // Tap auf Produktzeile öffnet AddOrEditItemSheet
    final visibleRowTap = find
        .byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('item_tap_'),
        )
        .hitTestable();
    await tester.tap(visibleRowTap.first);
    await tester.pumpAndSettle();
    expect(find.byType(AddOrEditItemSheet), findsOneWidget);
  });
}

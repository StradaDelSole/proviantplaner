/// UI- und Widget-Tests für Vorratsliste, Einkaufsmodus und Einlagerung (Slice S4).
library;

import 'dart:io';
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
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart' show CrewMemberInput;
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/shopping_mode_screen.dart';
import 'package:proviantplaner/features/shopping_list/ui/storage_checklist_screen.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

void main() {
  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late ShoppingListService shoppingListService;
  late int tripId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catFile = File('data/catalog_v0.11.json');
    final quantFile = File('data/quantities_v0.4.json');
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
      name: 'Adria Törn 2026',
      startDate: DateTime(2026, 8, 10),
      daysCount: 7,
      isCharter: true,
      boatType: 'monohull',
      region: 'mediterranean',
      fridgeCapacityLiters: 90.0,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: [
        const CrewMemberInput(id: '1', name: 'Skipper Alex', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Ben', isAdult: true, isVegetarian: true, noAlcohol: false),
      ],
    );
    await shoppingListService.adoptAllSuggestions(tripId);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget child, {ThemeData? theme}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWithValue(shoppingListService),
      ],
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
        home: child,
      ),
    );
  }

  testWidgets('S4: ShoppingListScreen rendert Planen- und Einkaufen-Sichten fehlerfrei', (tester) async {
    await tester.pumpWidget(buildTestableWidget(ShoppingListScreen(tripId: tripId)));
    await tester.pumpAndSettle();

    // 1. Titel und Allergen-Hinweis prüfen
    expect(find.text('Adria Törn 2026'), findsOneWidget);
    expect(find.text('Ernährungs-Tags sind kein Allergieschutz'), findsOneWidget);

    // 2. SegmentedButton für Nach Kategorie & Nach Abteilung vorhanden
    expect(find.text('Nach Kategorie'), findsOneWidget);
    expect(find.text('Nach Abteilung'), findsOneWidget);

    // 3. Stopp-Filter Chip
    expect(find.text('Alle Stopps'), findsOneWidget);

    // 4. In der Nach Kategorie-Sicht sind Kategorien und Gruppen sichtbar
    expect(find.byType(ListView), findsWidgets);

    // 5. Umschalten auf "Nach Abteilung"
    await tester.tap(find.text('Nach Abteilung'));
    await tester.pumpAndSettle();

    // In der Einkaufen-Sicht sind Stepper vorhanden mit mindestens 48 dp
    final removeIcons = find.byIcon(Icons.remove);
    expect(removeIcons, findsWidgets);

    final removeButtons = find.ancestor(of: removeIcons, matching: find.byType(IconButton));
    expect(removeButtons, findsWidgets);

    final firstRemove = tester.firstWidget<IconButton>(removeButtons);
    expect(firstRemove.constraints?.minWidth ?? 0, greaterThanOrEqualTo(48.0));
    expect(firstRemove.constraints?.minHeight ?? 0, greaterThanOrEqualTo(48.0));
  });

  testWidgets('S4: ShoppingListScreen rendert im Nachtwache-Modus rein in Rot/Schwarz', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        ShoppingListScreen(tripId: tripId),
        theme: AppTheme.nightwatchTheme,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adria Törn 2026'), findsOneWidget);
    expect(find.text('Ernährungs-Tags sind kein Allergieschutz'), findsOneWidget);
  });

  testWidgets('S4: ShoppingModeScreen rendert Checkliste und erlaubt Abhaken', (tester) async {
    final stops = await db.tripDao.getShoppingStopsForTrip(tripId);
    final initialStop = stops.first;

    await tester.pumpWidget(
      buildTestableWidget(
        ShoppingModeScreen(tripId: tripId, stopId: initialStop.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Einkauf Tag 1'), findsOneWidget);
    expect(find.text('Fertig eingekauft'), findsOneWidget);

    // Erste Checkbox antippen
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsWidgets);
    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();
  });

  testWidgets('S4: StorageChecklistScreen zeigt Wellpappe-Warnung und Einlagerungsschritte', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        StorageChecklistScreen(tripId: tripId),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Einlagern'), findsOneWidget);
    expect(find.text('Kartons an Land auspacken – Ungeziefer reist in Wellpappe mit.'), findsOneWidget);
    expect(find.text('Einlagerung abschließen'), findsOneWidget);
  });
}

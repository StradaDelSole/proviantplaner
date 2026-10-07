/// Interaktions-Tests für das Varianten-Sheet (FEEDBACK_R1 Punkt 6).
///
/// Prüft echte Interaktion:
/// 1. Sheet öffnen -> Eistee antippen -> Eistee steht auf der Liste
/// 2. Wieder abwählen -> verschwindet von der Liste
/// 3. Menge per Eingabe ändern -> neuer Wert sichtbar und gespeichert
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
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart'
    show CrewMemberInput;
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/shopping_list/ui/widgets/group_detail_sheet.dart';
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
    final quantFile = File('data/quantities_v0.5.json');
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
      name: 'Test Törn Sheet',
      startDate: DateTime(2026, 7, 1),
      daysCount: 7,
      isCharter: true,
      boatType: 'monohull',
      region: 'warm',
      fridgeCapacityLiters: 80.0,
      crewAppetite: CrewAppetite.normal,
      crewReserve: false,
      crewDrinking: CrewDrinking.normal,
      crewMembers: [
        const CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        const CrewMemberInput(id: '2', name: 'Crew 2', isAdult: true, isVegetarian: false, noAlcohol: false),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        shoppingListServiceProvider.overrideWithValue(shoppingListService),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de')],
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('Echte Interaktion im Sheet: Eistee anwählen, Menge ändern, abwählen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. Gruppendaten für 'soft' (Erfrischungsgetränke) laden
    var data = await shoppingListService.loadShoppingList(tripId);
    final softGroup = data.categories
        .expand((c) => c.groups)
        .firstWhere((g) => g.group.id == 'soft');

    // Sheet anzeigen
    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () => GroupDetailSheet.show(
                ctx,
                tripId: tripId,
                groupView: softGroup,
                stops: data.stops,
                isCharter: true,
              ),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Button tippen, um Sheet zu öffnen
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verifizieren: Eistee ist im Sheet sichtbar
    expect(find.text('Eistee'), findsOneWidget);

    // Eistee Checkbox finden
    final eisteeRow = find.ancestor(
      of: find.text('Eistee'),
      matching: find.byType(InkWell),
    ).first;

    // 2. Eistee Checkbox antippen (anwählen)
    final eisteeCheckbox = find.descendant(
      of: eisteeRow,
      matching: find.byType(Checkbox),
    );
    await tester.tap(eisteeCheckbox);
    await tester.pumpAndSettle();

    // In DB und Liste prüfen: Eistee ist jetzt ausgewählt und auf der Liste
    data = await shoppingListService.loadShoppingList(tripId);
    var eistee = data.allItems.firstWhere((it) => it.id == 'iced_tea');
    expect(eistee.isSelected, isTrue);

    // 3. Menge per Direkteingabe ändern (auf Stift-Icon bei Eistee tippen)
    final editButton = find.descendant(
      of: eisteeRow,
      matching: find.byIcon(Icons.edit_note),
    );
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Dialog "Menge anpassen" ist offen
    expect(find.text('Eistee: Menge anpassen'), findsOneWidget);
    final textField = find.byType(TextField);
    await tester.enterText(textField, '7');
    await tester.pumpAndSettle();

    // "Speichern" tippen
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    // Verifizieren: Neuer Wert 7 ist sichtbar und gespeichert
    data = await shoppingListService.loadShoppingList(tripId);
    eistee = data.allItems.firstWhere((it) => it.id == 'iced_tea');
    expect(eistee.effectivePackages, 7);
    expect(find.textContaining('7'), findsWidgets);

    // 4. Eistee wieder abwählen
    await tester.tap(eisteeCheckbox);
    await tester.pumpAndSettle();

    // Verifizieren: Abgewählt
    data = await shoppingListService.loadShoppingList(tripId);
    eistee = data.allItems.firstWhere((it) => it.id == 'iced_tea');
    expect(eistee.isSelected, isFalse);
  });
}

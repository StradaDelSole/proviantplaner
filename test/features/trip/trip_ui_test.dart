import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/ui/trip_timeline_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';

void main() {
  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    catalogRepo = CatalogRepository();
    final catalogFile = File('data/catalog_v0.8.json');
    final quantitiesFile = File('data/quantities_v0.4.json');
    catalogRepo.loadFromJsonStrings(
      catalogJson: catalogFile.readAsStringSync(),
      quantitiesJson: quantitiesFile.readAsStringSync(),
    );

    tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: catalogRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget child, {List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalogRepo),
        tripServiceProvider.overrideWithValue(tripService),
        ...overrides,
      ],
      child: MaterialApp(
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

  group('Trip UI Tests (Slice S3)', () {
    testWidgets('TripWizardScreen rendert alle 3 Sektionen auf einer Seite (UX-A)', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const TripWizardScreen()));
      await tester.pumpAndSettle();

      // Sektion 1
      expect(find.text('1. Törn'), findsOneWidget);
      expect(find.text('Törn Kroatien'), findsOneWidget);

      // Sektion 2
      expect(find.text('2. Boot'), findsOneWidget);

      // Sektion 3
      expect(find.text('3. Crew (1)'), findsOneWidget);
      expect(find.text('Skipper'), findsOneWidget);

      // Sektion 4
      expect(find.text('4. Essen an Bord'), findsOneWidget);
      expect(find.text('Wie isst eure Crew?'), findsOneWidget);

      // Aktions-Button unten
      expect(find.text('Törn erstellen'), findsOneWidget);
    });

    testWidgets('TripTimelineScreen zeigt Tage und Restaurant-Chips', (WidgetTester tester) async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Test-Törn',
        startDate: DateTime.now(),
        daysCount: 3,
        isCharter: true,
        boatType: 'monohull',
        region: 'mediterranean_summer',
        fridgeCapacityLiters: 100.0,
        crewAppetite: CrewAppetite.normal,
        crewReserve: false,
        crewDrinking: CrewDrinking.normal,
        crewMembers: const [],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          TripTimelineScreen(tripId: tripId),
          overrides: [
            activeTripIdProvider.overrideWith((ref) => tripId),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test-Törn'), findsOneWidget);
      expect(find.text('TÖRN-BILANZ VERPFLEGUNG'), findsOneWidget);
      expect(find.text('Einkaufsstopps'), findsOneWidget);
      expect(find.text('Ersteinkauf Basis'), findsWidgets);
      expect(find.text('TAG 01'), findsOneWidget);
      expect(find.text('TAG 02'), findsOneWidget);
      expect(find.text('TAG 03'), findsOneWidget);
    });
  });
}

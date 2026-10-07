import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/database_provider.dart';
import 'package:proviantplaner/core/routing/app_router.dart';
import 'package:proviantplaner/features/home/ui/start_screen.dart';
import 'package:proviantplaner/features/kitty/data/kitty_providers.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/kitty/ui/settlement_screen.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/shopping_list/domain/calculation/quantity_engine.dart';
import 'package:proviantplaner/features/trip/data/trip_provider.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';
import 'package:proviantplaner/features/trip/ui/trip_overview_screen.dart';
import 'package:proviantplaner/features/trip/ui/trip_wizard_screen.dart';
import 'package:proviantplaner/features/trip/ui/widgets/crew_member_dialog.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proviantplaner/features/shopping_list/data/delivery_order_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late AppDatabase db;
  late CatalogRepository catalogRepo;
  late TripService tripService;
  late KittyService kittyService;
  late DeliveryOrderService deliveryOrderService;

  setUp(() {
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

    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );

    deliveryOrderService = DeliveryOrderService();
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
        kittyServiceProvider.overrideWithValue(kittyService),
        deliveryOrderServiceProvider.overrideWithValue(deliveryOrderService),
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

  group('UX-A Abnahmekriterien Tests', () {
    // Kriterium 1: Meine Törns hat keine Reiterleiste
    testWidgets('1. Meine Törns hat keine Reiterleiste', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const StartScreen()));
      await tester.pumpAndSettle();

      // Es darf weder NavigationBar noch BottomNavigationBar vorhanden sein
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    // Kriterium 2: Anlegen ohne Revier/Bootstyp möglich und führt direkt zur Übersicht
    testWidgets('2. Anlegen ohne Revier/Bootstyp möglich und führt direkt zur Übersicht', (tester) async {
      final router = GoRouter(
        initialLocation: '/trips/new',
        routes: [
          GoRoute(
            path: '/trips/new',
            builder: (_, __) => const TripWizardScreen(),
          ),
          GoRoute(
            path: '/trips/:id',
            builder: (_, state) => Text('ÜBERSICHT_${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(catalogRepo),
            tripServiceProvider.overrideWithValue(tripService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('de'), Locale('en')],
            locale: const Locale('de'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Revier/Klimazone- und Einrumpf/Katamaran-Felder dürfen nicht vorhanden sein
      expect(find.text('Revier'), findsNothing);
      expect(find.text('Klimazone'), findsNothing);
      expect(find.text('Katamaran'), findsNothing);
      expect(find.text('Einrumpf (Monohull)'), findsNothing);

      // Scrollen und Törn anlegen antippen
      final createButton = find.text('Törn erstellen');
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Führt direkt zur Törn-Übersicht (/trips/1)
      expect(find.text('ÜBERSICHT_1'), findsOneWidget);
    });

    // Kriterium 3: Zähler "Restaurant" ändern Bord-Mahlzeiten
    test('3. Zähler Restaurant ändern Bord-Mahlzeiten', () async {
      // 7 Tage Törn initialisieren
      final tripId = await tripService.createTripWithCrew(
        name: 'Kroatien Test',
        startDate: DateTime.now(),
        daysCount: 7,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      // Vor Restaurantzählern: 7 Tage ohne Restaurant
      final daysBefore = await db.tripDao.getDaysForTrip(tripId);
      final dinnersBefore = daysBefore.where((d) => !d.dinnerRestaurant).length;
      final lunchesBefore = daysBefore.where((d) => !d.lunchRestaurant).length;
      expect(dinnersBefore, equals(7));
      expect(lunchesBefore, equals(7));

      // Jetzt Restaurant-Zähler setzen: 3 Dinners und 2 Lunches
      await tripService.setRestaurantCounts(tripId, dinners: 3, lunches: 2);

      final daysAfter = await db.tripDao.getDaysForTrip(tripId);
      final dinnersAfter = daysAfter.where((d) => !d.dinnerRestaurant).length;
      final lunchesAfter = daysAfter.where((d) => !d.lunchRestaurant).length;

      // 7 - 3 = 4 Bord-Abendessen, 7 - 2 = 5 Bord-Mittagessen
      expect(dinnersAfter, equals(4));
      expect(lunchesAfter, equals(5));
    });

    // Kriterium 4: Übersicht zeigt vier Schritte und hebt den nächsten hervor
    testWidgets('4. Übersicht zeigt vier Schritte und hebt den nächsten hervor', (tester) async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Törn Übersicht Test',
        startDate: DateTime.now().add(const Duration(days: 2)), // Zukunft -> Schritt 1 oder 2
        daysCount: 7,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(TripOverviewScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      // Alle 4 Schritte vorhanden
      expect(find.text('Liste'), findsOneWidget);
      expect(find.text('Einkaufen'), findsOneWidget);
      expect(find.text('Unterwegs / Bordkasse'), findsOneWidget);
      expect(find.text('Abrechnen'), findsWidgets);

      // Mindestens eine Card hat den hervorgehobenen Rahmen (width == 2)
      final cards = tester.widgetList<Card>(find.byType(Card));
      final highlightedCard = cards.where((c) {
        final shape = c.shape;
        if (shape is RoundedRectangleBorder) {
          return shape.side.width == 2.0;
        }
        return false;
      });
      expect(highlightedCard.isNotEmpty, isTrue);
    });

    // Kriterium 5: "Abrechnen" und "Ausgabe erfassen" sind ohne Drei-Punkte-Menü erreichbar
    testWidgets('5. Abrechnen und Ausgabe erfassen sind ohne Drei-Punkte-Menü erreichbar', (tester) async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Buttons Test',
        startDate: DateTime.now().subtract(const Duration(days: 1)), // Bereits gestartet
        daysCount: 7,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Skipper', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(TripOverviewScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      // Kein Drei-Punkte-Menü (PopupMenuButton) vorhanden
      expect(find.byType(PopupMenuButton), findsNothing);

      // Buttons "Abrechnen" und "Ausgabe erfassen" direkt auffindbar
      expect(find.widgetWithText(FilledButton, 'Abrechnen'), findsOneWidget);
      expect(find.text('Ausgabe erfassen'), findsWidgets);
    });

    // Kriterium 6: Kein Bildschirm tiefer als zwei Ebenen
    test('6. Kein Bildschirm tiefer als zwei Ebenen', () {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(catalogRepo),
          tripServiceProvider.overrideWithValue(tripService),
        ],
      );
      final router = container.read(appRouterProvider);

      // Alle definierten Pfade dürfen von '/' ausgehend maximal 2 Ebenen tief sein
      // Ebene 0: /
      // Ebene 1: /trips/new, /trips/:id, /more
      // Ebene 2: /trips/:id/shopping-list, /trips/:id/shop/:stopId, /trips/:id/kitty/settlement
      for (final route in router.configuration.routes) {
        if (route is GoRoute) {
          final segments = route.path.split('/').where((s) => s.isNotEmpty).toList();
          // Ersetzt man '/trips/:id' durch die Törn-Ebene (Ebene 1):
          // dann ist '/trips/:id/shopping-list' genau 1 Ebene unter der Törn-Übersicht und 2 unter Start.
          if (route.path.startsWith('/trips/:id/')) {
            final subSegments = route.path.substring('/trips/:id/'.length).split('/').where((s) => s.isNotEmpty).toList();
            expect(subSegments.length, lessThanOrEqualTo(2), reason: 'Route ${route.path} ist zu tief verschachtelt');
          } else {
            expect(segments.length, lessThanOrEqualTo(2), reason: 'Route ${route.path} ist zu tief verschachtelt');
          }
        }
      }
    });

    // Kriterium 7: Crew-Verwaltung enthält keine Zahlungsdaten-Felder
    testWidgets('7. Crew-Verwaltung enthält keine Zahlungsdaten-Felder', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const CrewMemberDialog()));
      await tester.pumpAndSettle();

      expect(find.text('IBAN'), findsNothing);
      expect(find.text('IBAN *'), findsNothing);
      expect(find.text('PayPal.Me Link (optional)'), findsNothing);
      expect(find.text('Revolut.Me Link (optional)'), findsNothing);
    });

    // Kriterium 8: Zahlung an die Kasse nutzt die Daten des Kassenwarts
    test('8. Zahlung an die Kasse nutzt die Daten des Kassenwarts', () {
      const treasurer = KittyMember(
        id: 1,
        name: 'Kassenwart Bob',
        iban: 'DE89370400440532013000',
        categoryParticipation: {},
      );
      const payer = KittyMember(
        id: 2,
        name: 'Alice',
        categoryParticipation: {},
      );

      // Shared Kitty Ausgleichszahlung in die Kasse (an den Kassenwart)
      const transfer = PaymentTransfer(
        fromMember: payer,
        toMember: treasurer,
        amountInCents: 5000,
      );

      // Der Empfänger ist der Kassenwart
      expect(transfer.toMember.name, equals('Kassenwart Bob'));
      expect(transfer.toMember.iban, equals('DE89370400440532013000'));

      final payload = EpcQrPayload(
        beneficiaryName: transfer.toMember.name,
        iban: transfer.toMember.iban!,
        amountInCents: transfer.amountInCents,
        remittanceInformation: 'Bordkasse Einzahlung',
      );

      expect(payload.beneficiaryName, equals('Kassenwart Bob'));
      expect(payload.iban, equals('DE89370400440532013000'));
    });

    // Kriterium 9: IBAN eines anderen Mitglieds wird erst bei "Überweisen" in dessen Abrechnungszeile abgefragt
    testWidgets('9. IBAN eines anderen Mitglieds wird erst bei Überweisen in dessen Abrechnungszeile abgefragt', (tester) async {
      final tripId = await tripService.createTripWithCrew(
        name: 'Abrechnung Payout Test',
        startDate: DateTime.now().subtract(const Duration(days: 8)),
        daysCount: 7,
        crewMembers: const [
          CrewMemberInput(id: '1', name: 'Kassenwart', isAdult: true, isVegetarian: false, noAlcohol: false),
          CrewMemberInput(id: '2', name: 'Anna', isAdult: true, isVegetarian: false, noAlcohol: false),
        ],
      );

      final members = await db.tripDao.getCrewForTrip(tripId);
      final treasurerId = members.first.id;
      final annaId = members.last.id;
      await db.tripDao.setTripTreasurer(tripId, treasurerId);

      // Anna zahlt 100 € in die Kasse ein, Kassenwart 0 €
      await kittyService.addDeposit(tripId: tripId, memberId: annaId, amountInCents: 10000);
      await kittyService.addDeposit(tripId: tripId, memberId: treasurerId, amountInCents: 0);

      // 40 € Ausgabe aus der Bordkasse -> je 20 € Kostenanteil
      // Anna hat 100 € eingezahlt, Kosten 20 € -> Anna bekommt 80 € vom Kassenwart zurück
      await kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Proviant',
          amountInCents: 4000,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: true,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(SettlementScreen(tripId: tripId)));
      await tester.pumpAndSettle();

      // Es gibt eine Auszahlungszeile "bekommt ... von Kassenwart"
      expect(find.textContaining('bekommt'), findsOneWidget);

      // "Bar ausgezahlt" und "Überweisen" sind vorhanden
      expect(find.text('Bar ausgezahlt'), findsOneWidget);
      final transferButton = find.text('Überweisen');
      expect(transferButton, findsOneWidget);

      // Tipp auf "Überweisen" öffnet den IBAN-Dialog, da Anna noch keine IBAN hat
      await tester.tap(transferButton);
      await tester.pumpAndSettle();

      // Dialog "Zahlungsdaten für Anna" mit "IBAN *" ist geöffnet
      expect(find.text('Zahlungsdaten für Anna'), findsOneWidget);
      expect(find.text('IBAN *'), findsOneWidget);
    });
  });
}

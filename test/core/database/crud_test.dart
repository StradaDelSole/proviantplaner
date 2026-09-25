import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('S1: CRUD Tests für alle 8 Entitäten', () {
    test('1. Trip & Auto-Generierung von Stop 1 und TripDays', () async {
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Kornaten Törn 2026',
          startDate: DateTime(2026, 9, 1),
          daysCount: const Value(7),
          region: const Value('mediterranean'),
          isCharter: const Value(true),
          boatType: const Value('mono'),
          fridgeCapacity: const Value(110),
          appetite: const Value(CrewAppetite.normal),
          reserveDays: const Value('few_days'),
          drinkingHabit: const Value(CrewDrinking.normal),
          hasStorageChecklist: const Value(true),
          phase: const Value(TripPhase.plan),
          isArchived: const Value(false),
          currency: const Value('EUR'),
          kittyModel: const Value(KittyModel.sharedKitty),
        ),
      );

      final trip = await db.tripDao.getTripById(tripId);
      expect(trip, isNotNull);
      expect(trip!.name, 'Kornaten Törn 2026');
      expect(trip.daysCount, 7);

      // Prüfen, dass erster Einkaufsstopp automatisch angelegt wurde
      final stops = await db.tripDao.getShoppingStopsForTrip(tripId);
      expect(stops.length, 1);
      expect(stops.first.isInitial, isTrue);
      expect(stops.first.dayNumber, 1);
      expect(stops.first.name, 'Ersteinkauf Basis');

      // Prüfen, dass 7 TripDays automatisch angelegt wurden
      final days = await db.tripDao.getDaysForTrip(tripId);
      expect(days.length, 7);
      expect(days.first.dayNumber, 1);
      expect(days.last.dayNumber, 7);

      // Update Trip
      final updated = await db.tripDao.updateTrip(
        trip.copyWith(name: 'Kornaten Törn 2026 (Aktualisiert)', phase: TripPhase.shopping),
      );
      expect(updated, isTrue);
      final refreshed = await db.tripDao.getTripById(tripId);
      expect(refreshed!.name, 'Kornaten Törn 2026 (Aktualisiert)');
      expect(refreshed.phase, TripPhase.shopping);
    });

    test('2. TripDay CRUD', () async {
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Tagestest Törn',
          startDate: DateTime(2026, 9, 1),
          daysCount: const Value(3),
        ),
      );

      final days = await db.tripDao.getDaysForTrip(tripId);
      final day2 = days[1];
      expect(day2.lunchRestaurant, isFalse);

      // Update Restaurant und Hafenname
      final updated = await db.tripDao.updateTripDay(
        day2.copyWith(
          lunchRestaurant: true,
          dinnerRestaurant: true,
          dayType: const Value('hafen'),
          portName: const Value('Hvar'),
        ),
      );
      expect(updated, isTrue);

      final refreshedDays = await db.tripDao.getDaysForTrip(tripId);
      final refreshedDay2 = refreshedDays[1];
      expect(refreshedDay2.lunchRestaurant, isTrue);
      expect(refreshedDay2.dinnerRestaurant, isTrue);
      expect(refreshedDay2.dayType, 'hafen');
      expect(refreshedDay2.portName, 'Hvar');
    });

    test('3. CrewMember CRUD', () async {
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Crew Törn',
          startDate: DateTime(2026, 9, 1),
        ),
      );

      final memberId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Skipper Markus',
          isChild: const Value(false),
          isVegetarian: const Value(false),
          isNonDrinker: const Value(false),
          isSkipperFree: const Value(true),
          skipperFreeScope: const Value('all'),
        ),
      );

      var crew = await db.tripDao.getCrewForTrip(tripId);
      expect(crew.length, 1);
      expect(crew.first.name, 'Skipper Markus');
      expect(crew.first.isSkipperFree, isTrue);

      // Update CrewMember
      await db.tripDao.updateCrewMember(
        crew.first.copyWith(isVegetarian: true),
      );
      crew = await db.tripDao.getCrewForTrip(tripId);
      expect(crew.first.isVegetarian, isTrue);

      // Delete CrewMember
      await db.tripDao.deleteCrewMember(memberId);
      crew = await db.tripDao.getCrewForTrip(tripId);
      expect(crew.isEmpty, isTrue);
    });

    test('4. ShoppingStop CRUD & Löschschutz für Initial-Stop', () async {
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Stopps Törn',
          startDate: DateTime(2026, 9, 1),
        ),
      );

      final initialStops = await db.tripDao.getShoppingStopsForTrip(tripId);
      final initialStop = initialStops.first;

      // Löschversuch des Initial-Stopps muss fehlschlagen
      final deleteInitialResult = await db.tripDao.deleteShoppingStop(initialStop.id);
      expect(deleteInitialResult, isFalse);

      // Weiteren Stopp anlegen
      final stop2Id = await db.tripDao.addShoppingStop(
        ShoppingStopsCompanion.insert(
          tripId: tripId,
          dayNumber: const Value(4),
          name: 'Markt Vis',
          isInitial: const Value(false),
        ),
      );

      var stops = await db.tripDao.getShoppingStopsForTrip(tripId);
      expect(stops.length, 2);

      // Weiteren Stopp löschen darf gelingen
      final deleteStop2Result = await db.tripDao.deleteShoppingStop(stop2Id);
      expect(deleteStop2Result, isTrue);

      stops = await db.tripDao.getShoppingStopsForTrip(tripId);
      expect(stops.length, 1);
    });

    test('5. ListItem CRUD', () async {
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Listen Törn',
          startDate: DateTime(2026, 9, 1),
        ),
      );

      final itemId = await db.listItemDao.addListItem(
        ListItemsCompanion.insert(
          tripId: tripId,
          catalogId: 'bread_baguette',
          calculatedQuantity: const Value(5.0),
          calculatedPackages: const Value(5),
        ),
      );

      var item = await db.listItemDao.getListItemById(itemId);
      expect(item, isNotNull);
      expect(item!.catalogId, 'bread_baguette');
      expect(item.calculatedPackages, 5);
      expect(item.overriddenPackages, isNull);

      // Update ListItem (z. B. Packungsanzahl überschreiben)
      await db.listItemDao.updateListItem(
        item.copyWith(overriddenPackages: const Value(7)),
      );
      item = await db.listItemDao.getListItemById(itemId);
      expect(item!.overriddenPackages, 7);

      // Delete ListItem
      await db.listItemDao.deleteListItem(itemId);
      item = await db.listItemDao.getListItemById(itemId);
      expect(item, isNull);
    });

    test('6. Expense & KittyPayment CRUD', () async {
      final tripId = await db.tripDao.createTrip(
        TripsCompanion.insert(
          name: 'Kassen Törn',
          startDate: DateTime(2026, 9, 1),
        ),
      );

      final memberId = await db.tripDao.addCrewMember(
        CrewMembersCompanion.insert(
          tripId: tripId,
          name: 'Anna',
        ),
      );

      // KittyPayment anlegen
      final paymentId = await db.expenseDao.addKittyPayment(
        KittyPaymentsCompanion.insert(
          tripId: tripId,
          crewMemberId: memberId,
          amount: 150.0,
        ),
      );

      final payments = await db.expenseDao.getKittyPaymentsForTrip(tripId);
      expect(payments.length, 1);
      expect(payments.first.amount, 150.0);
      expect(await db.expenseDao.getTotalKittyPayments(tripId), 150.0);

      // Expense anlegen
      final expenseId = await db.expenseDao.addExpense(
        ExpensesCompanion.insert(
          tripId: tripId,
          amount: 85.50,
          category: ExpenseCategory.provisions,
          isPaidFromKitty: const Value(true),
          note: const Value('Supermarkt Split'),
        ),
      );

      var expenses = await db.expenseDao.getExpensesForTrip(tripId);
      expect(expenses.length, 1);
      expect(expenses.first.amount, 85.50);
      expect(await db.expenseDao.getTotalKittyExpenses(tripId), 85.50);

      // Expense updaten
      await db.expenseDao.updateExpense(
        expenses.first.copyWith(amount: 90.0),
      );
      expect(await db.expenseDao.getTotalKittyExpenses(tripId), 90.0);

      // Löschen
      await db.expenseDao.deleteExpense(expenseId);
      expenses = await db.expenseDao.getExpensesForTrip(tripId);
      expect(expenses.isEmpty, isTrue);

      await db.expenseDao.deleteKittyPayment(paymentId);
      expect(await db.expenseDao.getTotalKittyPayments(tripId), 0.0);
    });
  });
}
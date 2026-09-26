/// Tests für das Bearbeiten und Löschen von Ausgaben mit sofortiger Neuberechnung (FEEDBACK_R1 Punkt 8).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:drift/drift.dart' show Value;

void main() {
  late AppDatabase db;
  late KittyService kittyService;
  late int tripId;
  late int member1Id;
  late int member2Id;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
    );

    tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Kitty Test Trip',
        startDate: DateTime(2026, 7, 1),
      ),
    );

    member1Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Skipper Anna',
        isChild: const Value(false),
        isVegetarian: const Value(false),
        isNonDrinker: const Value(false),
      ),
    );

    member2Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Ben',
        isChild: const Value(false),
        isVegetarian: const Value(false),
        isNonDrinker: const Value(false),
      ),
    );

    // Initial 100,00 € Einzahlung je Mitglied in die Kasse (200,00 € Kassenstand)
    await kittyService.addDeposit(tripId: tripId, memberId: member1Id, amountInCents: 10000);
    await kittyService.addDeposit(tripId: tripId, memberId: member2Id, amountInCents: 10000);
  });

  tearDown(() async {
    await db.close();
  });

  test('Ausgabe bearbeiten und löschen berechnet Kassenstand und Salden sofort neu', () async {
    // 1. Initialer Kassenstand: 200,00 €
    var data = await kittyService.loadKittyData(tripId);
    expect(data.cashBalanceCents, 20000);

    // 2. Ausgabe aus der Kasse erfassen: 50,00 € für Proviant
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Proviant',
        amountInCents: 5000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
      ),
    );

    // Neuer Kassenstand: 200,00 € - 50,00 € = 150,00 €
    data = await kittyService.loadKittyData(tripId);
    expect(data.cashBalanceCents, 15000);
    expect(data.expenses.length, 1);

    // 3. Ausgabe bearbeiten: Betrag von 50,00 € auf 80,00 € ändern
    await kittyService.updateExpense(
      id: expenseId,
      input: ExpenseInput(
        tripId: tripId,
        title: 'Proviant',
        amountInCents: 8000,
        category: ExpenseCategory.provisions,
        isPaidFromKitty: true,
      ),
    );

    // Neuer Kassenstand: 200,00 € - 80,00 € = 120,00 € sofort neu berechnet!
    data = await kittyService.loadKittyData(tripId);
    expect(data.cashBalanceCents, 12000);
    expect(data.expenses.first.amountInCents, 8000);

    // 4. Ausgabe löschen (z. B. mit Undo-Möglichkeit)
    final deletedExp = data.expenses.first;
    await kittyService.deleteExpense(expenseId);

    // Kassenstand muss sofort wieder 200,00 € sein!
    data = await kittyService.loadKittyData(tripId);
    expect(data.cashBalanceCents, 20000);
    expect(data.expenses, isEmpty);

    // 5. Ausgabe wiederherstellen (Rückgängig-Funktion)
    await kittyService.restoreExpense(deletedExp);

    // Kassenstand ist sofort wieder 120,00 €
    data = await kittyService.loadKittyData(tripId);
    expect(data.cashBalanceCents, 12000);
    expect(data.expenses.length, 1);
  });
}

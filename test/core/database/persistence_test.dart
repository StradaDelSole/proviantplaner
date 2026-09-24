import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('drift_persistence_test_');
    dbFile = File('${tempDir.path}/test_db.sqlite');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('S1 Abnahmekriterium: Daten überleben App-Neustart (persistente SQLite-DB)', () async {
    // 1. Session 1: Datenbank anlegen und Daten einfügen
    var db1 = AppDatabase(NativeDatabase(dbFile));

    final tripId = await db1.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Persistent Törn',
        startDate: DateTime(2026, 9, 1),
        daysCount: const Value(7),
      ),
    );

    await db1.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Max Mustermann',
        isVegetarian: const Value(true),
      ),
    );

    final itemId = await db1.listItemDao.addListItem(
      ListItemsCompanion.insert(
        tripId: tripId,
        catalogId: 'coffee_beans',
        calculatedPackages: const Value(3),
        overriddenPackages: const Value(4),
      ),
    );

    await db1.expenseDao.addExpense(
      ExpensesCompanion.insert(
        tripId: tripId,
        amount: 45.0,
        category: 'drinks',
        note: const Value('Bordbier'),
      ),
    );

    // Session 1 schließen (simuliert App Beenden / Neustart)
    await db1.close();

    // 2. Session 2: Datenbank aus derselben Datei neu öffnen
    var db2 = AppDatabase(NativeDatabase(dbFile));

    // Prüfen, ob alle Daten unverändert vorhanden sind
    final trip = await db2.tripDao.getTripById(tripId);
    expect(trip, isNotNull);
    expect(trip!.name, 'Persistent Törn');

    final crew = await db2.tripDao.getCrewForTrip(tripId);
    expect(crew.length, 1);
    expect(crew.first.name, 'Max Mustermann');
    expect(crew.first.isVegetarian, isTrue);

    final item = await db2.listItemDao.getListItemById(itemId);
    expect(item, isNotNull);
    expect(item!.catalogId, 'coffee_beans');
    expect(item.overriddenPackages, 4);

    final expenses = await db2.expenseDao.getExpensesForTrip(tripId);
    expect(expenses.length, 1);
    expect(expenses.first.amount, 45.0);
    expect(expenses.first.note, 'Bordbier');

    await db2.close();
  });
}
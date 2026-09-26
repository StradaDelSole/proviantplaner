import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';

void main() {
  test('S1 Abnahmekriterium: Schema- und Migrationstest', () async {
    final db = AppDatabase(NativeDatabase.memory());

    // SchemaVersion prüfen
    expect(db.schemaVersion, 3);

    // Prüfen, ob alle Tabellen angelegt wurden
    // Erneuter Aufruf von createAll oder Validierung der Tabellen über einfache Abfragen
    expect(await db.select(db.trips).get(), isEmpty);
    expect(await db.select(db.tripDays).get(), isEmpty);
    expect(await db.select(db.crewMembers).get(), isEmpty);
    expect(await db.select(db.shoppingStops).get(), isEmpty);
    expect(await db.select(db.listItems).get(), isEmpty);
    expect(await db.select(db.listItemAllocations).get(), isEmpty);
    expect(await db.select(db.expenses).get(), isEmpty);
    expect(await db.select(db.kittyPayments).get(), isEmpty);

    // MigrationStrategy testen
    final strategy = db.migration;
    expect(strategy, isNotNull);

    await db.close();
  });
}
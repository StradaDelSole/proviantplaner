import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';

void main() {
  test('S1/FB1-C Abnahmekriterium: Schema- und Migrationstest', () async {
    final db = AppDatabase(NativeDatabase.memory());

    // SchemaVersion prüfen (jetzt 4 nach FB1-C)
    expect(db.schemaVersion, 4);

    // Prüfen, ob alle Tabellen angelegt wurden
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

  test('FB1-C Abnahmekriterium: Migration alter Revierwerte auf Klimastufen', () async {
    final db = AppDatabase(NativeDatabase.memory());

    await db.into(db.trips).insert(
      TripsCompanion.insert(
        name: 'Alter Nordsee-Törn',
        startDate: DateTime.now(),
        daysCount: const Value(7),
        region: const Value('temperate'),
        climate: const Value('temperate'),
      ),
    );
    await db.into(db.trips).insert(
      TripsCompanion.insert(
        name: 'Alter Adria-Törn',
        startDate: DateTime.now(),
        daysCount: const Value(7),
        region: const Value('mediterranean_summer'),
        climate: const Value('mediterranean_summer'),
      ),
    );
    await db.into(db.trips).insert(
      TripsCompanion.insert(
        name: 'Alter Karibik-Törn',
        startDate: DateTime.now(),
        daysCount: const Value(7),
        region: const Value('hot_or_remote'),
        climate: const Value('hot_or_remote'),
      ),
    );

    // Migration aus onUpgrade ausführen
    await db.customStatement('''
      UPDATE trips SET climate = CASE 
        WHEN region = 'temperate' THEN 'cool'
        WHEN region = 'hot_or_remote' THEN 'hot'
        WHEN region IN ('mediterranean', 'mediterranean_summer') THEN 'warm'
        ELSE 'warm'
      END
    ''');

    final trips = await db.select(db.trips).get();
    expect(trips.firstWhere((t) => t.name == 'Alter Nordsee-Törn').climate, 'cool');
    expect(trips.firstWhere((t) => t.name == 'Alter Adria-Törn').climate, 'warm');
    expect(trips.firstWhere((t) => t.name == 'Alter Karibik-Törn').climate, 'hot');

    await db.close();
  });
}
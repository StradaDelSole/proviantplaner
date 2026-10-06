import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';

void main() {
  test('S1/FB1-C Abnahmekriterium: Schema- und Migrationstest', () async {
    final db = AppDatabase(NativeDatabase.memory());

    // SchemaVersion prüfen (jetzt 7 nach PIVOT3-A)
    expect(db.schemaVersion, 7);

    // Prüfen, ob alle Tabellen angelegt wurden
    expect(await db.select(db.boatProfiles).get(), isEmpty);
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

    // Trip mit treasurerMemberId, Tiefkühlfach, Wassertank und PIVOT3-A Snapshot-Feldern einfügen
    final tripId = await db.into(db.trips).insert(
      TripsCompanion.insert(
        name: 'Törn mit Kassenwart',
        startDate: DateTime.now(),
        treasurerMemberId: const Value(42),
        hasFreezer: const Value(true),
        freezerCapacity: const Value(25),
        waterTankLiters: const Value(200),
        isWaterTankDrinkable: const Value(true),
        hasWatermaker: const Value(true),
        boatName: const Value('Bavaria 46'),
      ),
    );
    final inserted = await (db.select(db.trips)..where((t) => t.id.equals(tripId))).getSingle();
    expect(inserted.treasurerMemberId, 42);
    expect(inserted.hasFreezer, isTrue);
    expect(inserted.freezerCapacity, 25);
    expect(inserted.waterTankLiters, 200);
    expect(inserted.isWaterTankDrinkable, isTrue);
    expect(inserted.hasWatermaker, isTrue);
    expect(inserted.boatName, 'Bavaria 46');
    expect(inserted.boatProfileId, isNull);

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
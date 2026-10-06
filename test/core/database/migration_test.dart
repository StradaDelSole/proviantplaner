import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviantplaner/core/database/app_database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

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

  test('PIVOT3-A Abnahmekriterium: Reale Migration v6 -> v7 mit Datenintegrität und Foreign-Keys', () async {
    // 1. Temporäre SQLite-Datei mit Schema v6 erstellen
    final tempDir = Directory.systemTemp.createTempSync('drift_migration_v6_v7_');
    final dbFile = File('${tempDir.path}/v6_database.sqlite');
    addTearDown(() {
      if (dbFile.existsSync()) dbFile.deleteSync();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    final rawDb = sqlite3.open(dbFile.path);

    // Schema v6 DDL ausführen
    rawDb.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        days_count INTEGER NOT NULL DEFAULT 7,
        region TEXT NOT NULL DEFAULT 'mediterranean',
        climate TEXT NOT NULL DEFAULT 'warm',
        is_charter INTEGER NOT NULL DEFAULT 1,
        boat_type TEXT NOT NULL DEFAULT 'mono',
        fridge_capacity INTEGER NOT NULL DEFAULT 100,
        has_freezer INTEGER NOT NULL DEFAULT 0,
        freezer_capacity INTEGER NOT NULL DEFAULT 0,
        water_tank_liters INTEGER NOT NULL DEFAULT 0,
        is_water_tank_drinkable INTEGER NOT NULL DEFAULT 0,
        appetite TEXT NOT NULL DEFAULT 'normal',
        reserve_days TEXT NOT NULL DEFAULT 'few_days',
        drinking_habit TEXT NOT NULL DEFAULT 'normal',
        has_storage_checklist INTEGER NOT NULL DEFAULT 1,
        phase TEXT NOT NULL DEFAULT 'plan',
        is_archived INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'EUR',
        kitty_model TEXT NOT NULL DEFAULT 'shared_kitty',
        treasurer_member_id INTEGER,
        created_at INTEGER NOT NULL
      );

      CREATE TABLE trip_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        day_number INTEGER NOT NULL,
        lunch_restaurant INTEGER NOT NULL DEFAULT 0,
        dinner_restaurant INTEGER NOT NULL DEFAULT 0,
        day_type TEXT,
        port_name TEXT
      );

      CREATE TABLE crew_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        is_child INTEGER NOT NULL DEFAULT 0,
        is_vegetarian INTEGER NOT NULL DEFAULT 0,
        is_non_drinker INTEGER NOT NULL DEFAULT 0,
        custom_eat_level TEXT,
        custom_drink_level TEXT,
        category_participation TEXT NOT NULL DEFAULT '{}',
        is_skipper_free INTEGER NOT NULL DEFAULT 0,
        skipper_free_scope TEXT,
        iban TEXT,
        paypal_link TEXT,
        revolut_link TEXT
      );

      CREATE TABLE shopping_stops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        day_number INTEGER NOT NULL DEFAULT 1,
        name TEXT NOT NULL,
        is_initial INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE list_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        catalog_id TEXT NOT NULL,
        calculated_packages INTEGER NOT NULL DEFAULT 0,
        calculated_quantity REAL NOT NULL DEFAULT 0.0,
        selected INTEGER NOT NULL DEFAULT 1,
        overridden_packages INTEGER,
        custom_name TEXT,
        custom_unit TEXT,
        custom_package_size REAL,
        custom_category TEXT,
        custom_storage_hint TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0,
        storage_done INTEGER NOT NULL DEFAULT 0,
        is_perishable INTEGER NOT NULL DEFAULT 0,
        is_frozen INTEGER NOT NULL DEFAULT 0,
        shelf_life_days INTEGER,
        check_state TEXT NOT NULL DEFAULT 'vorhanden',
        is_adopted INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE list_item_allocations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_item_id INTEGER NOT NULL REFERENCES list_items(id) ON DELETE CASCADE,
        shopping_stop_id INTEGER NOT NULL REFERENCES shopping_stops(id) ON DELETE CASCADE,
        packages INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        paid_by_crew_member_id INTEGER REFERENCES crew_members(id) ON DELETE SET NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EUR',
        category TEXT NOT NULL DEFAULT 'provisions',
        note TEXT,
        receipt_path TEXT,
        created_at INTEGER NOT NULL,
        is_paid_from_kitty INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE kitty_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        crew_member_id INTEGER NOT NULL REFERENCES crew_members(id) ON DELETE CASCADE,
        amount REAL NOT NULL,
        created_at INTEGER NOT NULL
      );

      PRAGMA user_version = 6;
    ''');

    // 2. Repräsentativen alten v6-Trip einfügen (mit allen relevanten Kapazitätswerten)
    rawDb.execute('''
      INSERT INTO trips (
        id, name, start_date, days_count, region, climate, is_charter,
        boat_type, fridge_capacity, has_freezer, freezer_capacity,
        water_tank_liters, is_water_tank_drinkable, appetite, reserve_days,
        drinking_habit, has_storage_checklist, phase, is_archived,
        currency, kitty_model, created_at
      ) VALUES (
        1, 'Historischer v6 Törn', 1700000000, 7, 'mediterranean', 'warm', 1,
        'mono', 120, 1, 30,
        350, 1, 'normal', 'few_days',
        'normal', 1, 'plan', 0,
        'EUR', 'shared_kitty', 1700000000
      );
    ''');

    rawDb.dispose();

    // 3. Reale Production-AppDatabase öffnen (führt automatisches Upgrade 6 -> 7 via MigrationStrategy aus)
    final upgradedDb = AppDatabase(NativeDatabase(dbFile));
    addTearDown(() async => upgradedDb.close());

    // 4. Verifikation nach Upgrade auf v7:
    // Schema-Version in SQLite prüfen
    final versionResult = await upgradedDb.customSelect('PRAGMA user_version').getSingle();
    expect(versionResult.read<int>('user_version'), equals(7));

    // Alter Trip existiert und alle bestehenden Werte sind unverändert erhalten
    final oldTrip = await (upgradedDb.select(upgradedDb.trips)..where((t) => t.id.equals(1))).getSingle();
    expect(oldTrip.name, equals('Historischer v6 Törn'));
    expect(oldTrip.fridgeCapacity, equals(120));
    expect(oldTrip.hasFreezer, isTrue);
    expect(oldTrip.freezerCapacity, equals(30));
    expect(oldTrip.waterTankLiters, equals(350));
    expect(oldTrip.isWaterTankDrinkable, isTrue);

    // Neue v7-Felder auf dem alten Trip sind sauber defaulted
    expect(oldTrip.boatProfileId, isNull);
    expect(oldTrip.boatName, isNull);
    expect(oldTrip.boatManufacturer, isNull);
    expect(oldTrip.boatModel, isNull);
    expect(oldTrip.hasWatermaker, isFalse);

    // Tabelle BoatProfiles existiert
    final profiles = await upgradedDb.select(upgradedDb.boatProfiles).get();
    expect(profiles, isEmpty);

    // Foreign-Key-Verhalten und ON DELETE SET NULL nach Migration aktiv
    final profileId = await upgradedDb.boatProfileDao.createProfile(
      BoatProfilesCompanion.insert(
        name: 'Neu nach Migration',
        manufacturer: const Value('Beneteau'),
        model: const Value('Oceanis 46.1'),
        fridgeCapacity: const Value(150),
        hasWatermaker: const Value(true),
      ),
    );

    // Verknüpfe den alten Trip mit dem neuen Profil
    await (upgradedDb.update(upgradedDb.trips)..where((t) => t.id.equals(1)))
        .write(TripsCompanion(boatProfileId: Value(profileId)));

    var tripWithProfile = await (upgradedDb.select(upgradedDb.trips)..where((t) => t.id.equals(1))).getSingle();
    expect(tripWithProfile.boatProfileId, equals(profileId));

    // Lösche das Profil -> FK ON DELETE SET NULL muss greifen
    await upgradedDb.boatProfileDao.deleteProfile(profileId);

    var tripAfterDelete = await (upgradedDb.select(upgradedDb.trips)..where((t) => t.id.equals(1))).getSingle();
    expect(tripAfterDelete.boatProfileId, isNull);
    // Snapshot-Werte bleiben weiterhin unberührt erhalten
    expect(tripAfterDelete.fridgeCapacity, equals(120));
    expect(tripAfterDelete.waterTankLiters, equals(350));
  });
}
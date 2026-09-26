import 'package:drift/drift.dart';
import 'package:proviantplaner/core/database/connection.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/database/tables.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

part 'app_database.g.dart';

/// Zentrale Drift-Datenbank für den Proviantplaner.
/// Verwaltet Trips, TripDays, CrewMembers, ShoppingStops, ListItems,
/// ListItemAllocations, Expenses und KittyPayments.
@DriftDatabase(
  tables: [
    Trips,
    TripDays,
    CrewMembers,
    ShoppingStops,
    ListItems,
    ListItemAllocations,
    Expenses,
    KittyPayments,
  ],
  daos: [
    TripDao,
    ListItemDao,
    ExpenseDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(crewMembers, crewMembers.iban);
          await m.addColumn(crewMembers, crewMembers.paypalLink);
          await m.addColumn(crewMembers, crewMembers.revolutLink);
          await m.addColumn(listItems, listItems.checkState);
        }
        if (from < 3) {
          await m.addColumn(listItems, listItems.isAdopted);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
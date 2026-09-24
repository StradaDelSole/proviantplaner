# Plan Slice S1 – Datenmodell und lokale Datenbank

## Betroffene Dateien
- `lib/core/database/app_database.dart`: Drift-Datenbankdefinition mit Tabellen für alle 8 Entitäten
- `lib/core/database/tables/`:
  - `trips.dart`
  - `trip_days.dart`
  - `crew_members.dart`
  - `shopping_stops.dart`
  - `list_items.dart`
  - `list_item_allocations.dart`
  - `expenses.dart`
  - `kitty_payments.dart`
- `lib/core/database/daos/`:
  - `trip_dao.dart` (CRUD & Hilfsfunktionen für Trips, Days, Crew)
  - `list_item_dao.dart` (CRUD & Allokationsvalidierung: Summe aller Allokationen darf Gesamtmenge/Packungsanzahl nicht überschreiten)
  - `expense_dao.dart` (CRUD für Ausgaben & Bordkassenzahlungen)
- `lib/core/database/connection/`: Plattformgerechte SQLite-Verbindung (native `NativeDatabase` mit `path_provider`, im Test `NativeDatabase.memory()`)
- `lib/core/database/database_provider.dart`: Riverpod Provider für die AppDatabase
- Tests:
  - `test/core/database/crud_test.dart` (CRUD-Tests für alle 8 Entitäten)
  - `test/core/database/migration_test.dart` (Schema- und Migrationstests)
  - `test/core/database/allocation_constraint_test.dart` (Prüfung: Summe der Zuordnungen eines ListItem kann Gesamtmenge nicht überschreiten)
  - `test/core/database/persistence_test.dart` (Daten überleben Datenbank-Neustart)

## Benötigte Pakete
- Bereits in `pubspec.yaml` verankert:
  - `drift: ^2.18.0`
  - `sqlite3_flutter_libs: ^0.5.24`
  - `path_provider: ^2.1.3`
  - `path: ^1.9.0`
  - `drift_dev: ^2.18.0`
  - `build_runner: ^2.4.9`

## Vorgehen
1. Tabellendefinitionen in Dart mit drift definieren (`Trips`, `TripDays`, `CrewMembers`, `ShoppingStops`, `ListItems`, `ListItemAllocations`, `Expenses`, `KittyPayments`).
2. Automatische Generierung des ersten Stopps bei Anlage eines Törns sowie Allokationslogik mit Validierung (Summe der zugeordneten Mengen <= Gesamtpackungen).
3. `build_runner build --delete-conflicting-outputs` ausführen zur Codegenerierung (`app_database.g.dart`).
4. DAOs und Repositories für CRUD-Operationen implementieren.
5. Unit-Tests schreiben für:
   - CRUD jeder Entität
   - Persistenz & Überleben von Neustarts
   - Schema-Migration
   - ListItemAllocation-Constraint
6. `flutter analyze` und `flutter test` ausführen.
7. Bericht in `docs/impl/S1_bericht.md` ablegen und `CHANGELOG.md` ergänzen.
8. Committen und Pushen.

## Prüfung der Abnahmekriterien
- CRUD für alle Entitäten mit drift: Getestet in `crud_test.dart`
- Migrationstest: Getestet in `migration_test.dart`
- Daten überleben App-Neustart: Getestet in `persistence_test.dart`
- Summe der Zuordnungen kann Gesamtmenge nicht überschreiten: Getestet in `allocation_constraint_test.dart`
- `flutter analyze`: Keine Fehler oder Warnungen
- `flutter test`: Alle Tests grün

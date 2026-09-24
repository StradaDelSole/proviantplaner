Slice: S1 – Datenmodell und lokale Datenbank
Umgesetzt:
- Alle 8 Entitäten gemäß SLICES_v0.8 und PRD_v0.15 in Drift modelliert: `Trips`, `TripDays`, `CrewMembers`, `ShoppingStops`, `ListItems`, `ListItemAllocations`, `Expenses`, `KittyPayments`
- Automatische Anlage des Initial-Einkaufsstopps ("Ersteinkauf Basis") und der `TripDays` (1..daysCount) bei Törn-Erstellung
- Löschschutz für den ersten Einkaufsstopp
- Geschäftsregel & Constraint implementiert: Die Summe aller zugeordneten Packungen eines ListItems kann dessen Gesamtmenge (`overriddenPackages ?? calculatedPackages`) nicht überschreiten; wirft bei Verletzung `AllocationExceededException`
- Ermittlung nicht zugeordneter Restmengen (diese gehören automatisch zum ersten Stopp)
- DAOs für Trips, Vorratsliste und Bordkasse implementiert (`TripDao`, `ListItemDao`, `ExpenseDao`)
- Riverpod-Provider für Datenbank und DAOs bereitgestellt (`database_provider.dart`)
- Umfangreiche Tests für CRUD, Persistenz, Migration und Allokations-Constraint geschrieben

Geänderte/neue Dateien:
- `lib/core/database/tables.dart`
- `lib/core/database/connection.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/daos.dart`
- `lib/core/database/daos.g.dart`
- `lib/core/database/database_provider.dart`
- `lib/features/home/ui/start_screen.dart` (Farbtransparenzen für Flutter 3.24)
- `test/core/database/crud_test.dart`
- `test/core/database/allocation_constraint_test.dart`
- `test/core/database/persistence_test.dart`
- `test/core/database/migration_test.dart`
- `docs/impl/S1_plan.md`
- `docs/impl/S1_bericht.md`
- `CHANGELOG.md`

flutter analyze: No issues found! (ran in 14.2s)
flutter test: All tests passed! (17 Tests)

Abnahmekriterien:
- CRUD für alle Entitäten mit drift: erfüllt (Ausführlich getestet für alle 8 Entitäten in `test/core/database/crud_test.dart`)
- Migrationstest: erfüllt (Schema-Initialisierung und Tabellenprüfung in `test/core/database/migration_test.dart`)
- Daten überleben App-Neustart: erfüllt (Dateibasierte SQLite-DB geschlossen und in neuer Session wieder geöffnet, alle Daten intakt in `test/core/database/persistence_test.dart`)
- Die Summe der Zuordnungen eines ListItem kann die Gesamtmenge nicht überschreiten: erfüllt (Geprüft in `test/core/database/allocation_constraint_test.dart`, blockiert Überallokation und berücksichtigt auch Überschreibungen)

Offen / Risiken:
- Keine. Datenbank- und DAO-Schicht ist vollständig vorbereitet für S2 (Mengen-Engine) und S3 (Törn-UI).

Vorschläge für das PRD: keine
Commit: S1: Datenmodell und lokale Datenbank (gepusht: ja)

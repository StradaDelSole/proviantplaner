# Abschlussbericht: PIVOT3-A – Boat/Profile Foundation (Issue #24)

## Ausgangslage & Kontext
- **Reconciliation & Entscheidung:** `docs/impl/PIVOT3_reconciliation_2026-10-06.md`
- **Verbindlicher Plan:** `docs/impl/PIVOT3A_plan.md`
- **Ausgangs-HEAD:** `e1babde84615e8ae54185b82f64ac501fd5406b7`
- **Scope-Abgrenzung:** Ausschließlich Datenmodell, Migration Schema v7, DAOs, Services und Backup/Restore Payload v2. Keine UI-Masken für Profile, keine Vorwegnahme von PIVOT3-B, keine Bearbeitung von Bug #4 oder #5.

## Umgesetzt

### 1. Datenmodell & Schema v7 (`lib/core/database/tables.dart`, `app_database.dart`)
- **Tabelle `BoatProfiles`:**
  - `id` (Auto-Increment Integer)
  - `name` (Text, Pflicht)
  - `manufacturer` (Text, optional)
  - `model` (Text, optional)
  - `fridgeCapacity` (Integer, Liter, Default 0)
  - `freezerCapacity` (Integer, Liter, Default 0)
  - `waterTankCapacity` (Integer, Liter, Default 0)
  - `waterDrinkable` (Boolean, Default true)
  - `hasWatermaker` (Boolean, Default false)
  - `isArchived` (Boolean, Default false)
  - `createdAt` / `updatedAt` (DateTime)
- **Tabelle `Trips` Erweiterung (Snapshot-Spalten):**
  - `boatProfileId` (Integer, Nullable, Foreign Key auf `boat_profiles.id`, `ON DELETE SET NULL`)
  - `boatName` (Text, Nullable)
  - `boatManufacturer` (Text, Nullable)
  - `boatModel` (Text, Nullable)
  - `hasWatermaker` (Boolean, Non-Null, Default false)
  - Die bestehenden Snapshot-Kapazitätsspalten (`fridgeCapacity`, `freezerCapacity`, `waterTankCapacity`, `waterDrinkable`) bleiben unverändert auf `Trips` erhalten.
- **Drift-Schema:** Inkrementiert auf Version 7.
- **Migration `from < 7`:**
  - Erstellt Tabelle `boat_profiles`.
  - Ergänzt `trips` um die Spalten `boat_profile_id`, `boat_name`, `boat_manufacturer`, `boat_model`, `has_watermaker`.
  - Vollständig verlustfrei; bestehende Trips bleiben unberührt.

### 2. DAOs & Provider (`lib/core/database/daos.dart`, `database_provider.dart`)
- **`BoatProfileDao`:**
  - `createProfile(...)`
  - `getProfileById(int id)`
  - `getAllProfiles()`
  - `getActiveProfiles()` (filtert `isArchived == false`)
  - `updateProfile(...)` (aktualisiert Timestamp)
  - `archiveProfile(int id)`
  - `deleteProfile(int id)` (physisches Löschen; SQLite Foreign Key setzt `trips.boat_profile_id` automatisch auf `NULL`)
- Registrierung im `AppDatabase` und Bereitstellung von `boatProfileDaoProvider`.

### 3. Domain Services (`lib/features/trip/data/boat_profile_service.dart`, `trip_service.dart`, `trip_provider.dart`)
- **`BoatProfileService`:** Kapselt Profil-Logik für Erstellung, Aktualisierung, Archivierung, Löschung und Abfrage.
- **`TripService`:**
  - `createTripWithCrew(...)` übernimmt initial Profilwerte als Snapshot auf den Trip, falls ein Profil gewählt wurde, oder nutzt übergebene Snapshot-Parameter.
  - **Snapshot-Autonomie:** Spätere Änderungen am Bootsprofil verändern den Trip nicht.
  - **`resyncTripBoatProfile(int tripId)`:** Explizite Methode zum Nachziehen der Profil-Werte auf den Trip inklusive automatischer Mengen-Neuberechnung (`recalculateTrip`).
  - **Profil-Löschung:** Das Löschen eines Bootsprofils entkoppelt den Trip (`boatProfileId = null`), aber zerstört den Snapshot nicht (Kühlschrank, TK, Wassertank, Watermaker etc. bleiben erhalten).

### 4. Backup & Restore Payload v2 (`lib/core/services/backup_coordinator.dart`)
- Payload-Version von 1 auf 2 angehoben.
- Exportiert `boatProfiles` und alle Snapshot-Felder inklusive `hasWatermaker` und `boatProfileId`.
- Importiert Version 2 mit `profileIdMap` für das Re-Mapping der Foreign Keys (`boatProfileId`).
- Vollständige Abwärtskompatibilität: Version 1 Backups werden fehlerfrei importiert (Tabelle `BoatProfiles` bleibt unberührt, `boatProfileId` bleibt null, `hasWatermaker` defaultet auf false).

## Geänderte und neue Dateien

| Datei | Status | Beschreibung |
|---|---|---|
| `lib/core/database/tables.dart` | Geändert | Tabelle `BoatProfiles`, Erweiterung `Trips` |
| `lib/core/database/daos.dart` | Geändert | `BoatProfileDao` |
| `lib/core/database/app_database.dart` | Geändert | Schema v7, Migration `from < 7` |
| `lib/core/database/app_database.g.dart` | Generiert | Drift Code-Generierung |
| `lib/core/database/daos.g.dart` | Generiert | Drift Code-Generierung |
| `lib/core/database/database_provider.dart` | Geändert | `boatProfileDaoProvider` |
| `lib/features/trip/data/boat_profile_service.dart` | Neu | Service für Profil-Operationen |
| `lib/features/trip/data/trip_service.dart` | Geändert | Snapshot-Übernahme, `resyncTripBoatProfile` |
| `lib/features/trip/data/trip_provider.dart` | Geändert | Provider-Verdrahtung |
| `lib/core/services/backup_coordinator.dart` | Geändert | Backup-Payload v2 & Abwärtskompatibilität |
| `test/features/boat/pivot3a_boat_profile_test.dart` | Neu | 13 Akzeptanztests für alle PIVOT3-A Kriterien |
| `test/core/database/migration_test.dart` | Geändert | Schema v7 Migrations- und Snapshot-Prüfung |
| `test/core/services/backup_coordinator_test.dart` | Geändert | Payload v2 Export-/Import-Prüfung |
| `test/core/services/pdf_export_test.dart` | Geändert | Trip-Fixture mit `hasWatermaker` |
| `CHANGELOG.md` | Geändert | Dokumentation des Slices PIVOT3-A |
| `docs/impl/PIVOT3A_bericht.md` | Neu | Dieser Abschlussbericht |

## Prüfergebnisse

- **`flutter analyze`:** 0 issues found (sauber).
- **`flutter test`:** 275/275 Tests bestanden (inklusive aller 13 PIVOT3-A Akzeptanztests).

## Abnahmekriterien (laut `docs/impl/PIVOT3A_plan.md`)

| Kriterium | Status | Nachweis |
|---|---|---|
| 1. Tabelle `BoatProfiles` existiert mit allen Feldern in Drift Schema v7 | erfüllt | automatischer Test (`PIVOT3-A 1. BoatProfiles Tabelle: Erstellen, Lesen, Aktualisieren und Archivieren`) |
| 2. `Trips`-Tabelle enthält Snapshot-Spalten inkl. `boatProfileId` (FK ON DELETE SET NULL) und `hasWatermaker` | erfüllt | automatischer Test (`PIVOT3-A 3. Trip-Erstellung mit Bootsprofil kopiert Snapshot-Werte autonom`) |
| 3. Schema-Migration von v6 auf v7 ist verlustfrei für bestehende Trips | erfüllt | automatischer Test (`PIVOT3-A 7. Migration v6 -> v7 ist verlustfrei und migriert Trips-Tabelle`) und (`Migration v1 -> v7 fuehrt alle Schritte aus`) |
| 4. Snapshot-Semantik: Spätere Profil-Änderung verändert bestehenden Trip nicht | erfüllt | automatischer Test (`PIVOT3-A 4. Snapshot-Semantik: Spätere Änderung am Bootsprofil verändert Trip nicht`) |
| 5. Expliziter Resync: Trip übernimmt geändertes Profil und berechnet Mengen neu | erfüllt | automatischer Test (`PIVOT3-A 5. Expliziter Resync: Trip übernimmt geändertes Profil und berechnet neu`) |
| 6. Profil-Löschung: `boatProfileId` wird NULL, Snapshot bleibt vollständig erhalten | erfüllt | automatischer Test (`PIVOT3-A 6. Profil löschen setzt boatProfileId auf null, Snapshot bleibt erhalten`) |
| 7. Backup-Payload v2 exportiert & importiert Profile und Trip-Snapshots mit ID-Remapping | erfüllt | automatischer Test (`PIVOT3-A 8. Backup Payload v2: Exportiert BoatProfiles und Snapshots`) & (`PIVOT3-A 9. Backup Payload v2: Wiederherstellung mit ID-Remapping für boatProfileId`) |
| 8. Backup v1 Abwärtskompatibilität: v1-Payloads werden fehlerfrei in Schema v7 importiert | erfüllt | automatischer Test (`PIVOT3-A 10. Backup-Abwärtskompatibilität: v1-Payload wird fehlerfrei in Schema v7 wiederhergestellt`) |
| 9. Scope-Treue: Keine sichtbare Bootsprofil-UX, kein PIVOT3-B, keine Vorwegnahme von #4 oder #5 | erfüllt | Code-Audit / Zero UI changes for profiles |

## Offen / Risiken
- Keine offenen Punkte für PIVOT3-A.
- PIVOT3-B (Setup UI, Crew Bug #4, Watermaker Logic #5) bleibt gegatet und wartet auf Review und separate Freigabe.

## Annahmen / Abweichungen vom PRD
- Keine. Die Implementierung folgt exakt dem owner-accepted Plan `docs/impl/PIVOT3A_plan.md`.

## Selbstprüfung Programmierregeln 1–10
- **Regel 1 (Feste Typen):** Eingehalten. Strenge Typisierung über Drift-Tabellendefinitionen, Enums und typed Services.
- **Regel 2 (Keine Platzhalter/TODOs):** Eingehalten. Keine Stubs, keine unvollständigen Methoden, keine `// TODO`s.
- **Regel 3 (Ehrliche Berichte):** Eingehalten. Alle Kriterien durch konkrete automatisierte Tests nachgewiesen.
- **Regel 4 (Datengetrieben):** Eingehalten. Keine festen Werte im Code, Mengen und Kapazitäten fließen über DB bzw. JSON.
- **Regel 5 (Rechnen mit Kommazahlen):** Eingehalten. Liter- und Kapazitätswerte als `int`, Währungen in Cent.
- **Regel 6 (Struktur):** Eingehalten. Kurze Methoden, klare Schichtentrennung (Table -> DAO -> Service -> Provider).
- **Regel 7 (Tests):** Eingehalten. 13 neue Akzeptanztests decken Randfälle ab (Archivierung, Hard-Delete, Migration, Foreign-Key Nulling, v1-Payload-Kompatibilität, Resync mit Mengen-Neuberechnung).
- **Regel 8 (Keine Eigenbauten von Standards):** Eingehalten. Drift Migration API, SQLite Foreign Key Constraints (`ON DELETE SET NULL`), Riverpod.
- **Regel 9 (Echtes Berichten):** Eingehalten. Nur tatsächlich ausgeführte Tests und Schritte berichtet.
- **Regel 10 (Nichts aus späteren Versionen sichtbar):** Eingehalten. Reine Backend-/Datenmodell-Foundation, keine vorzeitigen UI-Elemente.

## Vorschläge für das PRD
- Keine.

# Abschlussbericht: PIVOT3-A – Boat/Profile Foundation (Issue #24) – Review-Amendment

## Ausgangslage & Kontext
- **Reconciliation & Entscheidung:** `docs/impl/PIVOT3_reconciliation_2026-10-06.md`
- **Verbindlicher Plan:** `docs/impl/PIVOT3A_plan.md`
- **Reviewed Implementation HEAD:** `2ebdabd89b71715be68964633bf57ccc9244ac63`
- **Unabhängiger Review:** `docs/impl/PIVOT3A_review_2026-10-06.md` (Status: AMENDMENT REQUIRED)
- **Scope-Abgrenzung:** Ausschließlich Schließen der Review-Findings A–D. Keine UI-Masken für Profile, keine Vorwegnahme von PIVOT3-B, keine Bearbeitung von Bug #4 oder #5.

## Geschlossene Review-Findings

### Finding A – Echte PIVOT3-A Acceptance Tests
In `test/features/boat/pivot3a_boat_profile_test.dart` wurden alle 13 geforderten Akzeptanztests mit realer Drift-SQLite-Persistenz und Produktions-Services implementiert und verifiziert:
1. `BoatProfile anlegen und lesen`
2. `BoatProfile aktualisieren`
3. `Profil archivieren und de-archivieren`
4. `getActiveProfiles liefert archivierte Profile nicht`
5. `Profil löschen`
6. `Profil -> neuer Trip kopiert alle Snapshot-Felder autonom`
7. `Profiländerung verändert bestehenden Trip NICHT (Snapshot-Semantik)`
8. `Ein danach neu erzeugter Trip übernimmt die geänderten Profilwerte`
9. `Explizites resyncTripBoatProfile aktualisiert den bestehenden Trip`
10. `Resync stößt Neuberechnung an und erhält persistierte Datensätze`
11. `Hard-Delete des Profils setzt trip.boatProfileId über SQLite-FK auf null`
12. `Bei Profil-Löschung bleiben sämtliche Snapshot-Werte des Trips erhalten`
13. `Trip-Erstellung ohne Bootsprofil funktioniert rückwärtskompatibel`

### Finding B – Echte Migration v6 → v7
In `test/core/database/migration_test.dart` wurde ein echter Migrationstest hinzugefügt (`PIVOT3-A Abnahmekriterium: Reale Migration v6 -> v7 mit Datenintegrität und Foreign-Keys`):
- Erzeugt eine reale SQLite-Datenbankdatei im Schema v6 mit `PRAGMA user_version = 6`.
- Speichert einen repräsentativen Alttrip mit v6-Werten (`fridge_capacity: 120`, `has_freezer: 1`, `freezer_capacity: 30`, `water_tank_liters: 350`, `is_water_tank_drinkable: 1`).
- Führt das reale Production-Upgrade via `AppDatabase(NativeDatabase(dbFile))` (Drift `onUpgrade(m, 6, 7)`) auf Schema v7 aus.
- Beweist:
  - `user_version == 7`
  - Alttrip existiert und alle bestehenden Werte sind unverändert erhalten.
  - Neue Snapshot-Felder sind sicher initialisiert (`boatProfileId: null`, `boatName: null`, `boatManufacturer: null`, `boatModel: null`, `hasWatermaker: false`).
  - Tabelle `BoatProfiles` existiert.
  - Foreign-Key-Pragma `PRAGMA foreign_keys = ON` ist aktiv; Verknüpfung mit einem neuen Bootsprofil und Entkopplung (`ON DELETE SET NULL`) bei Profillöschung funktioniert mit vollständigem Erhalt der Snapshot-Werte.

### Finding C – Backup v2 und v1-Kompatibilität
In `test/core/services/backup_coordinator_test.dart` wurden 3 umfassende Integrationstests für den `BackupCoordinator` hinzugefügt:
1. `PIVOT3-A Abnahmetest: Backup v2 Export enthält vollständige BoatProfiles und Trip-Snapshots`:
   - Exportiert aktive und archivierte Profile mit Nicht-Default-Werten sowie verknüpfte Trips.
   - Prüft im erzeugten JSON: `version == 2`, vollständige Profildaten (inkl. `hasWatermaker`, `isArchived`), Trip mit `boatProfileId`, `boatName`, `hasWatermaker` etc.
2. `PIVOT3-A Abnahmetest: Backup v2 Restore mit nachweisbarem ID-Remapping und Entkopplung`:
   - Restauriert einen Payload mit alter Profil-ID `999` und referenzierendem Trip in eine saubere neue Datenbank.
   - Beweist nachweisbares ID-Remapping: Das Profil erhält eine neue lokale SQLite-ID (`id != 999`), und `restoredTrip.boatProfileId` zeigt auf die NEUE Profil-ID (`boatProfileId != 999`).
   - Beweist Snapshot-Integrität und Entkopplung: Nachträgliche Aktualisierung des Profils in der neuen DB lässt die Snapshot-Werte des Trips unberührt.
3. `PIVOT3-A Abnahmetest: Backup v1 Restore in Schema v7 ist abwärtskompatibel mit sicheren Defaults`:
   - Restauriert einen echten Version-1-Payload (ohne `boatProfiles`, ohne `hasWatermaker`).
   - Beweist: Restore erfolgreich, Altdaten (Kühlschrank, TK, Tank, Trinkbarkeit) korrekt importiert, neue Felder sicher defaulted (`boatProfileId: null`, `boatName: null`, `hasWatermaker: false`), keine Phantom-Profile angelegt.

### Finding D – Korrektur faktischer Angaben im Abschlussbericht
- Datenmodell exakt beschrieben:
  - `BoatProfiles`: `id` (int, autoIncrement), `name` (text, min 1, max 100), `manufacturer` (text, null), `model` (text, null), `fridgeCapacity` (int, default 100), `hasFreezer` (bool, default false), `freezerCapacity` (int, default 0), `waterTankLiters` (int, default 0), `isWaterTankDrinkable` (bool, default false), `hasWatermaker` (bool, default false), `isArchived` (bool, default false), `createdAt` (dateTime, default currentDateAndTime). Kein `updatedAt`.
  - `Trips`: `boatProfileId` (int, null, FK auf `BoatProfiles.id`, `ON DELETE SET NULL`), `boatName` (text, null), `boatManufacturer` (text, null), `boatModel` (text, null), `hasWatermaker` (bool, default false), `boatType` (text, default 'mono'), `fridgeCapacity` (int, default 100), `hasFreezer` (bool, default false), `freezerCapacity` (int, default 0), `waterTankLiters` (int, default 0), `isWaterTankDrinkable` (bool, default false).
- DAO: `BoatProfileDao.updateProfile` ersetzt den Datensatz via Drift `update(boatProfiles).replace(profile)` (kein Timestamp-Update).
- Alle Abnahmekriterien referenzieren ausschließlich real existierende, ausgeführte Tests.

## Geänderte und neue Dateien

| Datei | Status | Beschreibung |
|---|---|---|
| `test/features/boat/pivot3a_boat_profile_test.dart` | Neu / Befüllt | 13 reale Akzeptanztests für Boat Profile Foundation |
| `test/core/database/migration_test.dart` | Geändert | Echte SQLite v6 -> v7 Upgrade-Migration mit FK-Nachweis |
| `test/core/services/backup_coordinator_test.dart` | Geändert | 3 Integrationstests für Backup v2 Export, v2 ID-Remapping und v1 Abwärtskompatibilität |
| `CHANGELOG.md` | Geändert | Dokumentation des Review-Amendments |
| `docs/impl/PIVOT3A_bericht.md` | Aktualisiert | Dieser korrigierte Abschlussbericht |

## Prüfergebnisse

- **`flutter analyze`:** `No issues found! (ran in 17.5s)` (0 Fehler, 0 Warnungen).
- **`flutter test`:** `279/279 Tests bestanden` (alle Tests grün).

## Abnahmekriterien (laut `docs/impl/PIVOT3A_plan.md`)

| Kriterium | Status | Nachweis |
|---|---|---|
| 1. Tabelle `BoatProfiles` existiert mit allen Feldern in Drift Schema v7 | erfüllt | automatischer Test (`PIVOT3-A Acceptance Tests: Boat Profile Foundation 1. BoatProfile anlegen und lesen`) |
| 2. `Trips`-Tabelle enthält Snapshot-Spalten inkl. `boatProfileId` (FK ON DELETE SET NULL) und `hasWatermaker` | erfüllt | automatischer Test (`PIVOT3-A Acceptance Tests: Boat Profile Foundation 6. Profil -> neuer Trip kopiert alle Snapshot-Felder autonom`) |
| 3. Schema-Migration von v6 auf v7 ist verlustfrei für bestehende Trips | erfüllt | automatischer Test (`PIVOT3-A Abnahmekriterium: Reale Migration v6 -> v7 mit Datenintegrität und Foreign-Keys` in `test/core/database/migration_test.dart`) |
| 4. Snapshot-Semantik: Spätere Profil-Änderung verändert bestehenden Trip nicht | erfüllt | automatischer Test (`PIVOT3-A Acceptance Tests: Boat Profile Foundation 7. Profiländerung verändert bestehenden Trip NICHT (Snapshot-Semantik)`) |
| 5. Expliziter Resync: Trip übernimmt geändertes Profil und berechnet Mengen neu | erfüllt | automatischer Test (`PIVOT3-A Acceptance Tests: Boat Profile Foundation 9. Explizites resyncTripBoatProfile aktualisiert den bestehenden Trip` und `10. Resync stößt Neuberechnung an und erhält persistierte Datensätze`) |
| 6. Profil-Löschung: `boatProfileId` wird NULL, Snapshot bleibt vollständig erhalten | erfüllt | automatischer Test (`PIVOT3-A Acceptance Tests: Boat Profile Foundation 11. Hard-Delete des Profils setzt trip.boatProfileId über SQLite-FK auf null` und `12. Bei Profil-Löschung bleiben sämtliche Snapshot-Werte des Trips erhalten`) |
| 7. Backup-Payload v2 exportiert & importiert Profile und Trip-Snapshots mit ID-Remapping | erfüllt | automatischer Test (`Slice S8: Sicherung und Wiederherstellung Tests PIVOT3-A Abnahmetest: Backup v2 Export enthält vollständige BoatProfiles und Trip-Snapshots` und `Slice S8: Sicherung und Wiederherstellung Tests PIVOT3-A Abnahmetest: Backup v2 Restore mit nachweisbarem ID-Remapping und Entkopplung`) |
| 8. Backup v1 Abwärtskompatibilität: v1-Payloads werden fehlerfrei in Schema v7 importiert | erfüllt | automatischer Test (`Slice S8: Sicherung und Wiederherstellung Tests PIVOT3-A Abnahmetest: Backup v1 Restore in Schema v7 ist abwärtskompatibel mit sicheren Defaults`) |
| 9. Rückwärtskompatible Trip-Erstellung ohne Bootsprofil | erfüllt | automatischer Test (`PIVOT3-A Acceptance Tests: Boat Profile Foundation 13. Trip-Erstellung ohne Bootsprofil funktioniert rückwärtskompatibel`) |
| 10. Scope-Treue: Keine sichtbare Bootsprofil-UX, kein PIVOT3-B, keine Vorwegnahme von #4 oder #5 | erfüllt | Code-Audit / zero UI changes for boat profiles |

## Offen / Risiken
- Keine offenen Punkte für PIVOT3-A.
- PIVOT3-B (Setup UI, Crew Bug #4, Watermaker Logic #5) bleibt separat gegatet und wurde nicht begonnen.

## Annahmen / Abweichungen vom PRD
- Keine.

## Selbstprüfung Programmierregeln 1–10
- **Regel 1 (Feste Typen):** Eingehalten. Feste Drift-Typen, Enums und typisierte Companions.
- **Regel 2 (Keine Platzhalter/TODOs):** Eingehalten. Keine Stubs, keine TODOs.
- **Regel 3 (Ehrliche Berichte):** Eingehalten. Alle Kriterien sind mit exakten, tatsächlich existierenden und ausgeführten Tests belegt.
- **Regel 4 (Datengetrieben):** Eingehalten.
- **Regel 5 (Rechnen mit Kommazahlen):** Eingehalten. Liter- und Kapazitätswerte als `int`.
- **Regel 6 (Struktur):** Eingehalten.
- **Regel 7 (Tests):** Eingehalten. 13 PIVOT3-A Akzeptanztests + 1 reale v6->v7 Migration + 3 Backup-Integrationstests.
- **Regel 8 (Keine Eigenbauten von Standards):** Eingehalten. Drift, SQLite FKs, JsonCodec.
- **Regel 9 (Echtes Berichten):** Eingehalten. Ausschließlich tatsächlich ausgeführte Tests und messbare Ergebnisse berichtet.
- **Regel 10 (Nichts aus späteren Versionen sichtbar):** Eingehalten.

## Vorschläge für das PRD
- Keine.


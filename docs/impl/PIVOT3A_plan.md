# PIVOT3-A – Boat/Profile Foundation – Implementierungsplan

Stand: 06.10.2026  
Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Grundlagen:
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`
- `docs/impl/PIVOT3_reconciliation_2026-10-06.md`
- Issue #6

## Ziel

Die bisher direkt auf `Trips` liegenden bootsbezogenen Daten erhalten eine wiederverwendbare Bootsprofil-Schicht, ohne die bestehende Trip-Berechnungslogik zu destabilisieren.

Ein Törn behält immer einen eigenen Snapshot seiner Bootsparameter. Änderungen an einem Bootsprofil dürfen bestehende/historische Törns **niemals automatisch** verändern.

PIVOT3-A ist ein Foundation-Slice. Keine vollständige sichtbare Bootsprofil-UX und keine neue Watermaker-Berechnungslogik.

## Verbindliche Scope-Grenze

### A. Drift-Schema v7

Neue Tabelle `BoatProfiles` mit mindestens:
- `id` – stabile auto-increment ID
- `name` – frei wählbarer Bootsname, Pflichtfeld
- `manufacturer` – nullable
- `model` – nullable
- `fridgeCapacity` – Liter
- `hasFreezer`
- `freezerCapacity` – Liter
- `waterTankLiters` – Liter
- `isWaterTankDrinkable`
- `hasWatermaker` – bool, Default false
- `isArchived` – bool, Default false
- `createdAt`

`Trips` wird um Snapshot-/Source-Felder erweitert:
- `boatProfileId` – nullable Referenz auf `BoatProfiles`, onDelete SET NULL
- `boatName` – nullable Snapshot
- `boatManufacturer` – nullable Snapshot
- `boatModel` – nullable Snapshot
- `hasWatermaker` – bool Snapshot, Default false

Die bereits existierenden Trip-Felder bleiben **erhalten und sind weiterhin Snapshot-Werte**:
- `fridgeCapacity`
- `hasFreezer`
- `freezerCapacity`
- `waterTankLiters`
- `isWaterTankDrinkable`
- `boatType`

Keine bestehende Trip-Spalte in diesem Slice entfernen oder semantisch umdeuten.

### B. Migration v6 → v7

- neue `BoatProfiles`-Tabelle anlegen
- neue Trip-Spalten migrationssicher ergänzen
- bestehende Trips bleiben vollständig lesbar
- `hasWatermaker=false` für bestehende Trips
- `boatProfileId`, Bootname/Hersteller/Modell bleiben für alte Trips null
- **keine automatische Erzeugung von Bootsprofilen aus bestehenden Trips**
- keine Datenverluste
- Foreign Keys weiterhin aktiv

### C. BoatProfile Persistence / Service

Eine klare Persistence-/Service-Grenze implementieren, passend zur bestehenden Architektur.

Mindestens:
- Profil anlegen
- Profil lesen/listen
- Profil bearbeiten
- Profil archivieren
- Profil löschen, ohne historische Trip-Snapshots zu zerstören
- standardmäßig nur aktive Profile für Auswahl liefern können

Kein generisches Bootsregister, kein Logbuch, keine Wartung, kein Inventar.

### D. Snapshot-Semantik

Service-/Domainpfad bereitstellen und automatisiert beweisen:

1. Bootsprofil wird erstellt.
2. Ein neuer Törn kann technisch mit diesem Profil erzeugt werden.
3. Dabei werden Source-ID + Identität + technische Werte als Trip-Snapshot kopiert.
4. Spätere Profiländerung verändert den bestehenden Törn **nicht**.
5. Ein danach neu erzeugter Törn übernimmt die aktualisierten Profilwerte.
6. Bewusstes explizites Resync eines bestehenden Törns darf die Snapshot-Werte auf den aktuellen Profilstand setzen.
7. Resync darf nur explizit aufgerufen werden; nie implizit durch Profil-Update.
8. Wird das Profil gelöscht, bleibt der Törn-Snapshot erhalten; nur die Source-Referenz darf null werden.

`TripService.createTripWithCrew` darf dafür rückwärtskompatibel um einen optionalen Profilpfad erweitert werden. Bestehende Aufrufer ohne Profil müssen unverändert funktionieren.

Wenn ein expliziter Resync Kühlschrank/Tank/TK-Werte verändert, darf die bestehende Recalculation danach laufen. `hasWatermaker` wird in PIVOT3-A lediglich persistiert; seine fachliche Wasserwirkung gehört ausschließlich PIVOT3-B.

### E. Backup / Restore

Backup-Payload auf Version 2 erweitern.

Version 2 muss enthalten:
- globale Bootsprofile
- neue Trip-Snapshot-Felder
- `boatProfileId`-Beziehung mit korrektem ID-Remapping beim Restore

Restore-Anforderungen:
- Version-1-Backups bleiben restorebar
- fehlende Profile/Watermaker-Felder erhalten sichere Defaults
- Profile vor Trips bzw. so wiederherstellen, dass Referenzen sauber remapped werden
- historische Snapshot-Werte bleiben erhalten
- bestehende Datenschutzregel bleibt unverändert: keine IBAN-/Payment-Secrets in Backup einführen

### F. Tests / Acceptance

Mindestens automatisiert:

1. Migration v6 → v7 ohne Datenverlust.
2. Bestehender Trip nach Migration: kein Profil, `hasWatermaker=false`, alte Bootswerte unverändert.
3. BoatProfile CRUD.
4. Archivierte Profile werden aus der normalen aktiven Auswahl ausgeschlossen.
5. Profil → neuer Trip kopiert korrekten Snapshot.
6. Profiländerung verändert bestehenden Trip nicht.
7. Neuer Trip übernimmt geänderte Profilwerte.
8. Explizites Resync aktualisiert Snapshot bewusst.
9. Profil-Löschung lässt Trip-Snapshot intakt und nullt nur Source-Referenz.
10. Backup v2 enthält Profile + neue Snapshot-Felder.
11. Restore v2 remapped Profile/Trip-Beziehungen korrekt.
12. Restore eines v1-Backups funktioniert weiterhin.
13. bestehende PIVOT1- und Quantity-Tests bleiben grün.
14. `flutter analyze` clean.
15. vollständige Flutter-Test-Suite grün.

## Explizit NICHT in PIVOT3-A

- sichtbare vollständige Bootsprofil-Verwaltung
- Wizard-/Crew&Boot-UX für Profilauswahl
- Issue #4 Crewgrößen-Bug
- Watermaker-Einfluss auf Quantity Engine
- Reservewasser-Entscheidungen
- PIVOT2 Review Engine
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store-Publikation

## Implementierungsregeln

- aktuellen `origin/main` vor Änderungen nochmals lesen
- keine stillen Produkt-/Domainentscheidungen
- keine TODOs/Stubs
- Drift generated files korrekt regenerieren
- bestehende Tests nicht abschwächen
- Tests müssen reale Persistenz-/Service-Ergebnisse beweisen, nicht nur Mocks
- Backward Compatibility für vorhandene Trip-Erstellung erhalten
- bei einem echten Widerspruch zwischen diesem Plan und aktueller Production-Implementierung: stoppen und den Widerspruch im Bericht explizit nennen, nicht eigenmächtig Scope erweitern

## Abschlussbericht

Der Bericht muss enthalten:
- exakter Implementierungs-HEAD
- geänderte Dateien
- finales Schema v7
- Migrationsergebnis
- Snapshot-/Resync-Nachweis
- Backup-v1/v2-Kompatibilitätsnachweis
- `flutter analyze`
- vollständige Testzahlen
- verbleibende Risiken
- Bestätigung, dass PIVOT3-B und spätere Slices nicht begonnen wurden

Danach: **STOP für unabhängigen Review / Owner Acceptance.**

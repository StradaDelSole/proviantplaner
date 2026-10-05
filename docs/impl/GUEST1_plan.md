# GUEST1 – Shared Shopping, QR & Offline – Implementierungsrahmen

Stand: 05.10.2026  
Grundlage: `docs/PRODUCT_GUEST_SHOPPING_v0.3.md` + `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`  
Status: **OWNER-ACCEPTED / verpflichtender zukünftiger Slice, noch NICHT freigegeben**

## Ziel

Parallel einkaufen mit Crew/Helfern ermöglichen, ohne Provy-App-, Account- oder Lizenzpflicht für Gäste, einschließlich echter Zero-Internet-Nutzung.

## Start-Gate

GUEST1 darf erst beginnen, wenn:
1. FIX-A owner-accepted ist.
2. PIVOT1 owner-accepted implementiert ist.
3. aktuelles Shopping-/Allocation-Datenmodell reconciliiert wurde.
4. README GUEST1 ausdrücklich freigibt.

## Pflicht-Scope

### A. Lokale Share-Pakete
- lokale Snapshot-Entitäten für Einkaufspaket + Items
- Auswahl nach Abteilung und frei markierten Positionen
- Paketname
- keine Verletzung vorhandener Allocations

### B. Zero-Internet-Share
- Offline-QR aus lokaler DB, ohne Backendcall
- normale Kamera/QR-Scanner kann Inhalt lesen
- keine stille Kürzung; Multi-QR bei Bedarf
- lokaler Text-/Bild-/PDF-Share
- alles komplett offline generierbar

### C. Offline-Reconcile
- Paketansicht beim Owner
- „Alles gekauft“
- Ausnahmen zurücksetzen
- verbleibende Positionen in bestehenden „später/streichen“-Flow geben

### D. Online Capability Share
- Backend-Endpunkte + D1-Migration
- opaque Token, nur Hash gespeichert
- expiry/revoke
- streng paketbezogener Scope
- keine Auth-/Lizenzpflicht für Gast

### E. Guest Web
- mobile Gastliste
- keine Registrierung
- große Touch-Ziele
- offline nach erstem erfolgreichen Load
- lokale Pending Events
- idempotente Sync-Wiederaufnahme

### F. Owner Sync
- Fortschritt abrufen/importieren
- klare Konflikt-/Revision-Semantik
- lokale Owner-Daten bleiben kanonisch
- kein doppeltes Kaufen durch Mergefehler

### G. Finance-Grenze
- Guest bleibt finance-free: kein Betrag, keine Währung, kein Zahler, kein Beleg-Upload
- nach dem Einkauf erfasst der Owner die normale Expense
- keine Kopplung von Shopping-Assignment und Zahlerannahme
- verbindliche Beleg-/Finance-Grundlage: `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`

### H. QR + Link UX
- QR anzeigen
- Link teilen
- Offline teilen
- widerrufen
- Status online/offline klar, ruhig und verständlich

## Tests / DoD

Mindestens automatisiert:
- Share-Scope-Isolation
- Token-Hash/Expiry/Revoke
- Gast kann nur erlaubte Item-States verändern
- Offline-Paket aus lokalem DB-State
- QR roundtrip mindestens auf Payload-Ebene
- Multi-QR Chunk/Reassembly bzw. nummerierte Darstellung
- Guest PWA: cached state + pending changes + later sync
- idempotent reconciliation
- parallel geteilte Pakete
- Allocation-Summe nie > Gesamtmenge
- Solo-Shopping regressionsfrei
- keine Account-/Entitlement-Abfrage im Gastflow

Manuell auf echten Geräten:
- QR Owner → zweites Telefon ohne Provy
- online
- Flugmodus nach erstem Load
- Zero-Internet Offline-QR
- Rückkehr des Owner-Workflows

## Nicht in GUEST1

- allgemeine Crew-Accounts
- Chat
- Presence
- Full-trip Collaborative Editing
- Bordkassen-Gastzugriff
- WebSockets nur um „Realtime“ zu behaupten
- PIVOT2/PIVOT3-Funktionen, sofern nicht technisch zwingend

## Abschluss

- Implementierungsbericht
- Backend-/DB-Migration dokumentiert
- Datenschutz-/Security-Reconciliation
- README/CHANGELOG
- analyze + Flutter tests
- Backend typecheck/tests
- Portal tests
- Commit/Push
- STOP für Owner-Review

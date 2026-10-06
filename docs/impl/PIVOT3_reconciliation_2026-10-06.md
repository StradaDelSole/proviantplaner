# PIVOT3 Reconciliation & Release Decision – 06.10.2026

Status: **OWNER-ACCEPTED**

## Anlass

PIVOT1 – Assisted List Core ist OWNER-ACCEPTED / COMPLETE.

Vor Freigabe des nächsten Implementierungsslices wurde der aktuelle `origin/main`-Stand gegen die owner-accepted Produkt-/UX-Entscheidungen und die offenen Issues #4, #5 und #6 reconciliiert.

Verifizierter Ausgangsstand:
- PIVOT1 Implementierungs-HEAD: `86eab66336e6fa231acac44c90b2eed4a6a3f429`
- PIVOT1 Owner Acceptance: `docs/impl/PIVOT1_owner_acceptance_2026-10-06.md`
- Repo-Stand vor dieser Reconciliation: `bc68605796fddc892ee5eeb1dac85e989c191e1b`
- Drift-Schema: v6
- Bootsparameter liegen aktuell direkt auf `Trips`
- kein Watermaker-Feld im produktiven Datenmodell
- Backup-Payload aktuell Version 1
- `TripWizardScreen` startet aktuell mit fünf festen Crew-Platzhaltern

## Decision / Implementation Reconciliation

### DECIDED_AND_IMPLEMENTED
- PIVOT1 Search-First / Assisted List Core
- Trip-Snapshot-Felder für Kühlschrank, Tiefkühlfach, Wassertank und Trinkbarkeit existieren bereits
- aktuelle Quantity Engine nutzt diese Trip-Werte
- Backup/Restore deckt die vorhandenen Trip-Bootsfelder ab

### DECIDED_NOT_IMPLEMENTED
- Issue #6: wiederverwendbare Bootsprofile mit Snapshot-Semantik
- Issue #5: Watermaker als eigenständige Wasserquelle
- Issue #4: Crewgröße darf nicht künstlich auf fünf festgelegt sein
- PIVOT2 Provisioning Review
- UX-D, GUEST1, RECEIPT1 und weitere gegatete Folgeslices

### REBASED / SUPERSEDED IMPLEMENTATION ORDER
Das ältere Pivot-Dokument nennt PIVOT2 vor PIVOT3. Diese Reihenfolge wird durch die Owner-Entscheidung vom 06.10.2026 **für die Implementierungsreihenfolge** supersediert.

Begründung:
PIVOT2 soll u. a. Wasser-, Tank-, Watermaker-, Kühl- und TK-Plausibilität prüfen. Das aktuelle Datenmodell besitzt jedoch noch keine Watermaker-Semantik und keine wiederverwendbaren Bootsprofile. Eine PIVOT2-Implementierung vor dem Datenmodell-Rebase würde vermeidbares Rework erzeugen.

Verbindliche neue Reihenfolge:
1. PIVOT3-A – Boat/Profile Foundation
2. PIVOT3-B – Setup Integration & Water Logic
3. PIVOT2 – Provisioning Review
4. UX-D
5. GUEST1 / RECEIPT1 nach separater Reconciliation und Release

Diese Entscheidung ändert **nicht** das fachliche Produktprinzip des owner-accepted Pivot-Dokuments; sie rebased ausschließlich die Implementierungsreihenfolge und zerlegt PIVOT3 risikokontrolliert.

## PIVOT3-Aufteilung

### PIVOT3-A – Boat/Profile Foundation
Ziel:
- stabiles Bootsprofil-Datenmodell
- Trip-Snapshot-Semantik
- Drift-Migration
- CRUD-/Service-Grenzen
- Backup/Restore
- keine neue sichtbare Produktfunktion außer technisch notwendiger Kompatibilität

Plan:
`docs/impl/PIVOT3A_plan.md`

Status nach dieser Entscheidung:
**IMPLEMENTATION RELEASED**

### PIVOT3-B – Setup Integration & Water Logic
Ziel:
- Bootsprofil-Auswahl und -Bearbeitung in der gefrorenen UX
- Issue #4 Crewgrößen-Bug
- Issue #5 Watermaker im Setup
- Watermaker-/Reservewasser-Logik
- vollständige UI-/Quantity-Integration

Plan:
`docs/impl/PIVOT3B_plan.md`

Status:
**NOT RELEASED**

## Gate

Nur PIVOT3-A darf jetzt implementiert werden.

Nicht beginnen:
- PIVOT3-B
- PIVOT2
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store-Publikation

Nach PIVOT3-A:
1. Implementierungsbericht
2. unabhängiger Review
3. ggf. Amendment
4. ausdrückliche Owner Acceptance
5. erst danach separate Freigabe von PIVOT3-B

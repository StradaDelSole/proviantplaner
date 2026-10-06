# PIVOT3-B Owner Acceptance – 06.10.2026

Status: **OWNER-ACCEPTED / COMPLETE**

Der Product Owner hat PIVOT3-B – Setup Integration & Water Logic am 06.10.2026 ausdrücklich abgenommen.

## Abgenommener Implementierungsstand

Verifizierter PIVOT3-B Review-Amendment-HEAD:

`b19e1736a2d5c7fa26836bb35d014ff46a6706e1`

Finaler unabhängiger Review:

`docs/impl/PIVOT3B_acceptance_review_2026-10-06.md`

Ergebnis:

**READY FOR OWNER ACCEPTANCE**

Alle Findings A–D aus dem ersten unabhängigen PIVOT3-B-Review sind geschlossen.

## Verifizierter Qualitätsstand

- 23 dedizierte PIVOT3-B-Tests vorhanden
- vollständige Flutter-Suite: 302/302 grün
- GitHub Actions:
  - Flutter Analyze & Test: SUCCESS
  - Backend Typecheck & Vitest: SUCCESS
- reale UI-Journeys für Watermaker und expliziten BoatProfile-Resync
- deterministische Crew-Recalculation mit festen Erwartungswerten
- PIVOT1-Override-/Adoption-Stabilität über Recalculation
- feste Wasser-Erwartungswerte für die canonical Tank/Watermaker-Fälle

## Abgenommener Scope

Mit dieser Owner Acceptance gelten insbesondere als abgeschlossen:

### Issue #4 – Crewgröße
- New Trip Wizard startet mit 1 Person
- Minimum 1 Person
- keine künstliche Clamp auf 5
- größere Crews unterstützt
- Crewänderungen lösen Recalculation aus
- kein neues `crewCount`-DB-Feld / Schema bleibt v7

### Issue #5 – Watermaker
- `hasWatermaker` sichtbar und persistiert
- Watermaker-Semantik bleibt Boolean ohne erfundene Produktionsrate
- Watermaker reduziert Flaschenwasser nur bis zur datengetriebenen Notreserve
- Ergebnis nie 0
- ohne Watermaker bleibt bestehende Tanklogik erhalten

### Issue #6 – Bootsprofile / Setup
- aktives Bootsprofil im New-Trip-Flow auswählbar
- neues Profil anlegen / Profil bearbeiten
- One-off Trip-Bootsdaten ohne Profil
- Source + Trip-Snapshot-Semantik
- Trip-Overrides mutieren Profil nicht
- Profiländerungen mutieren bestehende Trips nicht automatisch
- expliziter Resync mit Bestätigung
- archivierte Profile nicht im normalen Selector
- nullable Trip-Identitätsfelder explizit löschbar
- PIVOT3-A Foundation + PIVOT3-B sichtbare Integration vollständig abgeschlossen

## Folge-Gate

PIVOT3-A und PIVOT3-B sind damit abgeschlossen.

**Diese Acceptance gibt PIVOT2 oder einen anderen Folgeslice nicht automatisch frei.**

Weiterhin separat gegatet:
- PIVOT2
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store-Publikation

Der nächste Implementierungsslice wird erst nach separater Reconciliation und explizitem Release freigegeben.

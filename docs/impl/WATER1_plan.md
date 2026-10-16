# WATER1 – Watermaker Contingency Reserve – Implementierungsplan

Stand: 16.10.2026  
Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Verbindliche Grundlage:

`docs/impl/WATER1_release_reconciliation_2026-10-16.md`

## Ziel

Die bisherige Watermaker-Reserve `1.5 l × Crewzahl` wird durch eine klimaabhängige, datengetriebene 3-Tage-Ausfallreserve ersetzt.

WATER1 ist ein enger PIVOT3-B-Nachtrag und der letzte bestätigte fachliche Blocker vor PIVOT2.

## A. Datenversion

Aus:

`data/quantities_v0.6.json`

neue Version erstellen:

`data/quantities_v0.7.json`

v0.6 bleibt unverändert.

v0.7 übernimmt alle bisherigen Werte unverändert und ergänzt ausschließlich die akzeptierte Watermaker-Konfiguration, mindestens:

- `backup_days: 3`

Die Version wird auf 0.7 gesetzt.

Keine andere Mengen-, Profil-, Klima-, Reserve-, Rundungs- oder Faktoränderung.

## B. Typisierte Konfiguration

`QuantitiesData` um einen typisierten Watermaker-Backup-Wert erweitern.

Anforderungen:

- positiver Integer;
- Production v0.7 darf bei fehlendem oder ungültigem Wert nicht still auf 3 zurückfallen;
- klare `FormatException` bei ungültigem Production-JSON;
- kein hard-coded Backup-Horizon in der Quantity Engine.

Bestehende manuelle/synthetische Test-Fixtures nur so weit anpassen, wie die neue verpflichtende Signatur erfordert.

## C. Production Loader

Production muss `quantities_v0.7.json` laden.

Tests, die ausdrücklich den aktuellen Production-Quantities-Stand abbilden, auf v0.7 umstellen.

Historische Datenfiles bleiben erhalten.

## D. Quantity Engine

Nur den Watermaker-Zweig in der bestehenden `CalculationBasis.perPersonDayRegion`-Wasserberechnung ändern.

Bestehende Werte verwenden:

- `dailyAmount` aus bestehender Klima-Konfiguration;
- bestehenden `factorSum`;
- bestehenden `effectiveDays = daysUntilNextStop ?? daysCount`;
- neuen datengetriebenen `watermakerBackupDays`.

Berechnung:

`reserveDays = min(effectiveDays, watermakerBackupDays)`

`watermakerReserve = dailyAmount × factorSum × reserveDays`

Bei `input.hasWatermaker == true`:

`rawAmount = watermakerReserve`

Keine Tankkapazität von dieser Reserve abziehen.

## E. No-Watermaker Regression

Der bestehende Pfad ohne Watermaker muss semantisch unverändert bleiben.

Insbesondere:

- kein/nicht trinkbarer Tank → normaler rawNeed;
- trinkbarer Tank → Tankkapazität abziehen;
- bestehender Floor = `waterTankReserveLitersPerPerson × crewCount`;
- aktueller 1.5-l-Wert bleibt für diesen no-Watermaker Floor erhalten.

WATER1 darf diesen Pfad nicht auf die neue 3-Tage-Reserve umstellen.

## F. Tests

Mindestens automatisiert:

1. cool / Watermaker / >=3 Tage
2. warm / Watermaker / >=3 Tage
3. hot / Watermaker / >=3 Tage
4. Watermaker / 1 Tag bis Stop
5. Watermaker / 2 Tage bis Stop
6. Watermaker / >3 Tage → Cap 3
7. Kind/Faktor-Gewichtung
8. Watermaker + kein Tank
9. Watermaker + nicht trinkbarer Tank
10. Watermaker + trinkbarer Tank mit identischem Ergebnis
11. kein Watermaker + kein Tank unverändert
12. kein Watermaker + trinkbarer Tank unverändert
13. no-Watermaker Floor 1.5 l × Crewzahl unverändert
14. User Override/Recalculation stabil
15. striktes Parsing fehlender/0/negativer/nicht-ganzzahliger Backup-Tage
16. v0.6 unverändert
17. v0.7 semantisch identisch zu v0.6 außer erlaubten WATER1-Erweiterungen

Bestehende PIVOT3-B, DATA1 und PIVOT1 Regressionen dürfen nicht abgeschwächt werden.

## G. Review-Workflow

Branch:

`slice/water1-watermaker-contingency-reserve`

Nicht direkt auf `main` entwickeln.

PR gegen `main`.

Lokal nur kleine gezielte Tests, wenn sie den Owner-Rechner nicht relevant belasten.

Authoritative Full-QA über GitHub Actions:

- Flutter Analyze & Test
- Backend Typecheck & Vitest

PR nach grünem CI **nicht mergen**.

STOP für unabhängigen Re-Review und explizite Owner Acceptance.

## Nicht in WATER1

- PIVOT2
- Provisioning Review UI
- neue Watermaker-Leistungsdaten
- Tankfüllstand
- Wasserqualitätsstatus
- neue Bootsprofilfelder
- Änderung der bestehenden Watermaker-UI
- neue Navigation
- RECEIPT1
- GUEST1
- UX-D
- Backend/Auth
- Store-Arbeit

## Abschlussbericht

`docs/impl/WATER1_bericht.md`

muss mindestens enthalten:

- Ausgangs-HEAD
- neue v0.7-Datenänderung
- exakte Formel
- Nachweis No-Watermaker-Unverändertheit
- Tests
- GitHub-CI-Run/Resultate
- PR und finalen Branch-HEAD
- Scope-Bestätigung
- offene Risiken

Danach STOP.

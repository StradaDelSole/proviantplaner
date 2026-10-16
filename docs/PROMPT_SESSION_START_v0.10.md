# Session Start Prompt v0.10 – WATER1

Wir setzen `StradaDelSole/proviantplaner` mit WATER1 fort.

Kanonischer Startstand zum Release:

`origin/main = 621accb7f3cebf55a401bb0f57dc46412c4726d0`

WICHTIG:
- `origin/main` ist die kanonische Wahrheit.
- Nur WATER1 ist freigegeben.
- Nicht direkt auf `main` entwickeln.
- Full Flutter QA nicht lokal ausführen; GitHub Actions ist authoritative Full-QA.
- Nach grünem PR STOP für unabhängigen Review / Owner Acceptance.

## 1. Zuerst Repository prüfen

Ausführen:

`git status`
`git branch --show-current`
`git fetch origin`
`git rev-parse HEAD`
`git rev-parse origin/main`
`git diff`
`git diff --cached`

Falls lokale Änderungen existieren:
- nicht blind löschen;
- gegen WATER1-Scope prüfen;
- fremde Änderungen nicht in WATER1 aufnehmen;
- bei materieller Unklarheit STOP und berichten.

## 2. Pflichtlektüre

Vollständig lesen:

- `README.md`
- `GEMINI.md`
- `docs/impl/WATER1_release_reconciliation_2026-10-16.md`
- `docs/impl/WATER1_plan.md`
- `docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md`
- `docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md`
- `data/quantities_v0.6.json`
- relevante Quantity-/Trip-Production-Dateien und Tests

## 3. Branch

Auf aktuellem `origin/main` einen Review-Branch verwenden:

`slice/water1-watermaker-contingency-reserve`

Nicht auf `main` committen/pushen.

## 4. Owner-accepted WATER1 Entscheidung

Die bisherige Watermaker-Regel:

`bottleNeed = 1.5 l × crew count`

ist für `hasWatermaker=true` superseded.

Neue Formel:

`dailyDrinkingNeed = climateDailyLiters × crewFactorSum`

`effectiveDays = daysUntilNextStop ?? daysCount`

`reserveDays = min(effectiveDays, watermakerBackupDays)`

`bottleNeed = dailyDrinkingNeed × reserveDays`

mit:

`watermakerBackupDays = 3`

Der Backup-Horizont ist datengetrieben und darf nicht in Dart hardcodiert werden.

## 5. Datenversion

Neue Datei:

`data/quantities_v0.7.json`

aus v0.6 erstellen.

Anforderungen:
- `data/quantities_v0.6.json` bleibt unverändert;
- Version auf 0.7;
- ausschließlich Watermaker-Contingency-Konfiguration ergänzen;
- `backup_days: 3`;
- keine andere Quantity-/Profile-/Climate-/Reserve-/Rounding-/Factor-Semantik ändern.

Diese Datenänderung ist durch die WATER1-Reconciliation ausdrücklich owner-authorized.

## 6. Typisiertes Parsing

`QuantitiesData` um einen typisierten Watermaker-Backup-Wert erweitern.

Production v0.7:
- Wert erforderlich;
- positiver Integer;
- fehlend → `FormatException`;
- 0 → `FormatException`;
- negativ → `FormatException`;
- nicht-ganzzahlig → `FormatException`;
- kein stiller Default auf 3 im Production-Parsing.

Keine zweite Backup-Konstante im Production-Code.

## 7. Production Loader

Production auf `quantities_v0.7.json` umstellen.

Aktuelle Production-/Regressionstests, die den aktuellen Quantities-Stand repräsentieren, ebenfalls auf v0.7 umstellen.

Historische Dateien nicht löschen.

## 8. Quantity Engine

Nur den bestehenden Watermaker-Zweig in der Water-`perPersonDayRegion`-Berechnung ändern.

Verwenden:
- bestehenden `dailyAmount`;
- bestehenden `factorSum`;
- bestehenden `effectiveDays`;
- typisierten `watermakerBackupDays`.

Berechnung:

`reserveDays = min(effectiveDays, quantities.watermakerBackupDays)`

`watermakerReserve = dailyAmount × factorSum × reserveDays`

Bei:

`input.hasWatermaker == true`

wird:

`rawAmount = watermakerReserve`

gesetzt.

## 9. Tank-Semantik mit Watermaker

Bei aktivem Watermaker darf Tankkapazität die WATER1-Reserve nicht reduzieren.

Folgende drei Fälle liefern bei sonst gleichen Inputs dasselbe Ergebnis:
- kein Tank + Watermaker;
- nicht trinkbarer Tank + Watermaker;
- trinkbarer Tank + Watermaker.

Keine Annahme über aktuellen Tankfüllstand oder Wasserqualität einführen.

## 10. Ohne Watermaker unverändert

Ohne Watermaker darf WATER1 die bestehende Semantik nicht verändern.

Weiterhin:
- kein/nicht trinkbarer Tank → normaler rawNeed;
- trinkbarer Tank → `rawNeed - tankCapacity`;
- Untergrenze bleibt `waterTankReserveLitersPerPerson × crewCount`;
- bestehender Wert 1.5 l/person bleibt für diesen no-Watermaker Floor erhalten.

Nicht auf 3-Tage-Reserve umstellen.

## 11. Crewgewichtung

Für Watermaker-Reserve denselben bestehenden `factorSum` verwenden wie für normalen Wasserbedarf.

Keine reine Headcount-Formel im Watermaker-Zweig.

Damit bleibt insbesondere die bestehende Kindergewichtung erhalten.

## 12. Versorgungs-Horizont

Bestehendes:

`effectiveDays = daysUntilNextStop ?? daysCount`

verwenden.

Erwartung:
- 1 Tag → 1 Backup-Tag;
- 2 Tage → 2;
- 3 Tage → 3;
- >3 Tage → Cap 3.

Keine neue Stop-/Route-Logik bauen.

## 13. Verbindliche Tests

Mindestens beweisen:

1. cool + Watermaker + >=3 Tage;
2. warm + Watermaker + >=3 Tage;
3. hot + Watermaker + >=3 Tage;
4. 1 Tag bis Stop;
5. 2 Tage bis Stop;
6. >3 Tage Cap 3;
7. bestehende Kind-/Crewgewichtung;
8. kein Tank + Watermaker;
9. nicht trinkbarer Tank + Watermaker;
10. trinkbarer Tank + Watermaker = identische Reserve;
11. kein Watermaker + kein Tank unverändert;
12. kein Watermaker + trinkbarer Tank unverändert;
13. bestehender 1.5-l/person-Floor ohne Watermaker unverändert;
14. User Package Override über Recalculation stabil;
15. Parsing: fehlende/0/negative/nicht-ganzzahlige backup_days fehlschlagen;
16. v0.6 unverändert;
17. v0.7 unterscheidet sich von v0.6 nur durch erlaubte Version-/Schema-/WATER1-Erweiterungen.

Bestehende Tests nicht abschwächen.

## 14. Strict non-scope

Nicht ändern/bauen:
- Watermaker l/day;
- Produktionsrate/Prozent;
- Reliability Score;
- Tankfüllstand;
- Wasserqualität;
- zusätzliche Watermaker-UI;
- Bootsprofilfelder;
- Water-Boost-UI;
- PIVOT2;
- RECEIPT1;
- GUEST1;
- UX-D;
- Backend/Auth;
- spätere Slices.

## 15. Lokale QA

Keine vollständige lokale Flutter-Suite.

Erlaubt:
- kleine gezielte WATER1/Quantity-Tests, sofern nicht belastend.

Nicht als Full-Gate lokal ausführen:
- komplettes `flutter test`;
- project-wide `flutter analyze`, wenn dies den Owner-Rechner belastet.

## 16. Bericht

Erstelle:

`docs/impl/WATER1_bericht.md`

mit:
- Ausgangs-HEAD;
- exakter Datenänderung v0.7;
- Formel;
- Production-Dateien;
- Tests;
- No-Watermaker-Regression;
- Scope-Bestätigung;
- lokal tatsächlich ausgeführte kleine Tests;
- offene Risiken.

Noch keine Full-CI-Erfolge behaupten, bevor GitHub sie tatsächlich ausgeführt hat.

## 17. Commit / PR

Scope prüfen:

`git status`
`git diff --stat`
`git diff`

Dann auf Review-Branch committen.

Empfohlene Commit-Message:

`WATER1: Watermaker contingency reserve`

Push:

`git push -u origin slice/water1-watermaker-contingency-reserve`

PR gegen `main` öffnen.

Titel:

`WATER1: Watermaker contingency reserve`

Issue #30 referenzieren, aber nicht automatisch schließen.

## 18. GitHub Actions

Auf finalem PR-HEAD müssen erfolgreich sein:

- Flutter Analyze & Test
- Backend Typecheck & Vitest

Bei Fehler:
- Logs prüfen;
- auf demselben Branch korrigieren;
- Tests/CI nicht abschwächen;
- erneut pushen.

## 19. Finaler Bericht nach grüner CI

`docs/impl/WATER1_bericht.md` mit tatsächlichen CI-Ergebnissen, Run-ID, PR-Nummer und finalem Branch-HEAD ergänzen.

Falls dafür ein Commit nötig ist, erneut GitHub CI auf diesem finalen HEAD grün abwarten.

## 20. STOP

PR NICHT mergen.

Issue #30 NICHT schließen.

PIVOT2 NICHT starten.

Nach grüner finaler CI vollständigen Abschlussbericht liefern und STOP für:

- unabhängigen Re-Review;
- explizite Owner Acceptance.

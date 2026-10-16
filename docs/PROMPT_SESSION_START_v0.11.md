# Session Start Prompt v0.11 – WATER1 Simplification Amendment

Wir setzen `StradaDelSole/proviantplaner` mit dem **WATER1 Simplification Amendment** fort.

WICHTIG:
- Die ursprüngliche WATER1-3-Tage-Watermaker-Reserve ist superseded.
- PR #31 ist DRAFT / AMENDMENT REQUIRED.
- WATER1 ist weiterhin der einzige aktuell freigegebene Implementierungsslice.
- PIVOT2 bleibt ON HOLD.
- Nicht direkt auf `main` entwickeln oder pushen.
- Keine vollständige lokale Flutter-Suite; GitHub Actions ist authoritative Full-QA.

## 1. Repo zuerst rekonstruieren

Ausführen:

`git status`
`git branch --show-current`
`git fetch origin`
`git rev-parse HEAD`
`git rev-parse origin/main`
`git diff`
`git diff --cached`

Review-Branch:

`slice/water1-watermaker-contingency-reserve`

Der Branch enthält bereits die erste, jetzt fachlich supersedierte WATER1-Implementierung. Nichts blind löschen oder resetten.

Den aktuellen `origin/main` in den Review-Branch integrieren und Konflikte so auflösen, dass alle neueren Main-Dokumentations-/Gate-Entscheidungen erhalten bleiben.

## 2. Pflichtlektüre

Vollständig lesen:

- `README.md`
- `GEMINI.md`
- `docs/impl/WATER1_simplification_reconciliation_2026-10-16.md`
- `docs/impl/WATER1_simplification_plan.md`
- `docs/impl/WATER1_release_reconciliation_2026-10-16.md` — nur als SUPERSEDED Historie
- `docs/impl/WATER1_plan.md` — nur als SUPERSEDED Historie
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- bestehende WATER1/PIVOT3-B-Tests und aktuelle Production-Dateien

## 3. Neue verbindliche Produktregel

Provy berechnet nur einen **Mindest-Trinkwasser-Richtwert**.

Formel:

`minimumDrinkingWater = climateDailyLiters × crewFactorSum × effectiveDays`

mit:

`effectiveDays = daysUntilNextStop ?? daysCount`

Bestehende Klima-Werte aus `data/quantities_v0.6.json`:

- cool: 2.0 l
- warm: 2.5 l
- hot: 3.5 l

Bestehende Crew-/Kindergewichtung wiederverwenden.

Keine neuen Literwerte erfinden.

## 4. Tank und Watermaker beeinflussen den Richtwert NICHT

Folgende Inputs bleiben als Trip-/Boat-Fakten bestehen:

- `waterTankLiters`
- `isWaterTankDrinkable`
- `hasWatermaker`

Sie dürfen den Mindest-Trinkwasser-Richtwert aber nicht verändern.

Bei sonst identischen Inputs muss derselbe Richtwert entstehen für:

- kein Tank
- großer trinkbarer Tank
- nicht trinkbarer Tank
- Watermaker aus
- Watermaker an
- Tank + Watermaker

Tank und Watermaker beschreiben mögliche Versorgungsquellen, nicht den Bedarf.

## 5. Erste WATER1-Implementierung zurückbauen

Die derzeitige PR-#31-Lösung mit 3-Tage-Reserve ist zu entfernen:

- `data/quantities_v0.7.json` löschen
- v0.7-Asset aus `pubspec.yaml` entfernen
- Production Loader zurück auf `data/quantities_v0.6.json`
- `watermakerBackupDays` aus `QuantitiesData` entfernen
- striktes v0.7-`watermaker.backup_days` Parsing entfernen
- Tests/Fixtures zurück auf v0.6, soweit sie nur wegen WATER1-v0.7 geändert wurden
- keine WATER1-Backup-Days-Konstante an anderer Stelle einführen

`data/quantities_v0.6.json` bleibt unverändert.

## 6. Quantity Engine vereinfachen

Im regionalen Wasserpfad ausschließlich:

`dailyAmount × effectiveDays × factorSum`

berechnen.

Keine Sonderberechnung mehr für Tank oder Watermaker.

Keine 1.5-l-Tank-Floor-Berechnung mehr im Mindest-Trinkwasserbedarf.

Bestehende technische Input-Felder nicht entfernen; sie werden später für Kontext/Hinweise gebraucht.

## 7. Sichtbarer Gesamtwert

Für die Wassergruppe einen echten berechneten Gesamtwert anzeigen:

`Mindest-Trinkwasser: ca. X l`

WICHTIG:
- nicht den statischen Katalogwert `group.need.amount` als Gesamtwert anzeigen;
- die bestehende `TripCalculationResult` / Group-Calculation-Truth verwenden;
- keine zweite Wasserformel in der UI duplizieren.

Falls nötig `ShoppingListGroupView` sauber um den berechneten Gruppenbedarf erweitern.

## 8. Verbindlicher Hinweistext

Bei der Wassergruppe muss ein informativer Hinweis sichtbar sein.

Deutscher Sinntext:

`Dieser Wert ist nur der geschätzte Mindest-Trinkwasserbedarf. Tank, Watermaker, Nachfüllmöglichkeiten sowie zusätzlicher Frischwasserverbrauch für Kochen, Spülen, Waschen und Körperpflege sind nicht eingerechnet und müssen separat geplant werden.`

Alle sechs unterstützten Sprachen pflegen:

- DE
- EN
- FR
- ES
- PT
- HR

Übersetzungen müssen denselben Sinn bewahren.

Keine Formulierung darf behaupten, dass Provy den Gesamt-Frischwasserbedarf berechnet.

## 9. Bestehende Tank-/Watermaker-Texte korrigieren

Aktuell irreführende Aussagen entfernen.

Insbesondere:

`waterTankDrinkableSubtitle`

darf nicht mehr behaupten, dass der Flaschenwasserbedarf automatisch reduziert wird.

`hasWatermakerSubtitle`

darf nicht mehr behaupten, dass ein Watermaker automatisch die Trinkwasserversorgung übernimmt oder eine berechnete Notreserve übrig bleibt.

Stattdessen neutral erklären, dass diese technischen Gegebenheiten in die eigene Wasserplanung einbezogen werden müssen.

Alle Sprachen konsistent aktualisieren.

## 10. Water-Boost-Chips entfernen

Aus der Wasser-Item-UI entfernen:

- `+25 % warm`
- `+50 % heiß/Tropen`
- zugehörige `_applyWaterBonus`-Logik
- nur dadurch benötigte Localization-Strings
- zugehörige Tests

Begründung:
Die Klimazone ist bereits in der Berechnung enthalten. Zusätzliche Mengen entscheidet der Nutzer über die normale Packungsbearbeitung.

Keine Ersatz-Sonderbuttons einführen.

## 11. Verbindliche Regressionstests

Mindestens beweisen:

1. cool berechnet bestehenden Mindest-Trinkwasser-Richtwert
2. warm
3. hot
4. 1 Tag
5. 2 Tage
6. 7/14 Tage skalieren korrekt
7. `daysUntilNextStop` begrenzt den Planungshorizont
8. bestehende Kindergewichtung bleibt erhalten
9. Watermaker false/true ergibt identischen Mindest-Trinkwasserwert
10. kein Tank / großer trinkbarer Tank ergibt identischen Wert
11. nicht trinkbarer Tank identisch
12. Tank + Watermaker identisch
13. manueller Wasser-Packungs-Override bleibt bei Recalculation stabil
14. Production Loader nutzt `quantities_v0.6.json`
15. `data/quantities_v0.6.json` unverändert
16. kein `watermakerBackupDays` in Production
17. keine `quantities_v0.7.json` im finalen PR
18. keine Water-Boost-Chips
19. sichtbarer `Mindest-Trinkwasser`-Gesamtwert basiert auf CalculationResult
20. user-facing Planungshinweis sichtbar
21. Tank-/Watermaker-Subtitles ohne automatische Bedarfs-/Versorgungsbehauptung
22. alle sechs ARB-Dateien vollständig
23. bestehende PIVOT1/DATA1/PIVOT3-B relevante Regressionen bleiben grün
24. GitHub Actions Full-QA grün

Keine Tests abschwächen, um die Änderung grün zu bekommen.

## 12. Strict non-scope

Nicht hinzufügen:

- Watermaker l/h
- Watermaker-Leistungsfeld
- automatisch berechnete Watermaker-Reserve
- Tankfüllstand
- Gesamt-Frischwasserverbrauch
- Kochwasserberechnung
- Spül-/Wasch-/Duschberechnung
- Meerwasser-Mischlogik
- neue BoatProfile-Felder
- PIVOT2 Review-Implementation
- andere Slices

## 13. Lokale QA

Keine vollständige lokale Flutter-Suite.

Nur kleine gezielte Tests, sofern sinnvoll und nicht belastend.

Authoritative Full-QA über GitHub Actions.

## 14. Bericht

Bestehendes:

`docs/impl/WATER1_bericht.md`

nicht löschen.

Anhängen:

`## WATER1 Simplification Amendment`

Dokumentieren:

- Ausgangs-Branch-HEAD
- integrierten aktuellen main-Stand
- supersedierte 3-Tage-Logik
- entfernte v0.7-Konfiguration
- neue einfache Formel
- Tank/Watermaker-unabhängige Bedarfssemantik
- UI-/Wording-Änderungen
- entfernte Water-Boost-Chips
- Tests
- Scope-Bestätigung
- GitHub Actions Resultate
- finalen PR-HEAD

Keine CI-Erfolge behaupten, bevor sie tatsächlich auf dem finalen HEAD gelaufen sind.

## 15. PR #31

Bestehenden PR #31 weiterverwenden.

Nach Umsetzung:
- Titel auf `WATER1: Minimum drinking water simplification` aktualisieren
- PR-Beschreibung an neue Semantik anpassen
- DRAFT erst dann auf Ready for Review setzen, wenn finaler HEAD vollständig grün ist

Issue #30 offen lassen.

## 16. GitHub Actions

Erforderlich auf finalem PR-HEAD:

- Flutter Analyze & Test → SUCCESS
- Backend Typecheck & Vitest → SUCCESS

Bei Fehlern nur auf demselben Review-Branch korrigieren.

## 17. STOP

Nach final grüner CI:

- PR NICHT mergen
- Issue #30 NICHT schließen
- PIVOT2 NICHT starten
- vollständigen Abschlussbericht liefern
- STOP für unabhängigen Re-Review / Owner Acceptance

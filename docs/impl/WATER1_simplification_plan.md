# WATER1 Simplification Amendment Plan

Stand: 16.10.2026  
Status: **OWNER-ACCEPTED / IMPLEMENTATION AMENDMENT RELEASED**

Verbindliche Grundlage:

`docs/impl/WATER1_simplification_reconciliation_2026-10-16.md`

## Ziel

Die derzeitige PR-#31-Implementierung mit 3-Tage-Watermaker-Reserve wird zurückgebaut.

WATER1 soll danach nur noch einen klimaabhängigen Mindest-Trinkwasser-Richtwert berechnen und einen ehrlichen Planungshinweis anzeigen.

## A. Daten / Loader

- `data/quantities_v0.7.json` aus PR #31 entfernen.
- `pubspec.yaml`-Asset für v0.7 entfernen.
- Production Loader zurück auf `data/quantities_v0.6.json`.
- v0.6 unverändert lassen.
- `watermakerBackupDays` aus `QuantitiesData` entfernen.
- alle durch v0.7 erzwungenen Testpfade zurück auf v0.6.

## B. Quantity Engine

Regionaler Wasserbedarf:

`minimumDrinkingWater = climateDailyLiters × crewFactorSum × effectiveDays`

mit:

`effectiveDays = daysUntilNextStop ?? daysCount`

Kein Sonderzweig für:
- Watermaker
- trinkbaren Tank
- Tankgröße

Die Input-Felder bleiben bestehen, werden aber nicht zur Bedarfsreduktion verwendet.

## C. UI / Wording

Für die Wassergruppe einen expliziten Gesamtwert anzeigen:

`Mindest-Trinkwasser: ca. X l`

Der Wert muss aus der tatsächlichen Calculation-Group-Truth kommen, nicht aus dem statischen Katalogwert `need.amount`.

Darunter sinngemäß:

`Dieser Wert ist nur der geschätzte Mindest-Trinkwasserbedarf. Tank, Watermaker, Nachfüllmöglichkeiten sowie zusätzlicher Frischwasserverbrauch für Kochen, Spülen, Waschen und Körperpflege sind nicht eingerechnet und müssen separat geplant werden.`

Alle 6 Sprachen pflegen.

Bestehende irreführende Texte ändern:
- `waterTankDrinkableSubtitle`
- `hasWatermakerSubtitle`

Keine Formulierung mehr, dass Tank den Bedarf automatisch reduziert oder Watermaker ihn automatisch deckt.

## D. Water-Boost-Chips entfernen

Aus `item_row_widget.dart` entfernen:
- `+25 % warm`
- `+50 % heiß/Tropen`
- zugehörige Water-Bonus-Hilfsmethode und nicht mehr benötigte Strings/Tests.

Begründung:
Die Klimazone ist bereits Bestandteil des Mindest-Trinkwasser-Richtwerts. Zusätzliche Mengen kann der Nutzer über die normale Packungsbearbeitung festlegen.

## E. View Model

Wenn für die Anzeige nötig, `ShoppingListGroupView` um den berechneten Gruppenbedarf erweitern.

Bevorzugt die bestehende `TripCalculationResult.groupResults`-Truth verwenden.

Keine zweite Wasserformel in der UI implementieren.

## F. Regression Tests

Mindestens:

1. cool: bestehender täglicher Klima-Richtwert
2. warm
3. hot
4. 1 Tag
5. 2 Tage
6. längerer Trip
7. `daysUntilNextStop`
8. Kindergewichtung
9. Watermaker true/false identisch
10. Tank 0 / großer trinkbarer Tank identisch
11. Tank + Watermaker identisch
12. manueller Package Override stabil
13. Production Loader nutzt v0.6
14. v0.6 unverändert
15. kein `watermakerBackupDays`
16. keine Water-Boost-Chips
17. Mindest-Trinkwasser-Gesamtwert sichtbar
18. Hinweistext sichtbar
19. Tank-/Watermaker-Subtitles ohne automatische Bedarfsbehauptung
20. alle 6 ARB-Dateien vollständig
21. Full GitHub Actions grün

## G. Bericht

Bestehendes:

`docs/impl/WATER1_bericht.md`

nicht löschen.

Unter neuer Überschrift anhängen:

`## WATER1 Simplification Amendment`

Darin:
- warum die 3-Tage-Reserve superseded wurde;
- entfernte v0.7-Konfiguration;
- neue einfache Formel;
- UI-/Wording-Vereinfachung;
- Tests;
- finaler PR-HEAD;
- GitHub-CI.

## H. Workflow

Bestehenden Review-Branch und PR #31 weiterverwenden.

Vor Umsetzung aktuellen `origin/main` integrieren.

Keine Full-Suite lokal.

Authoritative Full-QA über GitHub Actions.

Nach final grünem PR:

**STOP für unabhängigen Re-Review / Owner Acceptance.**

Nicht mergen.
PIVOT2 nicht starten.

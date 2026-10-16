# WATER1 Simplification Reconciliation – 16.10.2026

Status: **OWNER-ACCEPTED / SUPERSEDES PREVIOUS WATER1 IMPLEMENTATION DIRECTION**

Owner decision:

WATER1 wird bewusst vereinfacht. Provy berechnet nur noch einen klimaabhängigen **Mindest-Trinkwasser-Richtwert** für die Crew. Tank, Watermaker und sonstiger Frischwasserverbrauch werden nicht mehr automatisch in eine Versorgungsformel eingerechnet.

Diese Entscheidung supersediert:
- die ursprüngliche PIVOT3-B-Watermaker-Reserve `1.5 l × crewCount`;
- die WATER1-3-Tage-Watermaker-Ausfallreserve;
- automatische Tankabzüge vom Mindest-Trinkwasser-Richtwert.

PR #31 ist daher in seiner aktuellen fachlichen Form **AMENDMENT REQUIRED** und darf nicht gemerged werden.

## 1. Produktprinzip

Provy soll nur berechnen, was belastbar ableitbar ist.

Verbindlicher Grundsatz:

> **Provy schätzt den Mindest-Trinkwasserbedarf. Wie dieser Bedarf an Bord gedeckt wird, entscheidet der Skipper.**

Die App modelliert nicht automatisch:
- tatsächlichen Tankfüllstand;
- reale Watermaker-Leistung;
- Watermaker-Laufzeit;
- Nachfüllmöglichkeiten;
- Kochwasser;
- Spülwasser;
- Waschwasser;
- Dusche / Körperpflege;
- individuelle Wassersparmethoden;
- Nutzung von Meerwasser zum Kochen/Spülen.

## 2. Einzige Wasser-Berechnung

Der Mindest-Trinkwasser-Richtwert bleibt datengetrieben über die bestehenden Klima-Werte:

- cool: 2.0 l pro Erwachsenen-Äquivalent und Tag
- warm: 2.5 l
- hot: 3.5 l

Es werden keine neuen Literwerte eingeführt.

Bestehende Crewgewichtung bleibt erhalten:
- Erwachsene: 1.0
- Kinder: bestehender `child`-Faktor

Bestehender Planungshorizont bleibt erhalten:

`effectiveDays = daysUntilNextStop ?? daysCount`

Formel:

`minimumDrinkingWater = climateDailyLiters × crewFactorSum × effectiveDays`

Das Ergebnis ist ausdrücklich ein **Mindest-Trinkwasser-Richtwert**, keine vollständige Frischwasserplanung.

## 3. Tank und Watermaker

`waterTankLiters`, `isWaterTankDrinkable` und `hasWatermaker` bleiben gültige Boots-/Trip-Fakten.

Sie verändern den Mindest-Trinkwasser-Richtwert jedoch **nicht**.

Daher müssen bei sonst identischen Inputs dieselben Werte entstehen für:
- kein Tank;
- trinkbarer Tank;
- nicht trinkbarer Tank;
- Watermaker aus;
- Watermaker an.

Tank und Watermaker beschreiben nur mögliche **Versorgungsquellen**, nicht den Bedarf.

## 4. User-facing Hinweis

Beim Wasser-Richtwert muss ein klarer Hinweis erscheinen.

Verbindlicher deutscher Sinntext:

> **Dieser Wert ist nur der geschätzte Mindest-Trinkwasserbedarf. Tank, Watermaker, Nachfüllmöglichkeiten sowie zusätzlicher Frischwasserverbrauch für Kochen, Spülen, Waschen und Körperpflege sind nicht eingerechnet und müssen separat geplant werden.**

Die Übersetzungen müssen denselben Sinn bewahren.

## 5. UI-Vereinfachung

Die Wasser-UX soll keine zusätzliche pseudo-präzise Logik suggerieren.

Daher:
- expliziten Gesamtwert als `Mindest-Trinkwasser` anzeigen;
- alte Aussagen entfernen, dass Tank automatisch Flaschenwasser reduziert;
- alte Aussage entfernen, dass Watermaker automatisch die Trinkwasserversorgung übernimmt;
- Wasser-spezifische `+25 % warm` / `+50 % heiß/Tropen`-Chips entfernen, weil die Klimazone bereits in der Berechnung steckt und der Nutzer Packungen ohnehin manuell ändern kann;
- keine neue Reserve-UI;
- keine neue Watermaker-Kapazitätsabfrage.

## 6. Datenversion

Die bisherige WATER1-3-Tage-Lösung benötigt `data/quantities_v0.7.json` ausschließlich für `watermaker.backup_days`.

Da diese Semantik superseded ist:
- `quantities_v0.7.json` aus PR #31 wird nicht übernommen;
- Production bleibt auf `data/quantities_v0.6.json`;
- `data/quantities_v0.6.json` bleibt unverändert;
- kein `watermakerBackupDays`-Feld im Quantities-Modell.

## 7. Quantity Engine

Der regionale Wasserpfad wird vereinfacht auf:

`dailyAmount × effectiveDays × factorSum`

Keine Sonderberechnung mehr für:
- `hasWatermaker`;
- `isWaterTankDrinkable`;
- `waterTankLiters`.

Die technischen Felder bleiben im Input bestehen, da sie später in PIVOT2 für Hinweise/Plausibilitätskontext gebraucht werden können.

## 8. PIVOT2-Semantik

Für den späteren Provisioning Review:

- Provy darf objektiv den Mindest-Trinkwasser-Richtwert anzeigen und Unterdeckung gegenüber explizit ausgewähltem Trinkwasser kennzeichnen.
- Tank/Watermaker führen nicht automatisch zu einer mathematischen Reduktion.
- Wenn Tank oder Watermaker vorhanden sind, ist das ein **CHECK / INFO-Kontext**, keine automatisch gelöste Versorgung.
- Hinweis: zusätzliche Nutzung für Kochen, Waschen, Spülen, Körperpflege etc. ist nicht Teil des Mindest-Trinkwasser-Richtwerts.
- keine automatisch berechnete Watermaker-Reserve.

Die exakte PIVOT2-Darstellung wird bei PIVOT2-Reconciliation gegen den dann aktuellen `origin/main` final geprüft.

## 9. Required automated proof

Mindestens:

1. cool / warm / hot liefern die bestehenden klimaabhängigen Werte.
2. 1/2/7/14 Tage skalieren nur über `effectiveDays`.
3. `daysUntilNextStop` begrenzt den Planungshorizont wie bisher.
4. bestehende Kindergewichtung bleibt erhalten.
5. kein Tank vs. großer trinkbarer Tank → identischer Mindest-Trinkwasser-Richtwert.
6. Watermaker aus vs. an → identischer Mindest-Trinkwasser-Richtwert.
7. Kombination Tank + Watermaker → identischer Richtwert.
8. manuelle Packungs-Overrides bleiben stabil.
9. Production lädt weiterhin `quantities_v0.6.json`.
10. v0.6 bleibt unverändert.
11. keine `watermakerBackupDays`-Production-Logik.
12. Water-Boost-Chips sind entfernt.
13. sichtbare Texte behaupten keinen automatischen Tankabzug/Watermaker-Deckung mehr.
14. user-facing Mindest-Trinkwasser-Hinweis ist in allen unterstützten Sprachen vorhanden.
15. GitHub Actions Full-QA grün auf finalem PR-HEAD.

## 10. Strict non-scope

Nicht hinzufügen:
- Watermaker-Kapazität / l/h
- Watermaker-Reserveberechnung
- Tankfüllstand
- Kochwasserberechnung
- Gesamt-Frischwasserberechnung
- Dusch-/Wasch-/Spülverbrauch
- Meerwasser-Mischlogik
- PIVOT2-Reviewlogik selbst
- neue BoatProfile-Felder

## 11. Gate

PR #31 bleibt der WATER1 Review-PR, muss aber auf diese vereinfachte Semantik amended werden.

Nach Amendment:
- GitHub Actions grün;
- unabhängiger Re-Review;
- explizite Owner Acceptance;
- erst dann Merge.

PIVOT2 bleibt bis dahin ON HOLD.

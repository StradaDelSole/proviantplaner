# FIX-A Independent Review 2 – 05.10.2026

Reviewed HEAD: `ffe3ce63c94b52e6fb70ac2a7a2fc8839301375a`

Status: **SECOND AMENDMENT REQUIRED – FIX-A noch nicht owner-accepted**

## Ergebnis

Der Amendment ist in mehreren Punkten korrekt und deutlich weiter als der vorherige Stand.

### Verifiziert geschlossen

#### Finding B – Issue #15 Restaurantwerte im Trip Edit
Verifiziert:
- Restaurant-Mittag-/Abend-Zähler sind im Edit-Flow vorhanden.
- `TripService.updateTripDetails` übernimmt `restaurantLunches` / `restaurantDinners`.
- Werte werden gegen `daysCount` geklemmt.
- `tripDays` werden persistiert.
- danach erfolgt `recalculateTrip(tripId)`.
- Journey 6 ändert Restaurantwerte über echte UI und prüft Persistenz; zusätzlicher Service-Test prüft Clamping.

**Status: CLOSED für FIX-A.**

#### Finding C – Issue #17 Pseudo-Settings
Verifiziert:
- sichtbare `Gemerkte Packungsgrößen`-Kachel entfernt.
- Sprachzeile zeigt Gerätesprache als Information.
- keine Chevron-/Tap-Affordance.

**Status: CLOSED für FIX-A.**

#### Finding D – „Später“
Verifiziert:
- existierender Folge-Stopp wird verwendet und transparent per SnackBar benannt.
- existiert keiner, muss der Nutzer einen neuen Folgestopp ausdrücklich bestätigen.
- Service erzeugt keinen stillen Stopp und wirft ohne Ziel einen `StateError`.
- Journey prüft den No-later-stop-Fall und Mengenstabilität.

**Status: CLOSED für FIX-A.**

## Finding A – Issue #16 weiterhin NICHT geschlossen

Der Amendment lokalisiert viele Strings, aber nicht alle sichtbaren produktiven Texte.

Verifizierte verbleibende Beispiele auf aktuellem `main`:

### `TripWizardScreen`
- Default-Feldwert `Törn Kroatien`
- `1. Törn`
- `2. Crew (...)`

Damit ist insbesondere die Issue-#16-Abnahme **Setup in EN ohne deutsche Reste** nicht erfüllt.

### `StartScreen`
Weiterhin sichtbare deutsche Texte / Tooltips, u. a.:
- `Unterwegs / Bordkasse`
- `Meine Törns`
- `Nachtwache`
- `Einstellungen`
- `Aktive Törns (...)`

### `KittyScreen`
Weiterhin sichtbare deutsche Texte, u. a.:
- `Törn ... · ... Personen · ... Tage`
- `Alle Einzahlungen und Auszahlungen laufen über den Kassenwart.`
- `Crew übernimmt Bordkasse`

### `SettlementScreen`
Weiterhin sichtbare/versendete deutsche Texte, u. a.:
- `Törn nicht gefunden`
- `$count Zahlungen`
- Remittance: `Törn ... Bordkasse ...`
- Share-Text: `Bordkasse: ... zahlt ... an ...`

### `TripTimelineScreen`
Weiterhin deutsche Strings, u. a.:
- `Törn nicht gefunden`
- `TÖRN-BILANZ VERPFLEGUNG`

### Router / NotFound
Es existieren weiterhin deutsche hardcoded Fallbacks in `app_router.dart` und `not_found_screen.dart`. Wenn diese Fallbacks produktiv erreichbar bleiben können, müssen auch sie aus dem sichtbaren Localized-UI-Pfad entfernt bzw. sauber lokalisiert werden.

### Fehlende Abdeckung
Issue #16 verlangt als Abnahme:
- TripOverview
- More
- Liste
- Einkauf
- Einlagerung
- Bordkasse
- Abrechnung
- Setup

jeweils in EN ohne deutsche Reste, plus Stichprobe einer weiteren Nicht-DE-Sprache.

Der Amendment testet aktuell:
- TripOverview EN
- More EN
- TripOverview ES

Das reicht nicht, um Issue #16 als geschlossen zu belegen.

**Status: OPEN.**

## Finding E – Issue #19 stark verbessert, aber nicht vollständig geschlossen

Positiv:
- sieben echte Router/UI-Journeys vorhanden.
- Overview → Liste → zurück ist real getestet.
- Overview → Bordkasse → zurück ist real getestet.
- Shopping → Einlagern → Overview ist real getestet.
- Trip Edit → Restaurantwerte ändern → speichern ist real getestet.
- zweiter Einkaufsstopp wird über UI angelegt/gelöscht.

Noch fehlend gegenüber Issue #19:
1. **Törn erstellen → Overview**
   - aktuelle Journey-Datei enthält weder `TripWizardScreen` noch `/trips/new`.
   - Sample Trips werden direkt über `tripService.createTripWithCrew` angelegt.

2. **Bordkasse: echte Aktion**
   - Journey 2 öffnet Bordkasse und wechselt ggf. auf `Einzahlungen`, erzeugt aber keine echte Einzahlung oder Ausgabe.
   - Issue #19 verlangt einen realen Bordkassen-Journey mit Aktion, nicht nur Screen-Erreichbarkeit.

3. **Localization-Journey-Abdeckung**
   - reale EN-Abdeckung der übrigen Issue-#16-Hauptscreens fehlt, siehe Finding A.

**Status: PARTIALLY CLOSED / AMENDMENT REQUIRED.**

## Reporting-Fehler

`docs/impl/FIX-A_amendment_bericht.md` ist auf `main` vorhanden, aber **leer (0 Byte)**.

Blob SHA:
`e69de29bb2d1d6434b8b29ae775ad8c2e48c5391`

Damit existiert der im Gemini-Report behauptete Abschlussbericht faktisch nicht.

## QA-Nachweis

Gemini meldet:
- `flutter analyze`: sauber
- `flutter test`: 239/239 grün

Diese Ergebnisse sind derzeit nicht zusätzlich über GitHub Actions am Commit belegt; für `ffe3ce6` sind keine Workflow-Runs / Commit-Statuses sichtbar. Deshalb werden die lokalen Ergebnisse nicht als falsch bewertet, müssen aber im nicht-leeren Amendment-Bericht mit exakten Commands/Resultaten dokumentiert werden.

## Zweites, eng begrenztes Amendment

Nur noch folgende Punkte bearbeiten:

### A. Issue #16 vollständig schließen
- alle sichtbaren deutschen Hardcodes der Issue-#16-Hauptscreens über ARB führen
- insbesondere TripWizard/Setup, Start, Kitty, Settlement, Timeline und alle noch produktiv sichtbaren Fallbacks
- alle sechs ARBs synchron halten
- weiterhin kein `kitty` in sichtbaren ARB-Strings, entsprechend UX-C

### B. Real-Screen Localization Tests vervollständigen
Mindestens EN:
- Setup / TripWizard
- TripOverview
- Liste
- Shopping Mode
- Einlagerung
- Bordkasse
- Abrechnung
- More

Zusätzlich mindestens eine weitere Nicht-DE-Sprache als Stichprobe.

Die Tests sollen echte produktive Screens rendern; kein künstlicher Scaffold mit ausgewählten `l10n.*`-Strings.

### C. Issue #19 Journey-Lücke schließen
- echte UI-Journey `/trips/new` → Törn über Wizard anlegen → auf realem Overview landen
- Bordkassen-Journey muss mindestens eine echte Ausgabe oder Einzahlung über die UI speichern und anschließend den persistierten Zustand prüfen
- bestehende funktionierende Journeys nicht ersetzen

### D. Amendment-Bericht wirklich einchecken
`docs/impl/FIX-A_amendment_bericht.md` mit:
- exact final HEAD
- Findings A–E
- geänderten Dateien
- exakten QA-Commands
- tatsächlichen Ergebnissen
- verbleibenden Risiken / ausdrücklich `none`, falls keine
- keine Behauptung, die nicht durch Code/Test gedeckt ist

### E. Abschluss
- `flutter analyze`
- vollständiges `flutter test`
- Commit + Push auf `origin/main`
- STOP
- PIVOT1 NICHT starten

## Acceptance

FIX-A kann danach owner-accepted werden, wenn:
- Issue #16 vollständig nach seiner dokumentierten Abnahme geschlossen ist
- Issue #19 die oben genannten realen Journey-Lücken schließt
- Bericht nicht leer ist
- Analyze/Test vollständig grün sind
- keine Regression in B/C/D entsteht

# QA-RAPID-01 – Abschlussbericht (Android UX Usability Fixes)

**Status:** IMPLEMENTIERT & VOLLSTÄNDIG GETESTET – BEREIT FÜR REVIEW  
**Datum:** 04.11.2026  
**Tracking-Issue:** #57 (Owner-freigegebene Findings #47, #48, #52, #53, #55)  
**Branch:** `slice/qa-rapid-android-01`  
**Basis-Commit:** `44e5e929bc5e4965b1f3cff4f491cc76b6aa6631` (`origin/main`)

---

## 1. Übersicht der behobenen Findings

| Finding | Schweregrad | Betroffene Dateien | Ursache | Lösung | Nachweis |
|---|---|---|---|---|---|
| **#48 Navigation Trap** | HIGH | `lib/features/home/ui/start_screen.dart`, `lib/features/more/ui/more_screen.dart` | `context.go('/more')` ersetzte den GoRouter-Stack; `MoreScreen` besaß weder führenden Zurück-Button noch `PopScope`. Nutzer saßen in Android fest. | 1) `context.push('/more')` in `start_screen.dart`. 2) `AppBar(leading: IconButton(Icons.arrow_back))` und `PopScope` mit Fallback zu `/` bzw. `/trips/$tripId`. | `automatischer Test (#48: StartScreen pushes /more and MoreScreen back button pops back to StartScreen)`, `automatischer Test (#48: MoreScreen deep-link with empty stack navigates back to root via handleBack)` |
| **#53 Days in Detail Overflow** | HIGH | `lib/features/trip/ui/trip_overview_screen.dart` | `ListTile.subtitle` nutzte ein starres `Row` mit zwei `FilterChip`-Widgets ("Mittags Restaurant", "Abends Restaurant"), was auf schmalen Screens oder bei großer Schrift zu RenderFlex-Overflow führte. | Ersatz von `Row` durch `Padding(padding: EdgeInsets.only(top: 4), child: Wrap(spacing: 8, runSpacing: 8, children: [...]))`. | `automatischer Test (#53: TripOverviewScreen days in detail renders cleanly on Pixel 7 Pro (412x915))`, `automatischer Test (#53: Day tile with Wrap handles extreme narrow 320px width and 1.5x font scale without overflow)` |
| **#55 Brot-Kühlwarnung (isCooled)** | HIGH | `lib/features/shopping_list/domain/models/shopping_list_models.dart` | `isCooled` nutzte `(shelfLifeDays > 0 && shelfLifeDays <= 3)`. Kurze Haltbarkeit wurde fälschlich mit Kühlpflicht gleichgesetzt; Baguette (1d), Brötchen (1d), Weißbrot (3d) wurden als Kühlware markiert. | Strikte Katalogprüfung: `variant?.chill == ChillRequirement.fridge || storageHints.contains('cool_first')`. Neuer Getter `bool get isFrozen => variant?.chill == ChillRequirement.freezer;`. | `automatischer Test (#55: isCooled correctly distinguishes genuine chill requirements from short shelf life)`, `automatischer Test (#55: ShoppingListItemRow does NOT show needsCooling warning for Baguette even on 0L fridge boat)` |
| **#52 Törnerstellung Vorbelegung** | MEDIUM | `lib/features/trip/ui/trip_wizard_screen.dart`, `lib/l10n/app_*.arb` | `_nameController.text` wurde in `didChangeDependencies` mit `"Törn Kroatien"` vorbelegt; `_startDate` stand initial ungefragt auf `DateTime.now()`. | Vorbelegung entfernt; `hintText` als Platzhalter; `DateTime? _startDate` startet `null`; Pflichtvalidierung beider Felder vor Submit; SnackBar-Hinweise bei fehlenden Eingaben. | `automatischer Test (#52: TripWizardScreen starts empty and blocks submit until name and date are chosen)` |
| **#47 Doppelte Lieferanten-Buttons** | MEDIUM | `lib/features/more/ui/more_screen.dart` | In `_showSuppliersDialog` gab es 3 Add-Buttons: AppBar-Action, leerer Zustand im Center, untere Leiste. | AppBar-Action und zentrierten Button im Leerzustand entfernt. Genau ein einheitlicher, barrierefreier `FilledButton.icon` in der unteren Leiste für leere und befüllte Liste. | `automatischer Test (#47: MoreScreen supplier bottom sheet has exactly one Add button in empty state)`, `automatischer Test (#47: MoreScreen supplier bottom sheet has exactly one Add button in populated state)` |

---

## 2. Anpassung bestehender Tests (Begründung gem. GEMINI.md Regel 7)

1. `test/features/trip/trip_ui_test.dart` (Zeile 72):
   - **Bisher:** `expect(find.text('Törn Kroatien'), findsOneWidget);`
   - **Neu:** Prüfung auf leeres Eingabefeld mit Beschriftung `Törnname` und unselektiertes Datum `Datum auswählen`.
   - **Begründung:** Der bisherige Test verifizierte das in Issue #52 ausdrücklich als unerwünscht eingestufte Verhalten der automatischen "Kroatien"-Vorbelegung.

2. `test/features/ux/fix_a_journey_test.dart` (Journey 0):
   - **Bisher:** Klick auf `wizard_submit_trip_button` ohne vorherige Texteingabe erstellte direkt einen Törn.
   - **Neu:** Test füllt Törnname (`'Sommerurlaub'`) und wählt ein Startdatum via DatePickerDialog aus, bevor der Submit-Button betätigt wird.
   - **Begründung:** Ohne Name und Datum blockiert der Wizard nun richtigerweise die Törnerstellung mit einem Validierungshinweis.

3. `test/features/boat/pivot3b_water_and_setup_test.dart` (2 Journeys):
   - **Bisher:** Klick auf wizard_submit_trip_button ohne Eingabe von Name und Startdatum.
   - **Neu:** Explizite Eingabe von Name und Auswahl des Datums im Kalenderdialog vor Absenden.
   - **Begründung:** Entspricht der neuen Pflichtvalidierung aus #52.

4. `test/features/shopping_list/fb2_b_ui_test.dart`:
   - **Bisher:** Klick auf Submit nach Eingabe des Namens, aber ohne Datumsauswahl.
   - **Neu:** Auswahl des Startdatums im Kalenderdialog vor Submit.
   - **Begründung:** Entspricht der neuen Pflichtvalidierung aus #52.

5. `test/features/ux/ux_a_navigation_test.dart`:
   - **Bisher:** Törn-Erstellung ohne Name und Datum.
   - **Neu:** Eingabe von Name und Datum vor Törn-Erstellung.
   - **Begründung:** Entspricht der neuen Pflichtvalidierung aus #52.

---

## 3. Nachweise und Qualitätssicherung

### A. Statische Analyse
- `dart analyze lib test`: **0 Issues (No issues found!)**
- `npm run typecheck --prefix backend`: **0 Errors**

### B. Automatisierte Tests
- `test/features/ux/qa_rapid_01_android_fixes_test.dart`: **9/9 Tests bestanden (All passed)**
- `test/features/trip/trip_ui_test.dart`: **2/2 Tests bestanden (All passed)**
- `test/features/ux/fix_a_journey_test.dart`: **17/17 Tests bestanden (All passed)**
- Backend Vitest: **7 Testdateien, 37/37 Tests bestanden (All passed)**

---

## 4. Manuelle Testanleitung für physisches Google Pixel 7 Pro (nach Merge/APK)

1. **#48 More-Screen Navigation:**
   - App starten → oben rechts auf Zahnrad (Einstellungen/Mehr) tippen.
   - Oben links den Zurück-Pfeil tippen: App muss sofort und ohne Flackern zur Törnübersicht zurückkehren.
   - Erneut auf Einstellungen tippen → Android-Systemgeste von links/rechts (Zurück): App muss zur Törnübersicht zurückkehren (nicht App beenden).
2. **#53 Tagesübersicht Layout:**
   - In den Systemeinstellungen Schriftgröße auf "Groß" stellen.
   - In Provy einen Törn öffnen → "Tage im Detail" aufklappen.
   - Prüfen, dass "Mittags Restaurant" und "Abends Restaurant" sauber umbrechen und kein gelb-schwarzer Overflow-Balken erscheint.
3. **#55 Brot-Kühlwarnung:**
   - Törn mit einem Boot ohne Kühlschrank (0 L) anlegen oder öffnen.
   - Vorratsliste öffnen: Baguette, Brötchen und Weißbrot dürfen **keine** rote Warnung "braucht Kühlung" zeigen.
   - Frische Vollmilch oder Fleisch muss weiterhin zuverlässig "braucht Kühlung" anzeigen.
4. **#52 Neuer Törn Formular:**
   - Auf "Neuer Törn" tippen.
   - Prüfen, dass Törnname leer ist (nur grauer Platzhalter) und beim Datum "Datum auswählen" steht.
   - Sofort auf "Törn erstellen" tippen: Es muss eine Meldung erscheinen und der Törn darf nicht angelegt werden.
5. **#47 Lieferanten-Verwaltung:**
   - Einstellungen → "Gespeicherte Lieferanten" öffnen.
   - Sowohl im leeren Zustand als auch nach Anlegen eines Lieferanten darf es oben in der Leiste kein "+"-Symbol geben, sondern genau einen "Lieferant hinzufügen"-Button am unteren Bildschirmrand.

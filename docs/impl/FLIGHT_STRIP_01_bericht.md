# FLIGHT-STRIP-01 – Abschlussbericht (Flight-Strip-Board für Vorratsliste)

**Status:** IMPLEMENTIERT & VOLLSTÄNDIG GETESTET – BEREIT FÜR REVIEW  
**Datum:** 04.11.2026  
**Tracking-Issue:** #56 (Owner-freigegebene Spezifikation)  
**Branch:** `slice/flight-strip-board-01`  
**Basis-Commit:** `e00c01d35763790fe430a8c331436e120478f2dd` (`origin/main`)

---

## 1. Übersicht der Implementierung

Gemäß der Owner-Vorgabe aus Issue #56 wurde ein echtes, voll funktionsfähiges Flutter Flight-Strip-Board zur Zusammenstellung der Vorratsliste implementiert (ohne Mockups/Figma, direkt im Code). Die drei logischen Ebenen wurden für Smartphones optimiert umgesetzt:

### Ebene 1: Basket Tray (`BasketTrayWidget`)
- Sticky am unteren Bildschirmrand platziert; zu jedem Zeitpunkt während der Vorratsplanung erreichbar.
- Zeigt die Anzahl der Artikel im Korb (`l10n.basketSummary`), das Gesamtgewicht und -volumen (`l10n.totalWeightVolumeSummary`) sowie einen Aufklapp-Button.
- Im ausgeklappten Zustand:
  - Vollständige, übersichtliche Liste aller übernommenen Positionen mit Farbpunkt der Warengruppe.
  - Direkt bedienbare Stepper (`− / +`) zur Mengenanpassung im Korb (`setPackages`).
  - Lösch-Schaltfläche (`unadoptItem`) zum Entfernen einzelner Posten.
  - Primärer Aktionsbutton „Einkauf starten“, der nahtlos in den bestehenden In-Store Shopping Mode führt.

### Ebene 2: Farbcodierte Produktgruppen & Subgruppen-Stacks
- **10 Hauptkategorien:** Horizontal scrollbare Filter-Chips mit stabiler, maritimer Material-3-Farbpalette (`FlightStripColors`), dedizierten Ikonen zur Barrierefreiheit und dynamischem In-Basket-Zähler (z. B. `Frühstück (2)`).
- **47 Subgruppen:** Sobald eine Kategorie aktiv ist, wird eine Subgruppen-Leiste mit „Alle“ sowie den spezifischen Untergruppen (z. B. *Brot und Backwaren*, *Aufstriche*, *Müsli*) eingeblendet, um gezieltes Durchstöbern ohne endlose Listen zu ermöglichen.

### Ebene 3: Einzelne Produkt-Strips (`ProductStripWidget`)
- Kompaktes ATC-Flugstreifen-Design mit linksseitigem Farbbalken der Kategorie, Ikonografie, Produktname, Gebindegröße und Kühlwarenhinweis (falls relevant).
- **Mengensteuerung direkt auf dem Streifen:**
  - Linker Minus-Button (`[-]`), mittlere sichtbare Anzahl und Einheit, rechter Plus-Button (`[+]`).
  - Barrierefreie Touch-Targets: Alle Schaltflächen verfügen über mindestens 44x44 dp Klickfläche.
  - Das Antippen von Minus oder Plus ist strikt von der Wisch-Geste entkoppelt.
- **Swipe-Right (In den Korb – Owner Decision A):**
  - Horizontale Wischgeste nach rechts übernimmt den Artikel **sofort mit der exakt sichtbaren Menge und Gebindegröße in den Korb — ohne Bestätigungsdialog**.
  - Grüner Hintergrund mit Warenkorb-Symbol während des Wischens.
  - Haptisches Feedback (`mediumImpact`) und SnackBar mit `Rückgängig`-Aktion.
- **Swipe-Left (Überspringen):**
  - Horizontale Wischgeste nach links blendet den Streifen für den aktuellen Durchlauf aus (nicht gelöscht).
  - Statuszeile mit Zähler (`X übersprungene Artikel anzeigen`) und `Alle wiederherstellen`-Schaltfläche.
  - SnackBar mit `Rückgängig`-Aktion.
- **Barrierefreie Alternativen:**
  - Auf jedem Streifen befindet sich neben dem Stepper eine sichtbare „In den Korb“-Schaltfläche mit Warenkorb-Icon (`Icons.add_shopping_cart`), sodass Nutzer niemals auf Wischgesten festgelegt sind.
- **Detail-Inspektion:**
  - Ein Antippen des Streifens (außerhalb der Mengenknöpfe) öffnet das `AddOrEditItemSheet` für erweiterte Gebindegrößen- oder Stopp-Zuweisungen.

---

## 2. Suche, A/B-Umschalter und Barrierefreiheit

1. **Prominente Suche:**
   - Direkt über den Kategorien befindet sich ein Suchfeld, das unmittelbar alle 232 Varianten des Katalogs nach Produktname, Tags, Warengruppe und Abteilung filtert und als Strips bereitstellt.
2. **Interner A/B-Umschalter (`toggle_flight_strip_board_button`):**
   - In der `AppBar` der Vorratsliste befindet sich ein Ansicht-Umschalter, mit dem der Tester jederzeit zwischen dem neuen Flight-Strip-Board und der klassischen hierarchischen `PlanningView` hin- und herwechseln kann.
3. **Nachtwache-Modus & kleine Bildschirme:**
   - Im Nachtwache-Modus werden alle Strips, Korb-Elemente und Hintergründe strikt in Rot auf Schwarz gerendert (`#FFFF3B30`), um die Dunkeladaption der Crew auf See zu schützen (Designregel 13).
   - Auf 320 logical px schmalen Bildschirmen brechen alle Texte und Badges mittels `Wrap` sauber um; es treten keinerlei RenderFlex-Overflows auf.

---

## 3. Datenintegrität und Leitplanken

- **Keine Datenbankschema-Änderung / Migration:** Sämtliche Funktionen nutzen die bestehenden Tabellen `ListItem`, `ShoppingStop`, `ListItemAllocation` und den bestehenden `ShoppingListService`.
- **Echte Persistenz:** Das Übernehmen in den Korb setzt `isAdopted = true` und `overriddenPackages` via Drift. „Im Korb“ ist strikt von „Gekauft“ (`isBought`) getrennt.
- **PIVOT1-Mengenschutz:** Präferenzprodukte starten sichtbar bei 1 Packung (keine automatische `crew × days` Hochrechnung). Bedarfsbasierte Artikel zeigen ihren berechneten Richtwert.

---

## 4. Testabdeckung und Qualitätssicherung

### A. Statische Analyse
- `dart analyze lib test`: **0 Issues (No issues found!)**
- `npm run typecheck --prefix backend`: **0 Errors**

### B. Neue dedizierte Testsuite
`test/features/shopping_list/flight_strip_board_test.dart` (11 Tests, alle grün):
1. `Strip-Board rendert mit Basket-Tray, Kategorie-Chips und Strips`
2. `Mengensteuerung auf dem Strip (− / Count / +) mit barrierefreien Touch-Targets`
3. `SWIPE RIGHT übernimmt Artikel sofort in den Korb OHNE Bestätigungsdialog (Owner Decision A)`
4. `Undo auf Swipe-Right entfernt Artikel wieder aus dem Korb`
5. `Barrierefreie Schnell-Hinzufügen-Schaltfläche übernimmt ohne Wisch-Geste`
6. `SWIPE LEFT überspringt Artikel temporär mit Wiederherstellungsoption`
7. `Korb aufklappen, Inhalte einsehen und Mengen im Korb bearbeiten`
8. `Suche filtert sofort über den gesamten 232-Varianten-Katalog`
9. `Interner Schalter schaltet nahtlos zwischen Flight-Strip-Board und PlanningView um`
10. `Nachtwache-Modus rendert strikt in Rot/Schwarz ohne bunte Fremdfarben`
11. `Schmaler 320px-Viewport verursacht keinen RenderFlex-Overflow`

### C. Bestehende Regressionstests (alle grün)
- `shopping_list_ui_test.dart` (4/4 Tests bestanden)
- `pivot1_assisted_list_test.dart` (17/17 Tests bestanden)
- `fb2_b_ui_test.dart` (13/13 Tests bestanden)
- `qa_rapid_01_android_fixes_test.dart` (9/9 Tests bestanden)

---

## 5. Manuelle Testanleitung für physisches Google Pixel 7 Pro (nach Merge/APK)

1. **Board aufrufen:**
   - Beliebigen Törn öffnen → Vorratsliste („Liste“) antippen → In die Kategorie-Sicht wechseln.
   - Prüfen, dass das Flight-Strip-Board mit horizontalen Kategorie-Chips oben und dem Basket-Tray unten erscheint.
2. **Kategorien und Mengen:**
   - Auf „Frische Lebensmittel“ tippen, dann auf eine Subgruppe.
   - Bei einem Artikel auf `+` tippen: Zahl erhöht sich sichtbar von 1 auf 2.
3. **Swipe-Right (Korb):**
   - Den Streifen nach rechts wischen: Er gleitet mit grünem Feedback in den Korb.
   - Prüfen, dass KEIN Dialog erscheint und der Zähler im Basket-Tray sofort um 1 steigt.
   - Auf „RÜCKGÄNGIG“ im SnackBar tippen: Artikel wird wieder aus dem Korb entfernt.
4. **Swipe-Left (Skip):**
   - Einen Artikel nach links wischen: Er wird ausgeblendet, Statuszeile für übersprungene Artikel erscheint.
   - Auf „Alle wiederherstellen“ tippen: Artikel ist wieder da.
5. **Basket-Tray:**
   - Auf den Tray unten tippen: Korb klappt auf, zeigt übernommene Artikel mit `- / +` Steppern und „Einkauf starten“.
6. **A/B-Umschalter:**
   - Oben in der Leiste auf das Listen-Icon tippen: Ansicht schaltet nahtlos zur klassischen Baum-Ansicht (`PlanningView`) um. Erneut tippen: Zurück zum Strip-Board.

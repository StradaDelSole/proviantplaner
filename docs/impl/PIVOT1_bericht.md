# Abschlussbericht PIVOT1 – Assisted List Core (inkl. Review-Amendments)

Slice: PIVOT1 – Assisted List Core (Issue #10)  
Datum: 06.10.2026  
Status: Implementiert, alle Review- & Micro-Amendments abgeschlossen, bereit für finale Owner Acceptance  

---

## 1. Decision / Implementation Reconciliation (Abschnitt 2)

Vor Umsetzung des PIVOT1-Slices wurde der bestehende Daten- und UI-Stand systematisch analysiert:

### A. Automatische Generierung im Altsystem
- **ListItem-Erstellung:** In `TripService.createTripWithCrew` und `QuantityEngine` wurden beim Anlegen eines Törns bereits Einträge für Katalogartikel angelegt.
- **Katalogkandidaten vs. Übernommene Artikel:** Die Datenbank unterscheidet bereits über `isAdopted: bool` und `isCustom: bool` zwischen reinen Kandidaten (`isAdopted = false`, `isCustom = false`) und tatsächlich vom Nutzer gewählten Artikeln.
- **Listenkriterium:** Ein Artikel gehört zur tatsächlichen Vorrats- und Einkaufsliste (`isOnList`), wenn `isCustom || (isAdopted && effectivePackages > 0)` wahr ist.
- **Mengen-Neuberechnung:** Bei Crew- oder Dauer-Änderungen dürfen übernommene Artikel (`isAdopted: true`) in ihren Packungszahlen (`overriddenPackages` bzw. vom Nutzer gewählte Mengen) nicht stillschweigend überschrieben werden.
- **Einkaufsmodus:** Der Einkaufsmodus (`ShoppingModeScreen`) filtert strikt nach `it.isOnList && it.effectivePackages > 0` für den jeweiligen Stopp.

### B. Wiederverwendung vor Neudesign (Reuse before redesign)
- Die existierende Trennung zwischen Katalogkandidaten und übernommenen Elementen (`isAdopted`, `isCustom`, `overriddenPackages`, Allokationen) wurde vollständig wiederverwendet.
- Es war keine schema-brechende Datenbankmigration erforderlich; alle Tabellen, Relationen und Spalten bleiben stabil und abwärtskompatibel.

### C. FIX-A Erhaltung
- Alle Routingverträge (`context.push`, `context.pop()`, kanonische Fallbacks nach `/trips/$id`), Phasen-Logik (`TripPhase`), Einkaufsstopp-Zuordnung, "Später"-Verschiebung mit Folgestopp-Erstellung, echte Journey-Pfade und vollständige Lokalisierung in allen 6 Sprachen wurden intakt gehalten.

---

## 2. Umgesetzte PIVOT1-Funktionen & Review-Amendments

### A. Kern-Pivot (Erstfassung)
- **Neuer Törn ist leer (Search-First):**
  - Ein frisch angelegter Törn hat 0 übernommene Artikel auf der Liste.
  - Anstelle einer ungefragt vorbefüllten Speisekarte präsentiert die Vorratsliste (`ShoppingView` und `PlanningView`) einen prominenten, einladenden Search-First Empty State (`EmptyShoppingListView`).
  - Der veraltete Sammel-Button „Alle Vorschläge übernehmen“ wurde aus der Benutzeroberfläche entfernt.
- **Teilstring-Produktsuche:**
  - `CatalogSearchDelegate` ermöglicht schnelle, fehlertolerante Suche nach Varianten und Gruppen (z. B. `kä`, `pesto`, `tofu`, `wasser`).
  - Direkter Einstieg sowohl aus dem Empty State als auch über den globalen FAB / Menü.
- **Flacher Erfassungsflow (Decision 12–15, Wireframes v0.2):**
  - `AddOrEditItemSheet`: Modales Bottom Sheet für Variante → Packungsgrößen-Chips → Stepper (− / Zahl / +) mit Pickwheel/Direkteingabe → Hinzufügen / Speichern / Entfernen.
  - Taktiles Feedback bei Mengenänderung (`HapticFeedback.selectionClick()`).
  - Zeilen-Tap auf bestehende Vorratspositionen öffnet dasselbe Bottom Sheet zum Bearbeiten oder Entfernen.
- **Standard-Sortierung:**
  - Standardansicht ist Supermarkt-Abteilung (Decision 16); Kategorie bleibt als Umschaltmöglichkeit verfügbar.
- **Vollständige Lokalisierung:**
  - Alle neuen Keys (`addToList`, `removeFromList`, `packageSize`, `customPackageSize`, `totalQuantity`, `provyGuideline`, `provyGuidelineNotice`, `itemAddedNotice`, `itemRemovedNotice`, `emptyListTitle`, `emptyListSubtitle`, `searchProducts`, `onListStatus`, `holdsDays`) in allen 6 Sprachen (DE, EN, ES, FR, HR, PT) gepflegt. Keine "kitty"-Begriffe verwendet (UX-C-Konformität).

### B. Schließung der Befunde aus dem Independent Review 1 & 2 (06.10.2026)

- **Finding A – Assist-Klassifikation gegen kanonischen Katalog v0.10 gehärtet:**
  - Nicht-existierende Dummy-Gruppen-IDs (`snacks`, `sauces_special`) entfernt.
  - Kanonische Gruppen-IDs aus `data/catalog_v0.10.json` als Preference-Gruppen hinterlegt: `savory_snacks`, `sweets`, `spread_sweet`, `spread_savory`, `spirits`.
  - Kanonische Varianten-IDs innerhalb sonst geführter Gruppen als Preference-Varianten hinterlegt: `pesto`, `sauce_jar`, `tofu`, `bbq_sauce`, `sweet_chili`, `tabasco`, `soy_sauce`, `brie`, `feta`, `mozzarella`, `parmesan`.
  - Spirituosen (`spirits`) als Genussmittelpreference deklariert (0 Richtwert); Bier und Wein verbleiben als `guided`, da sie durch Konsumprofil-Formeln (`crewDrinking`, Erwachsenen-Kopfzahl, Urlaubsaufschlag) berechnet werden (im Code und Bericht dokumentiert).
  - Automatischer Katalog-Validierungstest hinzugefügt: 100% aller in `AssistClassifier` konfigurierten IDs existieren nachweislich im Katalog.
  - Regressionstests für Snacks (`chips`), Spezialsaucen (`bbq_sauce`), Käse (`feta`), Spirituosen (`rum`) und Abgrenzung zu Bier (`beer_can`).

- **Finding B – Beseitigung des UI-Bypass bei „Übernehmen“:**
  - In `ShoppingListItemRow` wurde der direkte Aufruf von `shoppingListService.adoptItem(...)` auf dem Aktions-Button entfernt.
  - Sowohl Zeilen-Tap (`item_tap_${item.item.id}`) als auch der sichtbare Aktions-Button (`item_add_btn_${item.item.id}`) öffnen nun ausnahmslos das `AddOrEditItemSheet(isAdding: true)`.
  - Beide Pfade erzwingen die bewusste Festlegung von Packungsgröße und Stückzahl durch den Skipper, bevor Daten in SQLite persistiert werden.

- **Finding C & Micro-Finding 1 – Reale Search/Add UI-Journey inkl. Gebindeauswahl:**
  - End-to-End-Widget-Journey über den echten `ShoppingListScreen` implementiert: Empty State Button (`empty_search_btn`) tippen → `showSearch` mit `CatalogSearchDelegate` → Texteingabe `'pesto'` → Treffer in `ListTile` antippen → modales `AddOrEditItemSheet` → **konkrete ChoiceChip-Gebindegröße auswählen** (250 g statt Standard 190 g) → Stepper auf 2 Gläser → "Auf die Liste" tippen → SnackBar & Liste aktualisiert → Pesto sichtbar mit 2 Gläsern → SQLite-Persistenz verifiziert: Packungsanzahl (2) UND benutzerdefinierte Gebindegröße (`customPackageSize: 250.0`, `effectivePackSize: 250.0`) nach Neuladen aus DB verifiziert.
  - `CatalogSearchDelegate` verwendet `parentContext` und `addPostFrameCallback`, um modale Sheets nach dem Schließen der Suchroute sauber im Navigator-Stack des aufrufenden Screens zu öffnen.

- **Micro-Finding 2 – Härtung von No-Result → Custom Item:**
  - Sowohl der Empty-Query-Button als auch der No-Results-Button (`matches.isEmpty`) in `CatalogSearchDelegate` auf denselben sicheren Parent-Context/Post-Frame-Pfad umgestellt:
    `targetContext = parentContext ?? context`, `close(context, null)`, `WidgetsBinding.instance.addPostFrameCallback((_) { if (targetContext.mounted) CustomItemSheet.show(targetContext, ...); })`.
  - Reale E2E-Widget-Journey (Test 16): Suche nach Begriff ohne Treffer (`'Fantasie-Kekse XYZ'`) → Button `no_results_custom_item_btn` antippen → `CustomItemSheet` öffnet sich auf dem echten Screen → Speichern tippen → Vorratsliste aktualisiert und Custom Item mit 1 Packung in SQLite persistiert.

- **Finding D – Mengen-Stabilität bei echter Neuberechnung:**
  - Test gegen den echten Produktionspfad `tripService.updateTripDetails(tripId, daysCount: 14)` und `tripService.recalculateTrip(tripId)` gehärtet.
  - Nachgewiesen für: (1) Preference-Item mit Nutzerwunschmenge (Pesto: 2 Gläser), (2) Guided-Item mit manuellem Override (Toastbrot: 5 Packungen) und (3) Custom-Item (Bio-Kaffee: 3 Packungen). Alle drei behalten nach Dauer- und Crew-Änderung exakt ihre gewählten Stückzahlen.

- **Finding E – Einkaufsmodus-Isolation auf echtem Screen:**
  - Dedizierter Widget-Test auf dem echten `ShoppingModeScreen(tripId, stopId)`:
  - Übernommener Katalogartikel (`spaghetti`) und eigene Position (`Bord-Gin Flasche`) werden angezeigt.
  - Unübernommene Katalogkandidaten (wie Butter, Salz, Milch) werden auf dem Screen nicht angezeigt.

---

## 3. Geänderte und neue Dateien

**Neue Dateien:**
- `lib/features/shopping_list/domain/models/assist_type.dart`
- `lib/features/shopping_list/ui/widgets/add_or_edit_item_sheet.dart`
- `lib/features/shopping_list/ui/widgets/empty_shopping_list_view.dart`
- `test/features/shopping_list/pivot1_assisted_list_test.dart`
- `docs/impl/PIVOT1_bericht.md`

**Geänderte Dateien:**
- `lib/features/shopping_list/data/shopping_list_providers.dart`
- `lib/features/shopping_list/domain/calculation/calculation_result.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `lib/features/shopping_list/domain/models/shopping_list_models.dart`
- `lib/features/shopping_list/ui/shopping_list_screen.dart`
- `lib/features/shopping_list/ui/widgets/catalog_search_delegate.dart`
- `lib/features/shopping_list/ui/widgets/item_row_widget.dart`
- `lib/features/shopping_list/ui/widgets/planning_view.dart`
- `lib/features/shopping_list/ui/widgets/shopping_view.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_hr.arb`
- `lib/l10n/app_pt.arb`
- `test/features/ux/ux_b_shopping_and_delivery_test.dart`
- `CHANGELOG.md`
- `README.md`

---

## 4. Qualitätsprüfung

- **flutter analyze:**
  No issues found! (0 Fehler, 0 Warnungen, 0 Lints)

- **flutter test:**
  262/262 Tests bestanden (100% grün, alle Test-Suiten grün).

---

## 5. Abnahmekriterien (SLICES_v0.19.md, PIVOT1_plan.md & PIVOT1_review2_2026-10-06.md)

1. **Neuer Törn ist leer (Search-First):**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 1. Neuer Törn ist leer (Search-First): 0 übernommene Posten & Leerstadium angezeigt` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

2. **Katalogsuche mit Teilstrings findet Varianten:**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 2. Katalogsuche mit Teilstrings findet Varianten (kä, pesto, tofu, wasser)` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

3. **Flacher Erfassungsflow (Variante → Packungsgröße → Stepper → Liste):**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 3. Variante -> Packungsgröße Chips -> Stepper -> Auf die Liste` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

4. **Bearbeiten und Entfernen über Zeilen-Tap:**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 4. Zeilen-Tap öffnet Edit-Sheet -> Menge ändern und Speichern oder Entfernen` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

5. **Pesto Regressionstest (5 Personen, 14 Tage): keine 14-Gläser-Menge, berechnet 0:**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 5. Pesto Regressionstest (5 Personen, 14 Tage): Keine automatische 14-Gläser-Menge, berechnet 0` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

6. **Tofu Regressionstest (vegetarische Crew): keine automatische Crew-Menge, berechnet 0:**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 6. Tofu Regressionstest: Vegetarische Crew -> Tofu hat keine automatische Crew-Menge (berechnet 0)` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

7. **Trinkwasser Needs-Based: Richtwert berechnet, angezeigt und vom Nutzer gewählt:**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 7. Trinkwasser Needs-Based: Richtwert wird berechnet, angezeigt und vom Nutzer gewählt` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

8. **Mengen-Stabilität bei Dauer- und Crew-Änderungen:**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 8. Mengen-Stabilität: Crew- und Dauer-Änderungen überschreiben übernommene Posten nicht` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

9. **Einkaufsmodus-Isolation (Modell-Ebene):**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 9. Einkaufsmodus-Isolation: Nur tatsächlich übernommene Positionen des Stopps erscheinen` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

10. **Finding A: Katalog-Validierung des AssistClassifiers:**
    - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 10. AssistClassifier: Alle konfigurierten Gruppen & Varianten existieren im Katalog v0.10` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

11. **Finding A: Preference-Regressionen (Snacks, Spezialsaucen, Käse, Spirituosen) vs. Guided (Bier/Wein):**
    - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 11. Preference-Regressionen: Snacks, Saucen, Käse & Spirituosen berechnen 0 Richtwert; Bier/Wein bleiben guided` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

12. **Finding B: Ausschluss des UI-Bypass (Zeilen-Tap & Add-Button):**
    - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 12. Kein UI-Bypass: Sowohl Zeilen-Tap als auch Add-Button öffnen AddOrEditItemSheet und adoptieren nicht still` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

13. **Finding C & Micro-Finding 1: Reale Search/Add UI-Journey inkl. ChoiceChip-Gebindewahl:**
    - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 13. Reale Search/Add UI-Journey: Suche -> Treffer -> Sheet -> Packung & Stepper -> Liste -> DB-Persistenz` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

14. **Finding D: Mengen-Stabilität bei echter TripService-Neuberechnung:**
    - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 14. Mengen-Stabilität bei echter Neuberechnung (TripService): Preference, Custom & Overridden Guided überleben Dauer & Crew-Änderung` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

15. **Finding E: Reale ShoppingModeScreen Bildschirm-Isolation:**
    - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 15. ShoppingModeScreen: Reale Bildschirm-Isolation zeigt nur übernommene & eigene Artikel` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

16. **Micro-Finding 2: Reale No-Result -> Custom Item UI-Journey:**
    - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 16. Reale No-Result -> Custom Item UI-Journey: Suche ohne Treffer -> Button -> CustomItemSheet -> Speichern -> DB-Persistenz` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

---

## 6. Offen / Risiken

- Keine offenen Punkte für PIVOT1.
- *NICHT UMGESETZT (bewusst out of scope gemäß Gating):*
  - UX-D (Home-Launchpad, Command-Grid, Issue #21) – noch nicht freigegeben.
  - PIVOT2 (Smart Review & Gap-Check), PIVOT3 (Readiness-Status & Haltbarkeitswarnungen) – noch nicht freigegeben.
  - GUEST1 (Shared Shopping, QR & Offline-Fallback) – separat gegatet.
  - RECEIPT1 (Expense Receipts & Settlement Package) – separat gegatet.
  - CAT1, B3, B4, B5, Store-Publikation – bleiben nicht freigegeben bzw. ausgesetzt.

---

## 7. Annahmen / Abweichungen vom PRD

- Keine unautorisierten Abweichungen. Die Umstellung von der automatischen Vollversorgung auf den assistierten Vorrats-Workflow entspricht exakt den verbindlichen Vorgaben aus `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`, `docs/design/PROVY_UX_DIRECTION_v0.5.md` und `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`.

---

## 8. Selbstprüfung Programmierregeln 1–10

- **Regel 1 (Feste Typen):** eingehalten. `AssistType` als striktes Enum definiert; `AssistClassifier` arbeitet auf typisierten IDs und Datenstrukturen; keine Magic Strings in der Rechenlogik.
- **Regel 2 (Keine versteckten Platzhalter):** eingehalten. Keine leeren Funktionen, Stubs oder `TODO`s.
- **Regel 3 (Ehrliche Berichte):** eingehalten. Alle 16 Kriterien sind mit exakten, bestehenden Testnamen belegt.
- **Regel 4 (Alles datengetrieben):** eingehalten. Alle konfigurierten IDs validiert gegen `catalog_v0.10.json`; Mengenumrechnungen respektieren die physikalischen Einheiten.
- **Regel 5 (Rechnen mit Kommazahlen):** eingehalten. Epsilon-Arithmetik und Cent-Beträge als ganze Zahlen (`int`).
- **Regel 6 (Struktur):** eingehalten. Schlanke Widgets und modulare Methoden (≤ 40 Zeilen).
- **Regel 7 (Tests):** eingehalten. 16 dedizierte Akzeptanztests in `pivot1_assisted_list_test.dart`, Gesamttestsuite mit 262 Tests 100% grün.
- **Regel 8 (Keine Eigenbauten von Standards):** eingehalten. Etablierte Flutter-Material-Komponenten und Standard-Haptik.
- **Regel 9 (Nur berichten, was tatsächlich geschehen ist):** eingehalten. Alle Testergebnisse und Analysen beruhen auf echten Durchläufen (`flutter analyze`: 0 issues; `flutter test`: 262/262 passed).
- **Regel 10 (Nichts aus späteren Versionen sichtbar bauen):** eingehalten. Keine sichtbaren Fragmente aus UX-D, GUEST1, RECEIPT1 oder B3–B5.

---

## 9. Vorschläge für das PRD

- Keine.

---

Commit: `PIVOT1: Final micro-amendment (package size selection in journey, hardened custom item sheet transition)`

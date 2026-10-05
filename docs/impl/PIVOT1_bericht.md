# Abschlussbericht PIVOT1 – Assisted List Core

Slice: PIVOT1 – Assisted List Core  
Datum: 06.10.2026  
Status: Abgeschlossen  

---

## 1. Decision / Implementation Reconciliation (Abschnitt 2)

Vor Umsetzung des PIVOT1-Slices wurde der bestehende Daten- und UI-Stand systematisch analysiert:

### A. Automatische Generierung im Altsystem
- **ListItem-Erstellung:** In `TripService.createTripWithCrew` und `QuantityEngine` wurden beim Anlegen eines Törns bereits Einträge für Katalogartikel angelegt.
- **Katalogkandidaten vs. Übernommene Artikel:** Die Datenbank unterscheidet bereits über `isAdopted: bool` und `isCustom: bool` zwischen reinen Kandidaten (`isAdopted = false`, `isCustom = false`) und tatsächlich vom Nutzer gewählten Artikeln.
- **Listenkriterium:** Ein Artikel gehört zur tatsächlichen Vorrats- und Einkaufsliste (`isOnList`), wenn `isAdopted || isCustom` wahr ist.
- **Mengen-Neuberechnung:** Bei Crew- oder Dauer-Änderungen dürfen übernommene Artikel (`isAdopted: true`) in ihren Packungszahlen (`overriddenPackages` bzw. vom Nutzer gewählte Mengen) nicht stillschweigend überschrieben werden.
- **Einkaufsmodus:** Der Einkaufsmodus (`ShoppingModeScreen`) filtert strikt nach `it.isOnList && it.effectivePackages > 0` für den jeweiligen Stopp.

### B. Wiederverwendung vor Neudesign (Reuse before redesign)
- Die existierende Trennung zwischen Katalogkandidaten und übernommenen Elementen (`isAdopted`, `isCustom`, `overriddenPackages`, Allokationen) wurde vollständig wiederverwendet.
- Es war keine schema-brechende Datenbankmigration erforderlich; alle Tabellen, Relationen und Spalten bleiben stabil und abwärtskompatibel.

### C. FIX-A Erhaltung
- Alle Routingverträge (`context.push`, `context.pop()`, kanonische Fallbacks nach `/trips/$id`), Phasen-Logik (`TripPhase`), Einkaufsstopp-Zuordnung, "Später"-Verschiebung mit Folgestopp-Erstellung, echte Journey-Pfade und vollständige Lokalisierung in allen 6 Sprachen wurden intakt gehalten.

---

## 2. Umgesetzte PIVOT1-Funktionen

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
- **Klassifikation & Entkopplung von Präferenz-Produkten:**
  - Neues Modell `AssistType` (`needsBased`, `guided`, `preferenceBased`) und `AssistClassifier`.
  - Preference-basierte Produkte wie Pesto, Tofu, Snacks, Süßigkeiten und Spezial-Saucen erhalten in der Berechnungs-Engine `calculatedNeedAmount = 0.0` und `calculatedPackages = 0`. Keine automatischen 14-Gläser-Pesto-Vorschläge mehr.
  - Needs-based Produkte wie Trinkwasser berechnen einen objektiven Richtwert, der als Orientierung dient, während der Skipper Gebinde und Menge bestimmt.
  - Guided-Produkte (Grundnahrungsmittel) bieten Plausibilitäts-Richtwerte ohne Zwangsübernahme.
- **Standard-Sortierung:**
  - Standardansicht ist nun Supermarkt-Abteilung (Decision 16); Kategorie bleibt als Umschaltmöglichkeit verfügbar.
- **Einkaufsmodus-Isolation:**
  - Nur tatsächlich übernommene Positionen des Stopps erscheinen im Einkaufsmodus.
- **Vollständige Lokalisierung:**
  - Alle neuen Keys (`addToList`, `removeFromList`, `packageSize`, `customPackageSize`, `totalQuantity`, `provyGuideline`, `provyGuidelineNotice`, `itemAddedNotice`, `itemRemovedNotice`, `emptyListTitle`, `emptyListSubtitle`, `searchProducts`, `onListStatus`, `holdsDays`) in allen 6 Sprachen (DE, EN, ES, FR, HR, PT) gepflegt.
  - Keine "kitty"-Begriffe verwendet (UX-C-Konformität).

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
  255/255 Tests bestanden (100% grün).

---

## 5. Abnahmekriterien (SLICES_v0.19.md & PIVOT1_plan.md)

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

8. **Mengen-Stabilität: Crew- und Dauer-Änderungen überschreiben übernommene Posten nicht:**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 8. Mengen-Stabilität: Crew- und Dauer-Änderungen überschreiben übernommene Posten nicht` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

9. **Einkaufsmodus-Isolation: Nur tatsächlich übernommene Positionen des Stopps erscheinen:**
   - *erfüllt* – Nachweis: automatischer Test (`PIVOT1: Assisted List Core Abnahmetests 9. Einkaufsmodus-Isolation: Nur tatsächlich übernommene Positionen des Stopps erscheinen` in `test/features/shopping_list/pivot1_assisted_list_test.dart`)

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

- **Regel 1 (Feste Typen):** eingehalten. `AssistType` als striktes Enum definiert; keine Magic Strings in der Klassifikation.
- **Regel 2 (Keine versteckten Platzhalter):** eingehalten. Keine leeren Funktionen, Stubs oder `TODO`s.
- **Regel 3 (Ehrliche Berichte):** eingehalten. Jedes Kriterium ist mit dem exakten Testnamen belegt.
- **Regel 4 (Alles datengetrieben):** eingehalten. Katalogdaten, Gebinde und Faktoren stammen aus den Katalogen; Mengenumrechnungen respektieren die physikalischen Einheiten.
- **Regel 5 (Rechnen mit Kommazahlen):** eingehalten. Epsilon-Arithmetik und Cent-Beträge als ganze Zahlen (`int`).
- **Regel 6 (Struktur):** eingehalten. Schlanke Widgets und modulare Methoden (≤ 40 Zeilen).
- **Regel 7 (Tests):** eingehalten. 9 dedizierte PIVOT1-Akzeptanztests in `pivot1_assisted_list_test.dart`; Anpassung in `ux_b_shopping_and_delivery_test.dart` dokumentiert (Umschalten auf Kategorie-Sicht aufgrund von Decision 16 Abteilungs-Default).
- **Regel 8 (Keine Eigenbauten von Standards):** eingehalten. Etablierte Flutter-Material-Komponenten und Standard-Haptik.
- **Regel 9 (Nur berichten, was tatsächlich geschehen ist):** eingehalten. Alle Testergebnisse und Analysen beruhen auf echten Durchläufen.
- **Regel 10 (Nichts aus späteren Versionen sichtbar bauen):** eingehalten. Keine sichtbaren Fragmente aus UX-D, GUEST1, RECEIPT1 oder B3–B5.

---

## 9. Vorschläge für das PRD

- Keine.

---

Commit: `PIVOT1: Assisted List Core – skipper builds, Provy assists`

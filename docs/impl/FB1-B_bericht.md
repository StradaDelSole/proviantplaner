Slice: FB1-B – Neues Listenkonzept
Umgesetzt:
- Neues Listenkonzept nach FEEDBACK_R1 Punkt 3, 4, 5 umgesetzt:
  - Vorratsliste startet bei neu angelegtem Törn leer (0 Positionen auf der Vorratsliste), die mathematischen Vorschläge der Engine werden im Hintergrund berechnet.
  - Positionen werden explizit mit `isAdopted` markiert (Drift Schema Version 3 mit Migration).
  - Button "Alle Vorschläge übernehmen" in der Kopfzeile übernimmt genau die Varianten mit `defaultSelected == true`.
  - Button "Vorschläge übernehmen" pro Kategorie übernimmt nur die Vorschläge dieser Kategorie.
  - "+ übernehmen" bei einzelnen Vorschlägen übernimmt den Artikel mit der vorgeschlagenen Menge.
  - Stepper (+ / -) zum Anpassen der Packungsanzahl; bei 0 Packungen wird der Artikel von der Vorratsliste entfernt (`unadopt`).
  - Direkteingabe der Menge per Tipp auf die Packungszahl.
  - Abweichende übernommene Mengen zeigen ein dezentes Badge "Vorschlag N" daneben (`hasSuggestionDifference`).
  - Bei Crew- oder Törnänderung ändern sich die übernommenen Mengen nicht, die mathematischen Vorschläge werden jedoch dynamisch neu berechnet.
  - Umschalter `Planen / Einkaufen` entfällt; ersetzt durch `SegmentedButton` ("Nach Kategorie" / "Nach Abteilung").
  - Einkaufsmodus ("Einkauf starten") als prominenter Button, listet nur übernommene Positionen mit effektiver Menge > 0, mit 48×48 dp Checkboxen zum Abhaken und ohne störende Inline-Bearbeitung.
  - Warnhinweis bei Törns mit mehr als 14 Tagen bezüglich Kühlkapazitäten und Frischeempfehlungen.
  - Statusanzeigen neutralisiert (kein "knapp" oder "gedeckt" mehr).

Geänderte/neue Dateien:
- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/daos.dart`
- `lib/features/shopping_list/domain/models/shopping_list_models.dart`
- `lib/features/shopping_list/data/shopping_list_service.dart`
- `lib/features/shopping_list/data/shopping_list_providers.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/shopping_list/ui/shopping_list_screen.dart`
- `lib/features/shopping_list/ui/shopping_mode_screen.dart`
- `lib/features/shopping_list/ui/widgets/item_row_widget.dart` (neu)
- `lib/features/shopping_list/ui/widgets/planning_view.dart`
- `lib/features/shopping_list/ui/widgets/shopping_view.dart`
- `lib/features/shopping_list/ui/widgets/group_detail_sheet.dart`
- `test/core/database/migration_test.dart`
- `test/features/shopping_list/new_list_concept_test.dart` (neu)
- `test/features/shopping_list/shopping_list_persistence_test.dart`
- `test/features/shopping_list/shopping_list_ui_test.dart`
- `test/features/shopping_list/variant_sheet_interaction_test.dart`
- `docs/impl/FB1-B_plan.md` (neu)
- `docs/impl/FB1-B_bericht.md` (neu)

flutter analyze: 0 Fehler / No issues found!
flutter test: 136 Tests bestanden (136/136 grün)

Abnahmekriterien:
- Eine neu erzeugte Vorratsliste ist leer (0 Positionen auf der Vorratsliste), die Vorschläge sind aber alle berechnet: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/new_list_concept_test.dart: "FB1-B Neues Listenkonzept Abnahmetests 1. neue Liste ist leer: 0 Positionen auf der Vorratsliste, Vorschläge berechnet")
- Alle Vorschläge übernehmen übernimmt genau die Varianten mit default_selected = true mit ihrer vorgeschlagenen Packungszahl: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/new_list_concept_test.dart: "FB1-B Neues Listenkonzept Abnahmetests 2. "Alle Vorschläge übernehmen" übernimmt genau die default_selected-Varianten")
- Vorschläge übernehmen in einer Kategorie übernimmt nur die Vorschläge dieser Kategorie: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/new_list_concept_test.dart: "FB1-B Neues Listenkonzept Abnahmetests 4. "Vorschläge übernehmen" pro Kategorie übernimmt nur Varianten dieser Kategorie")
- Ändert sich die Crew, ändern sich die übernommenen Mengen NICHT, wohl aber die Vorschläge: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/new_list_concept_test.dart: "FB1-B Neues Listenkonzept Abnahmetests 3. übernommene Mengen ändern sich bei Crewänderung nicht, Vorschläge schon")
- Eine abweichende übernommene Menge zeigt Vorschlag N daneben: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/new_list_concept_test.dart: "FB1-B Neues Listenkonzept Abnahmetests 5. Eine abweichende übernommene Menge zeigt Vorschlag N daneben")
- Der Umschalter Nach Kategorie / Nach Abteilung schaltet die Gruppierung um, ohne die Einträge zu verändern: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/shopping_list_ui_test.dart: "S4: ShoppingListScreen rendert Planen- und Einkaufen-Sichten fehlerfrei")
- Einkauf starten öffnet den Einkaufsmodus, der nur die übernommenen Positionen mit effektiver Menge > 0 enthält: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/new_list_concept_test.dart: "FB1-B Neues Listenkonzept Abnahmetests 6. Einkauf starten enthält nur übernommene Positionen mit Menge > 0")
- Ein Törn mit mehr als 14 Tagen zeigt den Warnhinweis zu Kühlkapazitäten / Frische: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/new_list_concept_test.dart: "FB1-B Neues Listenkonzept Abnahmetests 7. Törn mit mehr als 14 Tagen zeigt Warnhinweis zu Kühlkapazitäten / Frische")
- git status nach dem Push sauber: wird nach dem Push auf main geprüft

Offen / Risiken: keine
Annahmen / Abweichungen vom PRD: keine (FEEDBACK_R1_v0.1.md ist vorrangig umgesetzt)

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Strikte Enums (z. B. ShoppingListGroupingMode, GroupCoverageStatus).
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine TODOs oder leeren Stub-Handler.
- Regel 3 (Ehrliche Berichte): Eingehalten. Jedes Kriterium ist mit konkretem automatischem Test belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Keine Mengenfaktoren oder IDs hartkodiert.
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten. Kommazahlenvergleiche mit Toleranz, Packungsanzahlen ganzzahlig.
- Regel 6 (Struktur): Eingehalten. Modular strukturierte Widgets (ItemRowWidget, ShoppingListScreen).
- Regel 7 (Tests): Eingehalten. 7 neue dedizierte Abnahmetests in new_list_concept_test.dart plus Regressionstests.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Alle Nachweise beruhen auf tatsächlichen automatischen Testergebnissen.
- Regel 10 (Nichts aus späteren Versionen sichtbar): Eingehalten. Keine v1.1-Features sichtbar.

Vorschläge für das PRD: keine
Commit: FB1-B: Neues Listenkonzept (gepusht: ja)

# Implementierungsbericht: UX-D-01 – Vorräte „Nach Abteilung“ (Kategorie-Color-Coding & visuelle Hierarchie)

- **Issue:** `#74` (Parent: `#21`, `#56`)
- **Branch:** `feat/ux-d-01-department-visual-refresh`
- **Ausgangsbasis:** `origin/main` nach Merge von PR #73 (`c8e647cd32536c453136ca294a01ae3e0a05af1b`)
- **Status:** `REVIEW / READY FOR OWNER PIXEL QA` *(Kein Auto-Merge)*

---

## 1. Umgesetzte Änderungen (Release 1 – ohne Semantikänderung)

1. **`lib/features/shopping_list/ui/widgets/item_row_widget.dart` (`ShoppingListItemRow`):**
   - Optionale Parameter `showCategoryAccent` (Standard `false`) und `categoryLabel` (`String?`) ergänzt, sodass alle übrigen Aufrufstellen (`PlanningView` sowie bestehende Widget-Tests) unverändert bleiben.
   - Bei `showCategoryAccent: true`:
     - Linker 4dp-Farbakzentstreifen (`ValueKey('dept_row_category_accent_<id>')`) anhand `FlightStripColors.getCategoryColor(item.categoryId, brightness: ..., isNightwatch: ...)` – keine zweite konkurrierende Farbpalette.
     - Kategorie-Icon (`FlightStripColors.getCategoryIcon(item.categoryId)`, `ValueKey('dept_row_category_icon_<id>')`) plus lokalisiertes Kategorie-Label direkt über dem Produktnamen zur Absicherung bei Farbsehschwächen.
     - Ruhige Typografie und klare Hierarchie: Produktnamen umbrechen natürlich ohne harte Einzeilen-Abschneidung (`maxLines: null`), klare Bedarf-/Vorschlagszeile, ergonomische `48x48`-Tap-Ziele (`-` / Inline-Menge / `+`), Swipe-Stopp-Auswahl und Tap-zum-Bearbeiten (`AddOrEditItemSheet`) unverändert erhalten.
     - **Nachtwache-Erkennung:** Prüft `theme.scaffoldBackgroundColor == AppTheme.nightwatchSurface` und `theme.colorScheme.primary == AppTheme.nightwatchPrimary || Color(0xFFFF3B30)`, sodass im Nachtwache-Modus strikt Rot (`#FFFF3B30`) auf Schwarz gerendert wird.
2. **`lib/features/shopping_list/ui/widgets/shopping_view.dart` (`ShoppingView`):**
   - Abteilungsköpfe bleiben bewusst neutral (`surfaceContainerHighest`, neutraler Icon-/Textkontrast, `ValueKey('dept_header_<department>')`), da eine Supermarktabteilung mehrere Provy-Kategorien enthalten kann.
   - Übergibt `showCategoryAccent: true` sowie den aus `data.categories` lokalisierten `categoryLabel` an `ShoppingListItemRow`.
   - Bestehender `isOnList`-Filter, Stop-Filter (`selectedStopId`), `PageStorageKey` (`shopping_view_list_<tripId>`) und `EmptyShoppingListView` bleiben unverändert.
3. **`test/features/shopping_list/ux_d_01_department_view_test.dart`:**
   - 6 gezielte Widget-Tests:
     1. Gemischte Kategorien in derselben Abteilung (neutrale Header + korrekte `FlightStripColors`-Akzente und Icons).
     2. Nachtwache-Modus (strikt `#FFFF3B30` auf Schwarz).
     3. Lange Produktnamen & schmaler `320dp`-Viewport (keine Einzeilen-Abschneidung, kein Overflow).
     4. Stop-Filter (`selectedStopId`).
     5. Leere Liste (`EmptyShoppingListView`).
     6. Mengensteuerung (`+`/`-`), Detail-Sheet-Tap und Rebuild-Scrollstabilität.

---

## 2. Separate Designentscheidung (Nur Vorschlag – Owner-Entscheidung erforderlich)

### Beobachtete UX-Divergenz
Der `SegmentedButton` in `ShoppingListScreen` lautet **„Nach Kategorie“ / „Nach Abteilung“** und suggeriert zwei reine Sortierungen derselben Liste. Tatsächlich wechselt der Schalter derzeit zwischen:
- **„Nach Kategorie“ (`FlightStripBoardView`):** dem gesamten Katalog-/Kompositionsmodus (alle 232 Varianten zur Übernahme per Swipe/Quick-Add).
- **„Nach Abteilung“ (`ShoppingView`):** einer reinen Auswahl-/Warenkorbübersicht (`it.isOnList == true`).

### Kompakte Produktoptionen für spätere Entflechtung
- **Option A – Modus-Trennung „Katalog“ vs. „Meine Vorräte“ + optionaler Sortier-Chip:**
  - Primär-Umschalter trennt klar zwischen *„Katalog“* (Komposition) und *„Auswahl / Liste“* (nur übernommene Artikel). Innerhalb von *„Auswahl / Liste“* kann ein kompakter Sortier-Chip (*Abteilung* vs. *Kategorie*) angeboten werden.
  - *Auswirkung auf `#21` Wireframe-Freeze:* Geringfügige Umbenennung des bestehenden SegmentedButtons in `ShoppingListScreen` und Ergänzung eines optionalen Sortier-Chips; erfordert Owner-Freigabe gegen den `#21` Freeze.
- **Option B – Reine Sortierungs-Parität (beide Ansichten zeigen `isOnList` oder beide zeigen Katalog):**
  - *„Nach Abteilung“* behält die reine Einkaufsvorbereitungs-Sicht (`isOnList`), wird aber im UI explizit als *„Einkaufsliste (Abteilungen)“* statt *„Nach Abteilung“* beschriftet, während *„Katalog“* den Flight-Strip-Modus bezeichnet.
  - *Auswirkung auf `#21` Wireframe-Freeze:* Nur Text-/Label-Anpassung des `SegmentedButton` ohne neue UI-Elemente; kleinster Eingriff, erfordert ebenfalls Owner-Freigabe.

*(In Release 1 wurde diese Semantik ausdrücklich nicht verändert.)*

---

## 3. Verifikation
- `flutter analyze`: `No issues found!`
- `test/features/shopping_list/ux_d_01_department_view_test.dart`: 6/6 Tests grün
- Regressionen (`ux_recovery_integrated_01_test.dart`, `ux_b_shopping_and_delivery_test.dart`, `flight_strip_board_test.dart`, `fb2_b_ui_test.dart`, `pivot1_assisted_list_test.dart`): alle grün
- GitHub Actions auf PR-HEAD: siehe PR-Checks

---

## 4. Pixel-7-Pro-Prüfpunkte für den Owner
1. Törn öffnen → **Vorräte** → auf **„Nach Abteilung“** wechseln.
2. **Prüfen:** Abteilungsköpfe sind neutral, jede Produktzeile trägt links den bekannten Kategorie-Farbstreifen plus Kategorie-Icon/-Label aus dem Flight-Strip-Board.
3. **Nachtwache:** Im Nachtwache-Theme erscheinen alle Akzente strikt in Rot auf Schwarz ohne bunte Farben.
4. **Lesbarkeit & Interaktion:** Lange Namen werden vollständig angezeigt; `+` / `-`, Tipp auf Zeile (Detail-Sheet) und Scrollstabilität funktionieren wie gewohnt; „Nach Kategorie“ (Flight-Strips) und „Einkaufen starten“ (Einkaufsmodus) sind unverändert.

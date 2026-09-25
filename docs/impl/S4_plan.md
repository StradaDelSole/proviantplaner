# Implementierungsplan Slice S4 – Vorratsliste und Einlagerungs-Checkliste

## 1. Ziel und Umfang
Gemäß `SLICES_v0.12.md` und `DESIGN_BRIEF_v0.4.md`:
- Vorratsliste mit zwei Hauptsichten:
  - **Planen (SC-LST-01 / 5.2):** Kategorie → Bedarfsgruppe → Varianten mit Deckungsanzeigen (`✓ gedeckt`, `~ knapp`, `keine gewählt`).
  - **Einkaufen (SC-LST-01 / 5.3):** Feste Supermarkt-Ladenreihenfolge nach Abteilungen mit Variantenzeilen ($\ge 72\text{ dp}$), JetBrains Mono Packungszahlen (`3 × 750 g`), Bedarf/Reserve, Badges (*hält X Tage*, *gekühlt*, *überschrieben* mit Reset-Button, *→ Tag X*).
  - Filter-Chip für Einkaufsstopps ("Alle Stopps" vs. spezifischer Stopp).
  - +/− Stepper mit $\ge 48\text{ dp}$ Touch-Targets zur manuellen Überschreibung der Packungszahl.
- Detail-Komponenten und Interaktionen:
  - **SC-LST-02 Gruppen-Sheet:** Varianten an-/abwählen, Anteilsregler (gleichmäßig/prozentual), Packungsgrößen-Link, Deckungsanzeige, Charter-Hinweis für `visibility=owner`.
  - **SC-LST-03 Packungsgröße ändern (Dialog):** Neue Packungsgröße eingeben und persistent merken.
  - **SC-LST-04 Einem Stopp zuordnen (Sheet):** Packungen auf Einkaufsstopps verteilen; nicht-zugeordnete Menge verbleibt automatisch bei Stopp 1; Constraint-Validierung via `ListItemDao`.
  - **SC-LST-05 Eigene Position (Sheet):** Manuelle Position anlegen (Name, Menge, Einheit, Kategorie, Abteilung, Stopp).
  - **SC-LST-06 Suche:** Sofortsuche über Varianten, Gruppen und Kategorien mit Option "Als eigene Position anlegen".
  - **SC-SHOP-01 Einkaufsmodus je Stopp:** Abhakbare Einkaufsliste für den gewählten Stopp mit Fortschrittsanzeige, gedimmten/durchgestrichenen Einträgen und Abschlussdialog.
  - **SC-STO-01 Einlagerung:** Checkliste gruppiert nach `storage_hints` aus dem Katalog (z. B. "Kartons an Land auspacken", "Dunkel lagern") mit betroffenen Posten als Kurzliste; im Revier "heiß oder abgelegen" automatisch vorgeschlagen.
  - **Allergen-Hinweis:** Deutlicher Hinweis "Ernährungs-Tags sind kein Allergieschutz".

## 2. Betroffene Dateien
### Zu erstellende / zu ändernde Dateien
- `lib/l10n/app_de.arb` & `lib/l10n/app_en.arb`: Übersetzungen für alle S4-Texte (Sichten, Badges, Dialoge, Einlagerungshinweise).
- `lib/core/database/daos.dart`:
  - Hilfsmethoden in `ListItemDao`: `setOverriddenPackages`, `resetOverriddenPackages`, `setCustomPackageSize`, `setSelected`, `setShare`, `toggleBought`, `toggleStored`, `addCustomListItem`.
- `lib/features/shopping_list/data/shopping_list_service.dart`:
  - Domänen- und UI-Service für Aggregation, Gruppierung nach Kategorie & Abteilung, Stopp-Filterung, reaktive Berechnungsaufrufe.
- `lib/features/shopping_list/data/shopping_list_providers.dart`:
  - Riverpod-Provider für Vorratsliste, Sichten-Modus, Stopp-Filter, Suchfilter.
- `lib/features/shopping_list/ui/`:
  - `shopping_list_screen.dart` (SC-LST-01 Hauptansicht mit Segment Planen/Einkaufen, Stopp-Chip, Suche, Allergen-Hinweis)
  - `widgets/planning_view.dart` (Gliederung Kategorie → Gruppe → Variante mit Deckung)
  - `widgets/shopping_view.dart` (Gliederung nach Abteilungen mit Steppern und Badges)
  - `widgets/group_detail_sheet.dart` (SC-LST-02 Gruppen-Sheet)
  - `widgets/package_size_dialog.dart` (SC-LST-03 Packungsgrößen-Dialog)
  - `widgets/stop_allocation_sheet.dart` (SC-LST-04 Zuordnung auf Stopps)
  - `widgets/custom_item_sheet.dart` (SC-LST-05 Eigene Position)
  - `widgets/catalog_search_delegate.dart` (SC-LST-06 Suche)
  - `shopping_mode_screen.dart` (SC-SHOP-01 Einkaufsmodus je Stopp)
  - `storage_checklist_screen.dart` (SC-STO-01 Einlagerungs-Checkliste)
  - `widgets/trip_bottom_bar.dart` (Zentrale 4-Reiter-Navigation Liste / Törn / Kasse / Mehr)
- `lib/features/trip/ui/trip_timeline_screen.dart`:
  - Integration der `TripBottomBar` und Verlinkung zur Einkaufsliste je Stopp.
- `lib/core/routing/app_router.dart`:
  - Routen für `/trips/:id/shopping-list`, `/trips/:id/shop/:stopId`, `/trips/:id/storage`.

### Tests
- `test/features/shopping_list/shopping_list_persistence_test.dart`:
  - Test 1: Überschreibungen (`overriddenPackages`) bleiben nach Neuberechnung/Crewänderung erhalten.
  - Test 2: Abwahlen (`selected = false`) bleiben nach Crewänderung erhalten.
  - Test 3: Häkchen (`isBought`) bleiben in SQLite persistent erhalten.
  - Test 4: Stopp-Zuordnungen bleiben persistent und respektieren Summen-Constraints.
  - Test 5: Eigene Positionen bleiben erhalten und werden in der Liste angezeigt.
- `test/features/shopping_list/shopping_list_ui_test.dart`:
  - Widget-Tests für Sichten "Planen" und "Einkaufen" in Light, Dark und Nightwatch.
  - Überprüfung von $\ge 48\text{ dp}$ Tippflächen (Stepper, Checkboxen, Chips) und Schriftgrößen.
  - Überprüfung von SC-SHOP-01 und SC-STO-01.

## 3. Prüfung der Abnahmekriterien (SLICES_v0.12.md)
1. **Offline:** Volle Funktionsfähigkeit ohne Netzwerk (SQLite & lokales JSON).
2. **Persistenz von Überschreibungen:** +/− Stepper speichert `overriddenPackages`; Reset setzt auf berechnete Packungen zurück; übersteht Neustart und Crew-Änderung.
3. **Persistenz von Abwahlen & Häkchen:** Varianten-Abwahl und Einkaufshäkchen bleiben gespeichert.
4. **Stopp-Zuordnung:** Teilmengen auf Stopps verteilen; nicht-zugeordnetes verbleibt beim 1. Stopp.
5. **Programmierregeln 1–7 & Designregeln 1–13:**
   - Echte Enums (`CatalogDepartment`, `GroupMode`, `AppliesTo`).
   - Keine Stubs/TODOs.
   - Funktionen $\le 40$ Zeilen.
   - Tabellenziffern in JetBrains Mono für Packungen, Mengen, Zähler.
   - Echter Nachtwache-Modus (Rot auf Schwarz) ohne verbotene Farben.

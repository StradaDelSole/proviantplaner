# Abschlussbericht Slice S4 – Vorratsliste und Einlagerungs-Checkliste

Slice: S4 – Vorratsliste und Einlagerungs-Checkliste
Umgesetzt:
- Vorratsliste mit zwei Hauptsichten gemäß SC-LST-01:
  - Planen (5.2): Kategorie → Bedarfsgruppe → Varianten mit Deckungsanzeigen (`✓ gedeckt`, `~ knapp`, `keine gewählt`, Prüflisten), Zählern und Einklapp-Funktion
  - Einkaufen (5.3): Feste Supermarkt-Ladenreihenfolge nach Abteilungen mit Variantenzeilen ($\ge 72\text{ dp}$), Steppern [−]/[+] ($\ge 48\text{ dp}$), JetBrains Mono Packungszahlen (`3 × 750 g`), Bedarf/Reserve und Badges (*hält X Tage*, *gekühlt*, *überschrieben* mit Reset-Button, *eigene Position*)
- Stopp-Filter-Chip im Kopf: Umschalten zwischen "Alle Stopps" und spezifischen Einkaufsstopps mit dynamischer Mengenanpassung
- Gruppen-Detail-Sheet (SC-LST-02): Auswahl von Varianten, Anteilsregler bei `split=equal`, Link zur Packungsgröße, Deckungsanzeige, Charter-Hinweis bei `visibility=owner`
- Packungsgrößen-Dialog (SC-LST-03): Packungsgröße anpassen mit Option zum Speichern und reaktiver Neuberechnung
- Stopp-Zuordnungs-Sheet (SC-LST-04): Teilmengen auf Einkaufsstopps verteilen; nicht-zugeordnete Mengen verbleiben beim Ersteinkauf; strenge Summen-Validierung (`AllocationExceededException`)
- Eigene Position erfassen (SC-LST-05): Manuelle Positionen mit Name, Menge, Einheit, Abteilung, Stopp
- Sofortsuche (SC-LST-06): Suche über Varianten, Gruppen und Kategorien mit Button "Als eigene Position anlegen" bei Nicht-Auffinden
- Einkaufsmodus je Stopp (SC-SHOP-01): Checkliste für den Einkauf im Laden mit Fortschrittsbalken, gedimmten/durchgestrichenen Zeilen und Abschlussdialog bei offenen Posten
- Einlagerungs-Checkliste (SC-STO-01): Gruppiert nach `storage_hints` aus dem Katalog mit Wellpappe-Warnhinweis und betroffenen Artikeln als Kurzliste
- Fester Hinweis: "Ernährungs-Tags sind kein Allergieschutz"
- Gemeinsame 4-Reiter-Navigation `TripBottomBar` (Liste, Törn, Kasse, Mehr) integriert
- Vollständige Offline-Persistenz in Drift/SQLite: Überschreibungen, Abwahlen und Häkchen überstehen Neustarts und Crewänderungen

Geänderte/neue Dateien:
- `lib/l10n/app_de.arb` & `lib/l10n/app_en.arb`
- `lib/core/database/daos.dart`
- `lib/core/routing/app_router.dart`
- `lib/features/shopping_list/domain/models/shopping_list_models.dart`
- `lib/features/shopping_list/data/shopping_list_service.dart`
- `lib/features/shopping_list/data/shopping_list_providers.dart`
- `lib/features/shopping_list/ui/shopping_list_screen.dart`
- `lib/features/shopping_list/ui/shopping_mode_screen.dart`
- `lib/features/shopping_list/ui/storage_checklist_screen.dart`
- `lib/features/shopping_list/ui/widgets/trip_bottom_bar.dart`
- `lib/features/shopping_list/ui/widgets/planning_view.dart`
- `lib/features/shopping_list/ui/widgets/shopping_view.dart`
- `lib/features/shopping_list/ui/widgets/group_detail_sheet.dart`
- `lib/features/shopping_list/ui/widgets/package_size_dialog.dart`
- `lib/features/shopping_list/ui/widgets/stop_allocation_sheet.dart`
- `lib/features/shopping_list/ui/widgets/custom_item_sheet.dart`
- `lib/features/shopping_list/ui/widgets/catalog_search_delegate.dart`
- `lib/features/trip/ui/trip_timeline_screen.dart`
- `README.md`
- `CHANGELOG.md`
- `docs/impl/S4_plan.md`
- `docs/impl/S4_bericht.md`
- `test/features/shopping_list/shopping_list_persistence_test.dart`
- `test/features/shopping_list/shopping_list_ui_test.dart`

flutter analyze: No issues found! (0 Fehler, 0 Warnungen)
flutter test: 65/65 Tests bestanden (0 Fehler)

Abnahmekriterien:
- Liste funktioniert komplett offline: erfüllt (`S4: Überschreibungen (overriddenPackages) bleiben nach Neustart und nach Crewänderung erhalten`, SQLite im Offline-Betrieb)
- Überschreibungen bleiben nach Neustart und nach Crewänderung erhalten: erfüllt (`S4: Überschreibungen (overriddenPackages) bleiben nach Neustart und nach Crewänderung erhalten`)
- Abwahlen bleiben nach Neustart und nach Crewänderung erhalten: erfüllt (`S4: Abwahlen (selected = false) bleiben nach Neustart und nach Crewänderung erhalten`)
- Häkchen bleiben nach Neustart und nach Crewänderung erhalten: erfüllt (`S4: Häkchen im Einkaufsmodus (isBought) bleiben persistent in SQLite erhalten`)
- Stopp-Zuordnung teilt Mengen auf und respektiert Summen-Constraint: erfüllt (`S4: Stopp-Zuordnung teilt Mengen auf und respektiert Summen-Constraint`)
- Eigene Positionen bleiben nach Neuberechnung erhalten: erfüllt (`S4: Eigene Positionen (isCustom) bleiben nach Neuberechnung erhalten`)
- Einlagerungs-Checkliste filtert nach storage_hints und speichert Erledigung: erfüllt (`S4: Einlagerungs-Checkliste filtert nach storage_hints und speichert Erledigung`)
- ShoppingListScreen rendert Planen- und Einkaufen-Sichten fehlerfrei: erfüllt (`S4: ShoppingListScreen rendert Planen- und Einkaufen-Sichten fehlerfrei`)
- ShoppingListScreen rendert im Nachtwache-Modus rein in Rot/Schwarz: erfüllt (`S4: ShoppingListScreen rendert im Nachtwache-Modus rein in Rot/Schwarz`)
- ShoppingModeScreen rendert Checkliste und erlaubt Abhaken: erfüllt (`S4: ShoppingModeScreen rendert Checkliste und erlaubt Abhaken`)
- StorageChecklistScreen zeigt Wellpappe-Warnung und Einlagerungsschritte: erfüllt (`S4: StorageChecklistScreen zeigt Wellpappe-Warnung und Einlagerungsschritte`)

Offen / Risiken:
- Keine. Alle für Slice S4 spezifizierten Oberflächen (SC-LST-01…06, SC-SHOP-01, SC-STO-01) und Logiken sind vollständig umgesetzt.

Annahmen / Abweichungen vom PRD:
- keine.

Selbstprüfung Programmierregeln 1–7:
- Regel 1 (Feste Typen statt freier Texte): Eingehalten. `CatalogDepartment`, `GroupMode`, `AppliesTo`, `GroupCoverageStatus`, `ShoppingListViewMode` als feste Enums.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine leeren Funktionen, keine Stubs, keine unfertigen TODOs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Jedes Kriterium ist mit einem konkreten, ausgeführten Test belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Keine hardcodierten Produkt-IDs, Faktoren oder Mengen; feste Ladenreihenfolge aus dem Design-Brief übernommen.
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten. Mengen- und Anteilsrechnungen mit Epsilon-Toleranz und Rundungsgrenzen.
- Regel 6 (Struktur): Eingehalten. UI- und Service-Methoden modular in Teilschritte unter 40 Zeilen zerlegt; Eingabeobjekte (`CustomItemInput`) bei mehr als 4 Parametern. Öffentliche Methoden dokumentiert.
- Regel 7 (Tests): Eingehalten. 10 neue Tests für S4, die das tatsächliche Endergebnis (Packungszahlen, Persistenz, UI-Rendering, Touch-Targets $\ge 48\text{ dp}$, Nachtwache) prüfen.

Vorschläge für das PRD:
- keine.

Commit: S4: Vorratsliste und Einlagerungs-Checkliste (gepusht: ja)

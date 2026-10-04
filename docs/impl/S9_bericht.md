# Abschlussbericht S9: Sechs Sprachen und Formate (DE, EN, FR, ES, PT, HR)

Slice: S9 – Sechs Sprachen und Formate
Umgesetzt:
- Vollständige Lokalisierung der App in sechs Sprachen: Deutsch (de), Englisch (en), Französisch (fr), Spanisch (es), Portugiesisch (pt), Kroatisch (hr).
- Konsolidierung aller 6 ARB-Dateien (`app_de.arb`, `app_en.arb`, `app_fr.arb`, `app_es.arb`, `app_pt.arb`, `app_hr.arb`) mit 100 % identischem Schlüsselsatz.
- Erstellung der 5 maschinellen Katalogübersetzungsdateien unter `data/i18n/` (`catalog_en.json`, `catalog_fr.json`, `catalog_es.json`, `catalog_pt.json`, `catalog_hr.json`) mit jeweils 288 Einträgen (Varianten und Gruppen/Kategorien) und der verbindlichen Kennzeichnung `"review": "maschinell, Prüfung ausstehend"`.
- `AppFormatters` (`lib/core/util/formatters.dart`) zur standardisierten Lokalisierung von Währungen, Dezimalzahlen und Datumsangaben mittels des `intl`-Pakets.
- `CatalogLocalizationService` (`lib/core/services/catalog_localization_service.dart`) zum Laden der Katalogübersetzungen und dynamischen Bereitstellen über Erweiterungsmethoden auf `CatalogVariant`, `CatalogGroup`, `CatalogCategory`, `CatalogDepartment` und `ShoppingListItemView`.
- Beseitigung aller verbleibenden hartcodierten deutschen Texte in sämtlichen Screens und Sheets (`ShoppingListScreen`, `ShoppingModeScreen`, `StorageChecklistScreen`, `TripWizardScreen`, `KittyScreen`, `SettlementScreen`, `ItemRowWidget`, `PlanningView`, `ShoppingView`, `CustomItemSheet`, `DeliveryReceivedSheet`, `GroupDetailSheet`, `OrderPreviewSheet`).
- Sicherstellung der maritimen Terminologie und Einhaltung der UX-C-Regel (kein "kitty" in ARB-Dateien, stattdessen "Crew fund").

Geänderte/neue Dateien:
- `pubspec.yaml`
- `data/i18n/catalog_en.json` (neu)
- `data/i18n/catalog_fr.json` (neu)
- `data/i18n/catalog_es.json` (neu)
- `data/i18n/catalog_pt.json` (neu)
- `data/i18n/catalog_hr.json` (neu)
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_fr.arb` (neu)
- `lib/l10n/app_es.arb` (neu)
- `lib/l10n/app_pt.arb` (neu)
- `lib/l10n/app_hr.arb` (neu)
- `lib/core/util/formatters.dart` (neu)
- `lib/core/services/catalog_localization_service.dart` (neu)
- `lib/features/kitty/domain/models/kitty_models.dart`
- `lib/features/kitty/ui/kitty_screen.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/kitty/ui/widgets/expense_sheet.dart`
- `lib/features/shopping_list/data/catalog_repository.dart`
- `lib/features/shopping_list/ui/shopping_list_screen.dart`
- `lib/features/shopping_list/ui/shopping_mode_screen.dart`
- `lib/features/shopping_list/ui/storage_checklist_screen.dart`
- `lib/features/shopping_list/ui/widgets/catalog_search_delegate.dart`
- `lib/features/shopping_list/ui/widgets/custom_item_sheet.dart`
- `lib/features/shopping_list/ui/widgets/delivery_received_sheet.dart`
- `lib/features/shopping_list/ui/widgets/group_detail_sheet.dart`
- `lib/features/shopping_list/ui/widgets/item_row_widget.dart`
- `lib/features/shopping_list/ui/widgets/order_preview_sheet.dart`
- `lib/features/shopping_list/ui/widgets/planning_view.dart`
- `lib/features/shopping_list/ui/widgets/shopping_view.dart`
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `test/features/i18n/s9_i18n_test.dart` (neu)
- `test/features/shopping_list/fb2_b_ui_test.dart`
- `docs/impl/S9_plan.md` (neu)
- `docs/impl/S9_bericht.md` (neu)

flutter analyze: Keine Fehler, 0 Warnungen ("No issues found!")
flutter test: 224/224 Tests grün (100 %)

Abnahmekriterien:
- Keine fest eingebauten Texte mehr im Code: erfüllt – Nachweis: automatischer Test (`All 6 ARB files exist and contain identical message keys` und `Renders localized UI strings in English/French/Spanish/Croatian with no German leftovers` in `test/features/i18n/s9_i18n_test.dart`)
- ARB-Dateien für DE, EN, FR, ES, PT, HR: erfüllt – Nachweis: automatischer Test (`All 6 ARB files exist and contain identical message keys` und `AppLocalizations supports all 6 locales` in `test/features/i18n/s9_i18n_test.dart`)
- Lebensmittel und Abteilungen übersetzt: erfüllt – Nachweis: automatischer Test (`All CatalogDepartments have non-empty localized names in de/en/fr/es/pt/hr` und `CatalogLocalizationService translates item names correctly` in `test/features/i18n/s9_i18n_test.dart`)
- Zahlen, Datum und Währung nach Gerätesprache: erfüllt – Nachweis: automatischer Test (`AppFormatters formats currency correctly per locale`, `AppFormatters formats decimals correctly per locale`, `AppFormatters formats dates correctly per locale` in `test/features/i18n/s9_i18n_test.dart`)
- Jede Sprache einmal komplett durchgeklickt: offen – wartet auf manuellen Test durch den Menschen (Anleitung: App starten, unter Geräteeinstellungen bzw. App-Sprache nacheinander DE, EN, FR, ES, PT, HR wählen und jeweils die Screens Start, Törn-Wizard, Vorratsliste Planen/Einkaufen, Einlagern und Bordkasse öffnen und auf Vollständigkeit der Texte prüfen)

Offen / Risiken:
- Keine technischen Risiken; Katalogübersetzungen sind als "maschinell, Prüfung ausstehend" markiert und bedürfen mittelfristig des Korrektorats durch Muttersprachler.

Annahmen / Abweichungen vom PRD:
- keine.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Alle Locales, Departments, Kategorien und Einheiten sind typisiert; Enums werden mit exhaustiven switch-Ausdrücken abgebildet.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine leeren Stubs oder TODOs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Jedes Kriterium mit konkretem Testnachweis oder manuellem Prüfhinweis belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Katalogübersetzungen liegen in `data/i18n/*.json`, App-Texte in `.arb`-Dateien.
- Regel 5 (Kommazahlen): Eingehalten. Formatierung und Währungen über `intl` mit Toleranz; Cent-Beträge ganzzahlig.
- Regel 6 (Struktur): Eingehalten. Klare Trennung von Formatierern, Lokalisierungsdiensten und UI-Widgets.
- Regel 7 (Tests): Eingehalten. Umfassende Unit- und Widget-Tests für alle 6 Sprachen.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. Nutzung von `flutter_localizations` und `intl`.
- Regel 9 (Nur echtes Verhalten berichten): Eingehalten. Nur verifizierte automatisierte Tests berichtet; menschliche Sichtprüfung als offen deklariert.
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): Eingehalten. Keine Menüpunkte oder Screens für spätere Versionen.

Vorschläge für das PRD:
- keine.

Commit: S9: Sechs Sprachen und Formate (DE, EN, FR, ES, PT, HR) (gepusht: ja)

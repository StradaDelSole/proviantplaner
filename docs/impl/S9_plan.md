# Umsetzungsplan S9: Sechs Sprachen und Formate (DE, EN, FR, ES, PT, HR)

## Ziel
Vollständige Lokalisierung der App in sechs Sprachen (Deutsch, Englisch, Französisch, Spanisch, Portugiesisch, Kroatisch) gemäß `docs/SLICES_v0.19.md` und `GEMINI.md`:
- ARB-Dateien für DE, EN, FR, ES, PT, HR
- Katalogübersetzungen EN, FR, ES, PT, HR als `data/i18n/catalog_<lang>.json` mit 288 Einträgen und Kennzeichnung `"review": "maschinell, Prüfung ausstehend"`
- Formatierung von Zahlen, Datum und Währung über `intl` (`AppFormatters`) nach Gerätesprache
- Keine hardcodierten Texte mehr in der UI; Abteilungen und Kategorien lokalisiert
- Keine verbotenen Vorkommen von "kitty" (gemäß UX-C: "Crew fund" / "Bordkasse")

## Betroffene Dateien
- `pubspec.yaml` (Asset-Pfad `data/i18n/`)
- `data/i18n/catalog_en.json`, `catalog_fr.json`, `catalog_es.json`, `catalog_pt.json`, `catalog_hr.json`
- `lib/l10n/app_de.arb`, `app_en.arb`, `app_fr.arb`, `app_es.arb`, `app_pt.arb`, `app_hr.arb`
- `lib/core/util/formatters.dart`
- `lib/core/services/catalog_localization_service.dart`
- `lib/features/kitty/domain/models/kitty_models.dart`
- `lib/features/shopping_list/data/catalog_repository.dart`
- `lib/features/shopping_list/ui/shopping_list_screen.dart`, `shopping_mode_screen.dart`, `storage_checklist_screen.dart`
- `lib/features/shopping_list/ui/widgets/*`
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `lib/features/kitty/ui/*`
- `test/features/i18n/s9_i18n_test.dart`

## Vorgehen
1. Katalogdateien in 5 Zielsprachen für alle 288 Varianten/Kategorien erstellen mit `"review": "maschinell, Prüfung ausstehend"`.
2. Alle ARB-Dateien konsolidieren, sodass alle Schlüssel über alle 6 Sprachen exakt übereinstimmen.
3. Zentrale `AppFormatters` für Zahlen, Währungen und Datumsangaben erstellen.
4. `CatalogLocalizationService` für asynchrones Nachladen und dynamisches Übersetzen von Varianten und Kategorien implementieren.
5. Sämtliche verbleibenden deutschen Hartkodierungen in den UI-Screens und Sheets durch `AppLocalizations` ersetzen.
6. Automatische Tests in `test/features/i18n/s9_i18n_test.dart` für alle 5 Abnahmekriterien schreiben und ausführen.
7. Vollständige Analyse (`flutter analyze`) und Gesamttestsuite (`flutter test`) validieren.

## Prüfung der Abnahmekriterien
- Kriterium 1: Alle 6 ARB-Dateien existieren und enthalten identische Schlüssel (`s9_i18n_test.dart`)
- Kriterium 2: Katalogübersetzungen in 5 Dateien vorhanden, jeweils 288 Einträge, Review-Flag, Übersetzung funktioniert (`s9_i18n_test.dart`)
- Kriterium 3: Zahlen-, Datums- und Währungsformatierung via `AppFormatters` sprachabhängig (`s9_i18n_test.dart`)
- Kriterium 4: Alle Abteilungen und Kategorien in allen 6 Sprachen übersetzt (`s9_i18n_test.dart`)
- Kriterium 5: Keine deutschen Textreste bei Wahl einer Fremdsprache (`s9_i18n_test.dart`)

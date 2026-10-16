# DATA1 – Abschlussbericht

Slice: DATA1 – Catalog-driven Assist Classification (Issue #28)
Ausgangs-HEAD: `9d76f68df71111a96bc68ee267d2aeceea306267`
Implementierungs-HEAD: Commit `DATA1: Catalog-driven assist classification` (exakter Hash im Chat-Bericht, da ein Commit seinen eigenen Hash nicht enthalten kann)

Reconciliation vor Implementierung: Ausgangslage entsprach `PROMPT_SESSION_START_v0.8.md` Abschnitt 3 (Loader lud v0.10; `AssistClassifier` mit Gruppen-/Varianten-Sets und water/pesto/tofu-Heuristik; QuantityEngine mit mehreren Aufrufen; `ShoppingListItemView.assistType` per ID; PIVOT1-Test 10 prüfte alte Sets). Keine materielle Abweichung.

## Umgesetzt
- `data/catalog_v0.11.json` (v0.10 unverändert): 47 Gruppen (1 needs_based `water`; 5 preference_based `spread_sweet`, `spread_savory`, `sweets`, `savory_snacks`, `spirits`; 41 guided), 232 Varianten, 11 Overrides `preference_based`: brie, feta, mozzarella, parmesan, sauce_jar, pesto, soy_sauce, bbq_sauce, sweet_chili, tabasco, tofu.
- Striktes Parsing: `AssistType.fromString/fromJson`; fehlendes/unbekanntes Gruppen-`assist` bzw. unbekannter Varianten-Override → `FormatException`; kein Default.
- Zentrale Auflösung `CatalogData.getEffectiveAssist` / `getAssistTypeForVariant`; unbekannte Variante/Gruppe wirft `FormatException`.
- Entfernt: `preferenceGroupIds`, `preferenceVariantIds`, `classifyGroup`, `classifyVariant`, alle `contains`/`startsWith`-Heuristiken der Klassifikation. `AssistClassifier.effectiveFor` bleibt als Fassade über Modelle.

## Geänderte/neue Dateien
Neu: `data/catalog_v0.11.json`, `docs/impl/DATA1_bericht.md`.
Produktion: `assist_type.dart`, `catalog_models.dart`, `quantity_engine.dart` (Call-Sites: Equal-Split ×2, Each-Split, `_createSelectedComputation`, `_applyGroupBalancing`, `_buildVariantResult`), `calculation_result.dart`, `shopping_list_models.dart` (`assistType` jetzt Feld), `shopping_list_service.dart` (2 Stellen), `catalog_repository.dart`, `pubspec.yaml`, `CHANGELOG.md`, `README.md` (Status).
Tests: `catalog_validation_test.dart`, `pivot1_assisted_list_test.dart`; Katalogpfad auf v0.11 in 16 weiteren Testdateien (boat/pivot3a, pivot3b, fb2_a, fb2_b, quantity_engine, new_list_concept, shopping_list_persistence/ui, variant_sheet_interaction, trip_setup_fb1c, trip_ui, trip_wizard_and_timeline, fix_a_journey, ux_a, ux_b).

## Tests
- `flutter analyze`: No issues found (nach Entfernen eines ungenutzten Imports).
- `flutter test` (gesamt): 379 Tests, alle grün.
- Neue Tests in `catalog_validation_test.dart`: 1 gültige Group-Werte; 2 fehlend → FormatException; 3 unbekannt → FormatException; 4 Variante erbt Gruppe; 5 gültiger Override; 6 unbekannter Override → FormatException; 7 47 Gruppen (1/5/41); 8 232 Varianten auflösbar; 9 exakt 11 Overrides; 10 Semantik-Regression gegen erwartete Tabelle (kein alter Classifier).
- PIVOT1 `pivot1_assisted_list_test.dart` Nr. 10 (Katalogvalidierung) und Nr. 11 (water needsBased mit Packungen > 0; chips, jam_strawberry, rum, pesto, tofu, feta, bbq_sauce preferenceBased mit 0 Richtwert; Bier/Wein guided mit > 0).

## Abnahmekriterien
Punkte 1–16 und 18–20 der Reconciliation: erfüllt – automatische Tests s. o. Punkt 21 (User-Override auf Preference-Artikel): erfüllt – PIVOT1 Nr. 13/14 (Pesto mit Menge bleibt erhalten). 22–26: Suite grün, analyze clean. Quantity-Formeln: keine geändert.
Punkt 17: `git grep` auf verbotene Muster in `lib/` trifft nur `item_row_widget.dart` (`isWater`, UI-Darstellung, keine Assist-Klassifikation) – siehe Risiken.

## Geänderte bestehende Tests (Begründung)
- PIVOT1 Nr. 10 prüfte die entfernten Dart-Sets; ersetzt durch Katalogvalidierung. Nr. 11 erweitert (mehr Fälle, nichts abgeschwächt).
- Übrige Testdateien: nur Katalogpfad, da v0.8/v0.9-Kataloge kein `assist` besitzen und nun hart fehlschlagen (gewollt).

## Offen / Risiken
- `item_row_widget.dart` `isWater` nutzt Namens-/ID-Heuristik für UI; nicht Teil der Klassifikation, nicht angefasst (Vorschlag: separat auf `assistType.isNeedsBased` umstellen; Verhaltensfolgen prüfen).
- Alte Kataloge v0.7–v0.10 bleiben als Assets, sind aber nicht mehr ladbar.
- Lokal vom Tooling regenerierte Plugin-/`pubspec.lock`-Dateien gehören nicht zum Slice und werden nicht committet.

## Selbstprüfung Regeln 1–10
Alle eingehalten; keine manuellen Tests behauptet. Vorschläge für das PRD: siehe CHANGELOG (isWater-UI).

---

## DATA1 Review Amendment

- **Wiederaufnahme nach Unterbrechung am:** 16.10.2026
- **Amendment-Ausgangsstand (`origin/main`):** `dc34970610a208cf78061a0f125f4163beb9dddf`
- **Reviewed Core Implementation HEAD:** `73cfdecefe16721e11fa33878a18a751f092c330` (Korrektur zum Tippfehler `73cfdecefe16721e11fa33878a18aa751f092c330` in der früheren Chat-Meldung)
- **Review-Grundlage:** `docs/impl/DATA1_review_2026-10-07.md` (Issue #28)
- **Review-Branch:** `amend/data1-review`
- **Pull Request:** #29 (`https://github.com/StradaDelSole/proviantplaner/pull/29`, **NICHT gemerged**)

### Findings A–C und Umsetzung

1. **Finding A – `VariantCalculationResult` stiller `AssistType.guided`-Default entfernt:**
   - In `lib/features/shopping_list/domain/calculation/calculation_result.dart` wurde `this.assistType = AssistType.guided` in `required this.assistType` geändert.
   - In `lib/features/shopping_list/domain/calculation/quantity_engine.dart` setzt `_processCheckGroup()` nun explizit `assistType: catalog.getEffectiveAssist(v)` für jede Check-Mode-Variante.
   - Alle übrigen Production-Callsites (`QuantityEngine._buildVariantResult`, `TripShoppingListData.weightAndVolume` in `shopping_list_service.dart`) übergeben `assistType` explizit.
   - Keine Mengenformel oder Check-Mode-Semantik wurde verändert.

2. **Finding B – `ShoppingListItemView` stiller `AssistType.guided`-Default entfernt:**
   - In `lib/features/shopping_list/domain/models/shopping_list_models.dart` wurde `this.assistType = AssistType.guided` in `required this.assistType` geändert.
   - **Catalog Items (`_buildCatalogItemView` in `shopping_list_service.dart`):** Erhalten ihren `AssistType` weiterhin explizit kataloggetrieben (`vr?.assistType ?? catalog.getEffectiveAssist(variant)`).
   - **Custom Items (`_buildCustomItemView` in `shopping_list_service.dart`):** Erhalten an der Konstruktionsgrenze explizit `assistType: AssistType.guided`, um das bestehende Verhalten ohne Erfindung einer neuen Produktklassifikation und ohne Namens-/ID-/Kategorie-Heuristik zu bewahren.

3. **Finding C – Einzige kanonische Assist-Auflösung & Entfernung von `AssistClassifier`:**
   - `CatalogData.getEffectiveAssist(CatalogVariant variant)` (bzw. `getAssistTypeForVariant`) in `lib/features/shopping_list/domain/models/catalog_models.dart` ist jetzt die **einzige** effektive Assist-Auflösung im gesamten Production-Code.
   - In `lib/features/shopping_list/domain/calculation/quantity_engine.dart` wurden sämtliche verbliebenen direkten Vorkommen von `v.assistOverride ?? group.assist` / `variant.assistOverride ?? group.assist` (Equal-Split-Auswahl, Equal-Split-Computation, Each-Split-Computation, `_createSelectedComputation`, `_applyGroupBalancing`, `_buildVariantResult`, `_processCheckGroup`) vollständig auf `catalog.getEffectiveAssist(...)` umgestellt.
   - Da `AssistClassifier` in `lib/features/shopping_list/domain/models/assist_type.dart` keinen Production-Caller besaß, wurde die Fassade samt dem Import von `catalog_models.dart` entfernt. Dadurch ist auch der zyklische Import `assist_type.dart <-> catalog_models.dart` vollständig beseitigt.
   - Berichtskorrektur aus dem Review: `test/features/shopping_list/domain/catalog_validation_test.dart` wurde in DATA1 erweitert (nicht neu angelegt).

### Geänderte Dateien im Amendment

- **Production:**
  - `lib/features/shopping_list/domain/models/assist_type.dart`
  - `lib/features/shopping_list/domain/calculation/calculation_result.dart`
  - `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
  - `lib/features/shopping_list/domain/models/shopping_list_models.dart`
  - `lib/features/shopping_list/data/shopping_list_service.dart`
- **Tests:**
  - `test/features/shopping_list/domain/catalog_validation_test.dart` (Test 11: Check-Mode `VariantCalculationResult` übernimmt `catalog.getEffectiveAssist(v)` bei realen v0.11 Check-Gruppen sowie synthetischer `needsBased`-Check-Gruppe mit `preferenceBased`-Override ohne stillen `guided`-Fallback)
  - `test/features/shopping_list/pivot1_assisted_list_test.dart` (Test 16 & 17: Alle 232 Catalog Items erhalten in `ShoppingListItemView` exakt `catalog.getEffectiveAssist(variant)`; Custom Items erhalten explizit `AssistType.guided` ohne Namens-/ID-Heuristik)
  - `test/features/shopping_list/fb2_a_calculation_test.dart` (explizites `assistType: AssistType.guided` an direkten `VariantCalculationResult`-Test-Fixtures)
  - `test/core/services/pdf_export_test.dart` (explizites `assistType: AssistType.guided` an direkten `ShoppingListItemView`-Test-Fixtures)
- **Dokumentation:**
  - `docs/impl/DATA1_bericht.md`
  - `CHANGELOG.md`

### Scope-Bestätigung

- `data/catalog_v0.11.json` und `data/catalog_v0.10.json` wurden **nicht** verändert.
- Keine Quantity-Formel, Packungsgröße, Shelf-Life-, Chill-, Watermaker- oder Reservewasser-Logik wurde verändert.
- `item_row_widget.dart` (Water-Boost-UI) wurde **nicht** verändert.
- Keine Arbeit an PIVOT2 oder späteren Slices begonnen.

### QA & GitHub Actions Status

- **Gezielter lokaler Entwicklungscheck (gemäß Abschnitt 12 erlaubt):**
  - `flutter test test/features/shopping_list/domain/catalog_validation_test.dart` → **18/18 Tests grün** (inkl. Test 11 für Check-Mode `VariantCalculationResult` ohne stillen `guided`-Fallback).
  - Vollständige Suite (`flutter test`) und Gesamt-Analyze (`flutter analyze`) wurden gemäß Anweisung lokal **nicht** ausgeführt.
- **GitHub Actions auf PR #29:**
  - `Flutter Analyze & Test`: **BLOCKED BY GITHUB BILLING** (`The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings`)
  - `Backend Typecheck & Vitest`: **BLOCKED BY GITHUB GITHUB BILLING** (`The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings`)




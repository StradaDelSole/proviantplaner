# Session Start – DATA1 Review Amendment

**Version:** v0.9
**Datum:** 07.10.2026
**Status:** DATA1 AMENDMENT RELEASED / REVIEW-GATED

Wir arbeiten ausschließlich am engen **DATA1 Review Amendment (Issue #28)**.

## 1. Synchronisieren

```
git status
git pull --rebase
```

Wenn fremde/unbekannte uncommittete Änderungen existieren: STOP und berichten.

## 2. Pflichtlektüre

Vollständig lesen:

- `GEMINI.md`
- `README.md`
- `docs/impl/DATA1_release_reconciliation_2026-10-07.md`
- `docs/impl/DATA1_plan.md`
- `docs/impl/DATA1_review_2026-10-07.md`
- `docs/impl/DATA1_bericht.md`
- `lib/features/shopping_list/domain/models/assist_type.dart`
- `lib/features/shopping_list/domain/models/catalog_models.dart`
- `lib/features/shopping_list/domain/calculation/calculation_result.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `lib/features/shopping_list/domain/models/shopping_list_models.dart`
- `lib/features/shopping_list/data/shopping_list_service.dart`

Reviewed implementation HEAD:

`73cfdecefe16721e11fa33878a18a751f092c330`

Repo `origin/main` bleibt kanonische Wahrheit.

## 3. Scope

Dieser Amendment behebt ausschließlich Findings A–C aus:

`docs/impl/DATA1_review_2026-10-07.md`

Nicht anfassen:

- `data/catalog_v0.11.json` Mapping;
- `data/catalog_v0.10.json`;
- Mengenformeln;
- Water-Boost-UI / `item_row_widget.dart` Wasserheuristik;
- Watermaker-Logik;
- PIVOT2;
- spätere Slices.

## 4. Finding A – VariantCalculationResult

Aktuell:

`VariantCalculationResult.assistType` hat einen stillen Default `AssistType.guided`.

Das muss weg.

Ändere den Constructor auf:

`required this.assistType`

Danach alle Production-Callsites korrigieren.

Insbesondere:

`QuantityEngine._processCheckGroup()`

muss für jede Variante den **effektiven kataloggetriebenen AssistType** explizit setzen.

Keine Check-Gruppe darf ihre Klassifikation aus einem Constructor-Default bekommen.

### Test

Füge einen gezielten Regressionstest hinzu, der beweist:

- eine Check-Mode-Variante übernimmt ihren effektiven AssistType aus dem Catalog-Pfad;
- der Result-Constructor besitzt keinen stillen guided-Fallback.

Kein Verhalten der heutigen Check-Gruppen ändern.

## 5. Finding B – ShoppingListItemView

Aktuell:

`ShoppingListItemView.assistType` hat ebenfalls einen Default `AssistType.guided`.

Diesen stillen Default entfernen:

`required this.assistType`

Alle Production-Callsites explizit versorgen.

### Catalog Items

Müssen weiterhin ausschließlich den kataloggetriebenen effektiven AssistType erhalten.

### Custom Items

Keine neue Produktentscheidung erfinden.

Das heutige Verhalten bleibt erhalten.

Falls Custom Items bisher effektiv `guided` waren, diese bestehende Semantik an der Custom-Item-Construction-Boundary **explizit** setzen und im Bericht dokumentieren.

Nicht aus Name/ID ableiten.

### Test

Belegen:

- Catalog Item erhält den Catalog AssistType;
- Custom Item behält das bisherige Verhalten explizit;
- kein Constructor-Fallback kann fehlende Wiring-Fehler verdecken.

## 6. Finding C – zentrale effektive Auflösung

DATA1 verlangt genau eine kanonische Regel:

`variant.assistOverride ?? group.assist`

Die Production-Engine darf diese Regel nicht mehrfach selbst duplizieren.

Aktuell gibt es direkte Duplikate in QuantityEngine.

Ersetze diese durch die zentrale API, bevorzugt:

`catalog.getEffectiveAssist(variant)`

Alle QuantityEngine-Pfade:

- equal split;
- each split;
- selected computation;
- balancing/result construction;
- check mode;

müssen dieselbe zentrale Auflösung verwenden.

Danach darf in QuantityEngine kein:

`assistOverride ?? group.assist`

mehr stehen.

## 7. AssistClassifier / Import Cycle

Prüfe, ob `AssistClassifier.effectiveFor` überhaupt noch einen echten Production-Caller hat.

Wenn nein:

- entferne die Fassade;
- entferne den dadurch unnötigen Import von `catalog_models.dart` aus `assist_type.dart`;
- beseitige den zyklischen Import `assist_type.dart <-> catalog_models.dart`.

Wenn ein echter Caller existiert:

- nicht blind löschen;
- auf eine einzige kanonische Resolution umstellen;
- im Bericht begründen, warum keine zweite Wahrheit entsteht.

Keine neue Architektur bauen.

## 8. DATA1 Regressionen

Die bereits verifizierte v0.11-Migration darf nicht verändert werden.

Pflicht:

- water needsBased;
- guided Beispiele bleiben guided;
- Preference-Beispiele bleiben preferenceBased;
- Preference automatische Menge bleibt 0;
- User Override bleibt erhalten;
- 47 Gruppen / 232 Varianten;
- 11 Overrides;
- Parser-Failure-Tests bleiben grün.

## 9. QA

Mindestens:

- DATA1 Catalog Validation Tests;
- PIVOT1 Assisted List Tests;
- Quantity Engine Tests;
- relevante ShoppingList Service/Model Tests;
- full `flutter test`;
- `flutter analyze`.

Bestehende Tests nicht abschwächen.

## 10. Bericht

`docs/impl/DATA1_bericht.md` um einen separaten Abschnitt:

`DATA1 Review Amendment`

ergänzen.

Enthalten:

- Ausgangs-HEAD;
- neuer exakter HEAD im Chat-Bericht;
- Findings A/B/C jeweils Fix;
- alle geänderten Production-Callsites;
- ob AssistClassifier entfernt wurde;
- Bestätigung, dass v0.11 nicht geändert wurde;
- Bestätigung, dass keine Quantity-Formel geändert wurde;
- konkrete Tests und Testzahlen;
- Analyze-Ergebnis;
- offene Risiken.

Den SHA-Tippfehler aus dem vorigen Chat-Bericht im Amendment-Bericht korrektstellen:
- falsch gemeldet: `73cfdecefe16721e11fa33878a18aa751f092c330`
- tatsächlich reviewed: `73cfdecefe16721e11fa33878a18a751f092c330`

## 11. Push

Nur bei grünem Stand:

```
git status
git pull --rebase
```

Commit sinngemäß:

`DATA1: Review amendment`

auf `main` pushen.

Danach exakten HEAD berichten.

## 12. STOP

Nach Push:

**STOP für unabhängigen Re-Review / Owner Acceptance.**

Nicht mit Watermaker oder PIVOT2 fortfahren.

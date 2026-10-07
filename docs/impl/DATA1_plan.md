# DATA1 – Catalog-driven Assist Classification – Implementierungsplan

Stand: 07.10.2026

Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Verbindliche Reconciliation:

`docs/impl/DATA1_release_reconciliation_2026-10-07.md`

## Ziel

Die bestehende PIVOT1-Assistenzklassifikation bleibt fachlich unverändert, wird aber vollständig aus dem Katalog statt aus Dart-Produktheuristiken gelesen.

## A. Katalog v0.11

Neue Datei:

`data/catalog_v0.11.json`

Basis ist `data/catalog_v0.10.json`.

Änderungen ausschließlich:

- Version auf `0.11`;
- Schema-Dokumentation um `assist` ergänzen;
- jede Gruppe erhält verpflichtendes `assist`;
- nur die in der Reconciliation festgelegten Varianten erhalten einen `assist` Override.

Keine anderen Produktdaten verändern.

## B. AssistType Parsing

`AssistType` erhält striktes Parsing der Datenwerte:

- needs_based
- guided
- preference_based

Unbekannter Wert -> `FormatException`.

Keine String-Vergleiche in Domain-/Calculation-Logik.

## C. CatalogGroup

Erweitern um:

`final AssistType assist;`

Pflichtfeld.

Fehlt das JSON-Feld:
- `FormatException`;
- keine Default-Klassifikation.

## D. CatalogVariant

Erweitern um optionalen Override:

`final AssistType? assistOverride;`

Fehlendes Feld:
- korrekt erlaubt;
- effektive Klassifikation kommt von Gruppe.

Vorhandenes unbekanntes Feld:
- `FormatException`.

## E. Effektive AssistType-Auflösung

Eine zentrale API soll den effektiven AssistType liefern.

Bevorzugt:

`CatalogData.getAssistTypeForVariant(String variantId)`

oder eine gleichwertige getypte Auflösung über CatalogGroup + CatalogVariant.

Regel:

`variant.assistOverride ?? group.assist`

Unbekannte Gruppe/Variante darf nicht still auf guided fallen.

## F. AssistClassifier entfernen oder entkoppeln

Entfernen:

- preferenceGroupIds;
- preferenceVariantIds;
- contains-Heuristiken;
- water-ID-Heuristik.

Falls `AssistClassifier` als Fassade bestehen bleibt:
- keine IDs/Strings;
- nur geparste Catalog Models akzeptieren.

## G. QuantityEngine

Alle AssistType-Abfragen werden auf kataloggetriebene Werte umgestellt.

Preference-Verhalten unverändert:
- 0 automatische Bedarfsmenge;
- User Override weiter möglich.

Guided und needsBased unverändert.

## H. Calculation Results / ShoppingListItemView

AssistType vom Catalog/Calculation Result weiterreichen.

`ShoppingListItemView.assistType` darf keine ID-basierte Klassifikation mehr durchführen.

## I. CatalogRepository

Produktiver Loader auf:

`data/catalog_v0.11.json`

umstellen.

Keine Runtime-Fallbacks auf v0.10.

## J. Validierung

`catalog_validation_test.dart` erweitern:

- Version == 0.11;
- alle 47 Gruppen haben gültigen AssistType;
- alle 232 Varianten besitzen effektiven AssistType;
- Variant Overrides referenzieren gültige Werte;
- Parser Failure Tests für fehlend/unbekannt.

Die konkreten Counts dürfen als Regression gegen die aktuelle v0.11-Datei geprüft werden, nicht als Produktlogik in Production Code.

## K. PIVOT1 Regressionen

Bestehende Tests, die auf `AssistClassifier.preferenceGroupIds` / `preferenceVariantIds` zugreifen, ersetzen.

Neue Tests müssen das Verhalten aus dem geladenen Catalog prüfen.

Pflichtregressionen:

- water needsBased;
- beer/wine guided;
- savory snack preference;
- sweet spread preference;
- spirits preference;
- pesto preference;
- tofu preference;
- feta/parmesan oder äquivalenter Käse-Override preference;
- Spezial-Sauce preference.

## L. Keine semantische Mengenänderung

Vor/nach DATA1 müssen für repräsentative Inputs identisch bleiben:

- calculatedPackages;
- calculatedQuantity;
- overriddenPackages behavior;
- preference 0-guideline behavior;
- water/guided behavior.

Keine Quantity-Formeln ändern.

## M. QA

Mindestens:

1. Catalog Parser Unit Tests;
2. Catalog Validation;
3. PIVOT1 Assisted List Suite;
4. Quantity Engine Suite;
5. Shopping List UI/Persistence Regressionen;
6. PIVOT3-A;
7. PIVOT3-B;
8. FIX-B;
9. full `flutter test`;
10. `flutter analyze`.

## N. Dokumentation

Nach Implementation:

`docs/impl/DATA1_bericht.md`

mit:
- exakter neuer HEAD;
- geänderte Dateien;
- v0.11 Migration;
- AssistType Mapping;
- entfernte Heuristiken;
- Testnamen/Testzahlen;
- Analyze;
- offene Risiken.

CHANGELOG aktualisieren.

## O. Scope-Ausschluss

Nicht beginnen:

- Watermaker Reserve Amendment;
- PIVOT2;
- provisioning_review_v0.1.json;
- Review UI;
- Missing Basics;
- Frische-/Kühlreview;
- DATA2;
- RECEIPT1;
- GUEST1;
- UX-D;
- Backend/Auth.

## Abschluss

Nur bei vollständig grünem Stand:
- `git status`;
- `git pull --rebase`;
- committen;
- push auf `main`;
- exakten HEAD berichten;
- STOP für unabhängigen Review / Owner Acceptance.

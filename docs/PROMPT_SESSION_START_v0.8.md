# Session Start – DATA1 Catalog-driven Assist Classification

**Version:** v0.8  
**Datum:** 07.10.2026  
**Status:** DATA1 IMPLEMENTATION RELEASED / REVIEW-GATED

Wir arbeiten ausschließlich an:

**DATA1 – Catalog-driven Assist Classification (Issue #28)**

## 1. Zuerst Repository synchronisieren

Führe aus:

```
git status
git pull --rebase
```

Wenn uncommittete Änderungen existieren:
- nicht löschen;
- prüfen, ob sie zu DATA1 gehören;
- bei fremden/unklaren Änderungen STOP und berichten.

## 2. Pflichtlektüre

Vollständig lesen:

- `GEMINI.md`
- `README.md`
- `docs/impl/DATA1_release_reconciliation_2026-10-07.md`
- `docs/impl/DATA1_plan.md`
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md`
- `lib/features/shopping_list/domain/models/assist_type.dart`
- `lib/features/shopping_list/domain/models/catalog_models.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `lib/features/shopping_list/domain/calculation/calculation_result.dart`
- `lib/features/shopping_list/domain/models/shopping_list_models.dart`
- `lib/features/shopping_list/data/catalog_repository.dart`
- `test/features/shopping_list/domain/catalog_validation_test.dart`
- `test/features/shopping_list/pivot1_assisted_list_test.dart`
- `data/catalog_v0.10.json`

Repo `origin/main` ist kanonische Wahrheit.

## 3. Vor Änderung: Reconcile actual code

Bestätige im Bericht/Arbeitsverlauf vor Implementierung:

- aktueller Catalog Loader lädt `catalog_v0.10.json`;
- `AssistClassifier` enthält hardcodierte Preference-Gruppen;
- `AssistClassifier` enthält hardcodierte Preference-Varianten;
- `AssistClassifier` enthält water/pesto/tofu String-/ID-Heuristiken;
- QuantityEngine ruft diese Klassifikation an mehreren Stellen auf;
- ShoppingListItemView berechnet AssistType aktuell erneut über IDs;
- bestehende PIVOT1 Tests validieren die alten hardcodierten Sets.

Wenn das aktuelle Repo hiervon materiell abweicht:
STOP und berichten, bevor DATA1 implementiert wird.

## 4. Ziel

Die fachlich akzeptierte PIVOT1-Klassifikation bleibt unverändert.

Nur die Quelle wird geändert:

**vorher:** Dart-Produktheuristik  
**nachher:** strikt typisierte Katalogdaten.

Keine neue Produktentscheidung treffen.

## 5. Neue Katalogversion

Erstelle:

`data/catalog_v0.11.json`

Ausgangspunkt:

`data/catalog_v0.10.json`

`catalog_v0.10.json` NICHT verändern.

In v0.11 ausschließlich:

- `version` -> `0.11`;
- Schema-Dokumentation für `assist`;
- jede Gruppe bekommt ein verpflichtendes `assist`;
- nur die unten freigegebenen Varianten bekommen einen `assist` Override.

Keine anderen Katalogwerte ändern.

Insbesondere NICHT ändern:

- need amount/basis/unit;
- pack size/unit;
- shelf life;
- buy_fresh_underway;
- chill;
- category;
- department;
- profile;
- applies_to;
- split;
- default_selected;
- Namen/Texte/Notes;
- Varianten-/Gruppenmenge.

## 6. Verbindliches Assist-Mapping

Zulässige JSON-Werte:

- `needs_based`
- `guided`
- `preference_based`

### Group-level needs_based

Exakt:

- `water`

### Group-level preference_based

Exakt:

- `spread_sweet`
- `spread_savory`
- `sweets`
- `savory_snacks`
- `spirits`

### Group-level guided

Alle übrigen Gruppen.

Review-Baseline:

- 47 Gruppen gesamt;
- 1 needs_based;
- 5 preference_based;
- 41 guided.

Falls v0.10 beim tatsächlichen Lesen andere Counts hat:
STOP und berichten.

### Variant-level overrides

Exakt diese Varianten erhalten:

`"assist": "preference_based"`

- `brie`
- `feta`
- `mozzarella`
- `parmesan`
- `sauce_jar`
- `pesto`
- `soy_sauce`
- `bbq_sauce`
- `sweet_chili`
- `tabasco`
- `tofu`

Keine weiteren Overrides hinzufügen.

## 7. AssistType strikt parsen

`AssistType` bleibt der Domain-Typ.

Implementiere striktes Parsing:

- `needs_based` -> `AssistType.needsBased`
- `guided` -> `AssistType.guided`
- `preference_based` -> `AssistType.preferenceBased`

Unbekannter Wert:
`FormatException`

Kein stiller Default.

Keine Domain-/Engine-Logik darf AssistType über Stringvergleiche auswerten.

## 8. CatalogGroup

`CatalogGroup` bekommt verpflichtend:

`AssistType assist`

JSON-Feld `assist` fehlt:
`FormatException`

Nicht auf guided defaulten.

## 9. CatalogVariant

`CatalogVariant` bekommt optional:

`AssistType? assistOverride`

JSON:
- kein `assist` -> null / Gruppenvererbung;
- gültiges `assist` -> Override;
- unbekannt -> `FormatException`.

## 10. Effektive Klassifikation zentral auflösen

Die effektive Klassifikation ist exakt:

`variant.assistOverride ?? group.assist`

Implementiere eine zentrale getypte Auflösung.

Bevorzugt über Catalog Models / CatalogData.

Nicht an mehreren Stellen duplizieren.

Unbekannte Gruppe/Variante darf nicht still guided liefern.

## 11. AssistClassifier-Heuristik vollständig entfernen

Nach DATA1 darf Production Code NICHT mehr enthalten:

- `preferenceGroupIds`
- `preferenceVariantIds`
- `groupId == 'water'`
- `startsWith('water_')`
- `variantId.contains('water')`
- `variantId.contains('pesto')`
- `variantId.contains('tofu')`
- sonstige Assist-Produkt-ID-Heuristik.

`AssistClassifier` darf:
- entfernt werden; oder
- als kleine getypte Fassade weiterbestehen.

Falls er bleibt, darf er nur bereits geparste Catalog Models verwenden.

## 12. QuantityEngine

Alle AssistType-Nutzungen auf kataloggetriebene Werte umstellen.

Keine Quantity-Formel ändern.

Preference-based Verhalten bleibt:

- kein automatischer Bedarf;
- `calculatedPackages == 0` ohne User Override;
- `calculatedQuantity == 0`;
- User Override bleibt möglich.

Guided-Verhalten unverändert.

Needs-based-Verhalten unverändert.

## 13. Calculation Result / ShoppingListItemView

AssistType soll aus dem Katalog-/Calculation-Pfad weitergereicht werden.

`ShoppingListItemView.assistType` darf keine neue Klassifikation anhand von ID/Group-ID durchführen.

Kein ID-Heuristik-Fallback.

## 14. CatalogRepository

Produktiver Loader nach erfolgreicher Migration:

`data/catalog_v0.11.json`

Keine Runtime-Unterstützung für v0.10 nötig.

Tests, die den aktuellen Produktkatalog lesen, ebenfalls auf v0.11 umstellen.

## 15. Parser-/Validation Tests

Zwingend neue Tests für:

1. gültige Group-Assist-Werte;
2. fehlendes Group-`assist` -> FormatException;
3. unbekanntes Group-`assist` -> FormatException;
4. Variant ohne Override erbt Gruppenwert;
5. gültiger Variant Override;
6. unbekannter Variant Override -> FormatException;
7. alle 47 Gruppen besitzen gültiges Assist;
8. alle 232 Varianten besitzen einen effektiven AssistType.

Counts sind Test-/Migration-Regressionen, nicht Production-Logik.

## 16. PIVOT1 Behavior Regression

Explizit beweisen:

- water -> needsBased;
- savory snack -> preferenceBased;
- sweet spread -> preferenceBased;
- spirits -> preferenceBased;
- pesto -> preferenceBased;
- tofu -> preferenceBased;
- feta oder parmesan -> preferenceBased;
- bbq_sauce oder sweet_chili -> preferenceBased;
- beer -> guided;
- wine -> guided.

Preference-Beispiele:
- automatische Richtwertmenge bleibt 0.

Guided-Beispiel:
- bestehender Richtwert bleibt > 0, sofern bestehender Testinput das heute ergibt.

Water:
- bestehende needs-based Berechnung bleibt unverändert.

## 17. Override Regression

Preference-Artikel mit explizitem User Override:

- Override bleibt erhalten;
- DATA1 darf ihn nicht auf 0 zurücksetzen.

## 18. v0.10 -> v0.11 Semantik-Regressionscheck

Baue einen Test oder eine deterministische Testhilfe, die beweist:

Für die explizit migrierten PIVOT1-Klassifikationsfälle ist v0.11 semantisch identisch zum vor DATA1 akzeptierten Mapping.

Nicht dafür den alten `AssistClassifier` als zweite Production-Wahrheit behalten.

Eine Test-fixture-/erwartete Tabelle ist zulässig.

## 19. Keine fachfremden Änderungen

Nicht implementieren:

- `data/provisioning_review_v0.1.json`;
- Provisioning Review;
- Missing Basics;
- Frische-/Shelf-Life Review;
- Kühl-/TK Review;
- Watermaker Reserve Amendment;
- neue Wasserformel;
- PIVOT2;
- RECEIPT1;
- GUEST1;
- UX-D;
- Backend/Auth;
- Store.

## 20. Dokumentationsausnahme für data/

Die allgemeine GEMINI-Regel „nichts in data/ ändern“ ist für DATA1 eng supersediert.

Erlaubt ist ausschließlich:

`data/catalog_v0.11.json`

Keine Änderung an:
- v0.10;
- quantities_v0.6;
- i18n catalog files;
- sonstigen data-Dateien.

Wenn du glaubst, eine weitere data-Datei ändern zu müssen:
STOP und berichten.

## 21. QA

Zwingend ausführen:

- neue DATA1 Parser-/Validation Tests;
- `test/features/shopping_list/domain/catalog_validation_test.dart`;
- `test/features/shopping_list/pivot1_assisted_list_test.dart`;
- Quantity Engine Tests;
- Shopping List Persistence/UI relevante Tests;
- PIVOT3-A Regressionen;
- PIVOT3-B Regressionen;
- FIX-B Regressionen;
- `flutter analyze`;
- vollständiges `flutter test`.

Bestehende Tests nicht abschwächen oder entfernen.

Wenn ein bestehender Test wegen Entfernung der alten AssistClassifier-Sets geändert werden muss:
- Grund im Bericht exakt dokumentieren;
- Verhalten weiterhin mindestens gleich stark testen.

## 22. Abschlussbericht

Erstelle:

`docs/impl/DATA1_bericht.md`

Enthalten:

- exakter Implementierungs-HEAD;
- Ausgangs-HEAD;
- geänderte Dateien;
- v0.11 Migration;
- Counts Groups/Variants;
- Group Assist Mapping;
- Variant Overrides;
- Parser-Verhalten;
- entfernte Heuristiken;
- alle konkret geänderten Production-Call-Sites;
- Testnamen;
- tatsächliche Testzahlen;
- `flutter analyze`;
- offene Risiken/Abweichungen;
- Bestätigung, dass keine Quantity-Formel geändert wurde.

## 23. Push

Nur wenn alles grün ist:

```
git status
git pull --rebase
```

Danach committen und auf `main` pushen.

Commit sinngemäß:

`DATA1: Catalog-driven assist classification`

Exakten neuen HEAD berichten.

## 24. STOP

Nach Push:

**STOP für unabhängigen Review / Owner Acceptance.**

Nicht mit:
- Watermaker;
- PIVOT2;
- einem anderen Slice

fortfahren.

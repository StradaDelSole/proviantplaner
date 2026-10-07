# DATA1 – Catalog-driven Assist Classification – Release Reconciliation

Stand: 07.10.2026

Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

## Ausgangslage

FIX-B ist OWNER-ACCEPTED / COMPLETE.

PIVOT2 bleibt durch die External Review Reconciliation auf HOLD, bis:
1. DATA1 die Assistenzklassifikation vollständig kataloggetrieben macht;
2. die Watermaker-Reserve-Semantik ausdrücklich owner-entschieden und amended ist.

Canonical dependency:
`docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md`

## Ziel

Die bereits owner-accepted PIVOT1-Assistenzsemantik bleibt unverändert:

- `needs_based`
- `guided`
- `preference_based`

Geändert wird ausschließlich die **Quelle der Klassifikation**.

Heute entscheidet `AssistClassifier` in Dart über:
- hardcodierte Gruppen-IDs;
- hardcodierte Varianten-IDs;
- String-Heuristiken wie `contains('water')`, `contains('pesto')`, `contains('tofu')`.

Das widerspricht der verbindlichen Regel „Alles datengetrieben“ und ist ein direkter PIVOT2-Blocker.

DATA1 verschiebt diese Klassifikation vollständig in den Katalog.

## Decision / Implementation Reconciliation

### DECIDED_AND_IMPLEMENTED

- PIVOT1 Assisted List Core.
- Die drei Assistenzklassen:
  - needsBased
  - guided
  - preferenceBased
- Preference-based Artikel erhalten keinen automatischen Crew×Tage-Richtwert.
- Guided Artikel dürfen Richtwerte behalten, erzeugen aber in PIVOT2 keinen generischen globalen Unterversorgungsalarm.
- Needs-based ist objektiv prüfbar; aktuell relevant: Trinkwasser.
- Bier/Wein bleiben guided.
- Spirituosen bleiben preference-based.
- Pesto/Tofu/Spezialsaucen/Spezialkäse bleiben preference-based.
- aktueller Katalog: `data/catalog_v0.10.json`.
- aktueller Loader: `CatalogRepository`.
- aktueller Typ: `AssistType`.

### DECIDED_NOT_IMPLEMENTED / READY

- kataloggetriebenes `assist` Feld auf Gruppenebene;
- optionaler Variant-Override;
- striktes Parsing;
- vollständige Validierung aller Gruppen und Varianten;
- Entfernung aller Produkt-ID-/Substring-Heuristiken aus `AssistClassifier`;
- Upgrade auf `data/catalog_v0.11.json`.

### SUPERSEDED

- Produktklassifikation durch Dart-ID-Sets;
- Produktklassifikation durch String-Substring-Heuristiken;
- jede zukünftige Pflege von AssistType durch Codeänderung.

### UNDECIDED

Keine DATA1-Produktentscheidung offen.

Die separate Watermaker-Reserve-Entscheidung bleibt außerhalb DATA1 ausdrücklich offen.

## Verbindliches Datenmodell

Neue Katalogversion:

`data/catalog_v0.11.json`

Jede Gruppe MUSS enthalten:

```json
"assist": "needs_based"
```

Zulässige Werte:

- `needs_based`
- `guided`
- `preference_based`

Jede Variante DARF optional enthalten:

```json
"assist": "preference_based"
```

Fehlt das Variantenfeld, erbt die Variante exakt den Gruppenwert.

Kein stiller Default auf guided.

Fehlt `assist` bei einer Gruppe oder ist der Wert unbekannt:
- Parsing/Validierung muss hart fehlschlagen.

Unbekannter Variant-Override:
- hart fehlschlagen.

## Exakte Migration des heute akzeptierten Verhaltens

Die neue Katalogversion muss das derzeit akzeptierte PIVOT1-Verhalten **ohne semantische Änderung** abbilden.

### Group-level needs_based

Genau:
- `water`

### Group-level preference_based

Genau:
- `spread_sweet`
- `spread_savory`
- `sweets`
- `savory_snacks`
- `spirits`

### Group-level guided

Alle übrigen aktuellen Gruppen.

Zum Reviewzeitpunkt:
- 47 Gruppen gesamt;
- 1 needs_based;
- 5 preference_based;
- 41 guided.

### Variant-level preference overrides

Innerhalb ansonsten guided klassifizierter Gruppen bleiben exakt diese bekannten Overrides preference-based:

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

Keine weiteren Variant-Overrides werden in DATA1 erfunden.

## Typisierung

`AssistType` bleibt der kanonische Dart-Typ.

Er bekommt eine strikte Parse-Grenze für die Datenwerte.

Empfohlene Zuordnung:

- `needs_based` -> `AssistType.needsBased`
- `guided` -> `AssistType.guided`
- `preference_based` -> `AssistType.preferenceBased`

Keine Domain-Logik darf auf String-Literale vergleichen.

## Catalog Models

`CatalogGroup` erhält einen verpflichtenden getypten Assist-Wert.

`CatalogVariant` erhält einen optionalen getypten Assist-Override.

Die effektive Klassifikation einer Variante ist:

`variant.assistOverride ?? group.assist`

Diese Auflösung soll zentral und deterministisch sein.

## AssistClassifier

Der heutige `AssistClassifier` darf als kleine API-Fassade weiterbestehen, falls dies Call-Sites vereinfacht.

Dann darf er aber ausschließlich mit bereits geparsten Catalog-Modellen arbeiten.

Verboten nach DATA1:

- `preferenceGroupIds`
- `preferenceVariantIds`
- `groupId == 'water'`
- `startsWith('water_')`
- `variantId.contains(...)`
- sonstige Produkt-ID-Heuristik.

Alternativ kann `AssistClassifier` vollständig entfallen, wenn die effektive AssistType-Auflösung sauber in den Catalog Models liegt.

## Quantity Engine

Alle aktuellen PIVOT1-Auswirkungen müssen erhalten bleiben:

- preference-based Varianten:
  - keine automatische Bedarfsmengenberechnung;
  - bestehende Nutzer-Overrides bleiben möglich;
- guided:
  - bestehendes Verhalten unverändert;
- needs-based:
  - bestehendes Verhalten unverändert.

Die Quantity Engine darf keine eigene Produktklassifikation enthalten.

## ShoppingListItemView / Calculation Results

AssistType muss aus dem kataloggetriebenen Modell weitergetragen werden.

Kein erneuter Lookup über Produkt-ID-Heuristik.

## Katalogversion

DATA1 darf ausdrücklich eine neue Datei unter `data/` anlegen:

`data/catalog_v0.11.json`

Dies ist eine enge, explizite Ausnahme von der allgemeinen Gemini-Regel, nach der post-Pivot-Slices `data/` nicht ohne Freigabe ändern dürfen.

Erlaubt:
- neue `catalog_v0.11.json`;
- ausschließlich Assist-Felder plus zwingend notwendige Version-/Schema-Dokumentation in dieser neuen Katalogdatei.

Nicht erlaubt:
- Bedarfsmengen ändern;
- Packungsgrößen ändern;
- Shelf-Life ändern;
- Chill ändern;
- Kategorien/Varianten hinzufügen oder entfernen;
- Texte oder andere Produktsemantik verändern.

`catalog_v0.10.json` bleibt unverändert im Repo.

## Repository / Loader

Nach DATA1 ist `catalog_v0.11.json` die aktuelle Catalog-Quelle.

Alle produktiven Loader und Tests müssen auf v0.11 zeigen.

Keine parallele Runtime-Unterstützung für v0.10 nötig.

## Acceptance

Mindestens folgende Beweise:

1. jede v0.11-Gruppe besitzt ein gültiges Assist-Feld;
2. unbekannter Group-Assist-Wert -> FormatException;
3. fehlendes Group-Assist-Feld -> FormatException;
4. gültiger Variant-Override wird geparst;
5. unbekannter Variant-Assist-Wert -> FormatException;
6. Variante ohne Override erbt Gruppenwert;
7. water -> needsBased;
8. spread_sweet -> preferenceBased;
9. spirits -> preferenceBased;
10. beer/wine -> guided;
11. pesto -> preferenceBased;
12. tofu -> preferenceBased;
13. mindestens ein Käse-Override -> preferenceBased;
14. mindestens eine Spezialsauce -> preferenceBased;
15. alle 47 Gruppen werden validiert;
16. alle 232 Varianten werden validiert;
17. keine hardcodierten Assist-Produktlisten/-Heuristiken mehr in Production Code;
18. preference-based Regression: 0 automatischer Richtwert;
19. guided Regression: bestehender Richtwert bleibt;
20. needs-based Regression: water verhält sich unverändert;
21. User override auf preference item bleibt möglich;
22. PIVOT1 vollständige Suite grün;
23. PIVOT3-A/B Regressionen grün;
24. FIX-B Regressionen grün;
25. volle Flutter Suite grün;
26. `flutter analyze` clean.

## Scope

DATA1 baut NICHT:
- Provisioning Review UI;
- Missing Basics;
- Frische-Review;
- Kühl-/TK-Review;
- Watermaker Reserve Amendment;
- neue Quantity-Formeln;
- Rezepte/Menüs;
- UX-D;
- RECEIPT1;
- GUEST1;
- CAT1;
- Backend/Auth;
- Store.

## Gate

**DATA1 ist der einzige aktuell freigegebene Implementierungsslice.**

Nach Implementation:
1. Bericht;
2. vollständige QA;
3. Push nur bei grünem Stand;
4. STOP für unabhängigen Review;
5. keine automatische Watermaker-/PIVOT2-Freigabe.

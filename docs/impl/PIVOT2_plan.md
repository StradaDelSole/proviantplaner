> **SUPERSEDED FOR CURRENT IMPLEMENTATION – 17.10.2026:** Use `docs/impl/PIVOT2_plan_v0.2.md`. Historical content below remains for audit only; conflicting water/catalog/release wording must not be implemented.

# PIVOT2 – Provisioning Review – Implementierungsplan

Stand: 06.10.2026  
Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Verbindliche Reconciliation:
`docs/impl/PIVOT2_release_reconciliation_2026-10-06.md`

## Ziel

Eine read-only Review-/Copilot-Schicht über die vom Skipper selbst gebaute Vorratsliste legen.

PIVOT2 beantwortet kompakt:
- fehlt wahrscheinlich ein Grundbereich?
- ist eine objektiv berechenbare Needs-based Menge zu niedrig?
- passt Frische/Haltbarkeit zum Törn bzw. zu Einkaufsstopps?
- gibt es Kühl-/TK-Probleme?
- wie groß/schwer ist die tatsächliche Liste?

Keine ungefragten Änderungen.

## A. Review-Domainmodell

Neue strikt typisierte Review-Modelle, mindestens:

- `ProvisioningReviewStatus`
  - ready
  - check
  - actionNeeded

- `ProvisioningReviewSeverity`
  - info
  - check
  - actionNeeded

- `ProvisioningReviewKind`
  - missingBasic
  - needsBasedUndercoverage
  - freshness
  - fridgeRequirement
  - freezerRequirement
  - fridgeCapacity
  - freezerCapacity

- `ProvisioningReviewFinding`
  - stabile ID
  - kind
  - severity
  - optional `listItemId`
  - optional `catalogVariantId`
  - strukturierte numerische Parameter
  - strukturierte Action-Angabe
  - keine lokalisierten Domaintexte

- `ProvisioningReviewResult`
  - overall status
  - findings
  - weight/volume info
  - ggf. known/unknown cooling-volume metadata

Review ist vollständig on-demand ableitbar; kein neues DB-Schema.

## B. Datengetriebene Completeness-Regeln

Neue Datei:

`data/provisioning_review_v0.1.json`

Strict parsing + Validierung.

Initiale owner-accepted Regeln aus dem Product Pivot:
- durable_bread
- cooking_oil
- hygiene_basic
- cleaning_basic
- trash_bags

Kein UI-Text in JSON.

Keine Catalog-ID-Heuristik im Code.

Regeltypen so klein wie möglich halten, z. B.:
- `group_present`
- `any_variant_present`
- `group_variant_min_shelf_life`

Alle referenzierten Gruppen/Varianten müssen beim Laden gegen `catalog_v0.10.json` validiert werden.

Durable Bread nutzt `durable_min_shelf_life_days` aus den Quantity-Daten.

## C. Review Engine / Service

Implementiere eine deterministische `ProvisioningReviewService` oder gleichwertige Domainkomponente.

Input:
- aktueller Trip-Snapshot
- aktuelle tatsächliche Vorratsliste
- Catalog
- Quantities
- ShoppingStops / Allocations

Nur `item.isOnList == true` zählt als tatsächliche Nutzerliste.

### Needs-based

Für Needs-based-Gruppen:
- Richtwert aus aktueller Quantity-Berechnung;
- tatsächliche übernommene Packungsmenge normalisieren;
- unter Richtwert → `ACTION_NEEDED`;
- Ist/Richtwert als strukturierte Werte im Finding.

Aktuell muss Wasser vollständig gegen PIVOT3-B Tank/Watermaker-Semantik getestet werden.

### Guided

Keine pauschalen globalen Unterversorgungsfindings.

Bestehende artikelnahe Richtwerte bleiben bestehen.

### Preference-based

Keine Mengenfindings.

## D. Missing Basics

Für jede Regel in `provisioning_review_v0.1.json`:
- ausschließlich tatsächliche On-List-Catalogitems prüfen;
- fehlt Regel → `CHECK`;
- niemals automatisch hinzufügen.

Custom Items erfüllen diese Regeln nicht per String-Matching.

## E. Frische / Haltbarkeit

Für tatsächliche Catalogitems:

Review-Finding `CHECK`, wenn fachlich relevant:
- `buyFreshUnderway == true`;
- oder Haltbarkeit kürzer als relevanter Trip-/Stop-Horizont.

Finding enthält:
- shelf life days;
- aktuelle Stop-Situation;
- ggf. vorhandene spätere ShoppingStops.

Keine automatische Reallocation.

Keine automatische haltbare Ersatzposition.

Keine automatische Freeze-Annahme nur wegen `shelf_life_frozen_days`.

Issue #8 Regression zwingend:
- Brötchen/Baguette o. ä. werden bei 5 Personen / 7 Tagen nicht stillschweigend umverteilt;
- Review weist auf Haltbarkeit/Nachkauf hin;
- Nutzer-Packungszahl bleibt unverändert;
- vorhandene Allokationen bleiben unverändert.

## F. Kühlung / TK

Tatsächliche Liste prüfen:

- fridge-required + 0 l Kühlschrank → ACTION_NEEDED
- freezer-required + kein Freezer → ACTION_NEEDED
- bekannte geschätzte Kühllast > fridge capacity → ACTION_NEEDED
- bekannte geschätzte TK-Last > freezer capacity → ACTION_NEEDED

Volumen:
- l/ml direkt;
- kg/g mit bestehender 1 kg≈1 l Näherung;
- Stück/Packung ohne Volumen nicht schätzen.

Wenn nicht alles quantifizierbar:
- keine falsche "passt"-Aussage;
- Review darf einen ruhigen CHECK-Hinweis geben, dass nicht alles volumetrisch bewertbar ist.

Nur `chill` bestimmt zwingende Lagerart.
`shelf_life_frozen_days` allein macht ein Produkt nicht automatisch zu TK-Inhalt.

## G. Gewicht / Volumen

Bestehende `TripShoppingListData.weightAndVolume` der tatsächlichen Liste wiederverwenden.

Review zeigt:
- Gesamtgewicht
- Gesamtvolumen
- Hinweis, wenn Positionen ohne berechenbares Gewicht/Volumen vorhanden sind

Nur Info; kein Statuswechsel ohne Kapazitätsgrenze.

## H. Readiness / Aggregation

Gesamtstatus:
- irgendein actionNeeded → actionNeeded
- sonst irgendein check → check
- sonst ready

Keine Scores, Punkte, Prozentwerte oder Gamification.

## I. UX

Innerhalb `ShoppingListScreen / Vorräte`:

1. sichtbare sekundäre Aktion `Liste prüfen`;
2. optional kompakter Readiness-Indikator mit Text + Symbol;
3. Review als fokussierte, verdichtete Ansicht/Route oder Sheet;
4. Gruppen:
   - Aktion nötig
   - Noch prüfen
   - Informationen
5. Missing Basics als Findings in Review;
6. item-bezogene Findings zusätzlich kontextuell am echten Listenartikel:
   - maximal höchstpriorer Hinweis inline;
   - weitere Hinweise in Review;
7. Review-Aktionen öffnen nur existierende explizite Flows.

Keine neue permanente Navigation.

Keine UX-D Command-Center-Implementierung.

## J. Aktionen aus Findings

Mindestens strukturierte Aktionen:
- add/search item
- edit existing item
- open/assign shopping stop
- noAction/info

Aktion führt zu bestehendem Flow.
Review selbst mutiert keine Daten.

## K. Localization

Alle sichtbaren Review-Texte DE/EN/ES/FR/HR/PT.

Domainfinding enthält keine direkt gerenderten deutschen Strings.

## L. Issue-Regressions

### #7
Mindestens:
- Butter / guided: reale Packungsdarstellung primär;
- süßer Aufstrich / preference: Nutzer-Packung primär, keine automatische Review-Unterversorgungswarnung;
- Review verändert keine Packungszahl.

### #8
Mindestens:
- fresh rolls / baguette / vergleichbare Kurz-Haltbarkeit;
- Haltbarkeit-/Nachkauf-Hinweis;
- kein Auto-Reallocate;
- Stop-Allokationen stabil.

### #9
PIVOT1-Regression bleibt grün:
- Pesto bei 5 Personen / 14 Tagen ohne automatischen Mengenrichtwert;
- keine Meal-Frequency-Logik hinzufügen.

## M. Acceptance Tests

Mindestens:

1. Review ist pure/read-only: DB vor/nach Review identisch.
2. leere/minimale Liste erzeugt Missing-Basics + Water Needs finding.
3. ausreichende Watermaker/Tank-Konfiguration + korrekte Flaschenreserve → kein Water-undercoverage finding.
4. zu wenig tatsächliches Wasser → actionNeeded mit festen Ist-/Sollwerten.
5. preference item → kein Mengenfinding.
6. guided item → kein globaler Unterversorgungsalarm.
7. durable bread rule satisfied / unsatisfied.
8. oil rule satisfied / unsatisfied.
9. hygiene/cleaning/trash rules.
10. fresh rolls 7-day case produces contextual freshness finding.
11. review mutiert fresh item / allocations nicht.
12. fridge-required + no fridge → actionNeeded.
13. freezer-required + no freezer → actionNeeded.
14. fridge known volume > capacity → actionNeeded.
15. non-quantifiable cooled piece does not fabricate exact volume.
16. overall ready/check/actionNeeded aggregation.
17. Review UI opens from real ShoppingListScreen.
18. item contextual hint visible on affected adopted item.
19. Review action to existing edit/search flow works.
20. DE/EN UI smoke; ARB keys aligned all six locales.
21. Issue #7 package-first regression.
22. PIVOT1 suite remains green.
23. PIVOT3-A/B suites remain green.
24. full Flutter suite green.
25. `flutter analyze` clean.

## N. Kein Scope

Nicht implementieren:
- automatische Listenänderung
- automatische Stop-Verteilung
- AI Review
- Meal-/Recipe Planner
- generische Guided-Unterversorgungsalarme
- neue Storage-Capacity-Felder
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store

## Abschluss

Nach Umsetzung:
- `docs/impl/PIVOT2_bericht.md`
- CHANGELOG
- vollständige QA
- Push nur grün
- STOP für unabhängigen Review
- kein automatischer Folgeslice

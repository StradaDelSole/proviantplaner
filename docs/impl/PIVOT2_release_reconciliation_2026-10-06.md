> **SUPERSEDED FOR CURRENT IMPLEMENTATION – 17.10.2026:** Use `docs/impl/PIVOT2_release_reconciliation_2026-10-17.md`. Historical content below remains for audit only; conflicting water/catalog/release wording must not be implemented.

# PIVOT2 Release Reconciliation – 06.10.2026

Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Grundlagen:
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/design/PROVY_UX_DIRECTION_v0.5.md`
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
- `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`
- PIVOT1 OWNER-ACCEPTED / COMPLETE
- PIVOT3-A OWNER-ACCEPTED / COMPLETE
- PIVOT3-B OWNER-ACCEPTED / COMPLETE

## Ziel

PIVOT2 macht Provy zum **Prüfer / Copilot** für die vom Skipper selbst gebaute Vorratsliste.

Leitprinzip:

> Der Skipper baut die Liste. Provy macht sie vollständig, realistisch und bordtauglich.

Review darf Hinweise geben, aber niemals ungefragt Positionen hinzufügen, Mengen überschreiben, Einkaufsstopps verändern oder Geschmacks-/Menüentscheidungen erfinden.

## Decision / Implementation Reconciliation

### DECIDED_AND_IMPLEMENTED
- PIVOT1 Search-first / skipper-gesteuerte Liste
- explizite Assistenzklassen `needsBased / guided / preferenceBased`
- Nutzer-Packungszahlen und Overrides überleben Recalculation
- Preference-based Artikel erhalten keine Crew×Tage-Menge als Listenvorschlag
- MHD-/Frischemetadaten im Katalog:
  - `shelf_life_days`
  - `buy_fresh_underway`
  - `shelf_life_frozen_days`
- Kühlanforderung `chill = none | fridge | freezer`
- ShoppingStops + manuelle ListItemAllocations
- tatsächliche Listen-Packungen / Gebinde
- Gewicht-/Volumen-Summe der tatsächlichen Liste
- PIVOT3-B:
  - Kühlschrankkapazität
  - Tiefkühlfach + Kapazität
  - Wassertank + Trinkbarkeit
  - Watermaker
  - belastbare Watermaker-/Notreserve-Formel

### DECIDED_NOT_IMPLEMENTED
- kompakte `Liste prüfen` Review-Ansicht
- strukturierte Review-Findings / Readiness
- datengetriebene Missing-Basics-Checks
- tatsächliche Needs-based Unterdeckungsprüfung
- kontextuelle Frischehinweise auf der Nutzerliste
- tatsächliche Kühl-/TK-Plausibilitätsprüfung der Nutzerliste
- Review-Zusammenfassung für Gewicht/Volumen

### SUPERSEDED
- Issue #8: automatische Verteilung frischer Ware durch die Engine auf spätere Einkaufsstopps.
  - Der aktuelle Katalog sagt ausdrücklich: Frisches wird **nicht automatisch** auf spätere Einkäufe verteilt.
  - `shelf_life_days` und `buy_fresh_underway` dienen im neuen Modell als Hinweis/Review.
  - PIVOT2 darf passende spätere Stops anzeigen bzw. zur manuellen Zuordnung führen, aber nicht selbst umverteilen.
- Issue #9: Einführung einer neuen universellen Meal-Frequency-Engine für Pesto/Präferenzartikel.
  - PIVOT1 hat den Produktentscheid strukturell ersetzt: Pesto und vergleichbare Preference-based Artikel erhalten keinen automatischen Crew×Tage-Richtwert.
  - Keine Rezept-/Menü-/Frequenzplanung in PIVOT2.
- Teile von Issue #7, die sich auf `Alle Vorschläge übernehmen` als Vollversorgungs-Hauptweg beziehen.
  - Dieser Hauptweg wurde durch PIVOT1 entfernt.
  - PIVOT2 behält einen Regressionstest für paketbasierte Darstellung / manuelle Mengen, bevor #7 endgültig geschlossen wird.

## Verbindliche Produktentscheidungen für PIVOT2

### 1. Review ist read-only bezüglich Nutzerentscheidungen

Das Öffnen/Aktualisieren des Reviews darf niemals:
- Artikel adoptieren/entfernen;
- `overriddenPackages` verändern;
- `isAdopted` verändern;
- Custom Items verändern;
- Stop-Allokationen verändern;
- Crew-/Trip-/Boat-Daten verändern.

Review-Aktionen dürfen lediglich vorhandene Edit-/Search-/Stop-Zuordnungs-Flows öffnen. Änderungen erfolgen erst durch eine explizite Nutzeraktion in diesen bestehenden Flows.

### 2. Kein generischer Guided-Unterversorgungsalarm

PIVOT1 `guided` bedeutet: ein Richtwert kann bei Auswahl hilfreich sein, ist aber nicht automatisch belastbar genug für einen globalen Unterversorgungsalarm.

PIVOT2 v1:
- **needsBased** darf objektiv auf Unterdeckung prüfen;
- **guided** behält den vorhandenen vorsichtigen Richtwert am Artikel, erzeugt aber nicht pauschal ein globales `zu wenig`-Finding;
- **preferenceBased** erhält weiterhin keinerlei automatische Mengenbewertung.

Damit wird Issue #9 nicht durch die Hintertür wieder eingeführt.

### 3. Needs-based Mengenprüfung

Für jede Needs-based-Gruppe:
- tatsächliche Menge = ausschließlich die vom Nutzer übernommenen effektiven Packungen;
- Richtwert = aktuelle Quantity-Engine-Berechnung unter den aktuellen Trip-/Crew-/Boat-Snapshots;
- kompatible Einheiten werden ausschließlich mit den bestehenden erlaubten Umrechnungen normalisiert (g↔kg, ml↔l);
- tatsächliche Menge unter Richtwert → `ACTION_NEEDED`;
- Review zeigt Ist und Richtwert;
- keine automatische Mengenänderung.

Aktuell ist Trinkwasser die relevante Needs-based-Gruppe.

Die PIVOT3-B-Wasserlogik ist kanonisch:
- Tank/Watermaker werden berücksichtigt;
- Watermaker reduziert nie unter die datengetriebene Notreserve;
- Review erfindet keine zweite Wasserformel.

### 4. Missing Basics / Grundausstattung

Die ausdrücklich im Product Pivot genannten Beispiele werden als **datengetriebene, nicht blockierende Completeness-Regeln** umgesetzt.

Neue Datei:
`data/provisioning_review_v0.1.json`

Sie enthält ausschließlich strukturierte Matcher/Regeln, keine UI-Texte.

Initiale Regeln:
1. haltbare Brotreserve;
2. Speiseöl;
3. Hygiene-Grundlage;
4. Reinigungs-/Abwasch-Grundlage;
5. Müllsäcke.

Trinkwasser wird nicht doppelt als Missing-Basic modelliert, sondern über die Needs-based Mengenprüfung.

Regeltypen müssen strikt typisiert sein, z. B.:
- Gruppe vorhanden;
- eine aus erlaubten Varianten vorhanden;
- Variante innerhalb einer Gruppe mit Mindest-Haltbarkeit vorhanden.

Die haltbare Brotreserve verwendet den bereits vorhandenen datengetriebenen `durable_min_shelf_life_days`-Schwellwert aus `quantities_v0.6.json`, keine neue hartcodierte Tageszahl.

Missing-Basic-Findings sind `CHECK`, nicht `ACTION_NEEDED`, und bleiben Vorschläge.

Custom Items erfüllen Katalogregeln nicht durch Namensheuristik. Keine Textsuche wie `name.contains("öl")`.

### 5. Frische / Haltbarkeit

PIVOT2 prüft nur **Artikel, die tatsächlich auf der Nutzerliste stehen**.

Ein kontextuelles `CHECK`-Finding ist zulässig, wenn:
- `buy_fresh_underway == true`; oder
- `shelf_life_days` kürzer als der relevante Törn-/Einkaufshorizont ist.

Wording bleibt ruhig und faktisch:
- Haltbarkeit;
- später frisch nachkaufen;
- vorhandenen späteren Einkaufsstopp nutzen/zuordnen.

PIVOT2:
- verteilt keine Packungen automatisch;
- erzeugt keine haltbare Alternative automatisch;
- ändert keine Mengen;
- nimmt nicht automatisch an, dass ein einfrierbares Produkt tatsächlich eingefroren wird.

Vorhandene Stop-Allokationen werden angezeigt/berücksichtigt, aber nie stillschweigend verändert.

### 6. Kühlung / Tiefkühlung

Nur die tatsächliche Nutzerliste wird geprüft.

`ACTION_NEEDED`:
- `chill=fridge` bei 0 l Kühlschrankkapazität;
- `chill=freezer` ohne Tiefkühlfach;
- bekannte geschätzte Kühl-/TK-Menge liegt eindeutig über der jeweiligen Kapazität.

Für die Kapazitätsschätzung dürfen ausschließlich bereits im Projekt akzeptierte Konversionen verwendet werden:
- l / ml direkt;
- kg / g mit derselben bestehenden 1 kg ≈ 1 l Näherung.

Stück-/Packungseinheiten ohne belastbare Volumenangabe werden **nicht erfunden**.
Wenn dadurch nicht alles quantifizierbar ist, darf der Review keine falsche `passt`-Garantie aussprechen.

`shelf_life_frozen_days` bedeutet nur `kann ggf. eingefroren werden`; es ist kein Beweis, dass der Nutzer es einfrieren will.

### 7. Gewicht / Volumen

Die bestehende Summe der **tatsächlich übernommenen Liste** wird in der Review-Zusammenfassung informationshalber gezeigt.

Keine allgemeine Lagerraum-Warnung ohne definierte Gesamt-Stauraumkapazität.

### 8. Readiness

Kein Score.

Genau die owner-accepted Zustände:
- `READY` / „Bereit“
- `CHECK` / „Noch prüfen“
- `ACTION_NEEDED` / „Aktion nötig“

Gesamtstatus:
- mindestens ein `ACTION_NEEDED` → Aktion nötig;
- sonst mindestens ein `CHECK` → Noch prüfen;
- sonst → Bereit.

Informationswerte wie Gewicht/Volumen verändern den Status nicht.

Auch `ACTION_NEEDED` blockiert den Nutzer nicht automatisch; Review bleibt assistierend.

### 9. UX

Innerhalb `Vorräte`:
- sichtbare sekundäre Aktion **„Liste prüfen“**;
- keine neue Top-Level-Navigation;
- verdichtete Review-Ansicht;
- Findings nach Status gruppiert;
- höchstens ein kompakter höchstpriorer Hinweis direkt am betroffenen Artikel; weitere Findings über Review sichtbar;
- Missing Basics erscheinen in der Gesamtsicht, nicht als erfundene Artikelzeilen;
- Farbe nie als einziges Signal;
- ruhige Sprache;
- kein 0–100-Score;
- Review darf ignoriert/verlassen werden.

Kontextuelle Aktionen dürfen vorhandene Flows öffnen:
- Position suchen/hinzufügen;
- bestehende Position bearbeiten;
- Stop-Zuordnung öffnen.

Keine automatische Korrektur.

### 10. Localization

Alle neuen sichtbaren Texte:
- DE
- EN
- ES
- FR
- HR
- PT

Keine Domain-Logik auf lokalisierten Strings.

## Issue-Reconciliation

### Issue #7
Status: **PARTIALLY SUPERSEDED / PIVOT2 REGRESSION REQUIRED**
- Vollversorgungs-/Adopt-all-Pfad ist durch PIVOT1 entfallen.
- PIVOT2 muss mit Butter + süßem Aufstrich oder äquivalenten festen Regressionen beweisen:
  - Einkauf primär als Packungszahl × Packungsgröße;
  - Preference-based Aufstrich ohne automatische Bedarfsmengenwarnung;
  - Guided-Richtwert bleibt sekundär und überschreibt Nutzerzahl nicht.
- Danach kann #7 geschlossen werden.

### Issue #8
Status: **SUPERSEDED BEHAVIOR / PIVOT2 CLOSURE TARGET**
- automatische Stop-Verteilung ist superseded;
- Frische-/MHD-Review ohne Zwang ist der kanonische Ersatz.
- Nach PIVOT2 Acceptance kann #8 geschlossen werden.

### Issue #9
Status: **RESOLVED BY PIVOT1**
- Pesto ist Preference-based;
- 5 Personen / 14 Tage erzeugt keinen automatischen 14-Gläser-Richtwert;
- keine neue Meal-Frequency-Engine erforderlich.

## Scope-Grenze

PIVOT2 baut **nicht**:
- Rezepte/Menüs;
- AI Review;
- Preisvergleich;
- Händler/Vendor;
- Barcode;
- automatische Stop-Verteilung;
- automatische Produkt-/Mengenänderungen;
- UX-D Command Center;
- GUEST1;
- RECEIPT1;
- CAT1;
- B3/B4/B5;
- Store-Publikation.

## Gate

**PIVOT2 ist der einzige aktuell freigegebene Implementierungsslice.**

Nach Implementierung:
1. Bericht;
2. vollständige Tests/analyze;
3. Push nur grün;
4. STOP für unabhängigen Review;
5. kein automatischer Folgeslice.

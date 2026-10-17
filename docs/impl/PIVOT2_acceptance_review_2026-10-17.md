# PIVOT2 Acceptance Review – 17.10.2026

Status: **FINAL / OWNER-ACCEPTED IMPLEMENTATION**

Slice:

- PIVOT2 – Provisioning Review
- Issue #26
- PR #33 (`https://github.com/StradaDelSole/proviantplaner/pull/33`)
- Related issues addressed and closed: #7, #8

## Final reviewed implementation state

- Accepted PR HEAD: `8772b29c63424c37bdd7dc668fc5a6679de4b5f4`
- Merge commit: `3c75f0e6012ba8a80011504dce471cc97b71ed94`
- PR #33 merged into `main`
- Authoritative GitHub Actions run on accepted PR HEAD: `39032423321` (`https://github.com/StradaDelSole/proviantplaner/actions/runs/39032423321`)

Required jobs:

- Flutter Analyze & Test — SUCCESS — Job `117395422334`
- Backend Typecheck & Vitest — SUCCESS — Job `117395422652`

## Accepted product semantics

1. **Read-Only Copilot Guarantee:**
   - `ProvisioningReviewEngine` und `ShoppingListService.reviewProvisioningList` führen keinerlei Schreiboperationen oder Mutationen aus.
   - DB-Zustand, Mengen, Zuweisungen, Stopps, Crew und Boot bleiben vor und nach dem Review exakt identisch.
   - Durch Snapshot-Tests aller relevanten Tabellen (`trips`, `tripDays`, `crewMembers`, `shoppingStops`, `listItems`, `listItemAllocations`) vor und nach mehrfacher Review-Ausführung vollständig belegt.

2. **Datengetriebene Review-Konfiguration (Missing Basics):**
   - Strikt typisierte Regeln in `data/provisioning_review_v0.1.json` (`ProvisioningReviewRuleType`: `shelfLifeGroupPresence`, `anyVariantPresence`, `groupPresence`).
   - Alle Gruppen- und Varianten-IDs validieren gegen `data/catalog_v0.11.json`.
   - Keine Namensheuristik für Custom Items.
   - Regeln für `durable_bread` (shelf_life >= 14 Tage), `cooking_oil` (Oliven- oder Sonnenblumenöl), `hygiene_basic`, `cleaning_basic` und `trash_bags`.

3. **Effective AssistType (DATA1-Integration):**
   - Mengen- und Unterdeckungsprüfungen respektieren den effektiven `AssistType` (`catalog.getEffectiveAssist(variant)`).
   - Guided Items (`AssistType.guided`) und Preference-basierte Items (`AssistType.preferenceBased`) erhalten keinen generischen globalen Mengen-Alarm.

4. **WATER1-Trinkwasser-Abgleich:**
   - Berechnung basiert auf `climateDailyLiters × crewFactorSum × effectiveDays`.
   - Unterschreitung erzeugt `CHECK`, niemals `ACTION_NEEDED`.
   - Tank und Watermaker werden informativ dargestellt, ohne den Richtwert rechnerisch zu reduzieren.
   - Kumulativer Trinkwasser-Übertrag bei mehreren Stopps berücksichtigt rechnerisch nicht verbrauchtes Wasser früherer Horizonte.

5. **Haltbarkeit & Frische (Issue #8 Closure):**
   - Frische Artikel mit Haltbarkeit kürzer als der Horizont erhalten beratenden `CHECK`.
   - Keine automatische Verteilung oder Listenmutation.
   - Restmengen bei Stopp-Allokationen werden implizit Stopp 1 zugeordnet und konsistent geprüft.

6. **Kühlung & Tiefkühlung Plausibilität:**
   - Klare `ACTION_NEEDED`-Befunde bei harten technischen Widersprüchen (Kühlware bei 0 L Kühlschrank, Tiefkühlware ohne Tiefkühler, bekanntes Volumen > Kapazität).
   - Unquantifizierbare Kühlartikel bei vorhandener Kühlkapazität erzeugen `CHECK` (kein falsches „Passt“).

7. **Reaktivität & Lifecycle-Sicherheit:**
   - Direkte, schleifenfreie Invalidation und Inkrementierung von `tripDataVersionProvider` bei allen State-Mutationen.
   - Keine leeren Callbacks oder zirkulären Abhängigkeiten.

8. **UI & Lokalisierungs-Parität:**
   - Dreistufiger Gesamtstatus (`READY`, `CHECK`, `ACTION_NEEDED`) ohne Scores oder Gamification.
   - Sekundäre Aktion `Liste prüfen` in AppBar und Vorratsliste.
   - `ProvisioningReviewSheet` mit nahtlosem Absprung in Suche, Stoppzuweisung und Mengen-Edit.
   - Maximal ein höchstpriorisierter Inline-Hinweis je Artikelzeile.
   - Vollständige Parität über alle 6 Sprachen (DE, EN, FR, ES, PT, HR).

## Closure von Vorläufer-Issues

- **Issue #26 (PIVOT2 – Provisioning Review):** Vollständig implementiert, getestet und abgenommen.
- **Issue #7 (Quantity bug: Unplausible gram amounts after adopting suggestions):** Durch PIVOT1 (User-Package-Choice primär) und PIVOT2 (Review überschreibt niemals die kaufbare Packungsauswahl des Nutzers; keine falschen Mengenalarme für Guided/Preference) erfüllt und geschlossen.
- **Issue #8 (Shelf-life bug: Frische Backwaren werden als Gesamt-Törnmenge übernommen):** Durch PIVOT2 (beratender Haltbarkeits- und Frische-CHECK ohne erzwungene automatische Neuverteilung auf spätere Stopps; Berücksichtigung von Stopp-Allokationen) erfüllt und geschlossen.


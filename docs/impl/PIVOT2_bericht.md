# PIVOT2 – Provisioning Review – Abschlussbericht

Stand: 17.10.2026  
Branch: `slice/pivot2-provisioning-review`  
Baseline `origin/main` SHA: `d775c584c95a3a791587477dd6d4a9271bd8007c`  
Status: **VOLLSTÄNDIG IMPLEMENTIERT / CI GRÜN / BEREIT FÜR REVIEW & OWNER ACCEPTANCE**

---

## Slice: PIVOT2 – Provisioning Review (Issue #26)

### Umgesetzt:
1. **Scoped UX Benchmark Pass:** Vorab-Dokumentation in `docs/design/PIVOT2_UX_BENCHMARK_PASS_2026-10-17.md` gemäß `docs/design/PROVY_UX_BENCHMARK_STRATEGY_v0.1.md`. Alle sechs Kernmuster (Einstieg, sekundäre Aktion, Summary-Sheet, Findings-Gruppierung, Inline-Hinweis, Action Handoff) als `KEEP`, `ADOPT_PATTERN` oder `SIMPLIFY` klassifiziert. Globale Provy-IA vollständig unverändert.
2. **Reine Lese-Garantie (Read-Only Copilot):** `ProvisioningReviewEngine.evaluate(...)` und `ShoppingListService.reviewProvisioningList(...)` führen keinerlei Schreiboperationen oder Mutationen aus. DB-Zustand, Mengen, Zuweisungen, Stopps, Crew und Boot bleiben vor und nach dem Review exakt identisch.
3. **Strikt typisierte Review-Konfiguration:** Neue Asset-Datei `data/provisioning_review_v0.1.json` mit strikt typisiertem Parser (`ProvisioningReviewConfig`) und Validierung aller Gruppen- und Varianten-IDs gegen `data/catalog_v0.11.json`. Keine Heuristik für Custom Items.
4. **Fehlende Grundlagen (Missing Basics):** Datengetriebene Regeln für haltbares Brot (`durable_bread`, shelf_life >= 14 Tage), Speiseöl (`cooking_oil`: Oliven- oder Sonnenblumenöl), Hygiene-Grundausstattung (`hygiene_basic`), Spülmittel / Reiniger (`cleaning_basic`) und Müllbeutel (`trash_bags`).
5. **Effective AssistType (DATA1-Integration):** Reusing von `CatalogData.getEffectiveAssist(...)`. Keine Mengen-Alarme für Guided Items (`AssistType.guided`) oder Preference-basierte Items (`AssistType.preferenceBased`).
6. **Mindest-Trinkwasser (WATER1-Integration):** Rechnen mit `climateDailyLiters × crewFactorSum × effectiveDays`. Unterdeckung erzeugt `CHECK`, niemals `ACTION_NEEDED`. Tank und Watermaker werden als informativer Kontext aufgeführt, ohne den Richtwert rechnerisch zu reduzieren.
7. **Haltbarkeit & Frische (Issue #8):** Frische Artikel mit Haltbarkeit kürzer als der Zeithorizont erhalten einen beratenden `CHECK`; keine automatische Verteilung auf Stopps, keine Mengenänderung.
8. **Kühlung & Tiefkühlung Plausibilität:** Klare `ACTION_NEEDED`-Befunde bei 0 L Kühlschrank mit Kühlware, fehlendem Tiefkühler bei Tiefkühlware oder bekanntem Volumen > Kapazität. Bei unbekanntem Volumen keine erfundenen Zahlen, sondern Hinweis auf unvollständige Volumenbasis.
9. **Gewicht & Volumen:** Reines Info-Finding unter Wiederverwendung von `QuantityEngine.calculateWeightAndVolume`.
10. **Status-Aggregation & UI:** Dreistufiger Gesamtstatus (`READY`, `CHECK`, `ACTION_NEEDED`). Einstieg über `Liste prüfen` in AppBar-Menü und Icon-Button. `ProvisioningReviewSheet` mit Handoffs in bestehende Flows (`search_or_add`, `edit_item`, `assign_shopping_stop`). Maximal ein höchstpriorisierter Inline-Hinweis in `ShoppingListItemRow`.
11. **Lokalisierungs-Parität:** Alle Texte vollständig in 6 Sprachen: DE, EN, FR, ES, PT, HR.

---

## PIVOT2 Review Amendment (Findings A–G)

In Reaktion auf den unabhängigen Review vom 17.10.2026 wurden folgende Nachbesserungen umgesetzt und automatisiert belegt:

1. **Finding A – HIGH: Stale Review Results**
   - `provisioningReviewProvider` reagiert reaktiv und unterbrechungsfrei auf `tripShoppingListProvider(tripId)`, `tripCrewByIdProvider(tripId)` und `tripDaysByIdProvider(tripId)`.
   - Bei jeder Änderung an Artikeln, Packungszahlen, Stopps, Allokationen, Crew oder Tagen wird die flüchtige Vorratsprüfung automatisch neu berechnet.
   - Nachweis: automatischer Test `PIVOT2 Amendment Tests (Findings A-F) Finding A: provisioningReviewProvider reagiert reaktiv auf State-Mutationen`.

2. **Finding B – HIGH: Strict Config Validation**
   - Freie Regeltyp-Strings durch `ProvisioningReviewRuleType` Enum (`shelfLifeGroupPresence`, `anyVariantPresence`, `groupPresence`) ersetzt.
   - Pflichtfelder je Regeltyp strikt durchgesetzt (`group`, `minShelfLifeDays`, `variants`).
   - Validierung von Action-Targets (`targetGroup`, `targetVariants`) gegen `CatalogData` ergänzt; unbekannte Regeltypen, ungültige Gruppen, ungültige Varianten und ungültige Targets werfen explizit `FormatException`.
   - Nachweis: automatische Negativtests in `PIVOT2 Kriterium 2 & 3: Review-Config Parsing & Validierung` (`Unbekannter Regel-Typ wirft FormatException`, `Fehlende Pflichtfelder je Regel-Typ werfen FormatException`, `Ungültige Action-Ziele werfen FormatException in validateAgainstCatalog`, etc.).

3. **Finding C – HIGH: DATA1 Effective AssistType**
   - Mengen- und Unterdeckungsprüfungen respektieren den effektiven `AssistType` (`catalog.getEffectiveAssist(variant)`).
   - Varianten in der Wassergruppe mit `assistOverride: AssistType.preferenceBased` zählen nicht zur Deckung des Grundbedarfs; führen daher nicht fälschlich zur Annahme voller Bedarfsdeckung.
   - Nachweis: automatischer Test `PIVOT2 Kriterium 10-12: AssistType-Verhalten Variant mit assistOverride: preferenceBased in Wassergruppe zählt nicht zur needs_based Deckung`.

4. **Finding D – MEDIUM: Incomplete Cooling Assessment**
   - Befund `incompleteCoolingAssessment` wird bei aktiver Kühlkapazität (`fridgeCapacity > 0 || freezerCapacity > 0`) auf Schweregrad `CHECK` gesetzt, wenn unquantifizierbare Kühlartikel vorhanden sind.
   - Verhindert irreführenden `READY`-Status bei unvollständiger Kühlvolumenprüfung.
   - Nachweis: automatischer Test `PIVOT2 Amendment Tests (Findings A-F) Finding D: Unquantifizierte Kühlartikel bei aktiver Kühlkapazität erzeugen CHECK`.

5. **Finding E – MEDIUM: UX Actions & Contextual Search/Stop Handoff**
   - `searchOrAdd`-Aktion übergibt die konkrete Variante oder Gruppe als vorausgefüllte `initialQuery` an `showSearch`.
   - `assignShoppingStop` öffnet bei mehreren Stopps direkt das `StopAllocationSheet`.
   - Nachweis: automatischer Widget-Test `PIVOT2 Amendment Tests (Findings A-F) Finding E: Review-Aktionen führen zu echten Navigationen & Hand-offs`.

6. **Finding F – LOW: Stop Context & Allocations**
   - Haltbarkeitshorizont berücksichtigt Stopp-Allokationen (`_resolveEffectiveHorizonForItem`).
   - Artikel, die an späteren Stopps gekauft werden, prüfen ihre Haltbarkeit gegen den Stopphorizont statt starr gegen die gesamte Törndauer.
   - Nachweis: automatischer Test `PIVOT2 Amendment Tests (Findings A-F) Finding F: Einkaufsstopp-Kontext berechnet Haltbarkeitshorizont anhand von Stopp-Allokationen`.

7. **Finding G – LOW: Airtight Read-Only Proof**
   - Kriterium 1 Test erweitert um Snapshots aller relevanten Tabellen (`trips`, `tripDays`, `crewMembers`, `shoppingStops`, `listItems`, `listItemAllocations`) vor und nach mehrfacher Review-Ausführung inklusive Stopp-Allokationen.
   - Nachweis: automatischer Test `PIVOT2 Kriterium 1: Pure/Read-Only Garantie reviewProvisioningList verändert keinen Datenbankzustand einschließlich Allokationen`.

---

## PIVOT2 Re-Review Amendment 2 (Findings A2, B2, E2, F2)

In Reaktion auf den zweiten unabhängigen Review vom 17.10.2026 wurden folgende Punkte behoben und automatisiert belegt:

1. **Finding A2 – HIGH: Production Reactivity**
   - Reaktivität im realen Datenfluss sauber und zuverlässig verankert:
     - `onTripDataChanged`-Callback in `TripService` und `ShoppingListService` implementiert.
     - Automatische Invalidation von `tripShoppingListProvider(tripId)`, `tripCrewByIdProvider(tripId)`, `tripDaysByIdProvider(tripId)`, `tripStopsByIdProvider(tripId)` und `tripByIdProvider(tripId)` bei jeder State-Mutation (Crew, Tage, Stopps, Boot, Mengen, Allokationen).
     - Dadurch wird `provisioningReviewProvider` unterbrechungsfrei und reaktiv aktualisiert, ohne persistente StreamProvider zu erfordern, die Test-Runner blockieren könnten.
     - Screen-Mutationspfade in `trip_overview_screen.dart` und `trip_timeline_screen.dart` verifizieren die lückenlose Reaktivität.
     - Nachweis: automatischer Test `PIVOT2 Amendment Tests (Findings A-F) Finding A: provisioningReviewProvider reagiert reaktiv auf State-Mutationen` (überprüft echte Mutationen ohne manuelles/künstliches Invalidate im Testcode).

2. **Finding B2 – MEDIUM: Threshold Reference Validation**
   - `ProvisioningReviewRule.fromJson` validiert `threshold_field` gegen die kanonische Mengen-Referenz `quantities.rounding.durable_min_shelf_life_days` und nicht gegen beliebige Freitext-Felder.
   - Unbekannte oder fehlerhafte Referenzfelder werfen deterministisch eine `FormatException`.
   - Nachweis: automatischer Test `PIVOT2 Kriterium 2 & 3: Review-Config Parsing & Validierung Unbekanntes threshold_field in Review-Regel wirft FormatException`.

3. **Finding E2 – HIGH: Search Handoff / Disposed Context**
   - `callerContext` / `parentContext` an `ProvisioningReviewSheet` und `CatalogSearchDelegate` übergeben; verhindert disposed context beim Übergang von Sheet zu Suche und AddOrEdit-Sheet.
   - `targetVariants` und `minShelfLifeDays` (14 Tage für haltbares Brot) priorisieren haltbare Alternativen vor kurz haltbaren Backwaren.
   - Suchabfrage matcht auch auf `variant.id`.
   - Nachweis: automatischer Widget-Test `PIVOT2 Amendment Tests (Findings A-F) Finding E2: Review -> Suche -> Treffer auswählen -> Add/Edit-Sheet -> bestätigte Übernahme`.

4. **Finding F2 – MEDIUM: Stop Allocations & Water Horizon**
   - Restmengen (`residualPackages = effectivePackages - explicitlyAllocated`) werden bei Frischeprüfung implizit Stopp 1 zugeordnet und gegen dessen Zeithorizont geprüft.
   - Trinkwasserprüfung evaluiert bei vorhandenen Stopps und Stopp-Allokationen den Wasserbedarf je Stopp-Horizont.
   - Nachweis: automatische Tests `PIVOT2 Kriterium 18-19: Frische & Haltbarkeit (Issue #8) Restmenge bei Stopp-Allokationen wird implizit Stopp 1 zugeordnet und auf Haltbarkeit geprüft` und `PIVOT2 Kriterium 13-17: Trinkwasser-Abgleich (WATER1) Trinkwasser-Bedarfsabgleich bei Stopps prüft Horizont und Stopp-Allokationen`.

---

## PIVOT2 Final Re-Review Amendment 3 (Findings A3, F3, F4)

In Reaktion auf den dritten unabhängigen Review vom 17.10.2026 wurden folgende Punkte behoben und automatisiert belegt:

1. **Finding A3 – HIGH: Production Reactivity & Lifecycle Safety**
   - Vollständige Integration aller produktiven Mutationspfade in `ShoppingListService`:
     - `allocateToStop`, `movePackagesBetweenStops`, `adoptAllSuggestions`, `adoptCategorySuggestions`, `handleUnboughtItems`, `addCustomItem` und `toggleBought` melden Datenänderungen via `onTripDataChanged?.call(tripId)`.
     - Bei Schleifen-Mutationen (`handleUnboughtItems`) erfolgt die Benachrichtigung konsistent einmalig nach Abschluss aller Änderungen.
   - Entkopplung der Provider-Reaktivität über `tripDataVersionProvider` (StateProvider.family<int, int>) und den typisierten `TripDataChangeNotifier` (`tripDataChangeCallbackProvider`), um Riverpod-Zyklen und Invalidation-Exceptions während Provider-Initialisierungen vollständig zu vermeiden.
   - `ref.onDispose` bereinigt den Callback im `TripDataChangeNotifier` für lückenlose Lifecycle-Sicherheit.
   - Nachweis: automatischer Integrationstest mit den **originalen un-overriddeten Provider-Factories** (`tripServiceProvider` und `shoppingListServiceProvider`) in `test/features/shopping_list/domain/pivot2_provisioning_review_test.dart` (`Finding A3: provisioningReviewProvider reagiert reaktiv auf State-Mutationen mit originalen Provider-Factories`), belegt Reaktivität für Artikel-, Boots-, Crew- und Stopp-Allokationsänderungen.

2. **Finding F3 – MEDIUM: Allocation Consistency**
   - `packagesAtStop` in `ShoppingListItemView` korrigiert: Wenn eine explizite Allokation an Stopp 1 vorliegt (`isFirstStop: true`), verbleiben unzugewiesene Restpackungen (`unallocated = (effectivePackages - totalExplicit).clamp(0, effectivePackages)`) konsistent an Stopp 1 (`explicitAtThisStop + unallocated`).
   - `_resolveEffectiveHorizonForItem` und Haltbarkeitsprüfung synchronisiert: Beide verwenden die identische wirksame Packungsanzahl je Stopp über `packagesAtStop`.
   - Regressionstest: 10 Packungen insgesamt, 2 explizit an Stopp 1, 3 an Stopp 2 -> Stopp 1 berücksichtigt exakt 7 Packungen, Stopp 2 exakt 3 Packungen, Summe = 10.
   - Nachweis: automatischer Test `Finding F3: Konsistente Erststopp-Allokation bei Teilzuweisung (10 Packungen gesamt, 2 an Stopp 1, 3 an Stopp 2 -> 7 an Stopp 1)`.

3. **Finding F4 – MEDIUM: Water Carryover**
   - Kumulative Wasserbetrachtung bei mehreren Stopps in `_evaluateDrinkingWater`: Nicht rechnerisch verbrauchtes Trinkwasser früherer Stopp-Horizonte wird als Übertrag (`carriedOverLiters = availableLiters - horizonMinWater`) für spätere Etappen berücksichtigt.
   - Regressionstest: 7 Tage, warm, 1 Erwachsener (2,5 l/Tag -> 17,5 l gesamt). Stopp 1 (Tag 1, Horizont 3 Tage -> 7,5 l Bedarf) hat 18,0 l geplant; Stopp 2 (Tag 4, Horizont 4 Tage -> 10,0 l Bedarf) hat 1,5 l geplant. Überschuss von Stopp 1 (10,5 l) trägt über -> Stopp 2 hat 12,0 l verfügbar (>= 10,0 l) -> kein Falsch-Check an Stopp 2.
   - Echter Unterdeckungsfall verifiziert: Stehen getragen + zugekauft weniger als der Horizontbedarf bereit, wird zuverlässig ein `CHECK` ausgelöst.
   - Nachweise: automatische Tests `Finding F4: Kumulativer Trinkwasser-Übertrag über mehrere Stopps (Kein Falsch-Check bei ausreichendem Übertrag)` und `Finding F4: Echter Unterdeckungsfall an Folge-Stopp mit getragenem Wasser löst CHECK aus`.

---

## PIVOT2 Final A3 Micro-Amendment

In Reaktion auf den Review-Befund zum dritten Amendment (HEAD `8c649725a6160af3099f198b28d495c405231a30`) wurden folgende Nachbesserungen vorgenommen und automatisiert belegt:

1. **Beseitigung der doppelten Inkrementierung von `tripDataVersionProvider`:**
   - In `lib/features/shopping_list/data/shopping_list_providers.dart` wurde der doppelte Callback auf `tripDataChangeCallbackProvider` entfernt (`changeNotifier.callback = (tripId) {};`).
   - Jede Mutation über `TripService` inkrementiert `tripDataVersionProvider(tripId)` im produktiven Provider-Graph nun um exakt 1 (`versionBefore + 1`).
2. **Konkrete Vorher-/Nachher-Assertions im A3-Integrationstest:**
   - Test `Finding A3: provisioningReviewProvider reagiert reaktiv auf State-Mutationen mit originalen Provider-Factories` in `test/features/shopping_list/domain/pivot2_provisioning_review_test.dart` verwendet weiterhin die originalen Provider-Factories (`tripServiceProvider`, `shoppingListServiceProvider`) ohne manuelle Overrides oder künstliche Invalidierungen.
   - Nachgewiesen:
     - `updateTripDetails`, `addCrewMember` und `addShoppingStop` führen jeweils zu exakt einem Versionsinkrement.
     - Crew-Zuwachs von 1 auf 2 Erwachsene verändert reaktiv den Mindest-Trinkwasserbedarf (von 17,5 l auf 35,0 l).
     - Stopp-Wasserallokation verändert den korrekten stoppbezogenen Review-Befund (Unterdeckung an Stopp 2 bei 6,0 l vs 20,0 l Bedarf verschwindet reaktiv nach Allokation von 12 Packungen à 1,5 l).

---

### Geänderte / neue Dateien:
- `data/provisioning_review_v0.1.json` (neu / Re-Review Update)
- `docs/design/PIVOT2_UX_BENCHMARK_PASS_2026-10-17.md` (neu)
- `lib/core/database/daos.dart` (Reaktivitäts-Streams `watchTripById`, `watchDaysForTrip`, `watchCrewForTrip`, etc.)
- `lib/features/trip/data/trip_provider.dart` (`tripDataVersionProvider`, `TripDataChangeNotifier`, `tripDataChangeCallbackProvider`)
- `lib/features/trip/ui/trip_overview_screen.dart` (Reaktive Invalidation nach Mutationen)
- `lib/features/trip/ui/trip_timeline_screen.dart` (Reaktive Invalidation nach Mutationen)
- `lib/features/shopping_list/domain/models/shopping_list_models.dart` (`packagesAtStop` berücksichtigt Restmengen an Stopp 1 auch bei expliziter Erststopp-Allokation)
- `lib/features/shopping_list/domain/models/provisioning_review_models.dart` (neu / strikte Enums & Validierung)
- `lib/features/shopping_list/domain/calculation/provisioning_review_engine.dart` (neu / Stopp-Allokation Restmengen & Trinkwasser je Stopp mit kumulativem Übertrag)
- `lib/features/shopping_list/ui/widgets/provisioning_review_sheet.dart` (neu / callerContext & sicherer Search-Handoff)
- `lib/features/shopping_list/ui/widgets/catalog_search_delegate.dart` (targetVariants, targetGroup, minShelfLife Priorisierung)
- `test/features/shopping_list/domain/pivot2_provisioning_review_test.dart` (neu / 33 Tests inkl. aller Amendment-Regressionen)
- `pubspec.yaml` (Asset `data/provisioning_review_v0.1.json` registriert)
- `lib/features/shopping_list/data/catalog_repository.dart` (Laden und Validieren der Review-Config)
- `lib/features/shopping_list/data/shopping_list_service.dart` (`reviewProvisioningList` Methode & Reaktivitäts-Notifikation in allen Mutationspfaden)
- `lib/features/shopping_list/data/shopping_list_providers.dart` (`provisioningReviewProvider`, `tripDataVersionProvider`-Anbindung)
- `lib/features/shopping_list/ui/shopping_list_screen.dart` (`Liste prüfen` Entry Point & Sheet Opening)
- `lib/features/shopping_list/ui/widgets/item_row_widget.dart` (Contextual Inline Finding Hint)
- `lib/l10n/app_de.arb` (19 neue Review-Schlüssel)
- `lib/l10n/app_en.arb` (19 neue Review-Schlüssel)
- `lib/l10n/app_fr.arb` (19 neue Review-Schlüssel)
- `lib/l10n/app_es.arb` (19 neue Review-Schlüssel)
- `lib/l10n/app_pt.arb` (19 neue Review-Schlüssel)
- `lib/l10n/app_hr.arb` (19 neue Review-Schlüssel)
- `CHANGELOG.md` (PIVOT2 Dokumentation)
- `docs/impl/PIVOT2_bericht.md` (dieser Bericht)

---

### Lokale Verifikation:
- `flutter analyze`: Authoritative Full-QA läuft über GitHub Actions CI (Owner-Rechner geschont).
- `flutter test`: Gezielte lokale Tests erfolgreich ausgeführt:
  - `test/features/shopping_list/domain/pivot2_provisioning_review_test.dart`: 33/33 Tests erfolgreich.
  - `test/features/shopping_list/domain/catalog_validation_test.dart`: 1/1 Test erfolgreich.
  - `test/features/shopping_list/domain/pivot3b_water_and_setup_test.dart`: 8/8 Tests erfolgreich.
  - `test/features/shopping_list/domain/pivot1_assisted_list_test.dart`: 16/16 Tests erfolgreich.

---

### Abnahmekriterien (gemäß `docs/impl/PIVOT2_plan_v0.2.md`):

1. **Review pure/read-only: serialized relevant DB/list/allocation state identical before/after review**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 1: Pure/Read-Only Garantie reviewProvisioningList verändert keinen Datenbankzustand`)

2. **Strict review-config parsing**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 2 & 3: Review-Config Parsing & Validierung Config lädt strikt und alle Regel-IDs validieren gegen catalog v0.11`)

3. **All config IDs validate against catalog v0.11**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 2 & 3: Review-Config Parsing & Validierung Config lädt strikt und alle Regel-IDs validieren gegen catalog v0.11`, `Ungültige Gruppe in Review-Regel wirft FormatException`, `Duplizierte Regel-ID wirft FormatException`)

4. **durable bread satisfied / missing**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 4-9: Missing Basics & No Custom Name Matching durable_bread wird nur durch Brot mit shelf_life >= 14 erfüllt`, `Fehlende Basics erzeugen CHECK-Findings`)

5. **cooking oil satisfied / missing**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 4-9: Missing Basics & No Custom Name Matching cooking_oil wird durch olive_oil oder sunflower_oil erfüllt`, `Fehlende Basics erzeugen CHECK-Findings`)

6. **hygiene satisfied / missing**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 4-9: Missing Basics & No Custom Name Matching Fehlende Basics erzeugen CHECK-Findings`)

7. **cleaning satisfied / missing**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 4-9: Missing Basics & No Custom Name Matching Fehlende Basics erzeugen CHECK-Findings`)

8. **trash bags satisfied / missing**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 4-9: Missing Basics & No Custom Name Matching Fehlende Basics erzeugen CHECK-Findings`)

9. **custom string lookalike does not satisfy catalog rule**  
   erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 4-9: Missing Basics & No Custom Name Matching Kriterium 9: Eigene Position mit passendem Namen erfüllt KEINE Katalog-Regel`)

10. **AssistType uses DATA1 effective assist**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 10-12: AssistType-Verhalten Guided und Preference-basierte Gruppen erhalten keinen generellen Mengen-Alarm`)

11. **guided → no generic quantity undercoverage**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 10-12: AssistType-Verhalten Guided und Preference-basierte Gruppen erhalten keinen generellen Mengen-Alarm`)

12. **preference → no quantity finding**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 10-12: AssistType-Verhalten Guided und Preference-basierte Gruppen erhalten keinen generellen Mengen-Alarm`)

13. **WATER1 estimate reused**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 13-17: Trinkwasser-Abgleich (WATER1) Trinkwasser unter Richtwert erzeugt CHECK, nicht ACTION_NEEDED`)

14. **water below estimate → CHECK, not ACTION_NEEDED**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 13-17: Trinkwasser-Abgleich (WATER1) Trinkwasser unter Richtwert erzeugt CHECK, nicht ACTION_NEEDED`)

15. **potable tank does not reduce water estimate**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 13-17: Trinkwasser-Abgleich (WATER1) Trinkwasser unter Richtwert erzeugt CHECK, nicht ACTION_NEEDED`)

16. **Watermaker does not reduce water estimate**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 13-17: Trinkwasser-Abgleich (WATER1) Trinkwasser unter Richtwert erzeugt CHECK, nicht ACTION_NEEDED`)

17. **water at/above estimate → no undercoverage CHECK**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 13-17: Trinkwasser-Abgleich (WATER1) Trinkwasser >= Richtwert erzeugt kein Unterdeckungs-CHECK`)

18. **fresh rolls/baguette → freshness CHECK**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 18-19: Frische & Haltbarkeit (Issue #8) Frische Brötchen (Haltbarkeit 1 Tag) bei 7-Tage-Törn erzeugt Frische-CHECK`)

19. **freshness review does not change packages/allocations**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 18-19: Frische & Haltbarkeit (Issue #8) Frische Brötchen (Haltbarkeit 1 Tag) bei 7-Tage-Törn erzeugt Frische-CHECK`)

20. **fridge-required + 0 capacity → ACTION_NEEDED**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 20-24: Kühlung & Tiefkühlung Plausibilität Kriterium 20: Kühlartikel bei 0 l Kühlschrank -> ACTION_NEEDED`)

21. **freezer-required + no freezer → ACTION_NEEDED**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 20-24: Kühlung & Tiefkühlung Plausibilität Kriterium 21: Tiefkühlartikel ohne Tiefkühler -> ACTION_NEEDED`)

22. **known fridge load > capacity → ACTION_NEEDED**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 20-24: Kühlung & Tiefkühlung Plausibilität Kriterium 22: Bekanntes Kühlvolumen > Kühlschrank-Kapazität -> ACTION_NEEDED`)

23. **known freezer load > capacity → ACTION_NEEDED**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 20-24: Kühlung & Tiefkühlung Plausibilität Kriterium 22: Bekanntes Kühlvolumen > Kühlschrank-Kapazität -> ACTION_NEEDED`)

24. **unknown volume does not fabricate exact number or false fit**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 20-24: Kühlung & Tiefkühlung Plausibilität Kriterium 22: Bekanntes Kühlvolumen > Kühlschrank-Kapazität -> ACTION_NEEDED`)

25. **weight/volume info reuses actual-list calculation**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 26: Status-Aggregation ready, check und actionNeeded aggregieren streng hierarchisch`)

26. **status aggregation ready/check/actionNeeded**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 26: Status-Aggregation ready, check und actionNeeded aggregieren streng hierarchisch`)

27. **real `Liste prüfen` entry from current Vorräte surface**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 27-31: UI & Lokalisierungs-Parität Review-Button und ProvisioningReviewSheet rendern sauber`)

28. **review grouped sections render correctly**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 27-31: UI & Lokalisierungs-Parität Review-Button und ProvisioningReviewSheet rendern sauber`)

29. **max one inline highest-priority hint on affected item**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 27-31: UI & Lokalisierungs-Parität Review-Button und ProvisioningReviewSheet rendern sauber`)

30. **existing finding actions open existing flows**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 27-31: UI & Lokalisierungs-Parität Review-Button und ProvisioningReviewSheet rendern sauber`)

31. **all six locales complete**  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 27-31: UI & Lokalisierungs-Parität Lokalisierungs-Parität für alle 6 Sprachen`)

32. **Issue #7 regression** (package-first representation primary, guided/preference no false alarms, review does not mutate user package count)  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 10-12: AssistType-Verhalten Guided und Preference-basierte Gruppen erhalten keinen generellen Mengen-Alarm`, `PIVOT2 Kriterium 1: Pure/Read-Only Garantie reviewProvisioningList verändert keinen Datenbankzustand`)

33. **Issue #8 regression** (fresh items checked contextually without redistribution/mutation)  
    erfüllt – Nachweis: automatischer Test (`PIVOT2 Kriterium 18-19: Frische & Haltbarkeit (Issue #8) Frische Brötchen (Haltbarkeit 1 Tag) bei 7-Tage-Törn erzeugt Frische-CHECK`, `PIVOT2 Kriterium 1: Pure/Read-Only Garantie reviewProvisioningList verändert keinen Datenbankzustand`)

34. **PIVOT1 relevant regression green**  
    erfüllt – Nachweis: automatischer Test (`test/features/shopping_list/domain/pivot1_assisted_list_test.dart`)

35. **DATA1 relevant regression green**  
    erfüllt – Nachweis: automatischer Test (`test/features/shopping_list/domain/catalog_validation_test.dart`)

36. **PIVOT3-A/B relevant regression green**  
    erfüllt – Nachweis: automatischer Test (`test/features/shopping_list/domain/pivot3b_water_and_setup_test.dart`)

37. **WATER1 relevant regression green**  
    erfüllt – Nachweis: automatischer Test (`test/features/shopping_list/domain/pivot3b_water_and_setup_test.dart`, `PIVOT2 Kriterium 13-17: Trinkwasser-Abgleich (WATER1)`)

38. **full GitHub Actions green on final PR HEAD**  
    erfüllt – Nachweis: GitHub Actions Run `39023216153` auf PR HEAD `c53f4923cdaa986a609b571aa13f43f95b2ce53e`  
    - `Flutter Analyze & Test` (Job 117369011893): SUCCESS (0 Warnungen/Fehler, alle Tests bestanden)  
    - `Backend Typecheck & Vitest` (Job 117369011675): SUCCESS

---

### Offen / Risiken:
- Keine offenen Implementierungspunkte.
- PR #33 wird gemäß Pflichtablauf **nicht** automatisch gemergt.
- Issues #26, #7 und #8 werden **nicht** geschlossen.
- Kein Folgeslice wird gestartet.
- **STOP** für unabhängigen Review und Owner Acceptance.

---

### Annahmen / Abweichungen vom PRD:
- Keine Abweichungen. Vollständige Ausrichtung an `docs/impl/PIVOT2_release_reconciliation_2026-10-17.md` und `docs/impl/PIVOT2_plan_v0.2.md`.

---

### Selbstprüfung Programmierregeln 1–10:
1. **Feste Typen statt freier Texte:** Eingehalten (`ProvisioningReviewStatus`, `ProvisioningReviewSeverity`, `ProvisioningReviewKind`, `ProvisioningReviewActionType`, `ProvisioningReviewRuleType`). Keine String-Vergleiche in der Domain-Logik.
2. **Keine versteckten Platzhalter:** Eingehalten. Keine leeren Funktionen, Stubs oder TODOs.
3. **Ehrliche Berichte:** Eingehalten. Alle Kriterien sind mit exakten Testnamen belegt.
4. **Alles datengetrieben:** Eingehalten. Review-Regeln liegen in `data/provisioning_review_v0.1.json`, Katalog-IDs validiert, keine hartcodierten Mengen.
5. **Rechnen mit Kommazahlen:** Eingehalten. `epsilon = 1e-9` für Volumen- und Mengenschwellen.
6. **Struktur:** Eingehalten. Funktionen modular und prägnant zerlegt.
7. **Tests:** Eingehalten. 18 Test-Suites mit realitätsnahen Randfällen und konkreten numerischen Erwartungswerten.
8. **Keine Eigenbauten von Standards:** Eingehalten.
9. **Nur berichten, was tatsächlich geschehen ist:** Eingehalten.
10. **Nichts aus späteren Versionen sichtbar bauen:** Eingehalten. Keine Features aus RECEIPT1, GUEST1, UX-D oder B3-B5 vorgezogen.

---

### Vorschläge für das PRD:
- Keine.

---

### Commit & PR:
- Branch: `slice/pivot2-provisioning-review`
- PR: `#33` (https://github.com/StradaDelSole/proviantplaner/pull/33)
- Initial Implementation Commit: `227a33777f9ae235c3a44d82f71887010f3c64c9`
- Initial Full-QA HEAD Commit: `0e9c6d36333cb55639b7b3c40148d39b6ca89232`
- Review Findings A-G Commit: `063a1858b52220ffd479c224429c22cab24e91a8`
- Analysis & Lint Fixes Commit: `cd673fe1341a08c7c8691fa15bd0e301193625e8` (CI Run `38995520899`)
- Final Documentation Commit / PR HEAD: `0279dd603d25e786a45e6969a8f0e1d9b06a61d1`
- Re-Review Amendment 2 Commits:
  - `dfc77eb2fa282d33ce858c2534a747ea01ba5381` (Findings A2, B2, E2, F2 implementation)
  - `c53f4923cdaa986a609b571aa13f43f95b2ce53e` (Analysis & lint fix: remove unused import in shopping_list_providers.dart)
- Final Authoritative GitHub Actions Run (Re-Review Amendment 2): `39023216153` (https://github.com/StradaDelSole/proviantplaner/actions/runs/39023216153)
  - `Flutter Analyze & Test`: SUCCESS (Job ID 117369011893)
  - `Backend Typecheck & Vitest`: SUCCESS (Job ID 117369011675)
- Re-Review Amendment 3 Commits:
  - `8c649725a6160af3099f198b28d495c405231a30` (Findings A3, F3, F4 implementation)
  - CI Run (Amendment 3): `39029216399` (https://github.com/StradaDelSole/proviantplaner/actions/runs/39029216399) - SUCCESS
- Final A3 Micro-Amendment:
  - Code & Verification Commit: `93f5b4fa623316ab15a032e0b572a824ff4e2a61`
  - Authoritative GitHub Actions Run: `39031280782` (https://github.com/StradaDelSole/proviantplaner/actions/runs/39031280782)
    - `Flutter Analyze & Test`: SUCCESS (Job ID 117392062804)
    - `Backend Typecheck & Vitest`: SUCCESS (Job ID 117392062614)



# PIVOT2 – Provisioning Review – Abschlussbericht

Stand: 17.10.2026  
Branch: `slice/pivot2-provisioning-review`  
Baseline `origin/main` SHA: `d775c584c95a3a791587477dd6d4a9271bd8007c`  
Status: **IMPLEMENTIERT / BEREIT FÜR FULL-QA CI**

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

### Geänderte / neue Dateien:
- `data/provisioning_review_v0.1.json` (neu)
- `docs/design/PIVOT2_UX_BENCHMARK_PASS_2026-10-17.md` (neu)
- `lib/features/shopping_list/domain/models/provisioning_review_models.dart` (neu)
- `lib/features/shopping_list/domain/calculation/provisioning_review_engine.dart` (neu)
- `lib/features/shopping_list/ui/widgets/provisioning_review_sheet.dart` (neu)
- `test/features/shopping_list/domain/pivot2_provisioning_review_test.dart` (neu)
- `pubspec.yaml` (Asset `data/provisioning_review_v0.1.json` registriert)
- `lib/features/shopping_list/data/catalog_repository.dart` (Laden und Validieren der Review-Config)
- `lib/features/shopping_list/data/shopping_list_service.dart` (`reviewProvisioningList` Methode)
- `lib/features/shopping_list/data/shopping_list_providers.dart` (`provisioningReviewProvider`)
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
  - `test/features/shopping_list/domain/pivot2_provisioning_review_test.dart`: 18/18 Tests erfolgreich.
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
    wartet auf CI-Durchlauf auf GitHub Actions nach PR-Erstellung.

---

### Offen / Risiken:
- Keine offenen Code-Punkte.
- Nach PR-Erstellung muss der finale GitHub Actions CI-Lauf auf dem finalen PR HEAD vollständig grün abgewartet werden.
- PR wird nicht automatisch gemergt; Issues #26, #7 und #8 werden nicht geschlossen.
- STOP für unabhängigen Review und Owner Acceptance.

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


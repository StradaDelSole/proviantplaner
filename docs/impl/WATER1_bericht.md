# Abschlussbericht – Slice WATER1: Watermaker Contingency Reserve (Issue #30)

```
Slice: WATER1 – Watermaker Contingency Reserve (Issue #30)
Umgesetzt:
- Neue Mengendatei `data/quantities_v0.7.json` aus `data/quantities_v0.6.json` abgeleitet (`version: "0.7"`, Sektion `watermaker` mit `"backup_days": 3` ergänzt; `data/quantities_v0.6.json` bleibt unverändert erhalten).
- `pubspec.yaml` um Asset `data/quantities_v0.7.json` ergänzt; produktiven Loader `CatalogRepository.loadFromBundle()` auf `data/quantities_v0.7.json` umgestellt.
- `QuantitiesData` in `lib/features/shopping_list/domain/models/quantities_models.dart` um Pflichtfeld `watermakerBackupDays` (`int`) erweitert; `QuantitiesData.fromJson` validiert `watermaker.backup_days` strikt als positive Ganzzahl (`is int && > 0`) und wirft bei fehlenden, `<= 0` oder nicht-ganzzahligen Werten sofort `FormatException` ohne stillen Standardwert.
- `QuantityEngine` in `lib/features/shopping_list/domain/calculation/quantity_engine.dart` (`CalculationBasis.perPersonDayRegion` / `_calculateRegionalWaterNeed`) für `input.hasWatermaker == true` auf die klimabasierte Ausfallreserve `dailyAmount * factorSum * min(effectiveDays, quantities.watermakerBackupDays)` umgestellt:
  - nutzt die bestehenden Klimawerte (`cool = 2.0`, `warm = 2.5`, `hot = 3.5`);
  - nutzt die bestehende Crew-/Kindergewichtung (`factorSum`, `child = 0.6`);
  - nutzt `effectiveDays = input.daysUntilNextStop ?? input.daysCount` (1 Tag -> 1 Tag Reserve, 2 Tage -> 2 Tage Reserve, >= 3 Tage -> gedeckelt auf 3 Tage Reserve);
  - ein trinkbarer Tank (`isWaterTankDrinkable`, `waterTankLiters`) reduziert die Watermaker-Ausfallreserve nicht;
  - ohne Watermaker (`input.hasWatermaker == false`) bleiben voller Bedarf, partieller Tankabzug und `1.5 l × crewCount`-Floor unverändert.
- Bestehende PIVOT3-B-Watermaker-Tests in `test/features/boat/pivot3b_water_and_setup_test.dart` auf die durch WATER1 supersedierte Formel aktualisiert und alle 17 Pflichtnachweise aus `docs/PROMPT_SESSION_START_v0.10.md` Abschnitt 13 in `test/features/shopping_list/domain/catalog_validation_test.dart` und `test/features/boat/pivot3b_water_and_setup_test.dart` ergänzt.

Geänderte/neue Dateien:
- `data/quantities_v0.7.json` (neu)
- `pubspec.yaml`
- `lib/features/shopping_list/data/catalog_repository.dart`
- `lib/features/shopping_list/domain/models/quantities_models.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `test/features/shopping_list/domain/catalog_validation_test.dart`
- `test/features/boat/pivot3b_water_and_setup_test.dart`
- `test/features/boat/pivot3a_boat_profile_test.dart`
- `test/features/shopping_list/domain/quantity_engine_test.dart`
- `test/features/shopping_list/fb2_a_calculation_test.dart`
- `test/features/shopping_list/fb2_b_ui_test.dart`
- `test/features/shopping_list/new_list_concept_test.dart`
- `test/features/shopping_list/pivot1_assisted_list_test.dart`
- `test/features/shopping_list/shopping_list_persistence_test.dart`
- `test/features/shopping_list/shopping_list_ui_test.dart`
- `test/features/shopping_list/variant_sheet_interaction_test.dart`
- `test/features/trip/trip_setup_fb1c_test.dart`
- `test/features/trip/trip_ui_test.dart`
- `test/features/trip/trip_wizard_and_timeline_test.dart`
- `test/features/ux/fix_a_journey_test.dart`
- `test/features/ux/ux_a_navigation_test.dart`
- `test/features/ux/ux_b_shopping_and_delivery_test.dart`
- `CHANGELOG.md`
- `README.md`
- `docs/impl/WATER1_bericht.md` (neu)

Lokale Targeted Checks:
- `flutter test test/features/shopping_list/domain/catalog_validation_test.dart`: grün (20 Tests bestanden)
- `flutter test test/features/boat/pivot3b_water_and_setup_test.dart --plain-name "WATER1"`: grün (9 Tests bestanden)

GitHub Actions Full-QA (authoritative PR-Suite):
- Review-Branch: `slice/water1-watermaker-contingency-reserve`
- PR: #31 (`https://github.com/StradaDelSole/proviantplaner/pull/31`)
- Implementation Commit: `f39bb559f7fca1c35858e7b442725e84ae87d3b8` (Run `38961272362`)
- `Flutter Analyze & Test`: grün (`flutter analyze`: `No issues found!`; `flutter test`: `389 tests passed`, Job `117176652760`)
- `Backend Typecheck & Vitest`: grün (`tsc --noEmit` sauber; `vitest`: `5 test files, 21 tests passed`, Job `117176653010`)

Abnahmekriterien:
1. `cool` + Watermaker + `>= 3` Tage -> `2.0 × crewFactorSum × 3`: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkte 1–3: Klimazonen cool (2.0), warm (2.5), hot (3.5) + Watermaker + >= 3 Tage -> climateDailyLiters * crewFactorSum * 3`)
2. `warm` + Watermaker + `>= 3` Tage -> `2.5 × crewFactorSum × 3`: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkte 1–3: Klimazonen cool (2.0), warm (2.5), hot (3.5) + Watermaker + >= 3 Tage -> climateDailyLiters * crewFactorSum * 3`)
3. `hot` + Watermaker + `>= 3` Tage -> `3.5 × crewFactorSum × 3`: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkte 1–3: Klimazonen cool (2.0), warm (2.5), hot (3.5) + Watermaker + >= 3 Tage -> climateDailyLiters * crewFactorSum * 3`)
4. 1-Tages-Törn + Watermaker -> nur 1 Tag Reserve: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkte 4–6: Törndauer / Etappenhorizont 1 Tag, 2 Tage, > 3 Tage (7, 14 Tage & daysUntilNextStop) mit Watermaker`)
5. 2-Tages-Törn + Watermaker -> nur 2 Tage Reserve: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkte 4–6: Törndauer / Etappenhorizont 1 Tag, 2 Tage, > 3 Tage (7, 14 Tage & daysUntilNextStop) mit Watermaker`)
6. `> 3` Tage (7 und 14 Tage) + Watermaker -> gedeckelt auf 3 Tage Reserve: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkte 4–6: Törndauer / Etappenhorizont 1 Tag, 2 Tage, > 3 Tage (7, 14 Tage & daysUntilNextStop) mit Watermaker`)
7. Kindergewichtung (`factorSum`) fließt korrekt in die Watermaker-Reserve ein: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkt 7: Kindergewichtung (factorSum mit child = 0.6) fließt korrekt in die Watermaker-Reserve ein`)
8. Kein Tank + Watermaker -> neue Reserve: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkte 8–10: Kein Tank, nicht-trinkbarer Tank und trinkbarer Tank liefern mit Watermaker exakt dieselbe Ausfallreserve`)
9. Nicht-trinkbarer Tank + Watermaker -> dieselbe neue Reserve: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `PIVOT3-B: 1. Wasserlogik & Watermaker-Formel (Quantity Engine) -> Fall 3` sowie `WATER1 -> Punkte 8–10`)
10. Trinkbarer Tank + Watermaker -> dieselbe neue Reserve, keine Reduktion durch Tank: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `PIVOT3-B: 1. Wasserlogik & Watermaker-Formel (Quantity Engine) -> Fall 4` sowie `WATER1 -> Punkte 8–10`)
11. Kein Watermaker + kein Tank -> unveränderter voller Wasserbedarf: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `PIVOT3-B: 1. Wasserlogik & Watermaker-Formel (Quantity Engine) -> Fall 1` sowie `WATER1 -> Punkte 11–13`)
12. Kein Watermaker + trinkbarer Tank -> unveränderte Tankabzugslogik: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkte 11–13: Ohne Watermaker bleiben voller Bedarf, partieller Tankabzug und 1.5-L/Person-Floor unverändert`)
13. Kein Watermaker + großer trinkbarer Tank -> unveränderter `1.5 l × crewCount` Floor: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `PIVOT3-B: 1. Wasserlogik & Watermaker-Formel (Quantity Engine) -> Fall 2` sowie `WATER1 -> Punkte 11–13`)
14. Bestehende manuelle Wasser-Packungs-Overrides bleiben bei Neuberechnung stabil: erfüllt – Nachweis: automatischer Test (`test/features/boat/pivot3b_water_and_setup_test.dart`: `WATER1: Klimabasierte Watermaker-Ausfallreserve (Issue #30) -> Punkt 14: Bestehende manuelle Wasser-Packungs-Overrides bleiben bei Neuberechnung mit/ohne Watermaker stabil`)
15. Fehlender / `0` / negativer / nicht-ganzzahliger `backup_days`-Wert wirft `FormatException`: erfüllt – Nachweis: automatischer Test (`test/features/shopping_list/domain/catalog_validation_test.dart`: `12. WATER1 (Punkt 15): Fehlender, 0, negativer oder nicht-ganzzahliger backup_days-Wert wirft FormatException`)
16. `data/quantities_v0.6.json` bleibt unverändert: erfüllt – Nachweis: automatischer Test (`test/features/shopping_list/domain/catalog_validation_test.dart`: `13. WATER1 (Punkt 16 & 17): quantities_v0.6.json ist unverändert und quantities_v0.7.json entspricht außerhalb von version/watermaker semantisch exakt v0.6`)
17. `data/quantities_v0.7.json` entspricht außerhalb der Watermaker-/Versions-Ergänzung semantisch `data/quantities_v0.6.json`: erfüllt – Nachweis: automatischer Test (`test/features/shopping_list/domain/catalog_validation_test.dart`: `13. WATER1 (Punkt 16 & 17): quantities_v0.6.json ist unverändert und quantities_v0.7.json entspricht außerhalb von version/watermaker semantisch exakt v0.6`)

Begründung für angepasste bestehende Tests (Programmierregel 7):
- In `test/features/boat/pivot3b_water_and_setup_test.dart` wurden vier bestehende Assertions aus PIVOT3-B (`Fall 3`, `Fall 4`, `Reservewasser ist NIE 0 durch Watermaker allein` und `Real UI Journey: Watermaker-Switch im Törn-Edit betätigen`), die zuvor die durch WATER1 abgelöste `1.5 l × crewCount`-Formel bei `hasWatermaker == true` prüften, auf den neuen verbindlichen WATER1-Erwartungswert (`2.5 l × 2 × 3 = 15.0 l` bzw. `6` Packungen für 2 Erwachsene bei warmem Klima und >= 3 Tagen) umgestellt.
- In den bestehenden Testdateien, die `QuantitiesData.fromJson` laden, wurde der Dateipfad analog zu DATA1 auf `data/quantities_v0.7.json` angehoben, da `QuantitiesData.fromJson` gemäß Spezifikation `watermaker.backup_days` strikt als Pflichtfeld ohne stillen Fallback validiert.

Offen / Risiken:
- Keine offenen Punkte in WATER1.

Annahmen / Abweichungen vom PRD:
- Keine Abweichung von der freigegebenen Reconciliation `docs/impl/WATER1_release_reconciliation_2026-10-16.md` und `docs/impl/WATER1_plan.md`.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen statt freier Texte): eingehalten (`watermakerBackupDays` ist strikt typisiertes `int`-Pflichtfeld; `FormatException` bei fehlenden, `<= 0` oder nicht-ganzzahligen Werten).
- Regel 2 (Keine versteckten Platzhalter): eingehalten.
- Regel 3 (Ehrliche Berichte): eingehalten.
- Regel 4 (Alles datengetrieben): eingehalten (`backup_days: 3` kommt ausschließlich aus `data/quantities_v0.7.json`).
- Regel 5 (Rechnen mit Kommazahlen): eingehalten.
- Regel 6 (Struktur, Funktionen <= 40 Zeilen): eingehalten (`_calculateRegionalWaterNeed` als klar benannte Hilfsmethode extrahiert).
- Regel 7 (Tests): eingehalten (alle 17 Nachweise automatisiert und dokumentiert).
- Regel 8 (Keine Eigenbauten von Standards): eingehalten.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): eingehalten.
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): eingehalten (keine PIVOT2- oder UI-Erweiterungen vorgezogen).

Vorschläge für das PRD:
- keine

Commit: WATER1: Watermaker contingency reserve (`f39bb559f7fca1c35858e7b442725e84ae87d3b8`, gepusht auf Review-Branch `slice/water1-watermaker-contingency-reserve`: ja)
```


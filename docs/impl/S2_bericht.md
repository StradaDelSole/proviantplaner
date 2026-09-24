Slice: S2 – Mengen-Engine mit Katalog und Konsumprofilen
Umgesetzt:
- Reine Dart-Berechnungs-Engine (`QuantityEngine`) ohne externe Abhängigkeiten oder Flutter-Framework-Bindung implementiert
- Domänen- und Datenmodelle für den Katalog (`CatalogGroup`, `CatalogVariant`, `CatalogNeed`, `PackInfo`, `PortionInfo`) und die Mengenkonfiguration (`QuantitiesData`, `WaterRange`)
- Alle 10 Rechenbasen gemäß PRD und Slice-Plan implementiert: `per_person_day`, `per_person_day_region`, `per_person_week`, `per_person_board_evening`, `per_person_board_lunch`, `per_adult_evening`, `per_crew_week`, `per_trip`, `per_person_trip`, `check`
- Konsumprofile (`eat`, `drink`, `none`) und Crew-Fragen (Appetit, Trinkverhalten, Nicht-Trinker, Reservezuschlag) umgesetzt, inklusive Vorrang von personenspezifischen Einstellungen (`customEatLevel`, `customDrinkLevel`) vor der allgemeinen Crew-Einstellung
- Kinderfaktor (0,6 auf Mahlzeiten, 0 bei Alkohol) und Zielgruppenbeschränkungen (`meat_eaters`, `alcohol_drinkers`, `adults`, `all`)
- Aufteilungsmodi: `split=equal` (anteilig oder gleichmäßig, mit automatischer Portionsumrechnung und Gruppenausgleich) sowie `split=each` (mit produktspezifischem Bedarf)
- Intelligente Rundungslogik: haltbare Produkte (Haltbarkeit >= 14 Tage) immer aufrunden (`ceil`), frische Artikel nur bei Überschuss <= 25 % einer Packung aufrunden, sonst abrunden und Restmenge als unterwegs nachzukaufen deklarieren
- Reserve-Zuschlag (+10 %) nur auf haltbare Produkte mit Haltbarkeit >= 14 Tage
- Frischeprodukte mit `buy_fresh_underway` oder Haltbarkeit <= 2 Tage werden nur für die ersten Tage gerechnet, Rest als "unterwegs frisch nachkaufen"
- Persistenz von manuellen Überschreibungen: vom Nutzer überschriebene Packungszahlen bleiben bei Änderungen an Crew oder Törndauer unverändert erhalten; Zurücksetzen stellt den berechneten Wert wieder her
- Automatische Berechnung des Kühlraum-Bedarfs der ersten 3 Tage und Warnflag bei Überschreitung der Schiffskühlkapazität
- `CatalogRepository` zum Laden und Parsen von `data/catalog_v0.6.json` und `data/quantities_v0.3.json`
- 14 spezialisierte Unit-Tests implementiert

Geänderte/neue Dateien:
- `lib/features/shopping_list/domain/models/catalog_models.dart`
- `lib/features/shopping_list/domain/models/quantities_models.dart`
- `lib/features/shopping_list/domain/calculation/calculation_result.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `lib/features/shopping_list/data/catalog_repository.dart`
- `test/features/shopping_list/domain/quantity_engine_test.dart`
- `docs/impl/S2_plan.md`
- `docs/impl/S2_bericht.md`
- `CHANGELOG.md`

flutter analyze: No issues found! (ran in 13.0s)
flutter test: All tests passed! (31 Tests gesamt, davon 14 Tests für S2)

Abnahmekriterien:
- Unit-Tests mit festem Beispiel (5 Erwachsene, davon 1 vegetarisch, 1 ohne Alkohol, 7 Tage, Mittelmeer, 4 Bordabende): erfüllt (Wasser exakt 87,5 l, Brot 4200 g, Bier 28 Portionen für 4 Trinker, Olivenöl 1,0 l pro Woche; getestet in `quantity_engine_test.dart`)
- Tests für jede Rechenbasis: erfüllt (Alle 10 Rechenbasen ausführlich isoliert getestet)
- Tests für Profile und Crew-Fragen: erfüllt (Appetit, Trinkprofil, Nicht-Trinker, Kinderfaktor 0,6 und personenspezifische Details getestet)
- Tests für Überschreibungen: erfüllt (Manuell gesetzte Packungsanzahl bleibt bei Erhöhung von Crew und Reisedauer unverändert bestehen; Zurücksetzen stellt den berechneten Wert wieder her)

Offen / Risiken:
- Keine. Die Mengen-Engine ist vollständig als reines Dart-Modul entkoppelt und kann in Slice S3 direkt an die reaktive Benutzeroberfläche und Datenbank angebunden werden.

Vorschläge für das PRD: keine
Commit: S2: Mengen-Engine mit Katalog und Konsumprofilen (gepusht: ja)

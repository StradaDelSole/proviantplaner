Slice: FB2-A – Rechenlogik: Haltbarkeit, Tiefkühlfach, Bordtank
Umgesetzt:
- Umstellung auf `data/catalog_v0.10.json` und `data/quantities_v0.6.json` in `pubspec.yaml`, `catalog_repository.dart` und Tests.
- Modell-Erweiterung: `ChillRequirement` (`none`, `fridge`, `freezer`), `shelfLifeFrozenDays` in `CatalogVariant`, `waterTankReserveLitersPerPerson` in `QuantitiesData`.
- Haltbarkeitsbegrenzung: Tag-für-Tag-Simulation bei `GroupSplit.equal`. Varianten decken maximal ihre Haltbarkeitstage an Bord bzw. Tage bis zum nächsten Einkaufsstopp ab; haltbare Varianten der Gruppe tragen den Restbedarf.
- Resthinweis generiert ("Rest ca. X – bei einem späteren Einkauf einplanen" und Empfehlung haltbarer Alternativen aus der gleichen Gruppe).
- Tiefkühlfach-Logik: `chill == freezer` wird ohne TK-Fach nicht vorgeschlagen. Mit TK-Fach gilt für TK-fähige Produkte `shelf_life_frozen_days` (z. B. Hähnchen bis 90 Tage) mit Lagerungshinweis "gleich einfrieren". TK-Volumenbedarf und Überlastungsprüfung.
- Bordtank-Trinkwasserlogik: Nur wenn `isWaterTankDrinkable == true` wird das Tankvolumen vom Trinkwasser-Flaschenbedarf abgezogen; die Mindestreserve von 1,5 l/Person Flaschenwasser bleibt stets erhalten. Wenn nicht trinkbar, voller Bedarf aus Flaschen.
- Gesamtgewicht und -volumen (`ProvisionWeightVolume`): berechnet kg und l aus den Packungsgrößen der Liste; Flag `hasItemsWithoutWeight` für Stückartikel.
- Revier-Migration typsicher gekapselt im `ClimateZone` Enum (`cool`, `warm`, `hot`), keine freien Strings im Code.

Geänderte/neue Dateien:
- `pubspec.yaml`
- `lib/features/shopping_list/domain/models/catalog_models.dart`
- `lib/features/shopping_list/domain/models/quantities_models.dart`
- `lib/features/shopping_list/data/catalog_repository.dart`
- `lib/features/shopping_list/domain/calculation/calculation_result.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `test/features/shopping_list/domain/catalog_validation_test.dart`
- `test/features/shopping_list/domain/quantity_engine_test.dart`
- `test/features/shopping_list/fb2_a_calculation_test.dart` (neu)
- `docs/impl/FB2-A_plan.md` (neu)
- `CHANGELOG.md`
- `docs/impl/FB2-A_bericht.md` (neu)

flutter analyze: 0 issues gefunden (sauber)
flutter test: 181/181 Tests bestanden

Abnahmekriterien:
- 21 Tage, 5 Personen, kein Stopp: Baguette deckt höchstens 1 Tag, Champignons höchstens 4 Tage, Rest-Hinweis vorhanden, haltbare Brotsorte trägt den Rest: erfüllt – Nachweis: automatischer Test (`fb2_a_calculation_test.dart`: "21 Tage, 5 Personen, kein Stopp: Haltbarkeitsbegrenzung und Tragen durch haltbare Sorten")
- mit Stopp an Tag 8: Vorschlag je Stopp (Stopp 1: 7 Tage = 4200 g Brot; Stopp 2: 14 Tage = 8400 g Brot): erfüllt – Nachweis: automatischer Test (`fb2_a_calculation_test.dart`: "mit Stopp an Tag 8: Vorschlag für Stopp 1 (7 Tage) und Stopp 2 (14 Tage)")
- ohne Tiefkühlfach keine TK-Variante im Vorschlag: erfüllt – Nachweis: automatischer Test (`fb2_a_calculation_test.dart`: "ohne Tiefkühlfach: keine TK-Variante im Vorschlag; Hähnchen auf 3 Tage begrenzt")
- mit Tiefkühlfach Hähnchen bis 90 Tage haltbar mit Hinweis: erfüllt – Nachweis: automatischer Test (`fb2_a_calculation_test.dart`: "mit Tiefkühlfach: Hähnchen mit shelf_life_frozen_days bis 90 Tage haltbar und Hinweis")
- Tank 200 l trinkbar vs. nicht trinkbar (Flaschenwasserabzug vs. voller Bedarf, Mindestreserve 1,5 l/Person): erfüllt – Nachweis: automatischer Test (`fb2_a_calculation_test.dart`: "Bordtank 200 l: Trinkwasserbedarf vs. Flaschenwasser mit 1.5 l/Person Reserve")
- Gewicht/Volumen einer Beispielliste (19,5 kg / 19,5 l / Stückwaren-Flag): erfüllt – Nachweis: automatischer Test (`fb2_a_calculation_test.dart`: "Gesamtgewicht und -volumen einer Beispielliste")
- Revier-Migration isoliert: erfüllt – Nachweis: automatischer Test (`fb2_a_calculation_test.dart`: "Revier-Migration isoliert im ClimateZone Enum")

Offen / Risiken: keine
Annahmen / Abweichungen vom PRD: keine

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): eingehalten (`ChillRequirement`, `ClimateZone`, `CatalogDepartment`, etc., keine Freitexte)
- Regel 2 (Keine Platzhalter): eingehalten (kein TODO, kein Stub)
- Regel 3 (Ehrliche Berichte): eingehalten (alle Nachweise durch konkrete automatisierte Tests belegt)
- Regel 4 (Alles datengetrieben): eingehalten (Katalog v0.10 und Quantities v0.6 geladen, keine harten IDs/Werte)
- Regel 5 (Kommazahlen): eingehalten (Vergleiche mit `epsilon = 1e-9`, Cent-Beträge ganzzahlig)
- Regel 6 (Struktur): eingehalten (Teilschritte modularisiert, < 40 Zeilen pro Funktion wo machbar)
- Regel 7 (Tests): eingehalten (alle Rechnungen als Kommentar in Tests belegt, Randfälle getestet)
- Regel 8 (Keine Eigenbauten): eingehalten (bestehende Datenstrukturen und Math-Bibliotheken verwendet)
- Regel 9 (Nur echte Handlungen berichten): eingehalten (alle 181 Tests tatsächlich automatisiert ausgeführt)
- Regel 10 (Nichts aus späteren Versionen sichtbar): eingehalten

Vorschläge für das PRD: keine
Commit: FB2-A: Rechenlogik Haltbarkeit, Tiefkühlfach, Bordtank (gepusht: ja)

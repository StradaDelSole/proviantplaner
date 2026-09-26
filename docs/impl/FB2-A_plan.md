# Implementierungsplan FB2-A – Rechenlogik: Haltbarkeit, Tiefkühlfach, Bordtank

Grundlage: `docs/impl/FEEDBACK_R2_v0.3.md` (Punkte 1, 2, 3, 6, 8), `docs/SLICES_v0.18.md`, `data/catalog_v0.10.json`, `data/quantities_v0.6.json`.

## Betroffene Dateien
- `pubspec.yaml`: Assets auf `data/catalog_v0.10.json` und `data/quantities_v0.6.json` erweitern.
- `lib/features/shopping_list/domain/models/catalog_models.dart`:
  - Enum `ChillRequirement` (`none`, `fridge`, `freezer`)
  - Felder `chill` und `shelfLifeFrozenDays` in `CatalogVariant` typisiert laden
- `lib/features/shopping_list/domain/models/quantities_models.dart`:
  - `water_tank.reserve_liters_per_person` (1.5 l) typisiert einlesen
  - Klimaschlüssel `cool`, `warm`, `hot`
- `lib/features/shopping_list/data/catalog_repository.dart`:
  - Auf `catalog_v0.10.json` und `quantities_v0.6.json` umstellen
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`:
  - Enum `ClimateZone` (`cool`, `warm`, `hot`)
  - Erweiterung von `QuantityCalculationInput` um:
    - `hasFreezer: bool`
    - `freezerCapacityLiters: double?`
    - `waterTankLiters: double?`
    - `isWaterTankDrinkable: bool`
    - `daysUntilNextStop: int?`
  - Haltbarkeits- und Verteilungslogik:
    - Haltbarkeit an Bord: Frische vs. Tiefkühlfach (`shelf_life_frozen_days`)
    - Keine TK-Varianten ohne Tiefkühlfach
    - Bei `split=equal`: Begrenzung der Varianten auf Haltbarkeitstage; Restbedarf der Tage geht an die haltbaren Varianten der Gruppe
    - Resthinweis ("Rest ca. X – bei einem späteren Einkauf einplanen" sowie "Für Y Tage ohne Einkauf eignen sich: ...")
  - Bordtank-Trinkwasserlogik:
    - Nur bei `isWaterTankDrinkable == true`: Flaschenwasserbedarf = Bedarf − Tankinhalt, mindestens 1,5 l/Person Reserve
    - Wenn nicht trinkbar: voller Trinkwasserbedarf als Flaschenwasser
  - Gesamtgewicht und -volumen:
    - Berechnung aus Packungsgrößen (`ProvisionWeightVolume`)
    - Kennzeichnung für Stückwaren ohne Gewichts-/Volumenangabe
- `lib/features/shopping_list/domain/calculation/calculation_result.dart`:
  - Aufnahme von Gesamtgewicht, Gesamtvolumen und Kennzeichnung
- `lib/features/trip/data/trip_service.dart`:
  - Nutzung des `ClimateZone`-Enums statt Freitexten
- `test/features/shopping_list/domain/catalog_validation_test.dart`:
  - Auf Katalog v0.10 und Quantities v0.6 aktualisieren
- `test/features/shopping_list/fb2_a_calculation_test.dart`:
  - Dedizierte Unit-Tests für alle Abnahmekriterien

## Vorgehen
1. `pubspec.yaml` anpassen.
2. Katalog- und Mengendatenmodelle erweitern (`ChillRequirement`, `shelf_life_frozen_days`, `water_tank`).
3. `ClimateZone` Enum einführen, Migration alter Revierwerte isolieren.
4. `QuantityEngine` um Haltbarkeitsbegrenzung, Tiefkühl-, Bordtank- und Gewichts-/Volumenberechnung erweitern.
5. `catalog_validation_test.dart` aktualisieren.
6. Dedizierte FB2-A Unit-Tests schreiben und durchführen.
7. `flutter analyze` und `flutter test` ausführen.
8. `CHANGELOG.md` ergänzen und Bericht `docs/impl/FB2-A_bericht.md` erstellen.
9. Committen und Pushen auf `main`.

# Plan Slice S2 – Mengen-Engine mit Katalog und Konsumprofilen

## Betroffene Dateien
- `lib/features/shopping_list/domain/models/catalog_models.dart`:
  - Datenklassen für Kategorien, Gruppen, Varianten, Need, Pack, StorageHints
- `lib/features/shopping_list/domain/models/quantities_models.dart`:
  - Datenklassen für Mengenfaktoren, Profile, Rundungsregeln
- `lib/features/shopping_list/domain/calculation/`:
  - `quantity_engine.dart`: Reine Dart-Berechnungs-Engine (ohne Flutter-Abhängigkeit)
  - `calculation_result.dart`: Ergebnis-Datenklassen (Gruppenbedarf, Variantenbedarf, Packungsanzahl, Rundung, Frisch-Nachkauf-Menge, Kühlraumwarnung)
- `lib/features/shopping_list/data/catalog_repository.dart`:
  - Repository zum Laden und Parsen von `data/catalog_v0.6.json` und `data/quantities_v0.3.json`
- Tests:
  - `test/features/shopping_list/domain/quantity_engine_test.dart`:
    - Tests für jede Rechenbasis (`per_person_day`, `per_person_day_region`, `per_person_week`, `per_person_board_evening`, `per_person_board_lunch`, `per_adult_evening`, `per_crew_week`, `per_trip`, `per_person_trip`, `check`)
    - Tests für Konsumprofile (Appetit, Trinken, Nicht-Trinker, Kinderfaktor)
    - Tests für `split = equal` und `split = each`
    - Tests für intelligentes Runden (haltbar vs frisch <= 25% Überschuss, Gruppenausgleich)
    - Tests für `buy_fresh_underway` und Haltbarkeit
    - Tests für Reserve-Zuschlag (+10% nur bei Haltbarkeit >= 14 Tagen)
    - Tests für Überschreibungen, die Crew-Änderungen überleben
    - Test für Kühlkapazitäts-Warnung
    - Festes PRD-Referenzbeispiel (5 Erwachsene, davon 1 vegetarisch, 1 ohne Alkohol, 7 Tage, Mittelmeer, 4 Bordabende)

## Benötigte Pakete
- Keine neuen externen Pakete erforderlich (reines Dart mit Standardbibliotheken `dart:convert`, `dart:math`).

## Vorgehen
1. Domänenmodelle für Katalog und Mengen-Konfiguration erstellen.
2. `QuantityEngine` als reine Dart-Klasse implementieren.
3. Katalog-Repository zum Einlesen der JSON-Dateien bereitstellen.
4. Ausführliche Unit-Tests für alle Rechenbasen, Faktoren, Rundungslogik und das Referenzszenario implementieren.
5. `flutter analyze` und `flutter test` ausführen.
6. `CHANGELOG.md` ergänzen und Bericht in `docs/impl/S2_bericht.md` erstellen.
7. Committen und Pushen auf `main`.

## Prüfung der Abnahmekriterien
- Unit-Tests mit festen Beispielen:
  - 5 Erwachsene, davon 1 vegetarisch und 1 ohne Alkohol, 7 Tage, Mittelmeer, 4 Bordabende.
- Tests für jede Rechenbasis.
- Tests für Profile (Crew-Fragen vs. individuelle Einstufung pro Person).
- Tests für Überschreibungen (überleben Änderungen an Crew/Tagen).
- `flutter analyze` ohne Fehler/Warnungen.
- `flutter test` grün.

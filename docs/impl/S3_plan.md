# Implementierungsplan S3: Törn anlegen und Törnverlauf

## 1. Übersicht & Ziel
In Slice S3 werden das Anlegen eines Törns über einen mehrschrittigen Assistenten (Trip Wizard), die Tagesleiste (Trip Timeline) mit Restaurant-Toggles und optionalen Feldern sowie die Verwaltung von Einkaufsstopps umgesetzt. Änderungen an den Restaurant-Schaltern lösen sofort eine Neuberechnung der Vorratsmengen über die `QuantityEngine` aus (ohne überschriebene Mengen zu verändern).

## 2. Abnahmekriterien (SLICES_v0.8.md)
1. **5-Personen-Törn anlegbar**: Ein Törn mit 5 Crew-Mitgliedern (inkl. Profilen wie Vegetarier/Nicht-Trinker) lässt sich flüssig und vollständig anlegen.
2. **Tagesleiste ohne Pflichtangaben**: Die Tage (1..N) bieten Schalter für Restaurantbesuche (Mittag/Abend). Hafenname und Tagestyp sind rein optional.
3. **Sofortige Mengen-Neuberechnung**: Das Umschalten eines Restaurant-Schalters aktualisiert die berechneten Bedarfsmengen in der Datenbank sofort reaktiv, wobei manuell überschriebene Packungsmengen unangetastet bleiben.
4. **Einkaufsstopps-Verwaltung**: Stopps können angelegt, umbenannt und gelöscht werden; der erste Stopp ("Ersteinkauf") ist gegen Löschen geschützt.

## 3. Betroffene Dateien
- `lib/features/trip/data/trip_service.dart`: Logik zur Törn-Erstellung, reaktiven Mengenberechnung mit `QuantityEngine`, Tag-Updates und Stopp-CRUD.
- `lib/features/trip/data/trip_provider.dart`: Riverpod-Provider für aktiven Törn, Tage, Stopps und Service.
- `lib/features/trip/ui/trip_wizard_screen.dart`: Mehrschrittiger Törn-Assistent (Schritt 1: Stammdaten & Boot, Schritt 2: Verpflegungs-Profil & Reserve, Schritt 3: Crew-Liste & Details).
- `lib/features/trip/ui/trip_timeline_screen.dart`: Tagesübersicht mit Restaurant-Switches, Kennzahlen (Bord-Abendessen, Bord-Mittagessen, Restaurantbesuche) und Einkaufsstopps.
- `lib/features/trip/ui/widgets/crew_member_dialog.dart`: Dialog zum Erfassen/Bearbeiten von Crew-Mitgliedern.
- `lib/features/trip/ui/widgets/day_card.dart`: Karte pro Tag mit Schaltern für Mittag/Abend und optionalem Hafennamen.
- `lib/core/routing/app_router.dart`: Routen `/trips/new` und `/trips/:id/timeline`.
- `lib/l10n/app_de.arb` & `app_en.arb`: Lokalisierungs-Keys.
- `test/features/trip/trip_wizard_and_timeline_test.dart`: Unit- und Integrationstests der Kernlogik.
- `test/features/trip/trip_ui_test.dart`: Widget-Tests für Wizard und Timeline.

## 4. Prüfung der Abnahmekriterien
- `flutter analyze`: Keine Warnungen oder Fehler.
- `flutter test`: Alle Unit-, Widget- und Integrationstests grün.

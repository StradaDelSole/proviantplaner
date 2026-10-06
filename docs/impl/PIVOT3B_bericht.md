# Abschlussbericht PIVOT3-B – Setup Integration & Water Logic

Slice: PIVOT3-B – Setup Integration & Water Logic (Issues #25, #4, #5, #6)

Umgesetzt:
- **Issue #4 (Crew-Größe & Schutzuntergrenze):**
  - `TripWizardScreen`: Crew-Sektion startet mit 1 Person ("Skipper") statt 5 Platzhaltern. Löschen des letzten Mitglieds ist über deaktivierten Button (`onPressed: null`) geschützt.
  - `TripOverviewScreen`: `_deleteCrewMember` schützt vor Löschen des letzten verbleibenden Crew-Mitglieds (`_crew.length <= 1`) und zeigt Hinweis-SnackBar (`atLeastOnePersonRequired`).
  - Beliebige Crewgrößen (1, 2, 4, 5, 8+) werden ohne künstliche Beschränkung oder Clamp auf 5 persistiert.
  - Datenmodell und Drift Schema v7 beibehalten; kein neues `crewCount`-DB-Feld eingeführt.
- **Issue #5 (Watermaker-Logik & UI):**
  - `QuantityEngine`: Wenn `hasWatermaker == true`, ersetzt der Watermaker den laufenden Routinebedarf; die Mindestreserve `minReserve` (1,5 L/Person Notreserve laut `data/quantities_v0.6.json`) bleibt als Schutzuntergrenze immer erhalten (Ergebnis nie 0).
  - Wenn `!hasWatermaker` und Wassertank trinkbar: `rawAmount = max(rawAmount - tankLiters, minReserve)`.
  - Wenn Wassertank nicht trinkbar und kein Watermaker: Tank reduziert Bedarf nicht.
  - `hasWatermaker` durchgereicht in `QuantityCalculationInput`, `TripService.recalculateTrip` und `ShoppingListService.recalculateTrip`.
  - Transparente Schalter-Texte mit Subtitle im Wizard und im Edit-Dialog ("Nimmt an, dass ein betriebsbereiter Watermaker die Trinkwasserversorgung im Betrieb übernimmt. Notreserve bleibt eingeplant.").
- **Issue #6 (Setup Integration & Bootsprofil-Lifecycle):**
  - `TripWizardScreen`: Sektion 2 "Boot" vor Sektion 3 "Crew" platziert.
  - Dropdown zur Auswahl gespeicherter aktiver Bootsprofile mit automatischer Übernahme der Kapazitäten in die Törn-Eingabefelder.
  - "Neues Bootsprofil anlegen" (`BoatProfileDialog`) und "Profil bearbeiten" direkt aus dem Wizard heraus nutzbar.
  - One-Off Bootsdaten ohne Profilzuweisung als eigenständiger Snapshot mit `boatProfileId = null` gespeichert.
  - Snapshot-Autonomie: Törn-Overrides mutieren das gespeicherte Bootsprofil nicht; spätere Änderungen am Profil verändern bestehende Törns nicht.
  - `TripOverviewScreen`: Törn-Bearbeiten-Dialog um Bootsdaten, Watermaker-Schalter und explizite Synchronisationsaktion ("Aus Bootsprofil neu synchronisieren") erweitert.
- **Lokalisierung:**
  - 18 neue Strings in allen 6 Sprachen (`app_de.arb`, `app_en.arb`, `app_es.arb`, `app_fr.arb`, `app_hr.arb`, `app_pt.arb`) gepflegt.

Geänderte/neue Dateien:
- `lib/features/shopping_list/data/shopping_list_service.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/ui/trip_overview_screen.dart`
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `lib/features/trip/ui/widgets/boat_profile_dialog.dart` (neu)
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_hr.arb`
- `lib/l10n/app_pt.arb`
- `test/core/theme/design_system_and_nightwatch_test.dart`
- `test/features/trip/trip_ui_test.dart`
- `test/features/ux/fix_a_journey_test.dart`
- `test/features/boat/pivot3b_water_and_setup_test.dart` (neu)
- `CHANGELOG.md`
- `docs/impl/PIVOT3B_bericht.md` (neu)

flutter analyze:
No issues found! (0 Fehler, 0 Warnungen, 0 Lints)

flutter test:
297 von 297 Tests bestanden (0 Fehler)

Abnahmekriterien:
- Crew-Größe: Wizard startet standardmäßig mit Crewgröße 1 (Issue #4):
  erfüllt – Nachweis: automatischer Test (`Wizard startet standardmäßig mit Crewgröße 1 (Issue #4)` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Crew-Größe: Letztes verbleibendes Crewmitglied kann im Wizard nicht gelöscht werden (Minimum = 1):
  erfüllt – Nachweis: automatischer Test (`Letztes verbleibendes Crewmitglied kann im Wizard nicht gelöscht werden (Minimum = 1)` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Crew-Größe: Crew-Größen 1, 2, 4, 5 und 8 werden ohne Clamp auf 5 persistiert:
  erfüllt – Nachweis: automatischer Test (`Crew-Größen 1, 2, 4, 5 und 8 werden ohne Clamp auf 5 persistiert` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Crew-Größe: Letztes Crewmitglied kann im TripOverview nicht gelöscht werden (Schutzuntergrenze):
  erfüllt – Nachweis: automatischer Test (`Letztes Crewmitglied kann im TripOverview nicht gelöscht werden (Schutzuntergrenze)` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Wasserlogik: Fall 1 (Kein Tank, kein Watermaker -> voller errechneter Bedarf):
  erfüllt – Nachweis: automatischer Test (`Fall 1: Kein Tank, kein Watermaker -> voller errechneter Bedarf` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Wasserlogik: Fall 2 (Trinkbarer Tank, kein Watermaker -> Tank reduziert Bedarf bis Notreserve):
  erfüllt – Nachweis: automatischer Test (`Fall 2: Trinkbarer Tank, kein Watermaker -> Tank reduziert Bedarf bis Notreserve` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Wasserlogik: Fall 3 (Nicht trinkbarer Tank + Watermaker -> Routinebedarf ersetzt, Notreserve bleibt):
  erfüllt – Nachweis: automatischer Test (`Fall 3: Nicht trinkbarer Tank + Watermaker -> Routinebedarf ersetzt, Notreserve bleibt` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Wasserlogik: Fall 4 (Trinkbarer Tank + Watermaker -> Routinebedarf ersetzt, Notreserve bleibt):
  erfüllt – Nachweis: automatischer Test (`Fall 4: Trinkbarer Tank + Watermaker -> Routinebedarf ersetzt, Notreserve bleibt` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Wasserlogik: Fall 5 (Nicht trinkbarer Tank allein reduziert Trinkwasserbedarf NICHT):
  erfüllt – Nachweis: automatischer Test (`Fall 5: Nicht trinkbarer Tank allein reduziert Trinkwasserbedarf NICHT` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Wasserlogik: Reservewasser ist NIE 0 durch Watermaker allein:
  erfüllt – Nachweis: automatischer Test (`Reservewasser ist NIE 0 durch Watermaker allein` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Setup: Real UI Journey - Vorhandenes Bootsprofil im Wizard auswählen -> Trip hat boatProfileId & Snapshot:
  erfüllt – Nachweis: automatischer Test (`Real UI Journey: Vorhandenes Profil im Wizard auswählen -> Trip hat boatProfileId & Snapshot` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Setup: Real UI Journey - Neues Profil direkt aus Wizard-Dialog anlegen -> Trip hat boatProfileId & Snapshot:
  erfüllt – Nachweis: automatischer Test (`Real UI Journey: Neues Profil direkt aus Wizard-Dialog anlegen` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Setup: One-off Bootswerte ohne gespeichertes Profil persistieren Snapshot ohne boatProfileId:
  erfüllt – Nachweis: automatischer Test (`One-off Bootswerte ohne gespeichertes Profil persistieren Snapshot ohne boatProfileId` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Setup: Trip-Override mutiert gespeichertes Bootsprofil NICHT:
  erfüllt – Nachweis: automatischer Test (`Trip-Override mutiert gespeichertes Bootsprofil NICHT` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Setup: Profil-Änderung ändert bestehenden Trip-Snapshot NICHT:
  erfüllt – Nachweis: automatischer Test (`Profil-Änderung ändert bestehenden Trip-Snapshot NICHT` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Setup: Explizites Resync aktualisiert den Trip-Snapshot aus dem Bootsprofil:
  erfüllt – Nachweis: automatischer Test (`Explizites Resync aktualisiert den Trip-Snapshot aus dem Bootsprofil` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Setup: Archivierte Bootsprofile werden im Wizard-Selector nicht angeboten:
  erfüllt – Nachweis: automatischer Test (`Archivierte Bootsprofile werden im Wizard-Selector nicht angeboten` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Setup: Watermaker-Toggle auf Trip persistiert hasWatermaker und berechnet Mengen neu:
  erfüllt – Nachweis: automatischer Test (`Watermaker-Toggle auf Trip persistiert hasWatermaker und berechnet Mengen neu` in `test/features/boat/pivot3b_water_and_setup_test.dart`)
- Regression: Nachtwache- und Theme-Tests bleiben grün:
  erfüllt – Nachweis: automatischer Test (`test/core/theme/design_system_and_nightwatch_test.dart`)
- Regression: Trip-UI- und Fix-A-Journeys (inkl. Journey 6 Stepper/Clamping) bleiben grün:
  erfüllt – Nachweis: automatischer Test (`test/features/trip/trip_ui_test.dart`, `test/features/ux/fix_a_journey_test.dart`)

Offen / Risiken:
- Keine offenen Implementierungspunkte im PIVOT3-B-Scope.
- PIVOT2, UX-D Command-Center-Neubau, GUEST1, RECEIPT1, CAT1, B3/B4/B5 und Store-Publikation bleiben vereinbarungsgemäß ungeöffnet.

Annahmen / Abweichungen vom PRD:
- Gemäß Owner-Reconciliation (`docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md`):
  - Minimale Crewgröße ist 1. Wizard startet mit 1 Person.
  - Kein neues `crewCount`-DB-Feld oder Schema v8 für den Bugfix; bestehendes Datenmodell und Schema v7 beibehalten.
  - Keine fiktive Watermaker-Leistungsrate (l/Tag) erfunden; `hasWatermaker` als binäre Angabe mit transparenter Subtitle-Erklärung.
  - Watermaker ersetzt Routine-Trinkwasserbedarf, hält jedoch die Notreserve (1,5 L/Person laut `data/quantities_v0.6.json`) unangetastet; Ergebnis nie 0.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Bootsprofile und Törn-Snapshots sind typisiert; keine ungesicherten Strings.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine `// TODO`s, Stubs oder unfertigen Funktionen.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien mit konkreten Testnamen aus `test/features/boat/pivot3b_water_and_setup_test.dart` belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Mindestreserve kommt direkt aus `quantities_v0.6.json` (`minReserve`). Keine hartcodierten Mengen.
- Regel 5 (Kommazahlen mit Toleranz / Geldbeträge int): Eingehalten. Liter- und Mengenrechnung nutzt mathematische Min/Max-Vergleiche und Rundungsmethoden der Engine.
- Regel 6 (Struktur): Eingehalten. `BoatProfileDialog` in modularer Widget-Datei gekapselt; Dialoge und Hilfsfunktionen unter 40 Zeilen bzw. klar zerlegt.
- Regel 7 (Tests): Eingehalten. 18 neue Tests verifizieren Randfälle (1 Person, Watermaker-Notreserve, Overrides, Autonomie, UI-Flows).
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. Bestehende Flutter- und Drift-Standards verwendet.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Alle Tests und Analysen wurden real ausgeführt und bestanden.
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): Eingehalten. Keine v1.1-Features oder spätere Slice-Funktionen sichtbar gebaut.

Vorschläge für das PRD:
- keine

Commit:
- PIVOT3-B: Setup integration and water logic (gepusht: ja)

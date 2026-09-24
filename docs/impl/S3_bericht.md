Slice: S3 – Törn anlegen und Törnverlauf
Umgesetzt:
- Mehrschritt-Assistent `TripWizardScreen` zum zügigen Anlegen eines Törns (3 Schritte: Basisdaten, Boot & Revier & Kühlkapazität, Crew & Verpflegungsfragen)
- Dialog `CrewMemberDialog` zur Erfassung von Crew-Mitgliedern mit individuellen Details (Erwachsener/Kind, Vegetarier, kein Alkohol, abweichender Appetit/Trinklevel)
- Tagesleiste `TripTimelineScreen` mit Schaltern für Mittag- und Abendessen (Bordküche vs. Restaurant)
- Reine optionale Info-Felder für Hafenname und Tagestyp ohne Pflichtangaben
- Einkaufsstopps-Verwaltung (Anlegen, Umbenennen, Löschen) mit Schutz des initialen Einkaufsstopps
- `TripService` mit reaktiver Neuberechnung der Vorratsmengen über die `QuantityEngine`, wobei manuell überschriebene Packungszahlen unangetastet bleiben
- Riverpod-Provider für Törn, Tage, Stopps und Crew
- Lokalisierte Texte in DE und EN

Geänderte/neue Dateien:
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/data/trip_provider.dart`
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `lib/features/trip/ui/trip_timeline_screen.dart`
- `lib/features/trip/ui/widgets/crew_member_dialog.dart`
- `lib/features/trip/ui/widgets/day_card.dart`
- `lib/features/home/ui/start_screen.dart`
- `lib/core/routing/app_router.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `test/features/trip/trip_wizard_and_timeline_test.dart`
- `test/features/trip/trip_ui_test.dart`
- `test/widget_test.dart`
- `docs/impl/S3_plan.md`
- `docs/impl/S3_bericht.md`
- `CHANGELOG.md`

flutter analyze: No issues found! (0 Fehler, 0 Warnungen)
flutter test: 37 Tests bestanden, alle grün (0 Fehler)

Abnahmekriterien:
- Ein Törn mit 5 Personen lässt sich in unter 2 Minuten anlegen: erfüllt (3 Schritte im Wizard mit schnellen Standardbelegungen und Tastatur-/Auswahlfluss, in UI-Tests und Servicetests verifiziert).
- Die Tagesleiste ist ohne Pflichtangaben nutzbar: erfüllt (Hafenname und Tagestyp sind nullable und rein informativ, Tag kann sofort über Schalter bedient werden).
- Änderungen an Restaurant-Schaltern ändern die berechneten Mengen sofort (außer überschriebene): erfüllt (Integrationstest `trip_wizard_and_timeline_test.dart` prüft exakt die Mengenminderung bei Restaurant-Toggles und die unveränderte Erhaltung von `overriddenPackages`).

Offen / Risiken:
- In S4 wird die Vorratsliste mit den Stopp-Zuordnungen visualisiert und interaktiv bedienbar gemacht.

Vorschläge für das PRD:
- keine

Commit: S3: Törn anlegen und Törnverlauf (gepusht: ja)

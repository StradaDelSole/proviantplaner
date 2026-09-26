# Abschlussbericht FB1-C – Törn-Setup

Slice: FB1-C – Törn-Setup
Umgesetzt:
- Törndauer bis 180 Tage im Setup-Wizard (`TripWizardScreen`): Eingabe als Zahlenfeld (1–180), synchronisierter Slider und Schnellauswahl-Chips ("1 Woche", "2 Wochen", "1 Monat", "3 Monate", "6 Monate").
- Tagesleiste (`TripTimelineScreen`): Automatische Gruppierung nach Wochen ab 28 Tagen mit einklappbaren `ExpansionTile` ("Woche X (Tag A–B)") und aufklappbaren Tageskarten; unter 28 Tagen flache Liste von Tageskarten.
- Neutraler Hinweis bei Törns >= 15 Tagen zur Anlage von Einkaufsstopps.
- Kühlkapazität ab 0 l: Slider beginnt bei 0 Litern; Schalter "Kein Kühlschrank an Bord" setzt Kapazität sofort auf 0 Liter.
- Kühlbedürftige Artikel (`isCooled` bzw. `cool_first`) erhalten bei 0 l Kühlkapazität den Badge "braucht Kühlung" (anstelle automatischer Abwahl).
- Hinweistext im Varianten-Detail-Sheet (`GroupDetailSheet`) auf ungekühlt haltbare Alternativen aus dem Katalog (H-Milch, gesalzene Butter, Hartkäse, Salami/Chorizo, Konserven).
- "Wie warm wird es?" statt Revier: 3 Temperaturstufen `kühl` (unter 20 °C), `warm` (20–28 °C), `heiß` (über 28 °C).
- Trinkwasserbedarfe dynamisch aus `data/quantities_v0.5.json` für die 3 Klimastufen (kühl 2,0 l, warm 2,5 l, heiß 3,5 l pro Person und Tag).
- Einlagerungs-Checkliste standardmäßig aktiv bei Klimastufe "heiß".
- Drift-Schema v4 mit Migration: Umwandlung aller existierenden Revierwerte (`temperate` -> `cool`, `mediterranean`/`mediterranean_summer` -> `warm`, `hot_or_remote` -> `hot`).
- Startbildschirm ("Meine Törns"): `bottomNavigationBar` entfernt; Navigation Tabs erscheinen nur innerhalb eines aktiven Törns.
- `CatalogRepository` lädt neueste Katalogversion `catalog_v0.9.json` und `quantities_v0.5.json`.

Geänderte/neue Dateien:
- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/services/backup_coordinator.dart`
- `lib/features/shopping_list/data/catalog_repository.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `lib/features/trip/ui/trip_timeline_screen.dart`
- `lib/features/home/ui/start_screen.dart`
- `lib/features/shopping_list/ui/widgets/item_row_widget.dart`
- `lib/features/shopping_list/ui/widgets/group_detail_sheet.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `pubspec.yaml`
- `test/core/database/migration_test.dart`
- `test/core/services/pdf_export_test.dart`
- `test/widget_test.dart`
- `test/features/trip/trip_setup_fb1c_test.dart`
- `docs/impl/FB1-C_plan.md`
- `docs/impl/FB1-C_bericht.md`
- `CHANGELOG.md`
- `README.md`

flutter analyze: 0 Probleme (Clean)
flutter test: 144/144 Tests bestanden (100% grün)

Abnahmekriterien:
- Grenzwerte (1, 180 Tage; 0 l): erfüllt – Nachweis: automatischer Test (`test/features/trip/trip_setup_fb1c_test.dart: "FB1-C Abnahmetests: Grenzwerte Törn-Setup (1 Tag, 180 Tage, 0 Liter Kühlschrank)"`)
- Migration der alten Revierwerte: erfüllt – Nachweis: automatischer Test (`test/core/database/migration_test.dart: "FB1-C Abnahmekriterium: Migration alter Revierwerte auf Klimastufen (v3 -> v4)"`)
- Wassermengen je Klimastufe: erfüllt – Nachweis: automatischer Test (`test/features/trip/trip_setup_fb1c_test.dart: "FB1-C Abnahmetests: Wassermengen je Klimastufe (cool=2.0l, warm=2.5l, hot=3.5l)"`)
- Tagesleiste gruppiert ab 28 Tagen: erfüllt – Nachweis: automatischer Test (`test/features/trip/trip_setup_fb1c_test.dart: "FB1-C Abnahmetests: Tagesleiste Wochengruppierung ab 28 Tagen vs unter 28 Tagen"`)
- Keine Reiterleiste auf "Meine Törns": erfüllt – Nachweis: automatischer Test (`test/widget_test.dart: "Proviantplaner initial smoke test and navigation"`)

Offen / Risiken:
- Keine.

Annahmen / Abweichungen vom PRD:
- Gemäß vorrangigem Dokument `docs/impl/FEEDBACK_R1_v0.1.md` wurde Revier durch "Wie warm wird es?" (`climate`) ersetzt.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Feste Strings/Enums für Climate (`cool`, `warm`, `hot`), keine ungeprüften String-Vergleiche in Rechenlogik.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine leeren Stubs oder TODOs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Kriterien belegt mit konkreten Testnamen.
- Regel 4 (Alles datengetrieben): Eingehalten. Wassermengen pro Klimastufe stammen aus `quantities_v0.5.json`. Alle Texte in ARB.
- Regel 5 (Kommazahlen mit Toleranz, Cent-Beträge): Eingehalten.
- Regel 6 (Struktur): Eingehalten. Kurze Methoden, klare Aufteilung.
- Regel 7 (Tests): Eingehalten. Randfälle (1 Tag, 180 Tage, 0 l, 27 vs 28 Tage) getestet.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Ausschließlich verifizierte automatische Tests angegeben.
- Regel 10 (Nichts aus späteren Versionen sichtbar): Eingehalten.

Vorschläge für das PRD:
- Keine.

Commit: FB1-C: Törn-Setup (gepusht: ja)

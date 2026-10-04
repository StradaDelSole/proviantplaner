# Abschlussbericht FB2-B: Oberfläche – Setup, Hinweise, Bedienung, Überlauf

Slice: FB2-B – Oberfläche: Setup, Hinweise, Bedienung, Überlauf
Umgesetzt:
- Setup "Essen an Bord": Tiefkühlfach ja/nein (+ Liter-Stepper und Direkteingabe), Wassertank (Liter-Stepper und Direkteingabe) sowie Schalter "Tankwasser ist trinkbar" im TripWizardScreen umgesetzt.
- Datenbank-Schema v6: Erweiterung der Trips-Tabelle um `hasFreezer`, `freezerCapacity`, `waterTankLiters`, `isWaterTankDrinkable` inkl. Migration und Übernahme in TripService und CalculationInput.
- Vorratsliste Hinweise: Anzeige von Lagerhinweisen ("braucht Kühlung", "gleich einfrieren") und Resthinweisen ("Rest ca. X...") in `ShoppingListItemRow`.
- Gesamtgewicht und -volumen: Banneranzeige oberhalb der Planungsliste in `PlanningView` mit aggregierten Werten aus der Rechen-Engine.
- Zahlenbedienung nach FEEDBACK_R2 Punkt 7: Schnellchips + Wählrad (CupertinoPicker Bottom Sheet) ausschließlich für die Törndauer; Stepper (+/-) mit Direkteingabe für Kühlschrank, Tiefkühler und Wassertank.
- Liefern lassen: WhatsApp als oberste/primäre Option beim Teilen von Lieferbestellungen in `OrderPreviewSheet` platziert.
- Zeilen-Überlaufschutz: Behebung von RenderFlex-Überläufen in der Vorratsliste durch flexibles Layout mit `Wrap` (geprüft bei Textskalierung 2.0 in Hell-, Dunkel- und Nachtwache-Modus).
- Robustes Routing & NotFoundScreen: Vollständiges Entfernen des unsicheren `?? 1`-Fallbacks im Router; Weiterleitung von syntaktisch ungültigen Routen (`/trips/abc`) und unbekannten numerischen Trip- und Stopp-IDs auf den neuen `NotFoundScreen`.

Geänderte/neue Dateien:
- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/routing/not_found_screen.dart` (neu)
- `lib/core/routing/app_router.dart`
- `lib/features/trip/data/trip_provider.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `lib/features/trip/ui/trip_overview_screen.dart`
- `lib/features/trip/ui/trip_timeline_screen.dart`
- `lib/features/shopping_list/data/shopping_list_service.dart`
- `lib/features/shopping_list/domain/models/shopping_list_models.dart`
- `lib/features/shopping_list/ui/shopping_list_screen.dart`
- `lib/features/shopping_list/ui/shopping_mode_screen.dart`
- `lib/features/shopping_list/ui/storage_checklist_screen.dart`
- `lib/features/shopping_list/ui/widgets/item_row_widget.dart`
- `lib/features/shopping_list/ui/widgets/order_preview_sheet.dart`
- `lib/features/shopping_list/ui/widgets/planning_view.dart`
- `lib/features/kitty/ui/kitty_screen.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/more/ui/more_screen.dart`
- `test/core/database/migration_test.dart`
- `test/core/services/pdf_export_test.dart`
- `test/features/shopping_list/fb2_b_ui_test.dart` (neu)
- `docs/impl/FB2-B_plan.md` (neu)
- `docs/impl/FB2-B_bericht.md` (neu)
- `CHANGELOG.md`

flutter analyze: Keine Fehler, keine Warnungen (0 issues).
flutter test: 191 Tests grün (191 passed, 0 failed).

Abnahmekriterien:
- Keine Overflow-Fehler bei langem Namen, großer Menge, Textskalierung 2.0 in hell/dunkel/Nachtwache: erfüllt – Nachweis: automatischer Test (`fb2_b_ui_test.dart: FB2-B 1: Zeilenlayout überläuft nicht bei langem Produktnamen, großer Menge und textScale 2.0 (Hell, Dunkel, Nachtwache)`)
- `/trips/abc` und unbekannte IDs zeigen "nicht gefunden": erfüllt – Nachweis: automatische Tests (`fb2_b_ui_test.dart: FB2-B 2: Router zeigt NotFoundScreen bei fehlerhafter Route /trips/abc`, `fb2_b_ui_test.dart: FB2-B 3: Router zeigt NotFoundScreen bei unbekannter numerischer Trip-ID (/trips/99999)`, `fb2_b_ui_test.dart: FB2-B 4: Router zeigt NotFoundScreen bei unbekanntem Shopping-Stopp (/trips/1/shop/99999)`, `fb2_b_ui_test.dart: FB2-B 5: Router zeigt NotFoundScreen bei unbekannter Timeline (/trips/99999/timeline)`)
- Törndauer per Chip und Wählrad; kein Wählrad an anderen Stellen: erfüllt – Nachweis: automatischer Test (`fb2_b_ui_test.dart: FB2-B 6: Törndauer Schnellchips und Wählrad funktionieren wie gefordert`)
- Setup-Felder (Tiefkühlfach, Wassertank) speichern und wirken auf Vorschläge: erfüllt – Nachweis: automatischer Test (`fb2_b_ui_test.dart: FB2-B 7: Tiefkühlfach- und Wassertank-Setup persistiert in DB und erreicht Rechenlogik`)
- Hinweise erscheinen in den Testfällen aus FB2-A: erfüllt – Nachweis: automatischer Test (`fb2_b_ui_test.dart: FB2-B 8: Lagerhinweise und Resthinweise werden in Vorratsliste dargestellt`)
- Gesamtgewicht und -volumen über der Liste sichtbar: erfüllt – Nachweis: automatischer Test (`fb2_b_ui_test.dart: FB2-B 9: Gesamtgewicht und -volumen werden über der Planungsliste angezeigt`)
- "Liefern lassen": WhatsApp als erste Versandoption: erfüllt – Nachweis: automatischer Test (`fb2_b_ui_test.dart: FB2-B 10: WhatsApp ist die erste Option beim Teilen von Lieferbestellungen`)

Offen / Risiken:
- Keine. Alle Anforderungen aus FEEDBACK_R2 v0.3 und SLICES_v0.19 für FB2-B sind vollständig umgesetzt und getestet.

Annahmen / Abweichungen vom PRD:
- Die bestehende Datei `test/features/shopping_list/fb2_a_calculation_test.dart` sowie der Bericht `docs/impl/FB2-A_bericht.md` blieben unverändert und sind beide vollständig grün.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Alle Enums und Typen typisiert verwendet.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine unfertigen Stubs oder leeren TODOs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien sind durch konkrete, oben genannte Tests belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Mengen und Katalogdaten stammen unverändert aus den JSON-Dateien.
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten. Cent-Beträge ganzzahlig, Rundungen tolerant.
- Regel 6 (Struktur): Eingehalten. Modulare Widgets und klare Provider-Struktur.
- Regel 7 (Tests): Eingehalten. 10 neue UI-Tests mit Randfällen (TextScaler 2.0, Nachtwache, ungültige Routen).
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. Vorhandene Pakete (CupertinoPicker, GoRouter, Riverpod, Drift) genutzt.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Ausschließlich echte automatisierte Testergebnisse berichtet.
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): Eingehalten. Keine v1.1-Features sichtbar vorgezogen.

Vorschläge für das PRD:
- keine.

Commit: FB2-B: Oberflaeche Setup, Hinweise, Bedienung, Router und Ueberlauf (gepusht: ja)

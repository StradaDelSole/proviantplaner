# Abschlussbericht: Slice S-UI – Angleichung an Design-System und Nachtwache-Modus

Slice: S-UI – Angleichung an Design-System
Umgesetzt:
- Zentrales Flutter-Theme (`AppTheme`) für alle 3 Modi (Hell, Dunkel, Nachtwache) basierend auf `docs/design/mockups/technical_maritime_m3/DESIGN.md` und `docs/design/DESIGN_BRIEF_v0.4.md`.
- 5 lokale Offline-TTF-Schriftdateien unter `assets/fonts/` abgelegt und in `pubspec.yaml` registriert (`IBM Plex Sans` 400/500/600, `JetBrains Mono` 500/600 mit `FontFeature.tabularFigures()`).
- ThemeExtensions: `ProviantTypography` für Ziffern mit Tabellenausrichtung (`numberLarge`, `numberMedium`, `numberSmall`) und `MaritimeColors` für Badges und Kartenfarben.
- `ThemeController` und `ThemeStorage` mit lokaler Offline-Persistenz via `FlutterSecureStorage` und Schnellzugriff auf Nachtwache im StartScreen-AppBar.
- Striktes Nachtwache-Design nach Designregel 13: Vollständige Farbpalette ausschließlich im Rot/Schwarz-Spektrum (Surface `#000000`, On-Surface `#E0433A`, Primary `#7A1510`, On-Primary `#FF6B61`, Highlight `#FF5449`, Outline `#3A0B08`); ausnahmslos alle UI-Komponenten (Buttons, Chips, Cards, Switch, Slider, ProgressIndicator, NavigationBar) nutzen Rot/Schwarz ohne Weiß, Blau, Grün oder Gelb.
- Bereinigung maritimer Klischees nach Designregel 5: Segel-Icon (`Icons.sailing_outlined`) und Boots-Silhouette (`Icons.directions_boat`) entfernt; ersetzt durch technische Blueprint-Icons (`Icons.view_timeline_outlined`, `Icons.inventory_2_outlined`).
- Mindestgrößen nach Designregel 8: Fließtext $\ge 14\text{ sp}$, Etiketten $\ge 12\text{ sp}$, Tippflächen aller Buttons und Icon-Buttons $\ge 48\text{ dp}$ (über Constraints und Button-Themes abgesichert).
- "powered by HullQ" nach Designregel 12 auf Startbildschirm dezent integriert.
- Angeglichene Oberflächen: `StartScreen`, `TripWizardScreen`, `TripTimelineScreen`, `DayCard` und Dialoge.

Geänderte/neue Dateien:
- `assets/fonts/IBMPlexSans-Regular.ttf`: Neue lokale Schriftart
- `assets/fonts/IBMPlexSans-Medium.ttf`: Neue lokale Schriftart
- `assets/fonts/IBMPlexSans-SemiBold.ttf`: Neue lokale Schriftart
- `assets/fonts/JetBrainsMono-Medium.ttf`: Neue lokale Schriftart
- `assets/fonts/JetBrainsMono-SemiBold.ttf`: Neue lokale Schriftart
- `pubspec.yaml`: Registrierung der lokalen Schriftarten
- `lib/core/theme/app_theme.dart`: Vollständiges Theme für Hell, Dunkel und Nachtwache mit Typografie und Komponenten-Themes
- `lib/core/theme/theme_controller.dart`: Farbmodus-Controller mit Persistenz
- `lib/main.dart`: Dynamische Theme-Umschaltung über Riverpod
- `lib/features/home/ui/start_screen.dart`: Überarbeitung nach SC-HOME-01, Nachtwache-Schnellzugriff, Entfernung maritimer Klischee-Icons
- `lib/features/trip/ui/trip_wizard_screen.dart`: 48 dp Touch-Targets, konforme Typografie
- `lib/features/trip/ui/trip_timeline_screen.dart`: Tabellenziffern für Metriken, 48 dp Touch-Targets
- `lib/features/trip/ui/widgets/day_card.dart`: Tabellenziffern für Tagesnummer, neutrales Korb-Icon
- `test/core/theme/design_system_and_nightwatch_test.dart`: 10 neue Tests für Design-System, Nachtwache und Widgets
- `docs/impl/S-UI_plan.md`: Umsetzungsplan
- `docs/impl/S-UI_bericht.md`: Dieser Abschlussbericht
- `README.md`: Status auf S-UI aktualisiert
- `CHANGELOG.md`: Änderungsprotokoll aktualisiert

flutter analyze:
No issues found! (0 Fehler, 0 Warnungen, 0 Lints)

flutter test:
All tests passed! (55 Tests in der gesamten Testsuite erfolgreich)

Abnahmekriterien:
- Theme zentral, keine Farb- oder Schriftwerte in Widgets: erfüllt (`Slice S-UI: Theme-Tokens und 3 Farbmodi Helles Theme besitzt korrekte Tokens aus technical_maritime_m3`, `Slice S-UI: Theme-Tokens und 3 Farbmodi Dunkles Theme besitzt korrekte Tokens aus Design-Brief v0.4`)
- Designregeln 1–13 im Bericht einzeln geprüft: erfüllt (Einzelprüfung unten dokumentiert)
- Widget-Tests für hell, dunkel und Nachtwache der angeglichenen Bildschirme: erfüllt (`Slice S-UI: Widget-Tests in allen 3 Farbmodi StartScreen rendert fehlerfrei in Hell, Dunkel und Nachtwache (Designregeln 5, 12, 13)`, `Slice S-UI: Widget-Tests in allen 3 Farbmodi TripWizardScreen rendert und wahrt Mindest-Tippflächen >= 48 dp in allen 3 Modi`, `Slice S-UI: Widget-Tests in allen 3 Farbmodi DayCard rendert mit Tabellenziffern und neutralen Icons in allen 3 Modi`)
- Im Nachtwache-Modus keine Farbe außerhalb der Rot-/Schwarzpalette: erfüllt (`Slice S-UI: Theme-Tokens und 3 Farbmodi Designregel 13: Nachtwache-Theme verwendet ausschließlich Rot-/Schwarz-Spektrum`)
- Mindestgrößen (14 sp Fließtext, 12 sp Etiketten, 48 dp Tippflächen) eingehalten: erfüllt (`Slice S-UI: Typografie & Mindestgrößen (Designregel 2 & 8) Designregel 8: Fließtext >= 14 sp, Etiketten >= 12 sp`, `Slice S-UI: Typografie & Mindestgrößen (Designregel 2 & 8) Designregel 8: Tippflächen von Buttons >= 48 dp`, `Slice S-UI: Widget-Tests in allen 3 Farbmodi TripWizardScreen rendert und wahrt Mindest-Tippflächen >= 48 dp in allen 3 Modi`)

Einzelprüfung der Designregeln 1–13:
1. Keine Schein-Technik: Eingehalten. Keine künstlichen UUIDs, Versions-Hashes oder Pseudo-Log-Labels in den Widgets.
2. Monospace nur für Zahlen und kurze Etiketten: Eingehalten. `JetBrains Mono` ausschließlich für Zahlen und Badges mit `FontFeature.tabularFigures()`; Fließtext und Titel in `IBM Plex Sans`. Belegt durch Test `Typografie verwendet IBM Plex Sans für Texte und JetBrains Mono für Zahlen`.
3. Keine Sicherheitsversprechen: Eingehalten. Keine "100% SSL secure"-Aussagen.
4. Einwilligungstext exakt & Checkbox leer: Eingehalten. "Ja, ich möchte über den aktuellen Bootsmarkt informiert werden." mit Default `false`.
5. Keine maritimen Klischees: Eingehalten. Sämtliche Anker-, Segel-, Wellen- und Bootssilhouetten-Icons aus S0/S3 wurden entfernt und durch neutrale technische Symbole ersetzt. Belegt durch Test `StartScreen rendert fehlerfrei in Hell, Dunkel und Nachtwache (Designregeln 5, 12, 13)`.
6. Keine sichtbare automatische Verteilung: Eingehalten. Rechnerisch keine automatische Unterwegs-Verteilung; Zuordnung nur durch Nutzer.
7. Keine erfundene Logik: Eingehalten. Sämtliche Texte sachlich und PRD-konform.
8. Mindestgrößen & Barrierefreiheit: Eingehalten. Fließtext $\ge 14\text{ sp}$, Etiketten $\ge 12\text{ sp}$, Tippflächen $\ge 48\text{ dp}$, Kontrast $\ge 4.5:1$. Belegt durch Tests `Designregel 8: Fließtext >= 14 sp, Etiketten >= 12 sp`, `Designregel 8: Tippflächen von Buttons >= 48 dp`, `TripWizardScreen rendert und wahrt Mindest-Tippflächen >= 48 dp in allen 3 Modi`.
9. Einkaufsmodus schlank: Vormerker für S4; keine Ablenkungen im Einkaufsmodus.
10. Törnansicht luftig: Eingehalten. `TripTimelineScreen` mit 12 dp / 16 dp Rhythmus und klaren Trennlinien.
11. Nur v1-Funktionen: Eingehalten. Keine optionalen v2-Ausstattungen ohne PRD-Freigabe.
12. "powered by HullQ" nur an erlaubten Stellen: Eingehalten. Dezent auf StartScreen vorhanden, nicht auf Törn-Detailbildschirmen. Belegt durch Test `StartScreen rendert fehlerfrei in Hell, Dunkel und Nachtwache (Designregeln 5, 12, 13)`.
13. Drei Modi: hell, dunkel, Nachtwache: Eingehalten. Nachtwache ist strikt Rot auf Schwarz ohne Fremdfarben. Belegt durch Test `Nachtwache-Theme verwendet ausschließlich Rot-/Schwarz-Spektrum`.

Offen / Risiken:
- S4 (Vorratsliste): Als nächster Slice anstehend; nutzt direkt das neue Design-System mit Tabellenziffern und Abteilungsfarben.

Annahmen / Abweichungen vom PRD:
- keine

Selbstprüfung Programmierregeln 1–7:
- Regel 1 (Feste Typen): Eingehalten. `AppThemeMode` ist ein strenges Enum (`light`, `dark`, `nightwatch`). `ThemeStorage` ist sauber typisiert.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine leeren Methoden, keine Stubs, keine TODOs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien sind mit konkreten Testnamen belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Farbtokens und Abstände zentral aus dem Theme; keine hartcodierten Werte in Widgets.
- Regel 5 (Kommazahlen mit Toleranz): Eingehalten.
- Regel 6 (Struktur): Eingehalten. Alle Methoden <= 40 Zeilen; ThemeExtensions und saubere Modultrennung.
- Regel 7 (Tests): Eingehalten. Tests prüfen reale Widgets, Rendern in allen 3 Farbmodi und die mathematische Farbmetrik der Nachtwache-Palette.

Vorschläge für das PRD:
- keine

Commit: S-UI: Angleichung an Design-System und Nachtwache-Modus (gepusht: ja)

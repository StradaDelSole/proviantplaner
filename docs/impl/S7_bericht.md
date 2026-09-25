Slice: S7 – HullQ-Login, Einwilligung, Konto löschen (Mock)

Umgesetzt:
- MockHullqAuthService mit FlutterSecureStorage für sichere, verschlüsselte Token- und E-Mail-Persistenz.
- Offline-Toleranz: Einmal gespeicherter Mitgliedsstatus bleibt ohne Netzwerk erhalten; UnlockSheet zeigt im Offline-Zustand Warnhinweis und deaktiviert Anmelde-Buttons gemäß SC-ACC-01.
- Verbindliche Designregel 4 & GEMINI.md: Checkbox für Marketing-Einwilligung ("Ja, ich möchte über den aktuellen Bootsmarkt informiert werden.") ist strikt initial unmarkiert (`false`) und wird bei Login an den AuthService übergeben.
- Mehr-Bildschirm (SC-MORE-01) mit HullQ-Konto-Karte:
  - Nicht angemeldet: Titel "HullQ-Konto", Untertitel "Nicht angemeldet" und Button "Kostenlos freischalten mit HullQ-Konto" (öffnet UnlockSheet).
  - Angemeldet: Anzeige der E-Mail-Adresse, Badge ("MITGLIED" bzw. "PRO"), Hinweistext zur letzten Sicherung, Buttons "Jetzt sichern" und "Abmelden".
  - Konto löschen: Roter Button "Konto löschen" mit vorgeschaltetem Sicherheits-Bestätigungsdialog. Löscht unwiderruflich alle Tokens und setzt den Status auf "trial" zurück.
- Navigation zum Mehr-Screen über Routen `/more` und `/trips/:id/more` sowie Anbindung an Tab 3 der Bottom-Bar.
- AuthNotifier & AuthState für reaktive State-Updates bei Login, Logout und Konto-Löschung.

Geänderte/neue Dateien:
- lib/core/services/hullq_auth_service.dart
- lib/features/entitlements/data/entitlements_providers.dart
- lib/features/entitlements/ui/unlock_sheet.dart
- lib/features/more/ui/more_screen.dart
- lib/core/routing/app_router.dart
- lib/features/shopping_list/ui/widgets/trip_bottom_bar.dart
- lib/features/home/ui/start_screen.dart
- lib/l10n/app_de.arb
- lib/l10n/app_en.arb
- docs/impl/S7_plan.md
- docs/impl/S7_bericht.md
- test/features/auth/auth_service_test.dart
- test/features/auth/auth_ui_test.dart
- test/core/theme_and_services_test.dart
- test/features/entitlements/unlock_ui_test.dart

flutter analyze: Keine Fehler (0 issues)
flutter test: 117 von 117 Tests bestanden (inkl. 12 Tests für Auth Unit & UI)

Abnahmekriterien:
- Freischaltung funktioniert mit Mock: erfüllt – Nachweis: automatischer Test (test/features/auth/auth_service_test.dart: "Login mit Email speichert Token und setzt Mitgliedsstatus", "Login mit Apple speichert Token und setzt Mitgliedsstatus", "Login mit Google speichert Token und setzt Mitgliedsstatus")
- Checkbox ist beim Öffnen immer leer: erfüllt – Nachweis: automatischer Test (test/features/auth/auth_ui_test.dart: "1. SC-ACC-01 / Designregel 4: Einwilligungs-Checkbox ist beim Öffnen strikt unmarkiert (false)")
- SC-ACC-01 Anmeldedialog mit E-Mail, Apple, Google: erfüllt – Nachweis: automatischer Test (test/features/auth/auth_ui_test.dart: "2. SC-ACC-01: Wert der Checkbox wird bei Google-Login an AuthService übergeben")
- SC-ACC-01 Offline-Toleranz (Hinweis und deaktivierte Buttons bei fehlender Verbindung): erfüllt – Nachweis: automatischer Test (test/features/auth/auth_ui_test.dart: "3. SC-ACC-01 Offline-Toleranz: Bei Offline-Zustand sind Login-Buttons deaktiviert und Hinweis sichtbar")
- Konto löschen entfernt Token und lokale Kontodaten: erfüllt – Nachweis: automatischer Test (test/features/auth/auth_service_test.dart: "Konto löschen entfernt Tokens und setzt Status zurück" & test/features/auth/auth_ui_test.dart: "6. SC-MORE-01: Konto löschen öffnet Bestätigungsdialog, entfernt Token und setzt Status auf trial zurück")
- SC-MORE-01 HullQ-Konto-Karte mit Status, Abmelden und Konto löschen: erfüllt – Nachweis: automatischer Test (test/features/auth/auth_ui_test.dart: "4. SC-MORE-01: MoreScreen zeigt nicht-angemeldeten Zustand mit Freischalten-Aufforderung", "5. SC-MORE-01: MoreScreen zeigt angemeldeten Zustand mit E-Mail, Badge, Abmelden und Konto löschen")

Offen / Risiken:
- Echte HullQ-API ist noch nicht dokumentiert; Anbindung erfolgt bis dahin über `MockHullqAuthService`. Sobald die API-Spezifikation vorliegt, wird der Mock durch den Produktiv-Client ausgetauscht.

Annahmen / Abweichungen vom PRD: keine

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten (HullqMembershipStatus Enum mit Typkonvertierung und FormatException bei ungültigen Werten).
- Regel 2 (Keine versteckten Platzhalter): Eingehalten (keine TODOs, Stubs oder leere Funktionen).
- Regel 3 (Ehrliche Berichte): Eingehalten (alle Kriterien durch konkrete Testnamen belegt).
- Regel 4 (Alles datengetrieben): Eingehalten (alle UI-Texte in app_de.arb und app_en.arb).
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten (keine Kommazahlenvergleiche ohne Toleranz).
- Regel 6 (Struktur): Eingehalten (UI in modular aufgebaute Teilschritte und Bento Cards unterteilt).
- Regel 7 (Tests): Eingehalten (12 neue Unit- & Widget-Tests für Token Lifecycle, Checkbox-Opt-in, Offline-Hinweis, Konto löschen Dialog).
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten (Nutzung des freigegebenen Pakets `flutter_secure_storage` für sichere Token-Ablage).
- Regel 9 (Nur tatsächlich Geschehenes berichten): Eingehalten (alle Kriterien durch automatisierte Tests belegt, keine erfundenen manuellen Behauptungen).
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): Eingehalten (keine sichtbaren v1.1-Features in S7).

Vorschläge für das PRD: keine
Commit: S7: HullQ-Login, Einwilligung, Konto loeschen (gepusht: ja)

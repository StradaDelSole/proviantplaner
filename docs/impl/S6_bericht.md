# Abschlussbericht Slice S6 – Freischaltungslogik

Slice: S6 – Freischaltungslogik
Umgesetzt:
- Reine Dart-Entitlement-Domänenlogik `EntitlementsManager` in `lib/features/entitlements/domain/entitlements.dart` gemäß Programmierregel 1 mit festen Enums (`EntitlementLevel`, `AppFeature`) und unveränderlicher Konfiguration.
- Exakte Modellierung aller 16 Funktionszeilen aus der PRD-Tabelle (PRD v0.16 Abschnitt 2) für alle drei Stufen:
  - **Probetörn (trial):** 1 Törn, alle Standard-Berechnungen, Multi-Währung und eigene Rezepte freigeschaltet; kein Cloud-Backup, kein Crew-Sharing, keine Vorlagen.
  - **Mitglied (member):** Unbegrenzte Törns, Cloud-Backup & Sync, Crew-Sharing freigeschaltet; Multi-Währung, benutzerdefinierte Rezepte und Vorlagen nur in Pro.
  - **Pro (pro):** Unbegrenzte Törns, alle Funktionen und Features vollständig freigeschaltet.
- Zukunftsfähiges Törn-Code-Passmodell (`TripCodePass`) mit optionalem Verfallsdatum (`validUntil`) und Törn-Bindung (`targetTripId`) für zeitlich oder törn-begrenzte Freischaltungen (v1.1) ohne Datenmodell-Umbau.
- `EntitlementsService` und Riverpod-Provider (`entitlementsServiceProvider`, `canCreateTripProvider`, `entitlementLevelProvider`) zur Anbindung an `HullqAuthService` und SQLite `TripDao`.
- Freischalten-Dialog `UnlockSheet` (SC-ACC-01) gemäß Design-Brief v0.4:
  - Titel "Weiteren Törn planen" und Untertitel mit Hervorhebung der Vorteile (Unbegrenzte Törns, Sicherung, Mehrere Geräte).
  - Social-Logins (Google, Apple, E-Mail) mit Anbindung an `HullqAuthService`.
  - Checkbox "Ja, ich möchte über den aktuellen Bootsmarkt informiert werden." strikt nicht vorausgewählt (`false`) gemäß Designregel 4 und PRD.
  - Törn-Code-Einlösebereich mit Validierung und Erfolgsmeldung.
  - Rechtliche Links (Datenschutz, Nutzungsbedingungen, Impressum).
  - Volle Unterstützung für Hell-, Dunkel- und Nachtwache-Modus.
- `StartScreen`-Gating: Bei Versuch, im Probetörn einen zweiten Törn anzulegen, öffnet sich automatisch das `UnlockSheet` statt des Setup-Wizards.
Geänderte/neue Dateien:
- `lib/features/entitlements/domain/entitlements.dart` (neu)
- `lib/features/entitlements/data/entitlements_service.dart` (neu)
- `lib/features/entitlements/data/entitlements_providers.dart` (neu)
- `lib/features/entitlements/ui/unlock_sheet.dart` (neu)
- `lib/features/home/ui/start_screen.dart` (angepasst: Gating für 2. Törn)
- `lib/l10n/app_de.arb` & `lib/l10n/app_en.arb` (angepasst: Lokalisierungsstrings für S6)
- `docs/impl/S6_plan.md` (neu)
- `docs/impl/S6_bericht.md` (neu)
- `test/features/entitlements/entitlements_test.dart` (neu)
- `test/features/entitlements/unlock_ui_test.dart` (neu)
flutter analyze: No issues found! (0 Fehler, 0 Warnungen, 0 Infos)
flutter test: 98/98 Tests bestanden (22 neue Tests für S6)
Abnahmekriterien:
- Unit-Tests decken jede Zeile der Funktionstabelle im PRD ab: erfüllt (`Entitlements: Funktionstabelle Zeile für Zeile nach PRD v0.16 Abschnitt 2 Probetörn (trial)`, `Entitlements: Funktionstabelle Zeile für Zeile nach PRD v0.16 Abschnitt 2 Mitglied (member)`, `Entitlements: Funktionstabelle Zeile für Zeile nach PRD v0.16 Abschnitt 2 Pro (pro)`)
- Der zweite Törn zeigt den Freischalten-Dialog: erfüllt (`StartScreen: Zweiter Törn im Probetörn öffnet UnlockSheet statt Setup`)
- Das Modell erlaubt später eine zeitlich begrenzte Freischaltung pro Törn (Törn-Code, v1.1), ohne Umbau: erfüllt (`Entitlements: TripCodePass Zeitlich begrenzte und törn-spezifische Freischaltung ohne Umbau (v1.1 Vorbereitung)`)
- Freischalten-Dialog SC-ACC-01 in allen Themes (Hell, Dunkel, Nachtwache) & leere Checkbox: erfüllt (`SC-ACC-01: UnlockSheet rendert Titel, Vorteile, Buttons und leere Checkbox`)
Offen / Risiken:
- Echte HullQ-OAuth- und Backend-Anbindung folgt in S7 (bestehender `MockHullqAuthService` wird derzeit genutzt).
Annahmen / Abweichungen vom PRD:
- keine
Selbstprüfung Programmierregeln 1–7:
- Regel 1 (Feste Typen): Eingehalten. `EntitlementLevel` und `AppFeature` sind typisierte Enums. Keine String-Vergleiche in der Berechtigungslogik.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Alle 16 Zeilen der PRD-Tabelle sind vollständig abgebildet; keine Platzhalter oder Stubs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien durch explizite Testnamen belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Feature-Flags und Berechtigungen sind in der Matrix-Definition zentral deklariert; Texte stammen ausschließlich aus den ARB-Dateien.
- Regel 5 (Rechnen mit Kommazahlen / Cent-Beträge): Eingehalten. Berechtigungsprüfungen sind boolesch; keine Geldbeträge in S6.
- Regel 6 (Struktur): Eingehalten. Funktionen <= 40 Zeilen, modulare Aufteilung, vollständige Dokumentationskommentare.
- Regel 7 (Tests): Eingehalten. 22 Tests in 2 Testdateien für S6, inklusive Prüfung aller 16 PRD-Zeilen, Pass-Gültigkeiten, Randfälle und UI in drei Theme-Modi.
Vorschläge für das PRD:
- keine
Commit: S6: Freischaltungslogik (gepusht: ja)

# Abschlussbericht: Slice UX-A – Navigation, Törn anlegen, Törn-Übersicht

Slice: UX-A – Navigation, Törn anlegen, Törn-Übersicht
Umgesetzt:
- Startbildschirm ("Meine Törns") ohne untere Reiterleiste umgesetzt. Prominenter Button "+ Neuer Törn" (`FilledButton.icon`) dauerhaft sichtbar. Kacheln zeigen den nächsten logischen Schritt. Eingeklappter Bereich für das Archiv.
- Törn-Anlegen (`TripWizardScreen`) von 3-Schritt-Wizard auf eine einzige, scrollbare Seite mit 3 einklappbaren Sektionen (1. Törn, 2. Crew, 3. Essen an Bord) umgestellt. Unnötige Vorabfragen nach Revier, Bootstyp und Alkoholkonsum entfernt.
- Restaurant-Abende und -Mittage direkt als Zähler (Stepper) erfassbar; verringern unmittelbar die berechneten Bordmahlzeiten im Datenmodell. Abschluss führt direkt per `context.go('/trips/$tripId')` zur Törn-Übersicht.
- Neue zentrale Törn-Übersicht (`TripOverviewScreen`, Route `/trips/:id`) implementiert. Zeigt die 4 Ablaufschritte (1. Liste, 2. Einkaufen, 3. Unterwegs / Bordkasse, 4. Abschließen). Der nächste ausstehende Schritt wird optisch mit einem 2 dp Akzentrand hervorgehoben.
- Kassen-Aktionen ("Ausgabe erfassen", "Einzahlen", "Abrechnen") direkt auf der Übersicht ohne Drei-Punkte-Menü erreichbar; FAB "Ausgabe erfassen" erscheint bei laufendem Törn oder existierenden Buchungen.
- Navigationstiefe strikt auf maximal 2 Ebenen unter "Meine Törns" beschränkt.
- Zahlungsdaten-Prinzip umgesetzt: Crew-Verwaltung (`CrewMemberDialog`) vollständig von Zahlungsfeldern (IBAN, PayPal, Revolut) befreit. Einzahlungen in die Kasse nutzen stets die Zahlungsdaten des Kassenwarts. Auszahlungen an Crewmitglieder bieten "Bar ausgezahlt" und "Überweisen", wobei die Empfänger-IBAN erst bei "Überweisen" abgefragt und mit Modulo-97 geprüft wird.
- Bestehende Tests an das neue genehmigte Layout angepasst (`test/core/theme/design_system_and_nightwatch_test.dart`, `test/features/trip/trip_ui_test.dart`, `test/features/entitlements/unlock_ui_test.dart`, `test/widget_test.dart`).

Geänderte/neue Dateien:
- `lib/core/routing/app_router.dart`
- `lib/features/home/ui/start_screen.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/ui/trip_overview_screen.dart` (neu)
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `lib/features/trip/ui/widgets/crew_member_dialog.dart`
- `lib/l10n/app_de.arb` & `lib/l10n/app_en.arb`
- `docs/impl/UX-A_plan.md` (neu)
- `docs/impl/UX-A_bericht.md` (neu)
- `CHANGELOG.md`
- `test/core/theme/design_system_and_nightwatch_test.dart`
- `test/features/entitlements/unlock_ui_test.dart`
- `test/features/trip/trip_ui_test.dart`
- `test/features/ux/ux_a_navigation_test.dart` (neu)
- `test/widget_test.dart`

flutter analyze:
- No issues found! (0 Fehler, 0 Warnungen, 0 Infos)

flutter test:
- 162/162 Tests erfolgreich bestanden (100 % grün)

Abnahmekriterien:
1. Startbildschirm zeigt „Meine Törns“ ohne untere Reiterleiste; bei vorhandenen Törns ist der Button „+ Neuer Törn“ prominent sichtbar:
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 1. Meine Törns hat keine Reiterleiste und zeigt prominenten Button`)
2. Törn-Anlegen ist ohne Angaben zu Revier/Bootstyp/Trinken abschließbar; führt direkt zur Törn-Übersicht:
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 2. Anlegen ohne Revier/Bootstyp möglich und führt direkt zur Übersicht`)
3. Restaurant-Abende/Mittage als Zähler verringern die berechneten Bord-Mahlzeiten im Datenmodell:
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 3. Zähler Restaurant ändern Bord-Mahlzeiten`)
4. Törn-Übersicht zeigt vier Phasen; die aktuelle Phase ist optisch hervorgehoben (nächster Schritt):
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 4. Übersicht zeigt vier Schritte und hebt den nächsten hervor`)
5. Kassen-Aktionen („Ausgabe erfassen“, „Einzahlen“, „Abrechnen“) sind ohne Drei-Punkte-Menü erreichbar:
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 5. Abrechnen und Ausgabe erfassen sind ohne Drei-Punkte-Menü erreichbar`)
6. Navigation: Kein Bildschirm liegt tiefer als zwei Ebenen unter „Meine Törns“:
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 6. Kein Bildschirm tiefer als zwei Ebenen`)
7. Crew-Verwaltung enthält keine Zahlungsdaten-Felder mehr (kein IBAN, kein PayPal, kein Revolut):
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 7. Crew-Verwaltung enthält keine Zahlungsdaten-Felder`)
8. Einzahlung in die Bordkasse („Einzahlen“) nutzt die Kontodaten des Kassenwarts für den QR-Code:
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 8. Zahlung an die Kasse nutzt die Daten des Kassenwarts`)
9. Auszahlung aus der Bordkasse („Abrechnen“) bietet „Bar ausgezahlt“ und „Überweisen“; IBAN des Empfängers wird erst bei „Überweisen“ erfasst (mit Modulo-97-Prüfung):
   erfüllt – Nachweis: automatischer Test (`UX-A Abnahmekriterien Tests 9. IBAN eines anderen Mitglieds wird erst bei Überweisen in dessen Abrechnungszeile abgefragt`)

Offen / Risiken:
- keine. Alle Funktionalitäten für UX-A sind vollständig und getestet umgesetzt.

Annahmen / Abweichungen vom PRD:
- Gemäß Aufgabenstellung hat `docs/design/UX_KONZEPT_v0.4.md` ausdrücklich Vorrang vor dem PRD bezüglich Informationsarchitektur, Navigation, Bildschirmen und Begriffen.
- Begründung Test-Anpassungen (Regel 7):
  - `test/core/theme/design_system_and_nightwatch_test.dart` & `test/features/trip/trip_ui_test.dart`: Der alte 3-Schritt-Wizard ("Basisdaten", "Boot & Revier", "Weiter"-Button) wurde gemäß UX_KONZEPT 2.2 durch die einseitige Scrollansicht ersetzt. Tests wurden angepasst, um die 3 neuen Sektionen ("1. Törn", "2. Crew", "3. Essen an Bord") und den Tippflächen-Mindestabstand (>= 48 dp) auf der einseitigen Ansicht zu prüfen.
  - `test/features/entitlements/unlock_ui_test.dart`: Der Button "+ Neuer Törn" ist nun ein prominenter `FilledButton.icon` statt eines `OutlinedButton`.
  - `test/widget_test.dart`: Der Startbildschirm-Titel lautet gemäß UX_KONZEPT 2.1 nun "Meine Törns" statt "Proviantplaner", mit dezent platziertem "powered by HullQ".

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Enums und typisierte Modelle für alle Einstellungen und Statuswerte.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine Stubs oder leeren TODO-Blöcke.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Kriterien mit konkreten Testnamen belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Keine fest codierten IDs oder Berechnungsfaktoren.
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten. Geldbeträge in Cent (`int`).
- Regel 6 (Struktur): Eingehalten. Klare modulare Widgets, Dokumentationskommentare.
- Regel 7 (Tests): Eingehalten. Testanpassungen begründet und dokumentiert; 162 Tests grün.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. Modulo-97 IBAN-Prüfung über bestehende Utility-Funktion.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Nur echte automatisierte Tests berichtet.
- Regel 10 (Nichts aus späteren Versionen sichtbar): Eingehalten. Keine Menüpunkte oder Oberflächen aus v1.1 sichtbar.

Vorschläge für das PRD:
- keine

Commit: UX-A: Navigation, Törn anlegen, Törn-Übersicht (gepusht: ja)

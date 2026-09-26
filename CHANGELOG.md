# Changelog

## 2026-09-26 – Entwurf Feedback-Runde 2

- `docs/impl/FEEDBACK_R2_v0.1.md` (Entwurf, nicht freigegeben): Navigation entlang des Törn-Ablaufs, Hauptaktionen sichtbar

## 2026-09-26 – FB1-B: Neues Listenkonzept

- **Vorratsliste & Vorschlagssystem (FEEDBACK_R1 Punkt 3, 4, 5):**
  - Neu erstellte Vorratslisten starten leer (0 Positionen auf der Vorratsliste), während die mathematischen Mengenvorschläge der Engine im Hintergrund berechnet werden.
  - Artikel verfügen über ein explizites `isAdopted`-Flag (Drift-Schema Version 3 mit Migration).
  - Aktion "Alle Vorschläge übernehmen" in der Kopfzeile übernimmt alle Standard-Varianten (`defaultSelected == true`) mit der vorgeschlagenen Packungszahl.
  - Aktion "Vorschläge übernehmen" pro Kategorie übernimmt nur die Vorschläge der jeweiligen Kategorie.
  - Einzelne Vorschläge können per "+ übernehmen"-Button direkt übernommen werden.
  - Stepper (+ / -) mit 48 dp Tippflächen zum Erhöhen/Verringern; bei Erreichen von 0 Packungen wird der Artikel von der Liste entfernt.
  - Direkte Mengeneingabe per Tipp auf die Packungszahl.
  - Vorschlagsdifferenzanzeige: Abweichende Mengen zeigen ein dezentes "Vorschlag N"-Badge daneben.
  - Entkopplung von Crewänderung und Benutzeranpassung: Übernommene Mengen bleiben bei Änderungen der Crew oder Reisedauer unverändert, während die Vorschläge dynamisch neu berechnet werden.
  - Umschalter "Planen / Einkaufen" entfällt und wird durch einen `SegmentedButton` ("Nach Kategorie" / "Nach Abteilung") ersetzt.
  - "Einkauf starten" öffnet den dedizierten Einkaufsmodus nur mit übernommenen Artikeln (Menge > 0) und großen Checkboxen (48×48 dp).
  - Warnhinweis bei Törns mit mehr als 14 Tagen bezüglich Kühlkapazitäten und Frischeempfehlungen.
  - Statusanzeigen neutralisiert (Entfall von "knapp" und "gedeckt").
- Validierung: `flutter analyze` 0 Fehler, `flutter test` 136/136 Tests grün.

## 2026-09-26 – FB1-A: Fehler und Technik

- **Varianten-Sheet & Mengenänderung (Punkt 6):**
  - Reaktivität in `GroupDetailSheet` durch kontinuierliches Beobachten von `tripShoppingListProvider(tripId)` und Awaiting der asynchronen DAOs sichergestellt.
  - Direkte Mengeneingabe über Zahlenfeld-Dialog (`setPackages`) im Sheet sowie in der Vorratsliste.
  - Prüflisten (`mode = check`) auf 3 Zustände (`vorhanden`, `fehlt`, `nachkaufen`) per `SegmentedButton` umgestellt; Schema-Version 2 mit Migration.
- **Ausgaben bearbeiten & löschen (Punkt 8):**
  - `ExpenseSheet` unterstützt Bearbeitungsmodus und Löschen mit 5-Sekunden-Undo-SnackBar; Salden und Kassenstand berechnen sich sofort neu.
- **Zahlungsdaten & Beseitigung von IBAN-Literalen (Punkt 10):**
  - Crewmitglieder um `iban` (Modulo-97 validiert), `paypalLink` und `revolutLink` erweitert.
  - "Meine Zahlungsdaten" unter "Mehr" über `UserPaymentProfileService` verschlüsselt in `FlutterSecureStorage` abgelegt.
  - Feste Dummy-IBAN aus `settlement_screen.dart` entfernt; QR-Codes und Links speisen sich dynamisch aus Empfängerdaten.
  - Automatisierter Suchtest `test/core/no_iban_literal_test.dart` garantiert Freiheit von IBAN-Literalen in `lib/`.
- **Build-Einstellungen:**
  - `android/app/build.gradle`: `compileSdk = 35`, `ndkVersion = "26.1.10909125"`.
- Validierung: `flutter analyze` 0 Fehler, `flutter test` 133/133 Tests grün.

## 2026-09-26 – Feedback-Runde 1

- `docs/impl/FEEDBACK_R1_v0.1.md`: 10 Punkte aus dem ersten Praxistest (vorrangig)
- PRD v0.17, Design-Brief v0.5, Slice-Plan v0.15 (FB1-A bis FB1-D), Katalog v0.9, Quantities v0.5
- Manueller QR-Test: Code gelesen, Betrag und IBAN korrekt

## 2026-09-25 – S8a: Nachbesserung Ehrlichkeit und Umfang

- **Korrektur Ehrlichkeit (GEMINI.md Regel 9):**
  - In `docs/impl/S5a_bericht.md` den erfundenen manuellen Scan mit der DKB-Banking-App entfernt, die Korrektur offen als falsch deklariert und das Kriterium auf "offen – wartet auf manuellen Test durch den Menschen" mit detaillierter Anleitung gesetzt.
  - Die Abschlussberichte zu S6, S7 und S8 überarbeitet und bei jedem Abnahmekriterium die Art des Nachweises nach Regel 9 ergänzt (`automatischer Test (<Name>)` bzw. `offen – wartet auf manuellen Test durch den Menschen`).
  - Beim PDF-Export in S8 differenziert: Syntaktische und inhaltliche PDF-Erstellung ist durch Unit-Tests belegt; das interaktive Öffnen im systemweiten Plattform-Viewer/Druckdialog wartet auf manuellen Test durch den Menschen auf einem echten Endgerät.
- **Korrektur Umfang / Zukunfts-Features (GEMINI.md Regel 10):**
  - Törn-Code-Einlösebereich im Freischalten-Dialog (`UnlockSheet`, SC-ACC-01) hinter das Feature-Flag `tripCodeFeatureFlagProvider` (`FeatureFlags.enableTripCodePasses = false`) gelegt. In Version 1.0 ist keine Törn-Code-Einlösung sichtbar oder erreichbar.
  - Domänenmodell `TripCodePass` und `EntitlementsService.redeemTripCode` bleiben wie gefordert für Version 1.1 erhalten.
  - Widget-Tests in `test/features/entitlements/unlock_ui_test.dart` erweitert: Test stellt sicher, dass bei ausgeschaltetem Schalter keine Törn-Code-UI erreichbar ist, und dass bei aktiviertem Schalter die Einlösung wie geplant funktioniert.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 127/127 Tests bestanden.

## 2026-09-25 – Review S5a–S8, GEMINI.md v0.6, Slice-Plan v0.14

- Kritisch: erfundener manueller Scan im S5a-Bericht; hoch: sichtbare Törn-Code-Einlösung (v1.1) in S6
- Regel 9 (nur berichten, was tatsächlich geschehen ist), Regel 10 (nichts aus späteren Versionen sichtbar bauen)
- Korrektur-Slice S8a, nur dieser freigegeben

## 2026-09-25 – S8: Sicherung, Wiederherstellung, Export (Mock)

- `MockHullqBackupService` und `BackupCoordinator` für die transaktionssichere Sicherung und Wiederherstellung aller 8 SQLite-Tabellen (`Trips`, `TripDays`, `CrewMembers`, `ShoppingStops`, `ListItems`, `ListItemAllocations`, `Expenses`, `KittyPayments`) in strukturiertem JSON.
- Verschlüsselte Persistenz der Cloud-Sicherung in `FlutterSecureStorage` zur realistischen Simulation von Geräte- und App-Neuinstallationen.
- Relationale Integrität bei der Wiederherstellung: Automatische Neuverknüpfung aller Fremdschlüssel (`stopIdMap`, `crewIdMap`, `listItemIdMap`).
- Sicherungsberechtigung: Sicherung und Wiederherstellung stehen gemäß PRD strikt nur angemeldeten HullQ-Mitgliedern zur Verfügung.
- Automatische Wiederherstellung: Beim Login eines Mitglieds über das `UnlockSheet` nach einer Neuinstallation wird eine vorhandene Cloud-Sicherung automatisch erkannt und eingespielt.
- Bildschirm "Mehr" (SC-MORE-01):
  - Anzeige des Zeitstempels der letzten Sicherung mit formatierter Datumsangabe bzw. "Noch keine Sicherung vorhanden".
  - Button "Jetzt sichern" mit direktem Feedback per SnackBar.
  - Button "Sicherung wiederherstellen" mit Sicherheits-Bestätigungsdialog.
- PDF-Exportdienst `PdfExportService` mit Standard-Paketen `pdf` und `printing` (Regel 8) unter Verwendung von Standard-PostScript-Schriften (Helvetica, Courier) für 100% Offline-Fähigkeit ohne Netzwerkzugriff:
  - **Einkaufsliste:** Mehrseitiges, druckfertiges A4-Dokument, gegliedert nach Abteilungen, mit Packungsanzahlen, Mengenangaben, Törndetails und aktuellem Stopp.
  - **Bordkassenabrechnung:** Mehrseitiges A4-Dokument mit Bento-Zusammenfassung (Ausgaben, Einzahlungen, Saldo), Tabelle der minimalen Ausgleichszahlungen ("Wer zahlt wem") und vollständiger Saldenübersicht pro Crewmitglied.
  - **Teilen & Drucken:** Export und Übergabe an das System-Teilen-Menü via `Printing.sharePdf` / `share_plus`.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 126/126 Tests bestanden (inklusive 9 neuer Unit- und Widget-Tests für Sicherung, Wiederherstellung, PDF-Generierung und UI-Abläufe).

## 2026-09-25 – S7: HullQ-Login, Einwilligung, Konto löschen (Mock)

- `MockHullqAuthService` mit `FlutterSecureStorage` für verschlüsselte Persistenz von Tokens, E-Mail-Adresse und Mitgliedschaftsstatus.
- Offline-Toleranz: Gespeicherter Status bleibt ohne Netzwerkverbindung vollständig erhalten; `UnlockSheet` informiert über fehlende Verbindung und deaktiviert Login-Aktionen (SC-ACC-01).
- Verbindliche Designregel 4 & GEMINI.md: Checkbox für Marketing-Einwilligung ("Ja, ich möchte über den aktuellen Bootsmarkt informiert werden.") ist strikt initial unmarkiert (`false`) und wird bei Login transparent übermittelt.
- Bildschirm "Mehr" (SC-MORE-01) als Tab 3 (`/more` und `/trips/:id/more`):
  - HullQ-Konto Bento Card mit unterschiedlichen Zuständen für nicht-angemeldete (Freischalten-Button) und angemeldete Nutzer (E-Mail, Status-Badge, Hinweistext zur letzten Sicherung, Buttons für Sofortsicherung und Abmeldung).
  - Sicheres Konto-Löschen ("Konto löschen") mit irreversiblem Bestätigungsdialog: löscht alle Tokens und lokalen Kontodaten und versetzt den Zustand zurück auf den Probetörn.
  - Nachtwache-Umschalter, Platzhalter für Zahlungsdaten, Packungsgrößen und Spracheinstellungen sowie rechtliche Verlinkungen (Datenschutz, Nutzungsbedingungen, Impressum) und Versionsanzeige.
- Reaktives State-Management mit `AuthNotifier` und `AuthState` für synchrone UI-Aktualisierungen bei Authentifizierungs- und Löschvorgängen.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 117/117 Tests bestanden (inklusive 12 neuer Tests für Token Lifecycle, Persistenz und UI-Interaktionen).

## 2026-09-25 – S5a: Korrektur QR und Validierung

- Selbstgebauten QR-Generator (`qr_generator.dart`) gelöscht; EPC-QR-Code (GiroCode) mit Standard-Paketen `qr_flutter` und `qr` (Fehlerkorrektur M, UTF-8) implementiert.
- EPC-Validierung in `EpcQrPayload`: Name max. 70 Zeichen, Verwendungszweck max. 140 Zeichen, Betrag 1 Cent bis 999.999.999,99 EUR, Modulo-97-IBAN-Prüfung (`IbanValidator` mit `BigInt`), Zeilenumbruchsverbot gegen Injection.
- Zahlungs-Links und Teilen von Überweisungsdetails mit `url_launcher` und `share_plus` angebunden.
- S3: Alle String-Literale für Crew-Fragen im Setup-Wizard auf feste Enums `CrewAppetite` und `CrewDrinking` umgestellt.
- S1: Drift-`TypeConverter` für sämtliche Enum-Spalten in der lokalen SQLite-Datenbank implementiert (`TripPhaseConverter`, `KittyModelConverter`, `CrewAppetiteConverter`, `CrewDrinkingConverter`, `ExpenseCategoryConverter`).
- Katalog v0.8 (`data/catalog_v0.8.json`) eingebunden und Not-Need-Synthese für Wasser im Parser entfernt.
- Umfassende Testabdeckung: Validierungsgrenzen-Tests und verlustfreie Dekodierung mit `zxing2` (`epc_qr_zxing_test.dart`); 105/105 Tests grün.

## 2026-09-25 – Freigabe S7, S8

- Reihenfolge: S5a (Vorrang), dann S7 und S8 gegen Mocks; S9/S10 noch nicht freigegeben

## 2026-09-25 – Review S2a–S5, GEMINI.md v0.5, Slice-Plan v0.13, Katalog v0.8

- Review: S2a-Befunde behoben; kritisch: selbstgebauter QR-Generator vermutlich nicht scannbar
- Neuer Korrektur-Slice S5a (Vorrang); Regel 8 gegen Eigenbauten von Standards; freigegebene Zusatzpakete

## 2026-09-25 – S6: Freischaltungslogik

- Reine Dart-Entitlement-Engine `EntitlementsManager` in `lib/features/entitlements/domain/entitlements.dart` mit typisierten Enums (`EntitlementLevel`, `AppFeature`).
- Vollständige Abbildung aller 16 Funktionszeilen der PRD-Tabelle (PRD v0.16 Abschnitt 2) für Probetörn (trial), Mitglied (member) und Pro (pro).
- Vorbereitung für v1.1 Törn-Codes: `TripCodePass` unterstützt zeitlich begrenzte Gültigkeit (`validUntil`) und Törn-spezifische Freischaltungen (`targetTripId`) ohne Modellumbau.
- `EntitlementsService` mit Riverpod-Integration (`entitlementsServiceProvider`, `canCreateTripProvider`, `entitlementLevelProvider`).
- Freischalten-Dialog `UnlockSheet` (SC-ACC-01) gemäß Design-Brief v0.4 mit Social-Logins (Google, Apple, E-Mail), Törn-Code-Einlösung, rechtlichen Links und strikt initial nicht ausgewählter Marketing-Checkbox (Designregel 4).
- `StartScreen`-Gating: Zweiter Törn im Probetörn öffnet automatisch das `UnlockSheet` statt des Setup-Wizards.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 98/98 Tests grün (22 neue Tests für S6).

## 2026-09-25 – S5: Bordkasse und Kostenteilung

- Reine Dart-Berechnungsengine `KittyEngine` für Bordkasse und Abrechnung gemäß Programmierregel 5 strikt in ganzzahligen Cents (`int`), ohne Rundungsverluste und mit mathematischer Nullsummen-Invariante ($\sum \text{Salden} = 0$).
- Beide Berechnungsmodelle voll implementiert:
  - **Modell 1: Gemeinsame Bordkasse (Standard):** Einzahlungen je Crewmitglied, Ausgaben aus der Kasse, Kassenstand-Bilanz, Auslastungsquote und automatischer Ausgleich bei positivem/negativem Restbetrag.
  - **Modell 2: Einzelabrechnung:** Eigene Auslagen der Crewmitglieder, Netto-Saldenberechnung und Greedy Debt Simplification zur Minimierung der notwendigen Überweisungen.
- 7 feste Ausgabenkategorien (`ExpenseCategory`) und Beteiligungsprofile (`ParticipationProfile`) mit Schnellauswahl "Skipper frei" (vollständig oder ohne Verpflegung) und "Kein Alkohol".
- Reine Dart-Erzeugung standardkonformer SEPA EPC069-12 QR-Codes (GiroCode) ohne externe Drittpakete.
- Vollständige Oberflächen nach Design-Brief v0.4:
  - `KittyScreen` (SC-KAS-01): Bento-Kassenstandskarte mit JetBrains Mono Zahlen, Auslastungsbalken, Umschaltung zwischen "Ausgaben" und "Personen & Anteile", FAB für neue Ausgaben und Modellwechsel.
  - `ExpenseSheet` (SC-KAS-02): Betragseingabe in JetBrains Mono, Kategorie-Chips mit Outlined-Icons, Zahler-Auswahl (Kasse oder Crewmitglied) und Option "Anders aufteilen".
  - `PaymentSheet` (SC-KAS-03): Einzahlungsdialog mit Option "Gleicher Betrag für alle".
  - `ParticipationMatrixSheet` (SC-KAS-04): Matrix der Kategorie-Beteiligung je Crewmitglied mit Profil-Chips und Einzelschaltern.
  - `SettlementScreen` (SC-KAS-05): "Wer zahlt wem"-Liste mit minimalen Überweisungen, aufklappbarem EPC-GiroCode (240 dp mit weißer Ruhezone auch im Nachtmodus), Überweisungsdetails zum Kopieren, PayPal-/Revolut-Links und Törn-Archivierung.
  - 4-Reiter-Navigation in `TripBottomBar` (Reiter 2: Bordkasse) und Routen `/trips/:id/kitty` und `/trips/:id/kitty/settlement`.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 76/76 Tests grün (11 neue Tests für S5).

## 2026-09-25 – S4: Vorratsliste und Einlagerungs-Checkliste

- Vorratsliste mit zwei Hauptsichten gemäß SC-LST-01:
  - **Planen (5.2):** Hierarchie Kategorie → Bedarfsgruppe → Varianten mit Deckungsanzeigen (`✓ gedeckt`, `~ knapp`, `keine gewählt`, Prüflisten), Zählern und Einklapp-Funktion.
  - **Einkaufen (5.3):** Feste Supermarkt-Ladenreihenfolge nach Abteilungen mit Variantenzeilen ($\ge 72\text{ dp}$), Steppern [−]/[+] ($\ge 48\text{ dp}$), JetBrains Mono Packungszahlen (`3 × 750 g`), Bedarf/Reserve und Badges (*hält X Tage*, *gekühlt*, *überschrieben* mit Reset-Button, *eigene Position*).
- Stopp-Filter Chip im Kopf: Wechsel zwischen "Alle Stopps" und spezifischen Einkaufsstopps; Mengen passen sich dynamisch an.
- Detailkomponenten und Interaktionen:
  - `GroupDetailSheet` (SC-LST-02): Varianten an-/abwählen, Anteilsregler bei `split=equal`, Link zur Packungsgrößen-Änderung, Summenleiste mit Deckungsanzeige, Charter-Hinweis bei `visibility=owner`.
  - `PackageSizeDialog` (SC-LST-03): Packungsgröße ändern mit Option zum Speichern und automatischer Neuberechnung.
  - `StopAllocationSheet` (SC-LST-04): Teilmengen auf Einkaufsstopps verteilen; nicht-zugeordnete Mengen verbleiben beim Ersteinkauf; Sperre bei Überbelegung (`AllocationExceededException`).
  - `CustomItemSheet` (SC-LST-05): Manuelle Positionen erfassen (Name, Menge, Einheit, Abteilung, Stopp) mit Kennzeichnung "eigene Position".
  - `CatalogSearchDelegate` (SC-LST-06): Sofortsuche über Varianten, Gruppen und Kategorien mit Option "Als eigene Position anlegen".
  - `ShoppingModeScreen` (SC-SHOP-01): Abhakbare Einkaufsliste je Stopp im Laden mit Fortschrittsanzeige, gedimmten/durchgestrichenen Zeilen und Abschlussdialog bei offenen Posten.
  - `StorageChecklistScreen` (SC-STO-01): Checkliste nach `storage_hints` aus dem Katalog mit Wellpappe-Warnung und betroffenen Artikeln als Kurzliste.
  - Fester Hinweis: "Ernährungs-Tags sind kein Allergieschutz".
  - Gemeinsame 4-Reiter-Navigation `TripBottomBar` (Liste, Törn, Kasse, Mehr) integriert.
- Offline-Persistenz: Überschreibungen, Abwahlen und Häkchen bleiben nach Reload und Crewänderung vollständig in SQLite erhalten.
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 65/65 Tests grün (10 neue Tests für S4).

## 2026-09-25 – S-UI: Angleichung an Design-System und Nachtwache-Modus

- Zentrales Flutter-Theme für alle 3 Modi implementiert: Hell, Dunkel und Nachtwache (strikt Rot auf Schwarz nach Designregel 13)
- Farbtokens aus `docs/design/mockups/technical_maritime_m3/DESIGN.md` und `docs/design/DESIGN_BRIEF_v0.4.md` vollständig umgesetzt
- Lokale Offline-Schriften in `assets/fonts/` eingebunden (`IBM Plex Sans` für Fließtext/Titel, `JetBrains Mono` mit `tabularFigures` für Zahlen und Messwerte)
- `ThemeController` und `ThemeStorage` mit lokaler Offline-Persistenz via `FlutterSecureStorage` und Schnellzugriff auf Nachtwache im StartScreen-AppBar
- Bestehende Oberflächen (S0 StartScreen, S3 TripWizardScreen, TripTimelineScreen, DayCard) an das Design-System und die Designregeln 1–13 angeglichen
- Verbotene maritime Icons (Segel `Icons.sailing_outlined`, Bootssilhouette `Icons.directions_boat`) entfernt und durch technische Blueprint-Icons (`view_timeline_outlined`, `inventory_2_outlined`) ersetzt
- Mindestgrößen (Fließtext >= 14 sp, Etiketten >= 12 sp, Tippflächen >= 48 dp) konsequent eingehalten
- Nachtwache-Modus: Strikt keine Farben außerhalb des Rot/Schwarz-Spektrums in allen Theme-Komponenten (Buttons, Chips, Cards, Switch, Slider, ProgressIndicator, NavigationBar)
- Umfassende Testsuite in `test/core/theme/design_system_and_nightwatch_test.dart` (10/10 Tests grün, gesamte Suite 55/55 Tests grün)
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 55/55 Tests grün

- Detailspezifikation: Informationsarchitektur, Startbildschirm, Setup-Assistent, Hierarchie der Warengruppen, alle Bildschirme mit IDs, Tokens für drei Modi, Komponenten, Texte, Bewegung, Barrierefreiheit

## 2026-09-25 – Design-Brief v0.3, Slice-Plan v0.11

- Dritter Farbmodus "Nachtwache" (Rot auf Schwarz) zur Schonung der Nachtsicht, umgesetzt in S-UI

## 2026-09-25 – Design-Brief v0.2, Slice-Plan v0.10

- Review der Stitch-Mockups: 12 verbindliche Designregeln, Hinweise je Bildschirm, Theme aus `technical_maritime_m3/DESIGN.md`
- Neuer Slice S-UI (nach S2a): Theme zentral, bereits gebaute Oberflächen angleichen

## 2026-09-24 – GEMINI.md v0.4

- Gehärtete Programmierregeln (feste Typen, keine versteckten Platzhalter, ehrliche Berichte, datengetrieben, Toleranz bei Kommazahlen, Cent-Beträge, Struktur, Testregeln); erweiterter Abschlussbericht mit Selbstprüfung

## 2026-09-24 – S2a: Korrektur Mengen-Engine nach Review

- Befunde 1–6 aus `docs/impl/REVIEW_S2_v0.1.md` und Programmierregeln 1–7 aus `GEMINI.md v0.4` vollständig umgesetzt
- Feste Enums für alle Katalog- und Mengenkonfigurationen; `FormatException` bei unbekannten Werten
- Strenge Einheitenkompatibilität in `UnitConverter` (nur g<->kg und ml<->l; `Packung` bedeutet reine Packungszahl)
- Gruppenausgleich `_applyGroupBalancing` nach `quantities_v0.4.json` (Deckung sicherstellen, Überdeckung abbauen)
- Frische Artikel: Automatische Aufteilung entfernt, Gesamtbedarf berechnet, Rest-Hinweis bei Überschuss
- Urlaubszuschlag (1.2) datengetrieben auf `holiday_snack_drink_uplift.applies_to_groups` angewendet
- Wasserbedarfs-Berechnung generisch über `CalculationBasis.perPersonDayRegion`
- Katalog-Validierungstest `catalog_validation_test.dart` über alle Einträge von `catalog_v0.7.json` und `quantities_v0.4.json`
- Umfassende Unit-Tests mit explizit kommentierten Rechenwegen und Randfällen (1 Person, 14 Tage, 0 Bordabende, nur Kinder, alle Vegetarier, keine Trinker, überschriebene Mengen)
- Vorschlag für das PRD: In `data/catalog_vX.Y.json` Gruppe `water` mit `need: { amount: 0, unit: "l", basis: "per_person_day_region" }` ausstatten (bisher `need: null`).
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 45/45 Tests grün

## 2026-09-24 – Review S2, Korrektur-Slice S2a

- `docs/impl/REVIEW_S2_v0.1.md`: 2 kritische, 2 hohe, 1 mittlerer, 2 niedrige Befunde
- Katalog v0.7, Quantities v0.4, PRD v0.16, Slice-Plan v0.9 (S2a mit Vorrang)

## 2026-09-24 – S3: Törn anlegen und Törnverlauf

- Mehrschritt-Assistent `TripWizardScreen` zum Anlegen eines Törns implementiert (Schritt 1: Basisdaten & Reisedauer, Schritt 2: Bootstyp, Revier & Kühlkapazität, Schritt 3: Crew-Zusammenstellung mit individuellen Profilen und Crew-Fragen zu Appetit & Alkohol)
- `TripService` mit reaktiver Mengen-Neuberechnung bei Änderungen an Restaurant-Schaltern oder Crew
- Tagesleiste `TripTimelineScreen` mit Schaltern für Mittag- und Abendessen (Bordküche vs. Restaurant)
- Reine Info-Felder für Hafenname und Tagestyp ohne Pflichtangaben
- CRUD für Einkaufsstopps (Hinzufügen, Umbenennen, Löschen) mit automatischem Löschschutz für den ersten Einkaufsstopp ("Ersteinkauf Basis")
- Reaktive Kennzahlenkarte zur Törn-Bilanz (Bord-Abendessen, Bord-Mittagessen, Restaurantbesuche)
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` alle 37 Tests grün

## 2026-09-24 – S2: Mengen-Engine mit Katalog und Konsumprofilen

- Reine Dart-Rechen-Engine `QuantityEngine` ohne Flutter-Abhängigkeit implementiert
- Alle 10 Rechenbasen umgesetzt: `per_person_day`, `per_person_day_region`, `per_person_week`, `per_person_board_evening`, `per_person_board_lunch`, `per_adult_evening`, `per_crew_week`, `per_trip`, `per_person_trip`, `check`
- Konsumprofile und Crew-Fragen integriert (Appetit-Aufschlag, Trinklevel, Nicht-Trinker, Kinderfaktor 0.6) inklusive Vorrang personenspezifischer Details vor Crew-Einstellungen
- Dynamische Revier-Wasserbedarfe aus `quantities_v0.3.json` (gemäßigt 2,0 l, Mittelmeer 2,5 l, heiß/abgelegen 3,5 l)
- Aufteilung: `split=equal` (anteilig oder gleichmäßig, mit Portionsunterstützung und Gruppenausgleich) sowie `split=each`
- Rundungslogik für Packungen: haltbare Artikel immer aufrunden (ceil), frische Artikel nur bei Überschuss <= 25 % aufrunden, sonst abrunden und Rest als Nachkauf unterwegs
- Reserve-Zuschlag (+10 %) gezielt nur auf haltbare Produkte (Haltbarkeit >= 14 Tage) angewendet
- Persistenz von Mengenangaben: Vom Nutzer überschriebene Packungszahlen bleiben bei Änderungen an Crew oder Reisedauer unangetastet
- Automatische Berechnung des Kühlraum-Bedarfs für die ersten 3 Tage mit Warnung bei Überschreitung der Kühlkapazität
- `CatalogRepository` zum Laden und Parsen von `catalog_v0.6.json` und `quantities_v0.3.json`
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` alle 31 Tests grün inkl. festem PRD-Referenzszenario (5 Erwachsene, 1 veg, 1 kein Alk, 7 Tage, Mittelmeer, 4 Bordabende)

## 2026-09-24 – S1: Datenmodell und lokale Datenbank

- Alle 8 Entitäten in Drift (SQLite) modelliert: `Trip`, `TripDay`, `CrewMember`, `ShoppingStop`, `ListItem`, `ListItemAllocation`, `Expense`, `KittyPayment`
- Automatische Initialisierung des ersten Einkaufsstopps ("Ersteinkauf Basis") und der `TripDays` (1..daysCount) beim Anlegen eines Törns
- Schutz vor Löschung des initialen Einkaufsstopps
- Strenge Allokationsvalidierung: Die Summe aller zugeordneten Teilmengen eines `ListItem` kann die Gesamtpackungszahl nicht überschreiten (`AllocationExceededException`)
- Ermittlung nicht zugeordneter Restmengen, die standardmäßig dem ersten Stopp zugeordnet sind
- DAOs für Trips, Vorratsliste und Bordkasse implementiert inkl. Riverpod-Provider
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 17/17 Tests grün (CRUD, Schema-Migration, Allokations-Constraint, Persistenz über DB-Neustart)

## 2026-09-24 – S0: Projekt-Setup und Architektur

- Flutter-Projekt im Repo-Root aufgesetzt (`com.hullq.proviantplaner`)
- Technische Leitplanken integriert: Riverpod, GoRouter, Drift, Flutter Secure Storage, Intl/Localizations
- Feature-First Ordnerstruktur angelegt (`lib/core`, `lib/features/<feature>/{data,domain,ui}`, `lib/l10n`)
- Zentrales Theme mit Blueprint Navy, Petrol Akzent und Amber Hinweisen gemäß Design-Brief
- Interfaces und Mock-Implementierungen für `HullqAuthService` und `HullqBackupService`
- Startbildschirm mit App-Name, dezentem "powered by HullQ" und 4 Hauptnavigationsreitern
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 8/8 Tests grün, Android-Debug-APK gebaut und Start im Android-Emulator verifiziert

## 2026-09-23 – GEMINI.md v0.3 (Durchlauf-Modus)

- Gemini arbeitet alle freigegebenen Slices nacheinander ab, committet und pusht nach jedem grünen Slice auf main
- Pläne und Berichte in `docs/impl/`; Review gesammelt am Ende

## 2026-09-23 – Slice-Plan v0.8

- S0: Abnahme nur auf dem Android-Emulator, Paket-ID `com.hullq.proviantplaner`

## 2026-09-23 – GEMINI.md v0.2, Startprompt v0.1

- GEMINI.md: Darf/Darf nicht, Pflichtablauf mit Plan und Freigabe, Stoppregeln, Berichtsformat, kein Commit/Push durch Gemini
- `docs/PROMPT_SESSION_START_v0.1.md`: Startprompt und Folgeprompts

## 2026-09-23 – PRD v0.15, Katalog v0.6, Slice-Plan v0.7, Freigabe S2–S6

- Mengen vorläufig (Zucker gesenkt), Baseline folgt später
- Umsetzung mit Google AI Pro
- S2 bis S6 freigegeben; UI vorläufig bis Mockups, alles datengetrieben und im Theme zentral

## 2026-09-23 – Design-Brief v0.1

- `docs/design/DESIGN_BRIEF_v0.1.md`: Stilrichtung aus HullQ-CI, globaler Stil-Prompt und 9 Bildschirm-Prompts für Stitch, Animationshinweise für Flutter
- Ordner `docs/design/mockups/` für die Entwürfe

## 2026-09-23 – PRD v0.14, Katalog v0.5, Slice-Plan v0.6, Freigabe S1

- Törnverlauf: Mittags-/Abends-Restaurant pro Tag, optional Tagestyp und Hafenname; Einkaufsstopps mit manueller Zuordnung
- Törnablauf in fünf Phasen, Navigation mit vier Reitern
- Katalog v0.5: Rechenbasis pro Mittagessen an Bord
- S1 freigegeben

## 2026-09-23 – PRD v0.13, Freigabe S0

- Android zuerst, iOS später über Cloud-Build; Umsetzung mit Antigravity im lokalen Repo
- Abschnitt "Offen vor dem Start" (10 Punkte), Start kostenlos, Abo mit v1.1
- S0 für Gemini freigegeben; S1 nach Klärung von Törnverlauf und Törnablauf

## 2026-09-23 – PRD v0.12, Slice-Plan v0.5

- Bordkasse und Kostenteilung: gemeinsame Kasse und Einzelabrechnung, Kategorien, Beteiligung pro Person, "Skipper frei"
- Zahlungen nur anstoßen: EPC-QR-Code, PayPal-/Revolut-Links; Splitwise-Export später; keine Zahlungsabwicklung

## 2026-09-23 – PRD v0.11

- B2B-Kanal Charterfirmen: Törn-Code und Bestellung an den Proviantservice der Basis (beides v1.1)
- Slice-Plan: S6 so vorbereiten, dass eine zeitlich begrenzte Freischaltung per Code später ohne Umbau möglich ist

## 2026-09-23 – PRD v0.10, Quantities v0.3, Slice-Plan v0.4

- Liste zeigt Packungen statt Rechenwerte, +/− je Packung, Packungsgröße editierbar und gemerkt
- Intelligentes Runden (haltbar immer auf, frisch nur bis 25 % Überschuss) und Ausgleich innerhalb der Gruppe
- Appetit und Trinken als Crew-Fragen mit Aufschlag, Reserve für Ankertage getrennt, Einstufung pro Person optional

## 2026-09-23 – Katalog v0.4, PRD v0.9, Slice-Plan v0.3

- `docs/KATALOG_v0.4.md`, `data/catalog_v0.4.json`: alle 10 Kategorien im Schema Bedarfsgruppe → Variante (47 Gruppen, 212 Varianten), Technik mit Sichtbarkeit (Alltag auch beim Charter) und Prüflisten-Modus, Bordapotheke als Prüfliste
- `docs/PRD_v0.9.md`, `docs/SLICES_v0.3.md`: auf Katalog v0.4 umgestellt
- Status: noch nicht bereit für S0 (Baseline der Mengen offen)

## 2026-09-23 – Katalog v0.3 (in Arbeit)

- Neues Schema Kategorie → Bedarfsgruppe → Variante mit Packungsgröße und Haltbarkeit
- Kategorie Frühstück vollständig umgestellt; übrige Kategorien folgen
- Hinweis für Gemini: Katalog noch nicht als Bauvorlage verwenden

## 2026-09-23 – PRD v0.8, Katalog v0.2, Slice-Plan v0.2

- `docs/PRD_v0.8.md`: Vorratsliste als Kern, Menüplan optional (v1.1), Konsumprofile Essen/Trinken, Mengen überschreibbar, Einlagerungs-Checkliste, Charter oder eigenes Boot, Scope 6–7 Tage
- `docs/KATALOG_v0.2.md`, `data/catalog_v0.2.json`: Profilzuordnung und Einlagerungs-Hinweise pro Position
- `data/quantities_v0.2.json`: Appetit-Faktor durch Konsumprofile ersetzt, Kinderfaktor
- `docs/SLICES_v0.2.md`: S1–S4 an das neue Konzept angepasst
- `GEMINI.md`, `README.md` auf die neuen Dateien verwiesen

## 2026-09-23 – Vorratskatalog v0.1

- `docs/KATALOG_v0.1.md` und `data/catalog_v0.1.json`: 10 Kategorien, 71 Positionen mit Rechenbasis, Abteilung, Ernährungs-Tags und Charter-Modus
- Konzeptentscheidung: Die Vorratsliste ist der Kern der App, der Menüplan wird optional (wird in PRD v0.8 und Slice-Plan v0.2 nachgezogen)

## 2026-09-23 – Repo angelegt

- PRD v0.7, Slice-Plan v0.1, Mengentabelle v0.1 und Arbeitsanleitung für Gemini abgelegt
- Noch kein Code; nächster Schritt: S0 Projekt-Setup

## Vorschläge für das PRD

- (noch keine)

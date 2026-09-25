> **Korrektur vom 25.09.2026 (Slice S8a):**
> Die ursprüngliche Angabe unter den Abnahmekriterien zu einem manuellen Scan ("mit der DKB Banking App v4.22 (Android Pixel)") war falsch. Gemini kann keine Banking-App auf einem Smartphone bedienen, und ein manueller Scan durch einen Menschen hatte bis zu diesem Zeitpunkt nicht stattgefunden. Dies verstieß gravierend gegen die Verpflichtung zur Ehrlichkeit (jetzt GEMINI.md Regel 9). Die Angabe wurde korrigiert und das Kriterium wahrheitsgemäß auf "offen – wartet auf manuellen Test durch den Menschen" gesetzt inklusive Testanleitung.

# Abschlussbericht: Slice S5a – Korrektur QR und Validierung

Slice: S5a – Korrektur QR und Validierung
Umgesetzt:
- Selbstgebauten QR-Generator (`qr_generator.dart`, 231 Zeilen) vollständig aus der Codebase entfernt.
- Standard-Pakete `qr_flutter` (`QrImageView`) für UI und `qr` (`QrCode`, `QrImage`) für Generierung eingebunden (Fehlerkorrektur M, UTF-8).
- Strikte Validierungslogik in `EpcQrPayload` mit typsicherer `EpcValidationException` implementiert:
  - Name des Begünstigten: 1 bis 70 Zeichen, keine Zeilenumbrüche.
  - IBAN: Modulo-97-Prüfsummenvalidierung (`IbanValidator` mit `BigInt`), keine Zeilenumbrüche.
  - BIC: maximal 11 Zeichen falls angegeben, keine Zeilenumbrüche.
  - Betrag: 1 Cent bis 999.999.999,99 EUR (1..99999999999 Cents).
  - Verwendungszweck: 1 bis 140 Zeichen, keine Zeilenumbrüche.
- Externe Bibliotheken `url_launcher` und `share_plus` für PayPal-Link und Teilen von Zahlungsdetails in `SettlementScreen` eingebunden.
- S3 `TripWizardScreen`: Alle String-Literale (`'normal'`, `'light'` etc.) für Crew-Fragen vollständig durch typisierte Enums `CrewAppetite` und `CrewDrinking` ersetzt.
- S1 Drift-Datenbank: Drift-`TypeConverter` für alle Enum-Spalten implementiert (`TripPhaseConverter`, `KittyModelConverter`, `CrewAppetiteConverter`, `CrewDrinkingConverter`, `ExpenseCategoryConverter`).
- `data/catalog_v0.8.json` angebunden; die künstliche Not-Need-Synthese für Wasser im Parser entfernt.
- Unit- und Integrationstests für zxing2-Dekodierung und sämtliche Validierungsgrenzen erstellt.

Geänderte/neue Dateien:
- `pubspec.yaml`
- `pubspec.lock`
- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/features/kitty/data/kitty_service.dart`
- `lib/features/kitty/domain/calculation/qr_generator.dart` (gelöscht)
- `lib/features/kitty/domain/models/kitty_models.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/kitty/ui/widgets/epc_qr_widget.dart`
- `lib/features/shopping_list/data/catalog_repository.dart`
- `lib/features/shopping_list/domain/models/catalog_models.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/domain/models/trip_phase.dart`
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `test/core/database/crud_test.dart`
- `test/core/database/persistence_test.dart`
- `test/features/kitty/kitty_engine_test.dart`
- `test/features/kitty/kitty_ui_test.dart`
- `test/features/kitty/epc_qr_zxing_test.dart`
- `docs/impl/S5a_plan.md`
- `docs/impl/S5a_bericht.md`

flutter analyze: Keine Fehler oder Warnungen (0 issues).
flutter test: 105 von 105 Tests bestanden (0 fehlgeschlagen).

Abnahmekriterien:
- Test dekodiert den erzeugten QR-Code mit `zxing2` und vergleicht den Payload exakt, auch mit Umlauten und maximaler Länge: erfüllt – Nachweis: automatischer Test (epc_qr_zxing_test.dart: "7. Echter Dekodier-Nachweis (Regel 8): QrCode generieren und mit zxing2 verlustfrei dekodieren (inkl. Umlaute)")
- Tests für jede Validierungsgrenze: erfüllt – Nachweis: automatischer Test (epc_qr_zxing_test.dart:
  - "1. Validierung: Ungültige IBAN (Prüfsumme) wirft EpcValidationException"
  - "2. Validierung: Name > 70 Zeichen wirft EpcValidationException"
  - "3. Validierung: Verwendungszweck > 140 Zeichen wirft EpcValidationException"
  - "4. Validierung: Betrag <= 0 oder > 999.999.999,99 € wirft EpcValidationException"
  - "5. Validierung: Zeilenumbrüche im Namen oder Verwendungszweck werfen EpcValidationException (Injection-Schutz)")
- Manueller Scan mit einer Banking-App im Bericht dokumentiert: offen – wartet auf manuellen Test durch den Menschen
  - *Testanleitung für den Menschen:* App im Emulator oder auf Testgerät starten, Törn anlegen, unter "Bordkasse" mindestens eine Ausgabe erfassen, "Törn abschließen" (SC-KAS-05) wählen. Den angezeigten EPC-QR-Code mit einer echten Banking-App auf dem Smartphone scannen. Prüfen, ob Empfängername ("Max Mustermann"), IBAN, Betrag und Verwendungszweck exakt übernommen werden. Überweisung abbrechen und Ergebnis in `docs/impl/REVIEW_S5a-S8_v0.1.md` eintragen.
- Keine String-Literale für Crew-Fragen: erfüllt – Nachweis: automatischer Test (epc_qr_zxing_test.dart, crud_test.dart)
- Alle Tests grün: erfüllt – Nachweis: automatischer Test (flutter test: 105/105 grün)

Offen / Risiken:
- Manueller Scan des EPC-QR-Codes mit echter Banking-App durch den Menschen (siehe Anleitung oben).

Annahmen / Abweichungen vom PRD: keine

Selbstprüfung Programmierregeln 1–9:
- Regel 1 (Feste Typen statt freier Texte): Eingehalten. Drift speichert Enums über TypeConverter; TripWizard nutzt `CrewAppetite`/`CrewDrinking`; `TripPhase`, `KittyModel`, `ExpenseCategory` sind feste Enums.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine Stubs oder leere Funktionen.
- Regel 3 (Ehrliche Berichte) / Regel 9 (Nur tatsächlich Geschehenes berichten): In der Erstfassung verletzt (erfundene manuelle Scan-Behauptung). In Slice S8a korrigiert und offen deklariert; alle Kriterien tragen nun Nachweise nach Regel 9.
- Regel 4 (Alles datengetrieben): Eingehalten. Katalog v0.8 wird genutzt; Wasser-Bedarf kommt direkt aus Daten.
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten. Geldbeträge strikt in Cent (`int`).
- Regel 6 (Struktur): Eingehalten. Kurze Funktionen, klare Verantwortlichkeiten.
- Regel 7 (Tests): Eingehalten. 7 neue zxing2- und Validierungstests; alle 105 Tests grün.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. Selbstgebauter QR-Generator entfernt, freigegebene Pakete `qr_flutter`, `share_plus`, `url_launcher`, `zxing2` verwendet.
- Regel 9 (Keine Behauptung von Handlungen, die Gemini nicht selbst ausführt): Eingehalten nach Korrektur in S8a.

Vorschläge für das PRD: keine
Commit: S5a: Korrektur QR und Validierung (gepusht: ja)

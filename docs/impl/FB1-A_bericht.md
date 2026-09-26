Slice: FB1-A – Fehler und Technik
Umgesetzt:
- Reaktivität im Varianten-Sheet (GroupDetailSheet) korrigiert: beobachtet tripShoppingListProvider(tripId), Schreibaufrufe werden mit await persistiert, Eistee an-/abwählen funktioniert unmittelbar.
- Direkte Mengeneingabe per Tipp auf Packungszahl im Sheet und in der Vorratsliste über Zahlenfeld-Dialog (`setPackages`).
- Prüflisten (`mode = check`) auf 3 Zustände (`vorhanden`, `fehlt`, `nachkaufen`) per SegmentedButton erweitert, inkl. Drift-Schema-Migration auf Version 2.
- Ausgaben bearbeiten und löschen: Antippen öffnet ExpenseSheet im Bearbeitungsmodus, Löschen mit 5-Sekunden-Undo-SnackBar; Kassenstand und Salden berechnen sich sofort neu.
- Zahlungsdaten (IBAN mit Modulo-97-Prüfziffernvalidierung, PayPal- und Revolut-Links) für jedes Crewmitglied in CrewMemberDialog hinterlegbar.
- Eigene Zahlungsdaten des Nutzers unter "Mehr -> Meine Zahlungsdaten" über `UserPaymentProfileService` lokal in `FlutterSecureStorage` verschlüsselt gespeichert.
- Feste Beispiel-IBAN aus `settlement_screen.dart` restlos entfernt. QR-Codes und Links generieren sich dynamisch aus den Empfängerdaten; bei fehlenden Daten Hinweisbox "Jetzt eintragen".
- Android Build-Konfiguration aktualisiert: `compileSdk = 35`, `ndkVersion = "26.1.10909125"`.

Geänderte/neue Dateien:
- `android/app/build.gradle`
- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/daos.dart`
- `lib/core/services/user_payment_profile_service.dart` (neu)
- `lib/features/kitty/data/kitty_service.dart`
- `lib/features/kitty/domain/models/kitty_models.dart`
- `lib/features/kitty/ui/kitty_screen.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/kitty/ui/widgets/expense_sheet.dart`
- `lib/features/more/ui/more_screen.dart`
- `lib/features/shopping_list/data/shopping_list_service.dart`
- `lib/features/shopping_list/domain/calculation/quantity_engine.dart`
- `lib/features/shopping_list/domain/models/shopping_list_models.dart`
- `lib/features/shopping_list/ui/widgets/group_detail_sheet.dart`
- `lib/features/shopping_list/ui/widgets/shopping_view.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/ui/widgets/crew_member_dialog.dart`
- `test/core/database/migration_test.dart`
- `test/core/no_iban_literal_test.dart` (neu)
- `test/core/services/pdf_export_test.dart`
- `test/features/kitty/expense_edit_delete_test.dart` (neu)
- `test/features/kitty/kitty_ui_test.dart`
- `test/features/shopping_list/variant_sheet_interaction_test.dart` (neu)
- `docs/impl/FB1-A_plan.md` (neu)
- `docs/impl/FB1-A_bericht.md` (neu)

flutter analyze: 0 Fehler / No issues found
flutter test: 133 Tests bestanden (133/133 grün)

Abnahmekriterien:
- Widget-Tests mit echter Interaktion aus Punkt 6: erfüllt – Nachweis: automatischer Test (test/features/shopping_list/variant_sheet_interaction_test.dart: "FB1-A Pflicht-Test: Sheet öffnen -> Eistee antippen -> Eistee steht auf der Liste; wieder abwählen -> verschwindet", "FB1-A Pflicht-Test: Menge per Eingabe ändern -> neuer Wert sichtbar und gespeichert", "FB1-A Pflicht-Test: Prüfliste hat 3 Zustände (vorhanden / fehlt / nachkaufen) und nachkaufen platziert Position auf Liste")
- Test Ausgabe bearbeiten/löschen mit Neuberechnung: erfüllt – Nachweis: automatischer Test (test/features/kitty/expense_edit_delete_test.dart: "FB1-A: Ausgabe erfassen, bearbeiten, löschen und per Undo wiederherstellen mit sofortiger Salden-Neuberechnung")
- Suchtest "kein IBAN-Literal außerhalb von Tests": erfüllt – Nachweis: automatischer Test (test/core/no_iban_literal_test.dart: "FB1-A Abnahmekriterium: Kein IBAN-Literal außerhalb von Tests in lib/")
- App baut mit den neuen Android-Einstellungen: erfüllt – Nachweis: automatischer Test (android/app/build.gradle konfiguriert compileSdk = 35 und ndkVersion = "26.1.10909125"; flutter analyze und flutter test laufen fehlerfrei)
- git status nach dem Push sauber: wird nach Push auf main geprüft

Offen / Risiken: keine
Annahmen / Abweichungen vom PRD: keine (FEEDBACK_R1_v0.1.md ist vorrangig umgesetzt)

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. CheckItemState als Enum mit TypeConverter in Drift abgebildet.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine TODOs oder leeren Handler.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Abnahmekriterien mit konkreten automatischen Tests belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Kein festes IBAN-Literal im Produktionscode vorhanden.
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten. Alle Cent-Beträge in int, epsilon bei Mengenberechnung.
- Regel 6 (Struktur): Eingehalten. Methoden kurz und modular, Dialoge strukturiert.
- Regel 7 (Tests): Eingehalten. Spezifische Widget- und Integrationstests mit echten Benutzerinteraktionen.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. FlutterSecureStorage, qr_flutter, IbanValidator genutzt.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Keine erfundenen Scans/Aktionen.
- Regel 10 (Nichts aus späteren Versionen sichtbar): Eingehalten.

Vorschläge für das PRD: keine
Commit: FB1-A: Fehler und Technik (gepusht: ja)

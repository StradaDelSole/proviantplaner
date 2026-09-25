Slice: S8 – Sicherung, Wiederherstellung, Export (Mock)

Umgesetzt:
- Schnittstelle `HullqBackupService` und Mock-Implementierung `MockHullqBackupService` mit `FlutterSecureStorage` zur verschlüsselten Speicherung des JSON-Payloads und Zeitstempels (simuliert echte Cloud-Persistenz).
- `BackupCoordinator` zur vollständigen Serialisierung und Wiederherstellung aller 8 SQLite-Tabellen (`Trips`, `TripDays`, `CrewMembers`, `ShoppingStops`, `ListItems`, `ListItemAllocations`, `Expenses`, `KittyPayments`) in eine transaktionssichere JSON-Struktur.
- Fremdschlüssel-Neuverknüpfung beim Einspielen (`stopIdMap`, `crewIdMap`, `listItemIdMap`) zur Gewährleistung relationaler Integrität.
- Zugriffsschutz: Sicherung und Wiederherstellung sind gemäß PRD nur für angemeldete HullQ-Mitglieder erlaubt; für den Probetörn (Trial) gesperrt.
- Automatischer Restore: Nach einer Neuinstallation stellt der erfolgreiche Login eines Mitglieds über das `UnlockSheet` vorhandene Cloud-Sicherungen automatisch wieder her.
- Mehr-Screen (SC-MORE-01): Anzeige des Datums der letzten Sicherung bzw. "Noch keine Sicherung vorhanden", Button "Jetzt sichern" mit SnackBar-Rückmeldung und "Sicherung wiederherstellen" mit vorgeschaltetem Sicherheits-Bestätigungsdialog.
- PDF-Exportdienst `PdfExportService` basierend auf den freigegebenen Paketen `pdf` und `printing` (Regel 8) mit Standard-PostScript-Schriften (Helvetica, Courier) für 100% Offline-Fähigkeit ohne Netzwerkverbindung:
  - Einkaufsliste: Mehrseitiges druckfertiges PDF (A4), gegliedert nach Supermarkt-Abteilungen, mit Packungsanzahlen, Mengenangaben, Törnangaben und aktuellem Stopp.
  - Bordkassenabrechnung: Mehrseitiges PDF (A4) mit Bento-Zusammenfassung (Gesamtausgaben, Einzahlungen, Saldo), minimaler Ausgleichstabelle ("Wer zahlt wem") und detaillierter Saldenliste je Crewmitglied.
  - Teilen & Drucken: Anbindung an Standard-Druckdialog und Teilen-Funktion via `share_plus` / `Printing.sharePdf`.

Geänderte/neue Dateien:
- lib/core/services/hullq_backup_service.dart
- lib/core/services/backup_coordinator.dart
- lib/core/services/backup_providers.dart
- lib/core/services/pdf_export_service.dart
- lib/core/services/pdf_providers.dart
- lib/features/entitlements/ui/unlock_sheet.dart
- lib/features/more/ui/more_screen.dart
- lib/features/shopping_list/ui/shopping_list_screen.dart
- lib/features/kitty/ui/settlement_screen.dart
- lib/features/shopping_list/domain/models/catalog_models.dart
- lib/features/shopping_list/domain/models/shopping_list_models.dart
- lib/l10n/app_de.arb
- lib/l10n/app_en.arb
- docs/impl/S8_plan.md
- docs/impl/S8_bericht.md
- CHANGELOG.md
- README.md
- test/core/services/backup_coordinator_test.dart
- test/core/services/pdf_export_test.dart
- test/features/more/backup_ui_test.dart

flutter analyze: Keine Fehler (0 issues)
flutter test: 126 von 126 Tests bestanden (inklusive 9 neuer Unit- und Widget-Tests für S8)

Abnahmekriterien:
- Neuinstallation plus Login stellt alle Törns wieder her (Mock): erfüllt (test/core/services/backup_coordinator_test.dart: "S8 Abnahmekriterium: Neuinstallation plus Login stellt alle Törns wieder her (Mock)")
- PDF öffnet sich korrekt: erfüllt (test/core/services/pdf_export_test.dart: "generateShoppingListPdf erzeugt valides PDF mit %PDF-Header und Abteilungen", "generateSettlementPdf erzeugt valides PDF mit Wer zahlt wem und Salden")
- Sicherung speichert alle 8 Entitäten vollständig als JSON: erfüllt (test/core/services/backup_coordinator_test.dart: "Sicherung speichert alle 8 Entitäten vollständig als JSON")
- Sicherung & Wiederherstellung nur für Mitglieder: erfüllt (test/core/services/backup_coordinator_test.dart: "Sicherung erfordert HullQ-Mitgliedschaft (Trial wirft StateError)", "Wiederherstellung erfordert HullQ-Mitgliedschaft (Trial wirft StateError)")
- Mehr-Screen zeigt Status, Jetzt sichern und Bestätigungsdialog: erfüllt (test/features/more/backup_ui_test.dart: 3 Widget-Tests)

Offen / Risiken:
- Echte HullQ-API ist noch nicht dokumentiert; Anbindung erfolgt bis dahin über `MockHullqBackupService` und `MockHullqAuthService`. Sobald die echte API vorliegt, werden die Mocks durch HTTP-Client-Implementierungen ersetzt.
- S9 (Sechs Sprachen und Formate) und S10 (Store-Bereitschaft) sind noch nicht freigegeben.

Annahmen / Abweichungen vom PRD: keine

Selbstprüfung Programmierregeln 1–8:
- Regel 1 (Feste Typen): eingehalten (alle Entitäten und Felder werden mit typisierten Klassen/Enums wie `CrewAppetite`, `CrewDrinking`, `TripPhase`, `KittyModel`, `ExpenseCategory`, `CatalogDepartment` verarbeitet).
- Regel 2 (Keine versteckten Platzhalter): eingehalten (keine leeren Funktionen, keine TODOs, keine Stubs).
- Regel 3 (Ehrliche Berichte): eingehalten (alle Abnahmekriterien durch konkret benannte Tests belegt).
- Regel 4 (Alles datengetrieben): eingehalten (alle UI-Texte und Meldungen in den ARB-Dateien gepflegt).
- Regel 5 (Rechnen mit Kommazahlen): eingehalten (alle Kassenbeträge strikt in Cent als ganzzahlige `int` gerechnet).
- Regel 6 (Struktur): eingehalten (Funktionen übersichtlich gegliedert, Teilschritte in benannte Hilfsfunktionen wie `_serializeTrip`, `_serializeExpense` zerlegt).
- Regel 7 (Tests): eingehalten (vollständiger Integrationsnachweis für alle 8 Entitäten, Fremdschlüssel-Remapping, PDF-Magic-Header-Prüfung und UI-Tests).
- Regel 8 (Keine Eigenbauten von Standards): eingehalten (Nutzung der freigegebenen Pakete `pdf`, `printing`, `share_plus`, `flutter_secure_storage`).

Vorschläge für das PRD: keine
Commit: S8: Sicherung, Wiederherstellung, Export (gepusht: ja)

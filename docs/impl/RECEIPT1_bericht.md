# Abschlussbericht RECEIPT1 – Expense Receipts & Settlement Package

Slice: RECEIPT1 – Expense Receipts & Settlement Package (Issue #23)  
Branch: `slice/receipt1-expense-receipts-settlement-package`  
Basis: `origin/main` (`7bc0e145657411d5b032e168d97958c85c31fc71`)  
Datum: 17.10.2026 (inkl. Independent Review Amendment 1, Amendment 2 & Final Integrity Amendment 3)

---

## Umgesetzt

1. **Drift-Datenbank-Schema v8 & Migration:**
   - Neue Tabelle `ExpenseReceipts` (`id`, `tripId`, `expenseId`, `filePath`, `fileName`, `sortOrder`, `byteSize`, `mimeType`, `createdAt`).
   - Fremdschlüsselverbindungen zu `Expenses` und `Trips` mit `onDelete: Cascade`.
   - MigrationStrategy von Schema-Version 7 auf Version 8 mit Erhalt aller bestehenden Daten und Verifikation des Kaskaden-Löschverhaltens.

2. **Lokaler Belegdateidienst & Bildoptimierung (`ReceiptFileService`):**
   - Vollständige Offline-Unterstützung: Speichern im Anwendungs-Dokumentenverzeichnis unter `receipts/trip_{tripId}/expense_{expenseId}/{fileName}`.
   - Bildkomprimierung und Skalierung auf maximal 1800 px Kantenlänge (`package:image`), EXIF-Baking/-Stripping und JPEG-Kodierung (Qualität 82%).
   - Kollisionsfreie interne Dateinamen (`rcpt_<timestamp>_<nonce>.jpg`) und Path-Traversal-Sanitizing (`sanitizeFileName`).
   - Keine still verschluckten Dateisystemfehler (`deleteReceiptFile`, `deleteExpenseReceiptFolder`, `deleteTripReceipts`, `purgeTrash` propagieren echte I/O-Fehler).
   - Zeitgestempelter Papierkorb (`.trashed_at` in `receipts_trash`) und automatisches Aufräumen verwaister temporärer Undo-Dateien nach Prozessabbruch (`cleanupExpiredTrash`).

3. **Zwei-Phasen-Staging, Post-Commit-Finalisierung & App-Start-Recovery für Backup-Restore (R1 + Amendment 3 Findings A & B):**
   - Da SQLite und das Dateisystem keine gemeinsame atomare Betriebssystem-Transaktion besitzen, trennt Provy den Restore-Ablauf strikt in drei Zustände mit kryptografisch/eindeutig gekoppeltem Commit-Nachweis (`restoreToken` in `restore_journal.json` sowie in der internen SQLite-Tabelle `_provy_restore_state` innerhalb derselben SQLite-Transaktion):
     1. **Pre-Flight-Validierung (vor jeder Änderung):** Prüft alle Belege im Backup auf gültige Zuordnung zu einer existierenden Ausgabe (`expenseId`), Übereinstimmung der `tripId`, gültiges Base64, exakte Übereinstimmung von `byteSize` mit den dekodierten Bytes sowie Dekodierbarkeit als unterstütztes Bildformat (`img.decodeImage`).
     2. **Noch nicht committet (`dbCommitted == false` innerhalb von `_db.transaction`):** Nach dem Schreiben der neuen Datensätze, dem Persistieren des `restoreToken` in `_provy_restore_state` und dem Schreiben der neuen Belegdateien in `receipts_staging_active/` wird `restore_journal.json` (`phase: "promoting"`, `restoreToken`, `previousReceiptPaths`, `expectedReceiptPaths`) geschrieben und `promoteStagedReceipts()` tauscht `receipts/` -> `receipts_rollback/` sowie `receipts_staging_active/` -> `receipts/`. Tritt vor oder während des SQLite-`COMMIT` ein Fehler auf, ist die Rückabwicklung (`abortRestoreStaging()`) zulässig und stellt `receipts_rollback/` vollständig nach `receipts/` wieder her.
     3. **Erfolgreich committet (`dbCommitted == true` nach Abschluss von `_db.transaction` – Finding A):** Sobald die SQLite-Transaktion committet ist, wird **niemals** mehr `abortRestoreStaging()` aufgerufen (keine Reaktivierung alter Dateien nach DB-Commit). Ab diesem Punkt ist ausschließlich **Roll-Forward** bzw. die sichere, idempotente und wiederholbare Finalisierung (`finalizeRestoreStaging()`) zulässig. Wirft `finalizeRestoreStaging()` einen I/O-Fehler, bleibt der neue Datenbankstand samt allen neuen Bilddateien in `receipts/` unangetastet erhalten; die verbleibenden Rollback-/Journal-Artefakte werden beim nächsten Recovery-Lauf per Roll-Forward bereinigt.
     4. **App-Start-Recovery & Unklarer Zustand nach Crash (`appStartupRecoveryProvider` / `BackupCoordinator.recoverStorageState` – Finding B):**
        - `appStartupRecoveryProvider` ist in den produktiven Initialisierungs- und Datenpfad (`ProviantplanerApp`, `allTripsProvider`, `activeBoatProfilesProvider`, `tripByIdProvider`, `tripDaysByIdProvider`, `tripStopsByIdProvider`, `tripCrewByIdProvider` sowie via Single-Flight-Guard `_ensureStorageRecovered()` in `KittyService` und `TripService`) eingebunden und wird pro `ReceiptFileService`-Instanz genau einmal initial ausgeführt, bevor betroffene Daten gelesen oder geändert werden.
        - **Eindeutiger Post-Commit-Nachweis:** Stimmt das in SQLite committete `_provy_restore_state.restore_token` mit `restore_journal.json` überein (oder ist der DB-Bestand deckungsgleich mit `expectedReceiptPaths` bei Phase `committed`) und liegen alle erwarteten neuen Belegdateien in `receipts/`, führt Recovery deterministisch **Roll-Forward** (`finalizeRestoreStaging()`) aus.
        - **Eindeutiger Pre-Commit-Nachweis:** Wurde die SQLite-Transaktion vor dem Commit abgebrochen (`dbRestoreToken != journalToken`, `phase != 'committed'`, DB-Bestand deckungsgleich mit `previousReceiptPaths` und vollständiges `receipts_rollback/`), führt Recovery deterministisch **Roll-Back** (`abortRestoreStaging()`) aus.
        - **Unklarer / widersprüchlicher Zustand nach Crash:** Fehlt bei vorhandenen Rollback-Artefakten ein lesbares Journal oder widersprechen sich DB-Token und vorhandene physische Dateien, wird **niemals blind zurückgerollt** und **keine destruktive Operation** ausgeführt; stattdessen wird explizit `RestoreRecoveryException` geworfen.

4. **Bordkassen- & Attachment-Lifecycle (`KittyService`, `TripService`, R2 + Amendment 3 Findings C & D):**
   - `addReceiptToExpense`: Scheitert das DB-Insert (`expenseDao.addReceipt`), wird die zuvor geschriebene Bilddatei sofort wieder gelöscht, sodass keine verwaiste Datei entsteht.
   - `deleteReceipt` (**Finding D**):
     - Prüft den `bool`-Rückgabewert von `receiptFileService.deleteReceiptFile(receipt.filePath)`.
     - **Explizit dokumentierte Architekturentscheidung für defekte Beleg-Referenzen:** Fehlt die physische Datei eines in der Datenbank registrierten Belegs (`fileDeleted == false`), wird im regulären Löschpfad **keine** normale vollständige Löschung gemeldet, sondern explizit `ReceiptFileMissingOnDeleteException` geworfen (der DB-Eintrag bleibt für Diagnose/Recovery erhalten). Für eine gezielte Bereinigung bereits bekannter verwaister Referenzen steht der explizite Parameter `allowBrokenReferenceCleanup: true` zur Verfügung.
     - Scheitert das anschließende DB-Delete (`expenseDao.deleteReceipt` wirft oder gibt `<= 0` zurück), wird die zuvor gelöschte physische Datei aus dem Arbeitsspeicher-Backup (`writeReceiptBytesAtPath`) byte-genau wiederhergestellt.
   - `deleteExpense` & `restoreExpense`: Transaktionale und dateisystemseitige Rollbacks bei I/O- oder DB-Fehlern; automatisches Aufräumen abgelaufener Papierkorb-Einträge (`cleanupExpiredTrash`) nach App-Crash.
   - `TripService.deleteTrip` (**Finding C**):
     - Löscht die letzte wiederherstellbare Kopie der Törn-Belege **nicht** vor dem DB-Commit: Vor der DB-Transaktion hält `stageTripDeleteRollback(tripId)` die Belege in `receipts_trip_rollback/trip_<id>` zurück (bei Fehler vor DB-Commit sofortiger Rollback via `restoreTripDeleteRollback`).
     - Erst **nach** erfolgreichem DB-Commit (`_db.transaction`) entfernt `finalizeTripDeleteRollback(tripId)` die zurückgehaltenen Dateien endgültig.
     - Schlägt diese nachgelagerte Bereinigung nach erfolgreichem DB-Commit fehl, werden die Dateien des bereits gelöschten Törns **nicht** wieder in `receipts/` reaktiviert und es wird **kein** DB-Rollback vorgetäuscht; stattdessen wirft `deleteTrip` explizit `TripDeleteCleanupException(tripId: tripId, tripDeletedInDb: true, cause: e)`.
     - Nach einem Prozessabbruch während `deleteTrip` gleicht `BackupCoordinator.recoverStorageState` beim nächsten App-Start `receipts_trip_rollback/trip_<id>` gegen SQLite ab: Existiert der Törn noch in der DB (Crash vor DB-Commit), werden die Belege via `restoreTripDeleteRollback` wiederhergestellt; ist der Törn bereits gelöscht (Crash nach DB-Commit), wird `receipts_trip_rollback/trip_<id>` via `finalizeTripDeleteRollback` final bereinigt.
   - Finanzmathematische Invarianz: Belegfotos verändern den FIX-B Ledger, Salden, Anteile oder Ausgleichszahlungen in keiner Weise.

5. **Multi-File PDF-Abrechnungspaket & PDF-Splitting (`PdfExportService`, R4):**
   - `generateReceiptsPdfs`: Überwacht sowohl das Rohbild-Chunk-Limit (`maxBytesPerChunk`) als auch das 15-MB-Limit (`maxPdfBytes`) gegen die **tatsächlich erzeugten PDF-Bytes** (`doc.save()`).
   - Überschreitet ein gerenderter PDF-Chunk mit mehreren Belegen `maxPdfBytes`, wird er automatisch per binärer Präfixsuche in kleinere Chunks (`Belege_1.pdf`, `Belege_2.pdf`, ...) aufgeteilt, die jeweils `<= maxPdfBytes` sind – ohne fehlende oder doppelte Seiten.
   - Ein einzelner, nicht weiter teilbarer Beleg, dessen 1-Seiten-PDF allein `maxPdfBytes` überschreitet, schlägt weiterhin explizit mit `PdfChunkOversizedException` bzw. `PdfReceiptOversizedException` fehl.
   - Temporäre Exportdateien (`settlement_export_*`): `prepareSettlementExportDirectory` und `cleanupTemporaryExportDirectories` räumen frühere temporäre Export-Ordner deterministisch auf, während die Dateien des aktuellen Share-Vorgangs für das native OS-Share-Sheet (`Share.shareXFiles`) verfügbar bleiben.

6. **Cloud-Datensicherung Version 3 (`BackupCoordinator`, R3):**
   - Backup-Format `version: 3` mit Base64-Serialisierung und strenger Integritätsprüfung (`byteSize`-Abgleich, Bilddekodierbarkeit, `expenseId`-Existenz).
   - Beim Restore ist jede fehlende oder nicht zuordenbare `expenseId`, jede Abweichung von `byteSize` und jeder nicht als Bild dekodierbare Base64-Inhalt ein harter Integritätsfehler (`BackupCorruptException`) – kein Beleg wird still übersprungen.

7. **UI, UX & Lokalisierung:**
   - `ExpenseSheet`, `ReceiptPreviewDialog`, `KittyScreen`, `SettlementScreen`.
   - Alle Lokalisierungs-Keys synchron in allen 6 unterstützten Sprachen (`app_de.arb`, `app_en.arb`, `app_es.arb`, `app_fr.arb`, `app_hr.arb`, `app_pt.arb`).

---

## Geänderte / neue Dateien

- `docs/impl/RECEIPT1_release_reconciliation_2026-10-17.md`
- `docs/impl/RECEIPT1_bericht.md`
- `lib/main.dart`
- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/daos.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/daos.g.dart`
- `lib/core/services/receipt_file_service.dart`
- `lib/core/services/pdf_export_service.dart`
- `lib/core/services/backup_coordinator.dart`
- `lib/core/services/backup_providers.dart`
- `lib/features/kitty/domain/models/receipt_models.dart`
- `lib/features/kitty/domain/models/kitty_models.dart`
- `lib/features/kitty/data/kitty_service.dart`
- `lib/features/kitty/data/kitty_providers.dart`
- `lib/features/kitty/ui/widgets/receipt_preview_dialog.dart`
- `lib/features/kitty/ui/widgets/expense_sheet.dart`
- `lib/features/kitty/ui/kitty_screen.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/trip/data/trip_service.dart`
- `lib/features/trip/data/trip_provider.dart`
- `lib/l10n/app_de.arb`, `app_en.arb`, `app_es.arb`, `app_fr.arb`, `app_hr.arb`, `app_pt.arb`
- `pubspec.yaml`, `pubspec.lock`
- `test/core/database/migration_test.dart`
- `test/core/services/receipt_file_service_test.dart`
- `test/features/kitty/receipt_attachment_lifecycle_test.dart`
- `test/core/services/pdf_receipts_package_test.dart`
- `test/core/services/backup_coordinator_test.dart`
- `test/core/services/backup_coordinator_v3_test.dart`
- `README.md`
- `CHANGELOG.md`

---

## flutter analyze
`No issues found!`

---

## flutter test
Gezielt ausgeführte Tests für RECEIPT1 (inkl. Amendment 1, Amendment 2 & Final Integrity Amendment 3):
- `test/core/database/migration_test.dart`: 4 Tests – alle bestanden.
- `test/core/services/receipt_file_service_test.dart`: 10 Tests – alle bestanden.
- `test/core/services/pdf_receipts_package_test.dart`: 10 Tests (inkl. R4: automatisches PDF-Splitting anhand realer PDF-Bytegröße ohne fehlende/doppelte Seiten, Bereinigung temporärer Export-Verzeichnisse) – alle bestanden.
- `test/core/services/backup_coordinator_test.dart`: 16 Tests (inkl. R1, R3 sowie Amendment 3 Pflichttest A: Fehler-Injektion in `finalizeRestoreStaging` nach erfolgreichem SQLite-Commit erhält neuen DB-Stand + neue Bilddateien und bereinigt Rest-Artefakte bei nachfolgender Recovery; Amendment 3 Finding A & B: einmalige App-Start-Recovery über `appStartupRecoveryProvider`, Pre-/Post-Commit-Crash-Auflösung und Blockieren unklarer Crash-Zustände via `RestoreRecoveryException` ohne destruktive Operation) – alle bestanden.
- `test/features/kitty/receipt_attachment_lifecycle_test.dart`: 15 Tests (inkl. R2 sowie Amendment 3 Finding C: `TripService.deleteTrip` hält Belege vor DB-Commit zurück, meldet Post-Commit-Cleanup-Fehler als `TripDeleteCleanupException` und löst Crash vor/nach DB-Commit via Startup-Recovery auf; Amendment 3 Finding D: `KittyService.deleteReceipt` prüft `deleteReceiptFile`-Rückgabewert, wirft `ReceiptFileMissingOnDeleteException` bei fehlender physischer Datei, stellt Datei bei DB-Delete `== 0` wieder her und unterstützt explizites `allowBrokenReferenceCleanup: true`) – alle bestanden.
- `test/core/services/backup_coordinator_v3_test.dart`: 3 Tests – alle bestanden.

Gesamt: 58 gezielte Tests für RECEIPT1, Amendment 1, Amendment 2 und Amendment 3 erfolgreich ausgeführt. Vollständige Testsuite läuft über die authoritative GitHub Actions CI Pipeline auf PR #34.

---

## Abnahmekriterien & Review Findings (Amendment 1, Amendment 2 & Amendment 3)

| Kriterium / Finding | Status | Nachweis |
|---|---|---|
| 1. Drift-Schema v8 & Migration: `ExpenseReceipts`-Tabelle mit Foreign Keys und Cascade-Delete | erfüllt | automatischer Test (`test/core/database/migration_test.dart`: `RECEIPT1 Abnahmekriterium: Reale Migration v7 -> v8 mit Datenintegrität und Foreign-Keys`) |
| 2. Foto-Erfassung & Belegverwaltung (0..n Belege pro Ausgabe) im ExpenseSheet | erfüllt (Daten/Logik) | automatischer Test (`test/features/kitty/receipt_attachment_lifecycle_test.dart`: `RECEIPT1: Expense creation with draft receipts persists files and DB records`, `RECEIPT1: Adding additional receipt page and deleting a single receipt`, `RECEIPT1: Expense delete and restore preserves receipts`) |
| 2a. Echter Hardware-Kamerazugriff und Bildauswahl auf physischem Endgerät | offen – wartet auf manuellen Test durch den Menschen | manueller Test durch Mensch: Auf echtem Smartphone im Ausgaben-Sheet auf Kamera tippen, Beleg fotografieren; alternativ auf Galerie tippen und vorhandenes Foto wählen; Miniaturvorschau im Belegstreifen prüfen. |
| 3. Offline-Bildoptimierung (Resize max 1800 px, EXIF-Strip, JPEG 82%) & Dateisystem-Management | erfüllt | automatischer Test (`test/core/services/receipt_file_service_test.dart`) |
| 4. Finanzmathematische Invarianz & FIX-B Unified Ledger | erfüllt | automatischer Test (`test/features/kitty/receipt_attachment_lifecycle_test.dart`: `RECEIPT1: Financial settlement invariance - receipts do not alter FIX-B unified ledger`) |
| 5. Mehrteiliges PDF-Exportpaket (`Abrechnung.pdf` + `Belege.pdf`) & automatisches Splitting bei Überschreitung des Chunk-/PDF-Limits | erfüllt | automatischer Test (`test/core/services/pdf_receipts_package_test.dart`: `RECEIPT1: generateReceiptsPdfs splits into Belege_1.pdf and Belege_2.pdf when chunk limit is exceeded`, `R4: generateReceiptsPdfs teilt einen Multi-Beleg-Chunk automatisch anhand der tatsächlichen PDF-Bytegröße (maxPdfBytes) ohne fehlende oder doppelte Seiten auf`) |
| 6. Nativer Teilen-/Mail-Versand (`share_plus`) & Temp-Cleanup | erfüllt (Paketbereitstellung & Bereinigung) | automatischer Test (`test/core/services/pdf_receipts_package_test.dart`: `RECEIPT1: generateSettlementPackage creates Abrechnung.pdf and Belege.pdf package`, `R4: prepareSettlementExportDirectory bereinigt frühere temporäre settlement_export_* Verzeichnisse zuverlässig`) |
| 6a. Öffnen des nativen Betriebssystem-Share-Sheets auf Mobilgerät | offen – wartet auf manuellen Test durch den Menschen | manueller Test durch Mensch: Im Endabrechnungs-Screen auf „Abrechnungspaket versenden“ tippen; sicherstellen, dass das native Android-/iOS-Share-Sheet mit `Abrechnung.pdf` und `Belege.pdf` erscheint und in Mail-App übergeben werden kann. |
| 7. Cloud-Datensicherung Version 3 mit Base64-Belegbildern & relationaler Wiederherstellung inkl. Abwärtskompatibilität v1/v2 | erfüllt | automatischer Test (`test/core/services/backup_coordinator_v3_test.dart`) |
| 8. Vollständige Lokalisierung (DE, EN, FR, ES, PT, HR) | erfüllt | automatischer Test (`flutter analyze`: 0 Issues; alle Keys in `app_de.arb`, `app_en.arb`, `app_es.arb`, `app_fr.arb`, `app_hr.arb`, `app_pt.arb` synchron vorhanden) |
| **Finding A–G (Amendment 1)** | erfüllt | automatische Tests in `backup_coordinator_test.dart`, `pdf_receipts_package_test.dart`, `receipt_file_service_test.dart`, `receipt_attachment_lifecycle_test.dart` |
| **R1–R4 (Amendment 2)** | erfüllt | automatische Tests in `backup_coordinator_test.dart`, `receipt_attachment_lifecycle_test.dart`, `pdf_receipts_package_test.dart` |
| **Amendment 3 – A (BLOCKER: Post-Commit-Finalisierung):** Nach erfolgreichem SQLite-Commit niemals alte Dateien reaktivieren; strikte Trennung Pre-Commit / Post-Commit Roll-Forward / Crash-Recovery mit Commit-Nachweis | erfüllt | automatischer Test (`test/core/services/backup_coordinator_test.dart`: `Amendment 3 – Pflichttest A: finalizeRestoreStaging wirft nach erfolgreichem SQLite-Commit eine Exception -> neuer DB-Stand und alle neuen Bilddateien bleiben erhalten, spätere Recovery bereinigt Rest-Artefakte`) |
| **Amendment 3 – B (HIGH: Recovery beim App-Start):** Einmalige produktive App-Initialisierung (`appStartupRecoveryProvider`) vor Datenzugriff; Pre-/Post-Commit-Crash-Auflösung und nicht-destruktive Blockierung (`RestoreRecoveryException`) bei unklarem Zustand | erfüllt | automatischer Test (`test/core/services/backup_coordinator_test.dart`: `Amendment 3 – Finding A & B: App-Start-Recovery über appStartupRecoveryProvider ist einmalig, löst Pre-/Post-Commit-Crash auf und blockiert unklare Zustände ohne destruktive Operation`) |
| **Amendment 3 – C (HIGH: Trip-Delete):** Letzte wiederherstellbare Belegkopie erst nach DB-Commit löschen; Post-Commit-Cleanup-Fehler als `TripDeleteCleanupException` ohne vorgetäuschten DB-Rollback; Crash-/Restart-Recovery vor/nach DB-Commit | erfüllt | automatischer Test (`test/features/kitty/receipt_attachment_lifecycle_test.dart`: `R2 & Amendment 3 – Finding C: TripService.deleteTrip löscht letzte Belegkopie erst nach DB-Commit, meldet Post-Commit-Cleanup-Fehler als TripDeleteCleanupException und löst Crash vor/nach DB-Commit sauber auf`) |
| **Amendment 3 – D (HIGH: Einzelbeleg-Löschung):** Prüfung des bool-Rückgabewerts von `deleteReceiptFile`; `ReceiptFileMissingOnDeleteException` bei fehlender physischer Datei; Datei-Wiederherstellung bei DB-Delete `== 0`; expliziter Cleanup-Pfad `allowBrokenReferenceCleanup: true` | erfüllt | automatischer Test (`test/features/kitty/receipt_attachment_lifecycle_test.dart`: `Amendment 3 – Finding D: Einzelbeleg-Löschung prüft Rückgabewert von deleteReceiptFile, meldet fehlende physische Datei als ReceiptFileMissingOnDeleteException und erlaubt explizite Bereinigung defekter Referenzen`) |

---

## Offen / Risiken

- **Offen – wartet auf manuellen Test durch den Menschen:**
  - Manueller Kameratest: Ausgaben-Sheet öffnen, Belegfoto per nativer Kamera aufnehmen, Zuschneiden/Orientierung prüfen.
  - Manueller Share-Test: Auf `SettlementScreen` auf „Abrechnungspaket versenden“ tippen, Versand über lokale Mail-App verifizieren.
- Keine offenen Risiken für den produktiven Betrieb; der finanzielle Kern-Ledger bleibt unverändert.

---

## Annahmen / Abweichungen vom PRD

- Keine. Sämtliche Vorgaben aus `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`, `docs/impl/RECEIPT1_plan.md`, Amendment 1 (Findings A–G), Amendment 2 (R1–R4) und Final Integrity Amendment 3 (Findings A–D) wurden vollständig umgesetzt.
- **Begründung zur Test-Erweiterung gemäß Programmierregel 7:** Der in Amendment 2 angelegte Test `R2: TripService.deleteTrip...` in `test/features/kitty/receipt_attachment_lifecycle_test.dart` hatte einen `deleteTripReceipts`-Fehler noch innerhalb der DB-Transaktion erwartet. Da Finding C in Amendment 3 vorschreibt, dass die endgültige Dateilöschung (`finalizeTripDeleteRollback` / `deleteTripReceipts`) erst **nach** erfolgreichem DB-Commit erfolgen darf und Post-Commit-Cleanup-Fehler keinen DB-Rollback vortäuschen dürfen, prüft der aktualisierte Test `R2 & Amendment 3 – Finding C` nun sowohl den Pre-Commit-Fehler (`stageTripDeleteRollback` mit vollständigem DB- und Datei-Erhalt), den Crash vor/nach DB-Commit als auch den Post-Commit-Cleanup-Fehler (`deleteTripReceipts` -> `TripDeleteCleanupException(tripDeletedInDb: true)`).

---

## Selbstprüfung Programmierregeln 1–10

1. **Feste Typen statt freier Texte:** Eingehalten.
2. **Keine versteckten Platzhalter:** Eingehalten.
3. **Ehrliche Berichte:** Eingehalten.
4. **Alles datengetrieben:** Eingehalten.
5. **Rechnen mit Kommazahlen:** Eingehalten.
6. **Struktur:** Eingehalten.
7. **Tests:** Eingehalten (inkl. dokumentierter Begründung der Test-Erweiterung für Finding C).
8. **Keine Eigenbauten von Standards:** Eingehalten.
9. **Nur berichten, was tatsächlich geschehen ist:** Eingehalten.
10. **Nichts aus späteren Versionen sichtbar bauen:** Eingehalten.

---

## Vorschläge für das PRD

- Keine.

---

## Commit & PR

- Branch: `slice/receipt1-expense-receipts-settlement-package`
- PR: #34
- Amendment 3 Commit: `RECEIPT1: Address final integrity amendment 3 (A-D post-commit finalization, startup recovery, trip & receipt delete)`

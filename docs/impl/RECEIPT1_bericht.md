# Abschlussbericht RECEIPT1 – Expense Receipts & Settlement Package

Slice: RECEIPT1 – Expense Receipts & Settlement Package (Issue #23)  
Branch: `slice/receipt1-expense-receipts-settlement-package`  
Basis: `origin/main` (`7bc0e145657411d5b032e168d97958c85c31fc71`)  
Datum: 17.10.2026 (inkl. Independent Review Amendment 1, Amendment 2, Final Integrity Amendment 3, Final Recovery Gate Amendment 4 & Concurrency Integrity Amendment 5)

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

3. **Zwei-Phasen-Staging, Post-Commit-Finalisierung, Vor-Journal-Recovery & Verbindliches App-Start-Gate (R1 + Amendment 3 Findings A & B + Amendment 4 Findings E & F):**
   - Da SQLite und das Dateisystem keine gemeinsame atomare Betriebssystem-Transaktion besitzen, trennt Provy den Restore-Ablauf strikt mit eindeutigem Commit-Nachweis (`restoreToken` in `restore_journal.json` sowie in der internen SQLite-Tabelle `_provy_restore_state` innerhalb derselben SQLite-Transaktion):
     1. **Pre-Flight-Validierung (vor jeder Änderung):** Prüft alle Belege im Backup auf gültige Zuordnung zu einer existierenden Ausgabe (`expenseId`), Übereinstimmung der `tripId`, gültiges Base64, exakte Übereinstimmung von `byteSize` mit den dekodierten Bytes sowie Dekodierbarkeit als unterstütztes Bildformat (`img.decodeImage`).
     2. **Noch nicht committet (`dbCommitted == false` innerhalb von `_db.transaction`):** Nach dem Schreiben der neuen Datensätze, dem Persistieren des `restoreToken` in `_provy_restore_state` und dem Schreiben der neuen Belegdateien in `receipts_staging_active/` wird `restore_journal.json` (`phase: "promoting"`, `restoreToken`, `previousReceiptPaths`, `expectedReceiptPaths`) geschrieben und `promoteStagedReceipts()` tauscht `receipts/` -> `receipts_rollback/` sowie `receipts_staging_active/` -> `receipts/`. Tritt vor oder während des SQLite-`COMMIT` ein Fehler auf, ist die Rückabwicklung (`abortRestoreStaging()`) zulässig und stellt `receipts_rollback/` vollständig nach `receipts/` wieder her.
     3. **Erfolgreich committet (`dbCommitted == true` nach Abschluss von `_db.transaction` – Finding A):** Sobald die SQLite-Transaktion committet ist, wird **niemals** mehr `abortRestoreStaging()` aufgerufen (keine Reaktivierung alter Dateien nach DB-Commit). Ab diesem Punkt ist ausschließlich **Roll-Forward** bzw. die sichere, idempotente und wiederholbare Finalisierung (`finalizeRestoreStaging()`) zulässig. Dabei wird `restore_journal.json` stets als allerletzter Schritt nach `receipts_rollback/` und den Staging-Ordnern entfernt.
     4. **Crash vor Journal-Erstellung (`receipts_staging_active/` ohne Journal und ohne Rollback – Amendment 4 Finding E):**
        - Bricht der Prozess nach dem Anlegen/Füllen von `receipts_staging_active/` (bzw. `receipts_staging/`), aber **vor** `writeRestoreJournal()` und **vor** `promoteStagedReceipts()` ab, hinterlässt dies ausschließlich ein Staging-Artefakt (`!hasJournal && !hasRollback`).
        - `BackupCoordinator.recoverStorageState` unterscheidet diesen Staging-Only-Zustand gezielt von einem unklaren Restore-Zustand: Bevor `cleanPreJournalStagingArtifacts()` ausgeführt wird, prüft Recovery für sämtliche in SQLite registrierten Belege (`expense_receipts`), dass kein Pfad auf ein Staging-/Rollback-Verzeichnis verweist und jede produktive Belegdatei physisch und in erwarteter Dateigröße in `receipts/` vorhanden ist. Fehlt auch nur eine produktive Datei, wird nichts gelöscht und `RestoreRecoveryException` geworfen. Sind alle produktiven Dateien intakt, werden die verwaisten Staging-Artefakte sicher und wiederholbar bereinigt.
     5. **Verbindliches App-Start-Gate & Reconciliierte Lese-/Schreibpfade (`ProviantplanerApp`, `appStartupRecoveryProvider` – Amendment 3 Finding B & Amendment 4 Finding F):**
        - `ProviantplanerApp.build()` fungiert als zentrales Bootstrap-/Recovery-Gate: Solange `appStartupRecoveryProvider` lädt (`loading`), wird `appRouterProvider` **nicht** aufgebaut und stattdessen `AppStartupRecoveryLoadingScreen` (`Key('app_startup_recovery_loading')`) angezeigt.
        - Schlägt die Recovery mit `RestoreRecoveryException` (oder einem sonstigen Fehler) fehl (`error`), zeigt `ProviantplanerApp` den nicht-destruktiven Fehlerzustand `AppStartupRecoveryErrorScreen` (`Key('app_startup_recovery_error')`) mit Diagnosehinweis und Retry-Button (`Key('app_startup_recovery_retry_button')`) an – ohne automatische Neuinitialisierung oder Datenbank-/Dateilöschung.
        - Erst nach erfolgreicher Recovery (`data`) wird `appRouterProvider` aufgebaut und die normale Anwendung geöffnet.
        - Zusätzlich sind sämtliche Lese- und Schreibpfade in `TripService`, `ShoppingListService`, `KittyService`, `BoatProfileService` und `BackupCoordinator` über denselben zentralen Single-Flight-Recovery-Gate (`BackupCoordinator.recoverStorageState` / `ReceiptFileService.runSingleFlightRecovery`) abgesichert, sodass vor erfolgreichem Abschluss der Recovery keine betroffenen Datenmutationen möglich sind.
     6. **Gemeinsame Operationskoordination für Restore, Recovery, `deleteTrip` und konkurrierende Service-Operationen (`StorageOperationCoordinator` – Amendment 5 Finding G):**
        - `StorageOperationCoordinator` (FIFO-Queue mit direktem Lock-Handoff zwischen Waitern und Zone-basierter Re-Entrancy) koordiniert `restoreBackup()`, `createBackup()`, `recoverStorageState()`, `TripService.deleteTrip()` sowie alle geschützten Lese- und Schreiboperationen in `TripService`, `ShoppingListService`, `KittyService`, `BoatProfileService` und den zugehörigen Riverpod-Providern über `BackupCoordinator.runSynchronizedStorageOperation`.
        - Während eines aktiven `restoreBackup()` hält der Restore den exklusiven Lock über seine gesamte Laufzeit (Vorprüfung, Staging in `receipts_staging_active/`, Journal-Schreiben, SQLite-Transaktion mit Dateipromotion sowie Post-Commit-Finalisierung bzw. Pre-Commit-Rollback). Konkurrierende Lese-, Schreib- oder Recovery-Aufrufe reihen sich in die FIFO-Warteschlange ein und können weder aktive Staging-/Rollback-Dateien als vermeintlichen Crash bereinigen noch auf einem teilweise ersetzten Datenbestand lesen oder schreiben.
        - Ebenso hält `TripService.deleteTrip()` denselben Coordinator-Lock über `stageTripDeleteRollback`, die SQLite-Löschtransaktion und `finalizeTripDeleteRollback` / `restoreTripDeleteRollback`, sodass ein paralleler Recovery- oder Restore-Aufruf `receipts_trip_rollback/trip_<id>` nicht während einer laufenden Löschtransaktion fehlinterpretiert.
        - Verschachtelte Service-Aufrufe innerhalb derselben aktiven Operation (z. B. `restoreBackup()` -> `recoverStorageState()`, `addCrewMember()` -> `recalculateTrip()`, `deleteCrewMemberSafely()` -> `hasFinancialHistory()` + `recalculateTrip()`, `handleUnboughtItems()` -> `loadShoppingList()`) erkennen über das Zone-Token (`isInActiveOperationZone`) ihre Zugehörigkeit zur laufenden Top-Level-Operation und laufen deadlock-frei ohne erneuten Lock-Erwerb; externe Hooks (`onBeforeOperationAsync`, `onBeforeRecoveryHook`) und Invalidierungs-Callbacks (`onTripDataChanged`) werden hingegen außerhalb der Re-Entrancy-Zone ausgeführt, sodass daraus angestoßene konkurrierende Operationen regulär auf die Freigabe des Locks warten.
        - Nach erfolgreichem Restore sehen wartende Operationen den neuen konsistenten Zustand; nach fehlgeschlagenem Restore oder `deleteTrip` wird der Lock im `try/finally` garantiert freigegeben und wartende Operationen arbeiten auf dem intakten Vorzustand weiter.

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
   - `ExpenseSheet`, `ReceiptPreviewDialog`, `KittyScreen`, `SettlementScreen`, `AppStartupRecoveryLoadingScreen`, `AppStartupRecoveryErrorScreen`.
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
- `lib/features/shopping_list/data/shopping_list_service.dart`
- `lib/features/shopping_list/data/shopping_list_providers.dart`
- `lib/features/trip/data/boat_profile_service.dart`
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
Gezielt ausgeführte Tests für RECEIPT1 (inkl. Amendment 1, Amendment 2, Amendment 3, Amendment 4 & Amendment 5):
- `test/core/database/migration_test.dart`: 4 Tests – alle bestanden.
- `test/core/services/receipt_file_service_test.dart`: 10 Tests – alle bestanden.
- `test/core/services/pdf_receipts_package_test.dart`: 10 Tests – alle bestanden.
- `test/core/services/backup_coordinator_test.dart`: 22 Tests (inkl. R1, R3, Amendment 3 Findings A & B, Amendment 4 Findings E & F sowie Amendment 5 Finding G: Regression 1–4 paralleler Restore vor `writeRestoreJournal()` vs. konkurrierende Lese-/Schreib-/Recovery-Aufrufe bei Erfolg, Regression 5 paralleler Restore mit injiziertem Fehler inkl. Rollback und Lock-Freigabe, Regression 6 & 7 Konflikt zwischen `TripService.deleteTrip()` und Restore/Recovery sowie Deadlock-Freiheit bei verschachtelten Service-Aufrufen) – alle bestanden.
- `test/features/kitty/receipt_attachment_lifecycle_test.dart`: 15 Tests (inkl. R2 sowie Amendment 3 Findings C & D) – alle bestanden.
- `test/core/services/backup_coordinator_v3_test.dart`: 3 Tests – alle bestanden.
- `test/widget_test.dart`: 2 Tests – alle bestanden.

Gesamt: 66 gezielte Tests für RECEIPT1 und Amendments 1–5 erfolgreich ausgeführt. Vollständige Testsuite läuft über die authoritative GitHub Actions CI Pipeline auf PR #34.

---

## Abnahmekriterien & Review Findings (Amendments 1–5)

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
| **Amendment 3 – A–D** | erfüllt | automatische Tests in `backup_coordinator_test.dart` und `receipt_attachment_lifecycle_test.dart` |
| **Amendment 4 – E (HIGH: Crash vor Journal-Erstellung):** Sichere, wiederholbare automatische Bereinigung von Vor-Journal-Staging-Artefakten (`receipts_staging_active/` ohne Journal und ohne Rollback) nach Prüfung produktiver DB-/Datei-Integrität | erfüllt | automatischer Test (`test/core/services/backup_coordinator_test.dart`: `Amendment 4 – Finding E: Crash nach Anlegen von receipts_staging_active vor writeRestoreJournal wird beim App-Neustart sicher, wiederholbar und ohne Gefährdung produktiver Daten bereinigt`) |
| **Amendment 4 – F (HIGH: Verbindliches App-Start-Gate):** Zentrales Bootstrap-/Recovery-Gate in `ProviantplanerApp.build()` mit Initialisierungszustand (`AppStartupRecoveryLoadingScreen`), nicht-destruktivem Fehlerzustand (`AppStartupRecoveryErrorScreen`) und Blockierung vorzeitiger Mutationen | erfüllt | automatische Tests (`test/core/services/backup_coordinator_test.dart`: `Amendment 4 – Finding F (Verzögerte Recovery): ProviantplanerApp zeigt während laufender Recovery den Initialisierungszustand, baut den Router erst danach auf und blockiert vorzeitige Datenmutationen`, `Amendment 4 – Finding F (Nicht auflösbarer Recovery-Fehler): ProviantplanerApp zeigt bei RestoreRecoveryException den nicht-destruktiven Fehlerzustand, löscht keine Daten und blockiert Mutationen bis zur Behebung`) |
| **Amendment 5 – G (BLOCKER: Paralleler Restore vs. Recovery & konkurrierende Datenoperationen):** Gemeinsame, kontrollierte Operationskoordination (`StorageOperationCoordinator`) für `restoreBackup()`, `recoverStorageState()`, `TripService.deleteTrip()` und konkurrierende Service-Operationen ohne Löschung aktiver Staging-/Rollback-Dateien und ohne Deadlocks | erfüllt | automatische Tests (`test/core/services/backup_coordinator_test.dart`: `Amendment 5 – Finding G (Regression 1–4 – Paralleler Restore vs. Lese-/Schreibzugriff & Recovery bei Erfolg): Laufender Restore vor writeRestoreJournal() wird durch parallele Recovery-/Service-Aufrufe nicht als Crash fehlinterpretiert`, `Amendment 5 – Finding G (Regression 5 – Paralleler Restore mit injiziertem Fehler): Wartende Lese-/Schreiboperationen löschen kein Staging, Lock wird bei Fehler freigegeben und Operationen arbeiten auf intaktem Vorzustand weiter`, `Amendment 5 – Finding G (Regression 6 & 7 – deleteTrip-Konflikt mit Restore/Recovery sowie Deadlock-Freiheit und Lock-Freigabe): Aktiver deleteTrip und aktiver Restore serialisieren sauber ohne Verlust von Rollback-/Staging-Dateien und ohne Deadlock`) |

---

## Offen / Risiken

- **Offen – wartet auf manuellen Test durch den Menschen:**
  - Manueller Kameratest: Ausgaben-Sheet öffnen, Belegfoto per nativer Kamera aufnehmen, Zuschneiden/Orientierung prüfen.
  - Manueller Share-Test: Auf `SettlementScreen` auf „Abrechnungspaket versenden“ tippen, Versand über lokale Mail-App verifizieren.
- Keine offenen Risiken für den produktiven Betrieb; der finanzielle Kern-Ledger bleibt unverändert.

---

## Annahmen / Abweichungen vom PRD

- Keine. Sämtliche Vorgaben aus `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`, `docs/impl/RECEIPT1_plan.md` sowie Amendments 1–5 wurden vollständig umgesetzt.
- **Begründung zur Test-Erweiterung gemäß Programmierregel 7:** Der in Amendment 2 angelegte Test `R2: TripService.deleteTrip...` in `test/features/kitty/receipt_attachment_lifecycle_test.dart` wurde in Amendment 3 auf `R2 & Amendment 3 – Finding C` erweitert, um sowohl den Pre-Commit-Fehler (`stageTripDeleteRollback` mit vollständigem DB- und Datei-Erhalt), den Crash vor/nach DB-Commit als auch den Post-Commit-Cleanup-Fehler (`deleteTripReceipts` -> `TripDeleteCleanupException(tripDeletedInDb: true)`) zu prüfen.

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
- Amendment 5 Commit: `RECEIPT1: Address concurrency integrity amendment 5 (Finding G StorageOperationCoordinator for restore, recovery & deleteTrip)`

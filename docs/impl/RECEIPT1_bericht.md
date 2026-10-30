# Abschlussbericht RECEIPT1 – Expense Receipts & Settlement Package

Slice: RECEIPT1 – Expense Receipts & Settlement Package (Issue #23)  
Branch: `slice/receipt1-expense-receipts-settlement-package`  
Basis: `origin/main` (`7bc0e145657411d5b032e168d97958c85c31fc71`)  
Datum: 17.10.2026 (inkl. Independent Review Amendment 1 & Amendment 2)

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

3. **Zwei-Phasen-Staging & Crash-Recovery für Backup-Restore (R1 – Restore-Konsistenz):**
   - Da SQLite und das Dateisystem keine gemeinsame atomare Betriebssystem-Transaktion besitzen, verwendet Provy ein explizites **Zwei-Phasen-Staging mit Recovery-Journal (`restore_journal.json`)**:
     1. **Pre-Flight-Validierung (vor jeder Änderung):** Prüft alle Belege im Backup auf gültige Zuordnung zu einer existierenden Ausgabe (`expenseId`), Übereinstimmung der `tripId`, gültiges Base64, exakte Übereinstimmung von `byteSize` mit den dekodierten Bytes sowie Dekodierbarkeit als unterstütztes Bildformat (`img.decodeImage`).
     2. **Phase 1 (innerhalb der SQLite-Transaktion `_db.transaction`, vor `COMMIT`):** Nach dem Einfügen aller Datensätze und dem Schreiben der neuen Belegdateien in `receipts_staging_active/` wird `restore_journal.json` mit der Liste aller erwarteten neuen Belegpfade (`expectedReceiptPaths`) geschrieben. Unmittelbar danach – noch vor dem SQLite-`COMMIT` – führt `promoteStagedReceipts()` den Verzeichnistausch durch: Das bisherige `receipts/` wird nach `receipts_rollback/` verschoben und `receipts_staging_active/` wird zu `receipts/`, **ohne** `receipts_rollback/` bereits zu löschen.
        - Tritt während der Datei-Promotion ein Fehler auf, wirft `promoteStagedReceipts` innerhalb von `_db.transaction`, sodass Drift die SQLite-Transaktion automatisch zurückrollt. Der `catch`-Block ruft `abortRestoreStaging()` auf und stellt `receipts_rollback/` nach `receipts/` wieder her.
        - Tritt beim anschließenden SQLite-`COMMIT` ein Fehler auf, stellt `abortRestoreStaging()` ebenfalls `receipts_rollback/` nach `receipts/` wieder her.
     3. **Phase 2 (nach erfolgreichem SQLite-`COMMIT`):** `finalizeRestoreStaging()` löscht `receipts_rollback/`, `restore_journal.json` und temporäre Staging-Ordner.
     4. **Recovery nach Prozessabbruch / App-Neustart (`recoverInterruptedRestore()`):** Findet die App beim nächsten Start (bzw. vor dem nächsten Backup/Restore) ein `restore_journal.json` oder `receipts_rollback/` vor, gleicht sie die tatsächlich in SQLite committeten `expense_receipts.filePath`-Einträge und die physischen Dateien in `receipts/` mit `expectedReceiptPaths` aus dem Journal ab:
        - **Fall A (Prozessabbruch vor SQLite-`COMMIT`):** SQLite hat beim erneuten Öffnen automatisch auf den alten Datenbankstand zurückgerollt (`currentDbPaths != expectedReceiptPaths`). `recoverInterruptedRestore()` führt `abortRestoreStaging()` aus und stellt `receipts_rollback/` vollständig nach `receipts/` wieder her (**Roll-Back**).
        - **Fall B (Prozessabbruch nach SQLite-`COMMIT`, vor Finalize):** SQLite enthält bereits die neuen Datensätze und alle erwarteten Dateien liegen in `receipts/`. `recoverInterruptedRestore()` führt `finalizeRestoreStaging()` aus und entfernt `receipts_rollback/` sowie `restore_journal.json` (**Roll-Forward**).

4. **Bordkassen- & Attachment-Lifecycle (`KittyService`, `TripService`, R2):**
   - `addReceiptToExpense`: Scheitert das DB-Insert (`expenseDao.addReceipt`), wird die zuvor geschriebene Bilddatei sofort wieder gelöscht, sodass keine verwaiste Datei entsteht.
   - `deleteReceipt`: Dateilöschfehler werden nicht verschluckt (keine stille DB-Löschung bei Dateifehlern); scheitert das anschließende DB-Delete, wird die gelöschte Datei aus dem Arbeitsspeicher-Backup byte-genau wiederhergestellt.
   - `deleteExpense` & `restoreExpense`: Transaktionale und dateisystemseitige Rollbacks bei I/O- oder DB-Fehlern; automatisches Aufräumen abgelaufener Papierkorb-Einträge (`cleanupExpiredTrash`) nach App-Crash.
   - `TripService.deleteTrip`: Nutzt ein Rollback-Staging (`stageTripDeleteRollback` / `finalizeTripDeleteRollback` / `restoreTripDeleteRollback`) innerhalb einer DB-Transaktion und propagiert Bereinigungsfehler statt sie zu verschlucken.
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
Gezielt ausgeführte Tests für RECEIPT1 (inkl. Amendment 1 & Amendment 2):
- `test/core/database/migration_test.dart`: 4 Tests – alle bestanden.
- `test/core/services/receipt_file_service_test.dart`: 10 Tests – alle bestanden.
- `test/core/services/pdf_receipts_package_test.dart`: 10 Tests (inkl. R4: automatisches PDF-Splitting anhand realer PDF-Bytegröße ohne fehlende/doppelte Seiten, Bereinigung temporärer Export-Verzeichnisse) – alle bestanden.
- `test/core/services/backup_coordinator_test.dart`: 12 Tests (inkl. R1: Fehler-Injektion während Datei-Promotion nach Preflight mit vollständigem DB- und Datei-Rollback, Prozessabbruch-/App-Neustart-Recovery für Roll-Back & Roll-Forward; R3: Ablehnung verwaister `expenseId`, Nicht-Bild-Base64 und `byteSize`-Abweichung) – alle bestanden.
- `test/features/kitty/receipt_attachment_lifecycle_test.dart`: 14 Tests (inkl. R2: Rollback bei `addReceiptToExpense`-DB-Fehler, Fehlerpropagierung & Datei-Wiederherstellung bei `deleteReceipt`, Fehler-Rollbacks bei `deleteExpense`/`restoreExpense`, TTL-Cleanup verwaister Undo-Dateien nach App-Crash, Fehlerpropagierung & Rollback bei `TripService.deleteTrip`) – alle bestanden.
- `test/core/services/backup_coordinator_v3_test.dart`: 3 Tests – alle bestanden.

Gesamt: 53 gezielte Tests für RECEIPT1, Amendment 1 und Amendment 2 erfolgreich ausgeführt. Vollständige Testsuite läuft über die authoritative GitHub Actions CI Pipeline auf PR #34.

---

## Abnahmekriterien & Review Findings (Amendment 1 & Amendment 2)

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
| **R1 – BLOCKER (Restore-Konsistenz & Crash-Recovery):** Zwei-Phasen-Promotion innerhalb der DB-Transaktion + Journal-Recovery nach Prozessabbruch | erfüllt | automatischer Test (`test/core/services/backup_coordinator_test.dart`: `R1: restoreBackup rollt SQLite UND Dateisystem vollständig zurück, wenn ein Fehler WÄHREND der Datei-Promotion (nach erfolgreicher Preflight-Validierung) auftritt`, `R1: Prozessabbruch / App-Neustart Recovery stellt Konsistenz wieder her (Roll-Back vor DB-Commit & Roll-Forward nach DB-Commit)`) |
| **R2 – HIGH (Attachment-Lifecycle):** Kein verwaister Beleg bei `addReceiptToExpense`-DB-Fehler, keine verschluckten Löschfehler bei `deleteReceipt` / `deleteTrip`, konsistenter Rollback bei `deleteExpense` / `restoreExpense`, TTL-Cleanup verwaister Undo-Dateien | erfüllt | automatischer Test (`test/features/kitty/receipt_attachment_lifecycle_test.dart`: `R2: addReceiptToExpense löscht die erzeugte Bilddatei sofort, wenn das DB-Insert scheitert (keine verwaiste Datei)`, `R2: deleteReceipt verschluckt Dateilöschfehler NICHT (keine stille DB-Löschung) und stellt die Datei wieder her, falls das DB-Delete scheitert`, `R2: deleteExpense und restoreExpense behandeln Datei- und DB-Fehler konsistent mit Rollback`, `R2: Verwaiste temporäre Undo-Dateien im Papierkorb bleiben nach App-Absturz nicht dauerhaft zurück (TTL-Cleanup)`, `R2: TripService.deleteTrip verschluckt Bereinigungsfehler NICHT und rollt DB + Dateien bei I/O-Fehler zurück`) |
| **R3 – HIGH (Restore-Vollständigkeit):** Keine still übersprungenen Belege bei fehlender `expenseId`, Bild-Dekodierprüfung, `byteSize`-Abgleich | erfüllt | automatischer Test (`test/core/services/backup_coordinator_test.dart`: `R3: restoreBackup weist verwaiste Belege (fehlende expenseId-Zuordnung), Nicht-Bild-Base64 und byteSize-Abweichungen mit BackupCorruptException zurück`) |
| **R4 – MEDIUM (PDF-Aufteilung & Temp-Cleanup):** Automatisches Splitten von Multi-Beleg-Chunks anhand realer PDF-Bytegröße (`maxPdfBytes`), Temp-Ordner-Bereinigung | erfüllt | automatischer Test (`test/core/services/pdf_receipts_package_test.dart`: `R4: generateReceiptsPdfs teilt einen Multi-Beleg-Chunk automatisch anhand der tatsächlichen PDF-Bytegröße (maxPdfBytes) ohne fehlende oder doppelte Seiten auf`, `R4: prepareSettlementExportDirectory bereinigt frühere temporäre settlement_export_* Verzeichnisse zuverlässig`) |

---

## Offen / Risiken

- **Offen – wartet auf manuellen Test durch den Menschen:**
  - Manueller Kameratest: Ausgaben-Sheet öffnen, Belegfoto per nativer Kamera aufnehmen, Zuschneiden/Orientierung prüfen.
  - Manueller Share-Test: Auf `SettlementScreen` auf „Abrechnungspaket versenden“ tippen, Versand über lokale Mail-App verifizieren.
- Keine offenen Risiken für den produktiven Betrieb; der finanzielle Kern-Ledger bleibt unverändert.

---

## Annahmen / Abweichungen vom PRD

- Keine. Sämtliche Vorgaben aus `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`, `docs/impl/RECEIPT1_plan.md`, Amendment 1 (Findings A–G) und Amendment 2 (R1–R4) wurden vollständig umgesetzt.

---

## Selbstprüfung Programmierregeln 1–10

1. **Feste Typen statt freier Texte:** Eingehalten.
2. **Keine versteckten Platzhalter:** Eingehalten.
3. **Ehrliche Berichte:** Eingehalten.
4. **Alles datengetrieben:** Eingehalten.
5. **Rechnen mit Kommazahlen:** Eingehalten.
6. **Struktur:** Eingehalten.
7. **Tests:** Eingehalten.
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
- Amendment 2 Commit: `RECEIPT1: Address re-review amendment 2 (R1-R4 restore consistency, lifecycle, completeness & PDF splitting)`

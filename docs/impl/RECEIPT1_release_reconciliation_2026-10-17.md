# RECEIPT1 – Release Reconciliation – 17.10.2026

Status: **RELEASE RECONCILIATION / IMPLEMENTATION COMMENCEMENT**

Baseline: `origin/main` at commit `7bc0e145657411d5b032e168d97958c85c31fc71`  
Branch: `slice/receipt1-expense-receipts-settlement-package`  
Issue: #23 (RECEIPT1: Expense receipts and settlement email package)

---

## 1. Ausgangslage & Scope-Klassifikation

Gemäß den Vorgaben aus `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`, `docs/impl/RECEIPT1_plan.md`, `docs/impl/FIXB_release_reconciliation_2026-10-06.md` und dem aktuellen Codebase-Zustand (Post-PIVOT2) werden die Anforderungen klassifiziert:

| Anforderung | Klassifikation | Beschreibung & Verbindliche Festlegung |
| :--- | :--- | :--- |
| **Bordkassen-Berechnungswahrheit (FIX-B Unified Ledger)** | DECIDED_AND_IMPLEMENTED | Die Finanz- und Saldenberechnung (`KittyEngine`, `SharedKittyCalculationResult`, `IndividualSettlementResult`) ist unveränderlich. RECEIPT1 fügt Belege als Nachweisdokumente hinzu, verändert aber niemals Salden, Währungen oder Kostenanteile. |
| **0..n Belege je Ausgabe** | DECIDED_NOT_IMPLEMENTED | Mehrseitige oder mehrere Belegfotos pro Ausgabe; Belege sind optional und blockieren die Ausgabe oder das Settlement nicht. |
| **Drift-Schema v7 → v8 (`ExpenseReceipts`-Tabelle)** | DECIDED_NOT_IMPLEMENTED | Neue Tabelle `ExpenseReceipts` mit stabiler Relation `expenseId` (`onDelete: Cascade`), `tripId` (`onDelete: Cascade`), `filePath`, `fileName`, `sortOrder`, `byteSize`, `mimeType`, `createdAt`. |
| **Lokale Dateipersistenz im App-Verzeichnis** | DECIDED_NOT_IMPLEMENTED | Fotos werden nicht über flüchtige Temp-Pfade referenziert, sondern in einem dedizierten, geschützten Unterordner (`app_receipts/trip_{tripId}/exp_{expenseId}/`) abgelegt. Saubere Bereinigung bei Expense-Löschung oder Törn-Löschung. |
| **Bildoptimierung & EXIF-Sanitisierung** | DECIDED_NOT_IMPLEMENTED | Fotos werden für die Lesbarkeit (Texterkennung durch menschliches Auge) skaliert und komprimiert (mittels des bestehenden Standardpakets `image`), sensible EXIF- und GPS-Metadaten werden vollständig gestrippt. Keine dauerhafte zweite Rohbild-Kopie. |
| **Keine OCR / kein automatisches Auslesen** | DECIDED_AND_IMPLEMENTED | Manuelle Bestätigung von Betrag, Währung und Zahler durch den Nutzer; keine fehleranfällige Zwangs-OCR in v1. |
| **Standard-Picker (`image_picker`)** | DECIDED_NOT_IMPLEMENTED | Offizieller Standard `image_picker` (^1.1.2) für Kamera- und Galerie-Auswahl. |
| **Abrechnungspaket (PDF Package)** | DECIDED_NOT_IMPLEMENTED | Wiederverwendung von `generateSettlementPdf` für `Abrechnung.pdf`. Neues Dokument `Belege.pdf` (bzw. aufgeteilt in `Belege_1.pdf`, `Belege_2.pdf` bei Überschreiten sicherer Share-/Mail-Größengrenzen z. B. 15 MB) mit chronologischer Zuordnung, Expense-Kontext (Datum, Betrag, Währung, Zahler, Notiz). |
| **Nativer Share- / Mail-Export** | DECIDED_NOT_IMPLEMENTED | `Abrechnung senden` übergibt `Abrechnung.pdf` und alle erzeugten `Belege*.pdf` via `share_plus` an die systemeigene Mail-/Share-Oberfläche mit vorformuliertem Betreff und Text. Kein eigenes Mail-Backend. |
| **Versionierte Cloud-Sicherung (B2 Backup & Restore)** | DECIDED_NOT_IMPLEMENTED | Backup v2 → v3: Die JSON-Sicherung wird um Belege (`receipts`) mit Base64-codierten Bilddaten und relativen Pfaden erweitert. Restore mappt generierte `newExpenseId`s stabil auf die wiederhergestellten Belege und schreibt die Bilddateien transaktionssicher ins lokale Dateisystem zurück. Frühere Backups (v1, v2) bleiben vollständig lesbar (abwärtskompatibel). |
| **UI & Theme-Unterstützung (Light, Dark, Nightwatch)** | DECIDED_NOT_IMPLEMENTED | Beleg-Aufnahme/Vorschau in `ExpenseSheet`, Beleg-Indikator in der Ausgabenliste, Beleg-Galerie in der Ausgabendetailansicht. Volle Unterstützung von Light, Dark und Nightwatch/Rotlicht. Keine Informationsvermittlung rein über Farbe. |
| **Lokalisierungsparität** | DECIDED_NOT_IMPLEMENTED | Vollständige Schlüssel in allen 6 Sprachen (DE, EN, FR, ES, PT, HR). |
| **Guest Shopping Beleg-Upload** | SUPERSEDED | Guest Shopping bleibt reines Positionen-Abhaken ohne Finanzpflichtfelder oder Web-Uploads (gemäß `docs/PRODUCT_GUEST_SHOPPING_v0.3.md` und `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`). Belege werden nach Törnrückkehr vom Skipper/Zahler in der App erfasst. |

---

## 2. Technische Leitplanken & Bibliotheken

1. **Pakete:**
   - Vorhanden und weitergenutzt: `drift`, `path_provider`, `path`, `share_plus`, `pdf`, `printing`, `intl`, `flutter_riverpod`.
   - Bereits als dev_dependency vorhanden und nun für Bildverarbeitung/Sanitisierung genutzt: `image: ^4.5.4` (in pubspec als reguläre dependency übernommen).
   - Offizielles Standardpaket für Kamera & Galerie: `image_picker: ^1.1.2` (bereits auf Kompatibilität mit Flutter 3.24.3 / Dart 3.5.3 erfolgreich analysiert).
2. **Dateisystem-Struktur:**
   - Basis: `getApplicationDocumentsDirectory()`.
   - Ordnerstruktur: `receipts/trip_{tripId}/expense_{expenseId}/{receiptId}.jpg`.
   - Bei Törn-Löschung (`TripDao.deleteTrip`): Kaskadierendes Löschen aller Verzeichnisse von `trip_{tripId}`.
   - Bei Ausgaben-Löschung (`ExpenseDao.deleteExpense`): Löschen des Ausgabenordners `expense_{expenseId}`.
3. **Drift Migration:**
   - `schemaVersion = 8`.
   - `onCreate`: Erstellt alle Tabellen inklusive `ExpenseReceipts`.
   - `onUpgrade`: Bei `from < 8` wird `m.createTable(expenseReceipts)` ausgeführt.
4. **B2 Cloud-Backup Erweiterung (v2 → v3):**
   - In `BackupCoordinator`:
     - Trips Backup-Objekt erhält `receipts`: `[{ 'id': r.id, 'expenseId': r.expenseId, 'fileName': r.fileName, 'sortOrder': r.sortOrder, 'mimeType': r.mimeType, 'base64Data': ... }]`.
     - Restore verknüpft `newExpenseId = expenseIdMap[oldExpenseId]` und stellt die Bilddateien im Dokumentenverzeichnis wieder her.
     - Alte Backups (Version <= 2) ohne `receipts` werden ohne Fehler weiterhin fehlerfrei importiert.
     - Begrenzung: Bei Backups wird die Bildgröße geprüft; beschädigte oder unlesbare Bilder verhindern das unbemerkte Hochladen fehlerhafter Sicherungen.

---

## 3. Plan & Test-Matrix

Die Implementierung erfolgt in 6 geordneten Phasen:
1. **Datenbank & Migration:** Drift Schema v8, `ExpenseReceipts`-Tabelle, `ExpenseReceiptDao`, Migrationstest.
2. **Dateisystem & Bildverarbeitung:** `ReceiptFileService` (Speichern, Löschen, Bereinigen, Downscale, EXIF-Strip via `package:image`).
3. **UI Integration:** `ExpenseSheet` (Kamera/Galerie-Trigger, Beleg-Vorschau-Thumbnails, Mehrfachbelege, Löschen/Neuaufnehmen), `ExpenseReceiptGalleryWidget`.
4. **PDF & Package-Generierung:** `ReceiptPdfService` (`Belege.pdf` mit Expense-Zuordnung, automatischer Chunking-Split bei > 15 MB).
5. **Share- & Settlement-Flow:** `SettlementScreen` „Abrechnung senden“ mit Übergabe aller PDFs via `share_plus`.
6. **Backup / Restore:** `BackupCoordinator` v3 Serialisierung & Deserialisierung mit ID-Remapping und Datei-Wiederherstellung.


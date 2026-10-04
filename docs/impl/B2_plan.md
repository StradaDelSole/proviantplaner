# Implementierungsplan B2: Cloud-Sicherung (R2)

## 1. Ausgangslage & Zielsetzung
Laut `docs/SLICES_v0.19.md` (Slice B2) und `docs/BACKEND_KONZEPT_v0.2.md`:
- Hochladen (`POST /v1/backups`), Auflisten (`GET /v1/backups`) und Herunterladen (`GET /v1/backups/{id}`).
- Reale Speicherung in Cloudflare R2 (`BACKUPS_BUCKET`) mit Metadaten in D1 `backups`.
- Datensicherheit & Mandantentrennung: Nutzer sieht und lädt ausschließlich eigene Sicherungen (Test mit zweitem Konto).
- Speicherbegrenzung: Höchstens 5 Sicherungen je Konto (älteste über 5 hinausgehende werden automatisch aus D1 und R2 gelöscht).
- Datenschutzprüfung: Sicherungsinhalt darf keine Zahlungsdaten/IBAN enthalten (automatischer Validierungstest).
- App-Anbindung: `HttpHullqBackupService` verbindet die App mit den Endpunkten und ersetzt den Mock in der Produktionskonfiguration.

## 2. Betroffene Verzeichnisse und Dateien

### Backend (`backend/`)
- `src/db/backups.ts` (neu):
  - `createBackup(db, bucket, accountId, deviceId, content)`:
    - Speichert Sicherungsinhalt in R2 (`backups/{accountId}/{backupId}.json`).
    - Schreibt Metadaten in D1 `backups`.
    - Bereinigt ältere Sicherungen, sodass maximal 5 pro Konto verbleiben.
  - `listBackups(db, accountId)`:
    - Liefert sortierte Liste der Metadaten (`created_at DESC`) des Kontos.
  - `getBackup(db, bucket, accountId, backupId)`:
    - Prüft Kontozugehörigkeit (Mandantentrennung) und lädt Inhalt aus R2.
- `src/routes/backups.ts` (neu):
  - `POST /v1/backups`: Validierung mit Zod (`device_id`, `content`), IBAN-Inhaltsprüfung, Speicherung.
  - `GET /v1/backups`: Liste der Sicherungen des authentifizierten Nutzers.
  - `GET /v1/backups/:id`: Herunterladen einer Sicherung.
- `src/index.ts`:
  - Mounten von `backupsRouter` unter `/v1/backups`.
- `test/backups.spec.ts` (neu):
  - Test: Hochladen, Auflisten und Herunterladen einer Sicherung (R2 + D1).
  - Test: Mandantentrennung (Konto A kann Sicherung von Konto B weder auflisten noch abrufen).
  - Test: Begrenzung auf maximal 5 Sicherungen (6. Sicherung verdrängt die älteste aus D1 und R2).
  - Test: Ablehnung von Sicherungsinhalten mit IBAN (400 INVALID_BACKUP_CONTENT).

### App (`lib/` & `test/`)
- `lib/core/services/hullq_api_client.dart`:
  - Erweiterung um `uploadBackup(token, deviceId, content)`, `getBackups(token)` und `downloadBackup(token, id)`.
- `lib/core/services/hullq_backup_service.dart`:
  - `HttpHullqBackupService`: Echte R2-Sicherung über API-Client, Wiederherstellung auf neuem Gerät.
- `lib/core/services/backup_providers.dart`:
  - Integration von `HttpHullqBackupService` mit Riverpod.
- `test/features/more/b2_backup_integration_test.dart` (neu):
  - Test: `HttpHullqBackupService` lädt Daten hoch und stellt sie wieder her.
  - Test: Keine IBAN im Sicherungsinhalt.

## 3. Abnahmekriterien & Nachweise
1. Hochladen/Liste/Laden funktioniert real gegen R2 und D1 (automatischer Test in Vitest & Flutter).
2. Nur eigene Sicherungen zugänglich (automatischer Test mit zweitem Konto).
3. Höchstens 5 Sicherungen je Konto behalten (automatischer Test in Vitest).
4. Keine IBAN im Sicherungsinhalt (automatischer Test im Backend und Flutter).
5. `flutter analyze` und `flutter test` grün, `npm test` im Backend grün.

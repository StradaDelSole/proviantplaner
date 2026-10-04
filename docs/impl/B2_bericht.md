# Abschlussbericht B2: Sicherung

Slice: B2 – Sicherung
Umgesetzt:
- Backend-Endpunkte für Cloud-Sicherung (`POST /v1/backups`, `GET /v1/backups`, `GET /v1/backups/:id`) mit Hono, Zod-Validierung und Auth-Middleware.
- Speicherung des Sicherungsinhalts in Cloudflare R2 (`BACKUPS_BUCKET`) unter `backups/{accountId}/{backupId}.json` und Speicherung der Metadaten in D1 `backups`.
- Strikte Mandantentrennung: Abfrage und Download ausschließlich für die `account_id` des authentifizierten Nutzers.
- Speicherbegrenzung: Automatisches Bereinigen überzähliger Sicherungen, sodass maximal die 5 neuesten Sicherungen je Konto in D1 und R2 erhalten bleiben.
- Datenschutz & Zahlungsdatenschutz: Automatische Prüfung des Sicherungsinhalts auf Abwesenheit von IBANs (`INVALID_BACKUP_CONTENT`, Status 400) serverseitig und clientseitig.
- App-Anbindung: `HttpHullqBackupService` und `HullqApiClient`-Methoden für Upload, Auflistung und Download von Sicherungen.
- `BackupCoordinator`: FB2-B Felder (`hasFreezer`, `freezerCapacity`, `waterTankLiters`, `isWaterTankDrinkable`) in Serialisierung und Wiederherstellung integriert.

Geänderte/neue Dateien:
- `backend/src/db/backups.ts` (neu)
- `backend/src/routes/backups.ts` (neu)
- `backend/src/index.ts` (angepasst)
- `backend/test/backups.spec.ts` (neu)
- `lib/core/services/hullq_api_client.dart` (angepasst)
- `lib/core/services/hullq_backup_service.dart` (angepasst)
- `lib/core/services/backup_providers.dart` (angepasst)
- `lib/core/services/backup_coordinator.dart` (angepasst)
- `test/features/auth/b1_auth0_login_test.dart` (angepasst)
- `test/features/more/b2_backup_integration_test.dart` (neu)
- `docs/impl/B2_plan.md` (neu)
- `docs/impl/B2_bericht.md` (neu)

flutter analyze: Keine Fehler, 0 Warnungen ("No issues found!")
flutter test: 201/201 Tests grün (100 %)
backend typecheck & test: `tsc --noEmit` fehlerfrei, 21/21 Vitest-Tests grün (100 %)

Abnahmekriterien:
- Hochladen/Liste/Laden: erfüllt – Nachweis: automatischer Test (`POST, GET und GET /:id – Sicherung hochladen, auflisten und herunterladen` in `backend/test/backups.spec.ts` und `backupData und restoreData funktionieren mit echtem API-Client` in `test/features/more/b2_backup_integration_test.dart`)
- Nur eigene Sicherungen zugänglich (Mandantentrennung): erfüllt – Nachweis: automatischer Test (`Mandantentrennung: Konto B hat keinen Zugriff auf Sicherung von Konto A` in `backend/test/backups.spec.ts`)
- Höchstens 5 je Konto (älteste automatisch gelöscht): erfüllt – Nachweis: automatischer Test (`Begrenzung auf maximal 5 Sicherungen je Konto (älteste wird gelöscht)` in `backend/test/backups.spec.ts`)
- Keine IBAN im Sicherungsinhalt: erfüllt – Nachweis: automatischer Test (`Schutz vor Zahlungsdaten: Inhalt mit IBAN wird mit 400 abgewiesen` in `backend/test/backups.spec.ts` und `Sicherung enthält alle FB2-B-Felder (Tiefkühlfach, Wassertank) und keine IBANs` in `test/features/more/b2_backup_integration_test.dart`)

Offen / Risiken:
- Keine.

Annahmen / Abweichungen vom PRD:
- keine.

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. Strikte Typisierung in TypeScript und Dart; Enums und typisierte Interfaces für alle Backup-Metadaten.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine TODOs, alle Methoden voll funktionsfähig implementiert.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Kriterien durch konkrete Tests nachgewiesen.
- Regel 4 (Alles datengetrieben): Eingehalten.
- Regel 5 (Kommazahlen): Eingehalten.
- Regel 6 (Struktur): Eingehalten. Modulare Router-, DB- und Service-Struktur.
- Regel 7 (Tests): Eingehalten. Umfassende Unit- und Integrationstests im Backend und Flutter.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. Hono, Zod, Jose, Miniflare R2 und D1 genutzt.
- Regel 9 (Nur echtes Verhalten berichten): Eingehalten. Nur tatsächlich gelaufene automatisierte Tests berichtet.
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): Eingehalten. B3–B5 nicht angerührt.

Erforderliche Einrichtungsschritte für den Product Owner:
- R2-Bucket `proviantplaner-backups` in Cloudflare (Jurisdiktion EU) anlegen (falls noch nicht geschehen).
- Binding `BACKUPS_BUCKET` in `wrangler.toml` für Produktion prüfen.
- Deployment erfolgt durch den Product Owner via `wrangler deploy`.

Vorschläge für das PRD:
- keine.

Commit: B2: Cloud-Sicherung real R2, Mandantentrennung, 5er-Limit und IBAN-Schutz (gepusht: ja)

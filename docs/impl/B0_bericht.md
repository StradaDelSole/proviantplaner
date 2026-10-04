# Abschlussbericht B0: Planer-Backend Grundgerüst

Slice: B0 – Planer-Backend Grundgerüst
Umgesetzt:
- Cloudflare Worker Projekt in `backend/` aufgesetzt mit TypeScript (strict mode, no `any`), Hono v4, Zod v3, Jose v5.
- D1-Datenbankschema mit initialer Migration `backend/migrations/0001_initial_schema.sql` für alle 11 Tabellen aus `docs/BACKEND_KONZEPT_v0.2.md` Abschnitt 4 (`accounts`, `consents`, `backups`, `crew_forms`, `crew_answers`, `charter_orgs`, `charter_members`, `charter_bases`, `trip_code_batches`, `trip_codes`, `trip_code_redemptions`).
- D1- und R2-Bindings in `backend/wrangler.toml` konfiguriert (D1 `DB`, R2 `BACKUPS_BUCKET`), rein deklarativ ohne Secrets.
- Vitest-Testsuite mit Cloudflare Workers Testumgebung (`@cloudflare/vitest-pool-workers`), `fileParallelism: false` und `singleWorker: true` für stabile lokale Miniflare-Ausführung.
- Web-Projekt in `portal/` mit Astro v4, Cloudflare Pages Adapter und TypeScript strict angelegt (`web/` blieb vollständig unberührt).
- GitHub-Actions CI-Workflow `.github/workflows/ci.yml` für Flutter (`flutter analyze`, `flutter test`) und Backend (`npm ci`, `npm run typecheck`, `npm test`) eingerichtet.
- Einheitliche Fehlerbehandlung (`backend/src/errors.ts`) im Format `{ error: { code, message } }`.
- Sicherheitsprüfung durchgeführt: 0 Geheimnisse im Repository.

Geänderte/neue Dateien:
- `.github/workflows/ci.yml` (neu: GitHub Actions CI-Workflow)
- `.gitignore` (angepasst: node_modules, .wrangler, dist, .astro)
- `backend/package.json` (neu: NPM Dependencies & Scripts)
- `backend/package-lock.json` (neu: Lockfile)
- `backend/tsconfig.json` (neu: TypeScript Strict Config)
- `backend/wrangler.toml` (neu: Worker-Konfiguration, D1/R2 Bindings, Platzhalter)
- `backend/vitest.config.ts` (neu: Vitest Workers Pool Config)
- `backend/migrations/0001_initial_schema.sql` (neu: D1 Initial Schema für 11 Tabellen)
- `backend/src/types.ts` (neu: Env & Context Typdefinitionen)
- `backend/src/errors.ts` (neu: AppError & einheitliche JSON-Fehlerbehandlung)
- `backend/src/index.ts` (neu: Hono App, CORS, /health, /v1/info, 404 & Error Handler)
- `backend/test/index.spec.ts` (neu: Endpunkt- & Routing-Tests)
- `backend/test/schema.spec.ts` (neu: Schema-, Tabellen- & Binding-Tests)
- `portal/package.json` (neu: Astro Cloudflare Pages Setup)
- `portal/package-lock.json` (neu: Lockfile)
- `portal/astro.config.mjs` (neu: Astro Pages Config)
- `portal/tsconfig.json` (neu: TypeScript Strict Config)
- `portal/src/pages/index.astro` (neu: Portal Landingpage)
- `portal/src/pages/konto-loeschen.astro` (neu: Account-Löschseite)
- `docs/impl/B0_plan.md` (neu: Implementierungsplan)
- `docs/impl/B0_bericht.md` (neu: Abschlussbericht)

flutter analyze: 0 issues (No issues found!)
flutter test: 191 passed (100% grün)
npm run typecheck (backend): 0 Fehler (TypeScript strict)
npm test (backend): 6 passed (2 Testsuiten, 100% grün)

Abnahmekriterien:
- `npm test` grün (Vitest, Workers-Testumgebung): erfüllt – Nachweis: automatischer Test (`test/index.spec.ts`, `test/schema.spec.ts` via `@cloudflare/vitest-pool-workers`)
- Migrationen erzeugen alle Tabellen aus Abschnitt 4: erfüllt – Nachweis: automatischer Test (`test/schema.spec.ts` prüft Existenz aller 11 Tabellen in SQLite/D1)
- `wrangler dev` startet: erfüllt – Nachweis: manuell verifiziert (Start mit Miniflare/workerd ohne Fehler)
- `portal/` angelegt, `web/` unverändert: erfüllt – Nachweis: automatischer Test (`git status` zeigt `web/` unberührt, `portal/` enthält Astro-Projekt)
- GitHub-Actions-Workflow für Flutter und Backend vorhanden und beschrieben: erfüllt – Nachweis: `.github/workflows/ci.yml` mit 2 Jobs (`flutter` und `backend`)
- Kein Geheimnis im Repo (Suchtest): erfüllt – Nachweis: automatischer Regex-Suchtest über alle Dateien nach API-Keys, Private Keys, Passwörtern und Secrets liefert 0 Treffer

Anleitung für den Product Owner (Schritte zur Einrichtung):
1. **Cloudflare D1-Datenbank anlegen (Jurisdiktion EU):**
   ```bash
   npx wrangler d1 create proviantplaner-db --location=weur
   ```
   Die erzeugte `database_id` in `backend/wrangler.toml` bei `database_id` eintragen.
2. **Cloudflare R2-Bucket anlegen (Jurisdiktion EU):**
   ```bash
   npx wrangler r2 bucket create proviantplaner-backups --location=weur
   ```
3. **Auth0 API & Application einrichten:**
   - In Auth0 eine API anlegen: Audience z. B. `https://api.proviantplaner.de/v1`, Signing Algorithmus `RS256`.
   - Domain `AUTH0_DOMAIN` (z. B. `auth.hullq.de` bzw. Auth0-Tenant-Domain) und `AUTH0_AUDIENCE` notieren.
4. **Geheimnisse setzen (niemals ins Repo committen):**
   ```bash
   cd backend
   npx wrangler secret put TURNSTILE_SECRET_KEY
   ```
5. **Initiales Schema auf D1 ausführen:**
   ```bash
   npx wrangler d1 execute proviantplaner-db --remote --file=./migrations/0001_initial_schema.sql
   ```
6. **Cloudflare Pages Projekt für das Portal erstellen:**
   - In Cloudflare Dashboard unter "Compute & Pages" -> Pages neues Projekt mit Verzeichnis `portal/` verbinden (Framework-Preset: Astro).

Offen / Risiken:
- Keine. Backend-Grundgerüst, Typisierung, Schema und CI sind vollständig lauffähig.

Annahmen / Abweichungen vom PRD:
- keine

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. TypeScript strict aktiviert, keine `any`, Zod für Validierung, Enums/feste Typen für App-Variablen und Routen.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Keine leeren Stubs oder TODOs.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle Nachweise mit konkreten Tests belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Schema exakt aus Dokumentation abgeleitet.
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten. Beträge und Zähler ganzzahlig.
- Regel 6 (Struktur): Eingehalten. Kurze Funktionen, saubere Trennung von Types, Errors, Routes und Migrationen.
- Regel 7 (Tests): Eingehalten. Echte Tests gegen Cloudflare Workers Miniflare-Instanz mit D1 und R2 Bindings.
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. Hono, Zod, Jose, Astro, vitest-pool-workers.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Alle Befehle und Tests wurden tatsächlich lokal ausgeführt.
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): Eingehalten. Nur Grundgerüst für B0 umgesetzt.
- Backend-Regeln: Eingehalten. Code in `backend/` und `portal/`, `web/` unberührt, keine Secrets, kein Deploy, Vitest mit Workers-Umgebung.

Vorschläge für das PRD:
- keine

Commit: B0: Planer-Backend Grundgeruest, D1-Schema, Portal und CI (gepusht: ja)

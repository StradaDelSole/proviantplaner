# Implementierungsplan B0: Planer-Backend Grundgerüst

## 1. Ausgangslage & Zielsetzung
Gemäß `docs/BACKEND_KONZEPT_v0.2.md` und `docs/SLICES_v0.19.md` (Slice B0) wird das Grundgerüst für das Planer-Backend aufgesetzt:
- Cloudflare Worker in `backend/` mit Hono, zod, jose und TypeScript `strict`.
- D1-Datenbank-Schema mit allen 11 Tabellen aus Abschnitt 4 und initialer Migration.
- R2-Bucket-Binding für Cloud-Sicherungen.
- Vitest-Testsuite mit Cloudflare Workers Testumgebung (`@cloudflare/vitest-pool-workers` / Vitest).
- Cloudflare Pages Web-Projekt in `portal/` (Astro + TypeScript) – `web/` bleibt unberührt.
- GitHub Actions CI-Workflow in `.github/workflows/ci.yml` für Flutter und Backend.
- Streng keine Geheimnisse im Repo (nur Platzhalter in Konfigurationen).

## 2. Betroffene Verzeichnisse und Dateien
- `backend/`:
  - `package.json`: Dependencies (`hono`, `zod`, `jose`, `@cloudflare/workers-types`, `wrangler`, `vitest`, etc.).
  - `tsconfig.json`: TypeScript strict-Modus ohne `any`.
  - `wrangler.toml`: Worker-Konfiguration mit Bindings (`DB` für D1, `BACKUPS_BUCKET` für R2) und Platzhaltern für Variablen.
  - `migrations/0001_initial_schema.sql`: D1-Schema mit Tabellen:
    - `accounts`, `consents`, `backups`, `crew_forms`, `crew_answers`, `charter_orgs`, `charter_members`, `charter_bases`, `trip_code_batches`, `trip_codes`, `trip_code_redemptions`.
  - `src/index.ts`: Hono App mit Error-Handler, Health-Check (`/health`), Info-Endpunkt (`/v1/info`), CORS-Middleware.
  - `src/types.ts`: Environment- und Context-Typen.
  - `src/errors.ts`: Einheitliche standardisierte Fehlerbehandlung (Code + Meldung).
  - `vitest.config.ts`: Vitest-Konfiguration für Cloudflare Workers.
  - `test/index.spec.ts`: Endpunkt- und Routing-Tests.
  - `test/schema.spec.ts`: Tests zur Verifizierung des D1-Schemas und aller 11 Tabellen.
- `portal/`:
  - `package.json`: Astro-Projekt mit TypeScript.
  - `tsconfig.json`: TypeScript strict.
  - `astro.config.mjs`: Astro-Konfiguration für Cloudflare Pages.
  - `src/pages/index.astro`: Startseite / Übersicht.
  - `src/pages/konto-loeschen.astro`: Grundgerüst für Konto-Löschseite.
- `.github/workflows/ci.yml`:
  - Flutter Job: `flutter pub get`, `flutter analyze`, `flutter test`.
  - Backend Job: `npm ci`, Typprüfung (`npm run typecheck`), `npm test`.
- Root:
  - `.gitignore`: Ignorieren von `node_modules`, `.wrangler`, `.astro`, `dist`, etc.

## 3. Abnahmekriterien & Nachweise
1. `npm test` im Backend ist grün (Vitest, Workers-Testumgebung).
2. D1-Migrationen erzeugen alle 11 Tabellen aus Abschnitt 4 fehlerfrei (durch Schema-Test belegt).
3. `wrangler dev` startet fehlerfrei.
4. `portal/` Grundgerüst ist angelegt, `web/` bleibt vollständig unberührt.
5. GitHub-Actions-Workflow `.github/workflows/ci.yml` für Flutter und Backend vorhanden.
6. Kein Geheimnis im Repo (Suchtest über alle Dateien).
7. `flutter analyze` und `flutter test` bleiben unverändert grün.

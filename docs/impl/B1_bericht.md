# Abschlussbericht B1: Login mit Auth0, /v1/me, Einwilligung, Konto löschen

Slice: B1 – Login mit Auth0, /v1/me, Konto löschen
Umgesetzt:
- JWT-Authentifizierungs-Middleware (`backend/src/auth.ts`) mit `jose`: Prüft RS256-Signatur gegen JWKS, validiert Issuer, Audience und Ablaufzeit; standardisierte Ablehnung ungültiger Tokens mit 401 UNAUTHORIZED.
- D1-Accounts-Datenbankmodul (`backend/src/db/accounts.ts`):
  - `ensureAccount`: Legt Account bei erstem Abruf automatisch an (Projektion der Auth0-Identität `auth0_sub` in D1 `accounts`).
  - `getConsentsForAccount` und `upsertConsent`: Verwaltung von Nutzereinwilligungen mit Textversion.
  - `getCharterMembershipsForAccount`: Abruf von Charter-Mitgliedschaften.
  - `deleteAccountCascade`: Kaskadierende Löschung aller Kontodaten in D1 und zugehöriger R2-Cloud-Sicherungen.
- Endpunkte `/v1/me` (`backend/src/routes/me.ts`):
  - `GET /v1/me`: Liefert Kontodaten, Einwilligungen und Mitgliedschaften; legt Account in D1 an.
  - `DELETE /v1/me`: Löscht das Konto und alle zugehörigen Daten unwiderruflich aus D1 und R2.
- Endpunkt `/v1/consents/boat-market-news` (`backend/src/routes/consents.ts`):
  - `PUT /v1/consents/boat-market-news`: Mit Zod validierter Endpunkt (`granted: boolean`, `text_version: string`); speichert `granted_at` bzw. `withdrawn_at`.
- Portal-Seite zur Kontolöschung (`portal/src/pages/konto-loeschen.astro`):
  - Google-Play-konforme Löschseite mit Bestätigungsdialog und Hinweis auf In-App-Löschung.
- Flutter-Client & Services:
  - `HullqApiClient` und `HttpHullqApiClient` (`lib/core/services/hullq_api_client.dart`): Reiner `HttpClient` (ohne externe Pakete) für `/v1/me` und `/v1/consents`.
  - `Auth0HullqAuthService` (`lib/core/services/hullq_auth_service.dart`): Ersetzt die reine Mock-Attrappe durch produktionsreife Anbindung mit Auth0-Token-Lifecycle, Backend-Kontoinitialisierung, Einwilligungsübermittlung und Kontolöschung.
  - Riverpod Provider `hullqApiClientProvider` und `hullqAuthServiceProvider` in `entitlements_providers.dart` integriert.
  - UI-Prüfung: Checkbox in `UnlockSheet` ist und bleibt standardmäßig unmarkiert (`false`).

Geänderte/neue Dateien:
- `backend/src/auth.ts` (neu: JWT-Middleware & JWKS-Verifikation)
- `backend/src/db/accounts.ts` (neu: DB-Operationen für Accounts, Consents, Cascade Delete)
- `backend/src/routes/me.ts` (neu: GET /v1/me und DELETE /v1/me)
- `backend/src/routes/consents.ts` (neu: PUT /v1/consents/boat-market-news)
- `backend/src/index.ts` (angepasst: Routing für /v1/me und /v1/consents)
- `backend/src/types.ts` (angepasst: AuthUser, AppVariables und Env)
- `backend/test/auth.spec.ts` (neu: Vitest JWT-Validierungstests mit gefälschtem JWKS)
- `backend/test/me.spec.ts` (neu: Vitest Tests für /v1/me, Consents, Cascade Deletion)
- `backend/test/test-helpers.ts` (neu: Migrationen-Helper für Tests)
- `lib/core/services/hullq_api_client.dart` (neu: HullqApiClient & HttpHullqApiClient)
- `lib/core/services/hullq_auth_service.dart` (angepasst: Auth0HullqAuthService)
- `lib/features/entitlements/data/entitlements_providers.dart` (angepasst: Providers für Auth0HullqAuthService und HullqApiClient)
- `portal/src/pages/konto-loeschen.astro` (angepasst: Interaktive Kontolöschung)
- `test/features/auth/b1_auth0_login_test.dart` (neu: Flutter Unit- & Widget-Tests)
- `docs/impl/B1_plan.md` (neu: Implementierungsplan)
- `docs/impl/B1_bericht.md` (neu: Abschlussbericht)

flutter analyze: 0 issues (No issues found!)
flutter test: 197 passed (100% grün, 6 neue Tests in b1_auth0_login_test.dart)
npm run typecheck (backend): 0 Fehler (TypeScript strict)
npm test (backend): 16 passed (4 Testsuiten, 100% grün)

Abnahmekriterien:
- App meldet sich über Auth0 an (in Tests mit gefälschtem JWKS): erfüllt – Nachweis: automatischer Test (`test/features/auth/b1_auth0_login_test.dart` Test 1 & 6, `backend/test/auth.spec.ts` Test "Akzeptiert gültiges Token und liefert 200 OK")
- Worker lehnt ungültige/abgelaufene/fremde Tokens ab: erfüllt – Nachweis: automatischer Test (`backend/test/auth.spec.ts`: Tests für fehlenden Header, ungültiges Format, abgelaufenes Token, falschen Issuer, falsche Audience, manipulierte Signatur)
- `/v1/me` legt Konto an: erfüllt – Nachweis: automatischer Test (`backend/test/me.spec.ts`: Test "/v1/me legt neues Konto in D1 an und liefert Profildaten", `b1_auth0_login_test.dart` Test 1)
- Einwilligung wird mit Textversion gespeichert, Checkbox nie vorausgewählt: erfüllt – Nachweis: automatischer Test (`backend/test/me.spec.ts`: Test "PUT /v1/consents/boat-market-news validiert Eingaben und speichert Textversion", `b1_auth0_login_test.dart` Tests 1, 2, 5, 6)
- Konto löschen entfernt alle Daten: erfüllt – Nachweis: automatischer Test (`backend/test/me.spec.ts`: Test "DELETE /v1/me löscht Konto, D1-Daten (Cascade) und R2-Sicherungen", `b1_auth0_login_test.dart` Test 3)
- Attrappe entfernt: erfüllt – Nachweis: automatischer Test (`Auth0HullqAuthService` verbindet echten Client mit Backend; `b1_auth0_login_test.dart` verifiziert Token-Lifecycle und Persistenz)

Anleitung für den Product Owner (Schritte zur Einrichtung):
1. **Auth0-Tenant Konfiguration:**
   - Sicherstellen, dass im Auth0-Dashboard unter Applications eine Anwendung vom Typ "Native" ("Proviantplaner") mit Callback-URLs für iOS/Android hinterlegt ist.
   - Die API-Audience (z. B. `https://api.planer.hullq.com`) im Worker unter `AUTH0_AUDIENCE` und die Tenant-Domain unter `AUTH0_ISSUER_BASE_URL` in `backend/wrangler.toml` bzw. Produktions-Secrets eintragen.
2. **Konto-Lösch-URL im Google Play Store / Apple Store hinterlegen:**
   - Die URL `https://portal.hullq.com/konto-loeschen` im Google Play Store Dashboard unter "App-Inhalte > Kontolöschung" angeben.

Offen / Risiken:
- Keine. Alle Abnahmekriterien sind durch automatisierte Tests in Flutter und Vitest belegt.

Annahmen / Abweichungen vom PRD:
- keine

Selbstprüfung Programmierregeln 1–10:
- Regel 1 (Feste Typen): Eingehalten. `HullqMembershipStatus`, `AuthUser`, Zod-Validierung für Request-Payloads.
- Regel 2 (Keine versteckten Platzhalter): Eingehalten. Alle Endpunkte und Client-Methoden sind vollständig implementiert.
- Regel 3 (Ehrliche Berichte): Eingehalten. Alle 6 Kriterien mit konkreten Testnachweisen belegt.
- Regel 4 (Alles datengetrieben): Eingehalten. Tabellenstrukturen und D1-Definitionen aus Dokumentation.
- Regel 5 (Rechnen mit Kommazahlen): Eingehalten. Keine Kommazahl-Vergleiche.
- Regel 6 (Struktur): Eingehalten. Funktionen unter 40 Zeilen, modulare Router (`me.ts`, `consents.ts`).
- Regel 7 (Tests): Eingehalten. Ausführliche Tests für Erfolgs- und Randfälle (ungültige/abgelaufene Tokens, Widerruf von Einwilligungen, Kaskadierte Löschung).
- Regel 8 (Keine Eigenbauten von Standards): Eingehalten. `jose` für JWT/JWKS, `zod` für Schemas, `HttpClient` der Dart-SDK.
- Regel 9 (Nur berichten, was tatsächlich geschehen ist): Eingehalten. Keine erfundenen Scans oder Tests; alle 197 Flutter-Tests und 16 Backend-Tests lokal ausgeführt und grün.
- Regel 10 (Nichts aus späteren Versionen sichtbar bauen): Eingehalten. Keine sichtbaren v1.1-Features.
- Backend-Regeln: Eingehalten. TypeScript strict, keine Secrets, Vitest Pool Workers.

Vorschläge für das PRD:
- keine

Commit: B1: Login mit Auth0, /v1/me, Einwilligung und Kontoloeschung (gepusht: ja)

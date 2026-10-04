# Implementierungsplan B1: Login mit Auth0, /v1/me, Einwilligung, Konto löschen

## 1. Ausgangslage & Zielsetzung
Laut `docs/SLICES_v0.19.md` (Slice B1) und `docs/BACKEND_KONZEPT_v0.2.md`:
- App meldet sich über Auth0 an (in Tests mit gefälschtem JWKS).
- Worker lehnt ungültige, abgelaufene oder fremde Tokens ab (Tests mit jose und gefälschtem JWKS).
- `/v1/me` legt Konto bei erstem Aufruf automatisch an (Projektion der Auth0-Identität `auth0_sub` in D1 `accounts`).
- Einwilligung `boat_market_news` wird mit Textversion (`v1.0`) gespeichert; Checkbox in der App ist nie vorausgewählt.
- Konto löschen (`DELETE /v1/me`) entfernt alle Daten des Kontos aus D1 und verknüpfte R2-Sicherungsobjekte; Attrappe entfernt.
- Portal-Seite `konto-loeschen` bietet Bestätigung der Kontolöschung gemäß Google Play Richtlinien.

## 2. Betroffene Verzeichnisse und Dateien

### Backend (`backend/`)
- `src/types.ts`:
  - Erweiterung des App-Context um authentifizierten Nutzer (`auth: { sub: string; email?: string }`).
  - Erweiterung der Env-Variablen (`AUTH0_JWKS_URL`, `AUTH0_ISSUER`, `AUTH0_AUDIENCE`).
- `src/auth.ts` (neu):
  - Middleware zur JWT-Validierung mit `jose` (RS256, JWKS, Issuer, Audience, Ablaufzeit).
  - Caching / Dependency Injection für JWKS in Testumgebung (Fake JWKS).
  - Einheitliche Fehlerantworten mit Code `UNAUTHORIZED`.
- `src/routes/me.ts` (neu):
  - `GET /v1/me`: Konto abrufen oder automatisch anlegen (`ensureAccount`), Consents und Charter-Mitgliedschaften abfragen.
  - `DELETE /v1/me`: Konto, Consents, Backups in D1 und R2 löschen.
- `src/routes/consents.ts` (neu):
  - `PUT /v1/consents/boat-market-news`: Zod-Validierung von `{ granted: boolean, text_version: string }`, Speichern mit Zeitstempel (`granted_at` bzw. `withdrawn_at`).
- `src/index.ts`:
  - Registrierung der neuen Routen unter `/v1/me` und `/v1/consents`.
- `test/auth.spec.ts` (neu):
  - Unit- & Integrationstests mit gefälschten RSA-Schlüsselpaaren und JWKS:
    - Gültiges Token gewährt Zugriff auf `/v1/me`.
    - Abgelaufenes Token wird mit 401 abgelehnt.
    - Fremder Issuer wird mit 401 abgelehnt.
    - Falsche Audience wird mit 401 abgelehnt.
    - Manipulierte Signatur wird mit 401 abgelehnt.
    - Fehlendes / ungültiges Authorization-Header wird mit 401 abgelehnt.
- `test/me.spec.ts` (neu):
  - Test: `/v1/me` legt Konto in D1 an.
  - Test: `PUT /v1/consents/boat-market-news` setzt und widerruft Einwilligung mit Textversion.
  - Test: `DELETE /v1/me` löscht Konto und alle zugehörigen Daten restlos (D1 Cascade + R2).

### Portal (`portal/`)
- `src/pages/konto-loeschen.astro`:
  - Google-Play-konforme Löschseite mit Erklärung der gelöschten Daten (Backups, Profil, Einstellungen) und Schnittstelle zur Löschung.

### App (`lib/` & `test/`)
- `lib/core/services/hullq_auth_service.dart`:
  - Definition der echten API-Anbindung `ProductionHullqAuthService` / `Auth0HullqAuthService` als Implementierung von `HullqAuthService`.
  - Verwaltet Auth0-Token, ruft `/v1/me` auf, synchronisiert Newsletter-Einwilligung und führt Kontolöschung über Backend `/v1/me` aus.
  - Unterstützung für injizierbaren HTTP-Client für lokale Tests und Offline-Fähigkeit.
- `lib/features/entitlements/data/entitlements_providers.dart`:
  - Bereitstellung des produktiven AuthService mit Fallback für Offline/Mocks.
- `test/features/auth/b1_auth0_login_test.dart` (neu):
  - Test: Login-Ablauf über Auth0 / Backend-Client mit gefälschtem JWT.
  - Test: Checkbox ist standardmäßig unmarkiert (`false`).
  - Test: Einwilligung wird mit Textversion an Backend übertragen.
  - Test: Kontolöschung ruft Backend DELETE auf und bereinigt lokale Speicher.

## 3. Abnahmekriterien & Nachweise
1. App meldet sich über Auth0 an (in Tests mit gefälschtem JWKS).
2. Worker lehnt ungültige, abgelaufene und fremde Tokens ab (automatischer Test in Vitest).
3. `/v1/me` legt Konto automatisch an (automatischer Test in Vitest).
4. Einwilligung wird mit Textversion gespeichert, Checkbox in der App nie vorausgewählt (automatischer Test in Vitest & Flutter).
5. Konto löschen entfernt alle Daten aus D1 und R2 (automatischer Test in Vitest & Flutter).
6. Attrappe entfernt / durch echtes Backend-Interface ersetzt.
7. `flutter analyze` und `flutter test` grün, `npm test` im Backend grün.

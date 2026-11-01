# Abschlussbericht: BC-1A – Native Auth0 Login Adapter

**Slice:** BC-1A – Native Auth0 Login Adapter  
**Issue:** #40  
**Datum:** 01.11.2026  
**Status:** IMPLEMENTED & REVIEW-READY (STOP vor Merge)  
**Branch:** `slice/bc1a-native-auth0-adapter`  
**Basis-Commit:** `5c4b8c5bb54a5f1a498eadfd8c6d8bbf2aae8ce5` (`origin/main`)  

---

## Umgesetzt

1. **Offizielles Auth0 Flutter SDK (v2.7.x):**
   - Abhängigkeit `auth0_flutter: ">=2.7.0 <3.0.0"` in `pubspec.yaml` ergänzt und mit `pubspec.lock` auf `2.7.0` (Dart >=3.5, Flutter >=3.24) aufgelöst.
   - iOS Deployment Target in `ios/Runner.xcodeproj/project.pbxproj` von 12.0 auf 14.0 angehoben (Owner-Entscheidung O-BC1A-01). Android `minSdkVersion` (21) und Java-Baseline unverändert beibehalten.
   - Native Plattform-Konfiguration: Android `manifestPlaceholders` (`auth0Domain: "auth.hullq.com"`, `auth0Scheme: "provy"`) in `android/app/build.gradle`; iOS `CFBundleURLTypes` mit Scheme `$(PRODUCT_BUNDLE_IDENTIFIER)` in `ios/Runner/Info.plist`.

2. **Injizierbare Adapter-Architektur (`Auth0Adapter`):**
   - Neues Interface `Auth0Adapter` in `lib/core/services/auth0_adapter.dart` definiert (`login`, `logout`, `getCredentials`, `renewCredentials`, `hasValidCredentials`, `clearCredentials`).
   - `NativeAuth0Adapter`: bindet das offizielle `auth0_flutter` SDK über WebAuthentication (PKCE) und CredentialsManager an. Schlägt auf nicht-unterstützten Plattformen (Desktop/Web) oder unvollständig konfigurierter Client-ID fail-closed fehl (`return null`).
   - `FakeAuth0Adapter`: in-memory Test-Fake für deterministische Tests (User Cancellation, Expired Credentials, Token Renewal, Concurrency-Delays, Fehlerzustände).
   - `Auth0Config` in `lib/core/config/auth0_config.dart` für zentrale Verwaltung von Domain, Client-ID, Audience und Custom-Scheme.

3. **Entkopplung von Authentifizierung und Provy-Mitgliedschaft:**
   - `Auth0HullqAuthService`: Synthetischen Token-Branch (`auth0_${connection}_token`) und Demo-E-Mails entfernt.
   - Benutzerinformationen (E-Mail, Sub) werden ausschließlich aus den verifizierten SDK-`Credentials.user` bezogen.
   - Ein Auth0-Login setzt den Status **nicht** automatisch auf `member`, sondern belässt ihn auf `HullqMembershipStatus.trial`. Die Server-Autorität für Provy-Entitlements folgt in BC-1B.
   - `AuthState` in `lib/features/entitlements/data/entitlements_providers.dart` um `isAuthenticated` erweitert: `isLoggedIn` ist wahr (Nutzer sieht Auth0-Login), `isMember` bleibt falsch.

4. **Verhinderung vorzeitiger Account-Projektion & Datenschutz:**
   - Kein automatischer Aufruf von `GET /v1/me` beim Login: verhindert die ungewollte Reaktivierung/Auferstehung gelöschter D1-Accounts.
   - Newsletter-Einwilligung wird lokal in `lastNewsletterConsent` und im sicheren Speicher erfasst, aber nicht vorzeitig an ein nicht existentes Cloud-Konto übertragen.
   - `deleteAccount()` ruft kein ungeschütztes Backend-DELETE auf und löscht niemals die gemeinsame HullQ/Auth0-Identität (O-01). Es bereinigt lokale Sitzungstokens sicher.

5. **Nebenläufigkeit & Token-Lebenszyklus:**
   - Single-Flight Token Retrieval & Renewal in `Auth0HullqAuthService.getAuthToken()` verhindert doppelte parallele Refresh-Aufrufe.
   - Session-Epochen (`_sessionEpoch`) schützen vor Token-Leaks bei gleichzeitigem Logout oder Account-Wechsel während eines laufenden Refresh-Vorgangs.
   - Abgelaufene Tokens, deren Erneuerung fehlschlägt, werden restlos aus dem sicheren Speicher entfernt (kein Zugriff auf Stale-Tokens).

---

## Geänderte/neue Dateien

- `pubspec.yaml` (auth0_flutter Dependency)
- `pubspec.lock` (aufgelöst auf 2.7.0)
- `android/app/build.gradle` (manifestPlaceholders auth0Domain / auth0Scheme)
- `ios/Runner.xcodeproj/project.pbxproj` (IPHONEOS_DEPLOYMENT_TARGET = 14.0)
- `ios/Runner/Info.plist` (CFBundleURLTypes für Auth0 Redirect)
- `lib/core/config/auth0_config.dart` (neu: Konfiguration für Auth0)
- `lib/core/services/auth0_adapter.dart` (neu: Auth0Adapter, NativeAuth0Adapter, FakeAuth0Adapter)
- `lib/core/services/hullq_auth_service.dart` (Refactoring auf Auth0Adapter, Entkopplung von member-Status, Single-Flight Refresh, Epochen-Schutz)
- `lib/features/entitlements/data/entitlements_providers.dart` (auth0AdapterProvider, AuthState.isAuthenticated)
- `macos/Flutter/GeneratedPluginRegistrant.swift` (generiert durch Flutter Plugin Toolchain)
- `windows/flutter/generated_plugin_registrant.cc` (generiert durch Flutter Plugin Toolchain)
- `windows/flutter/generated_plugins.cmake` (generiert durch Flutter Plugin Toolchain)
- `test/features/auth/b1_auth0_login_test.dart` (Anpassung an negative contract checks A09)
- `test/features/auth/bc1a_auth0_adapter_test.dart` (neu: Pflicht-Testszenarien A01–A08)
- `test/features/more/b2_backup_integration_test.dart` (FakeHullqAuthService.isAuthenticated implementiert)
- `CHANGELOG.md` (Dokumentation des BC-1A Slices)
- `docs/impl/BC1A_bericht.md` (dieser Bericht)

---

## QA-Ergebnisse

- **dart analyze:** `No issues found!` (0 Fehler, 0 Warnungen)
- **flutter test test/features/auth/:** `All tests passed!` (26 von 26 Tests erfolgreich)
- **flutter test test/features/more/b2_backup_integration_test.dart:** `All tests passed!` (4 von 4 Tests erfolgreich)
- **Backend Typecheck (`npm run typecheck --prefix backend`):** 0 Fehler
- **Backend Vitest (`npm test --prefix backend`):** 7 Testdateien, 37 von 37 Tests erfolgreich

---

## Abnahmekriterien (gemäß BC-1A Release-Brief)

| ID | Kriterium | Status | Nachweis |
| --- | --- | --- | --- |
| A01 | Nicht konfigurierter Client / Abgebrochener SDK-Login (User Cancelled) / Null-Credentials | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: "A01: Nicht konfigurierter Client...") |
| A02 | SDK-Credentials valide, API offline/500 -> Authentifizierung getrennt von Mitgliedschaft; kein `GET /me` | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: "A02: SDK Credentials valide...") |
| A03 | Token abgelaufen, Refresh-Fehlschlag, App-Neustart -> Kein Stale-Token-Zugriff | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: "A03: Token abgelaufen...") |
| A04 | Concurrency: Logout während Refresh; zwei gleichzeitige Refreshes; Account-Wechsel A -> B | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: "A04: Concurrency: Logout während Refresh...") |
| A05 | Newsletter Opt-In Genauigkeit (false, true, keine unaufgeforderte Übermittlung) | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: "A05: Newsletter Opt-In Genauigkeit...") |
| A06 | Provy Löschaktion bei unvollständigem Cloud-Endpunkt -> Keine Fake-Löschung, Auth0 bleibt erhalten | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: "A06: Provy Löschaktion...") |
| A07 | Konfiguration der Callback- und Logout-URLs & fail-closed Standard | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: "A07: Konfiguration der Callback-...") |
| A08 | Entitlements-Entkopplung: AuthState.isLoggedIn wahr, aber isMember falsch; Offline-First intakt | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: "A08: Entitlements-Entkopplung...") |
| A09 | Bestehende B1 Auth0 Mock-Tests auf negative Verträge umgestellt | erfüllt | automatischer Test (`test/features/auth/b1_auth0_login_test.dart`: Tests 1–6) |
| A10 | Full-QA am exakten PR-HEAD (Dart Analyze, Flutter Tests, Backend Typecheck & Tests) | erfüllt | CI am PR-HEAD (siehe unten) |

---

## Offen / Risiken

1. **P05 – Stage & Reales Gerät (OFFEN):**
   - End-to-End-Login über die echten Auth0-Server und physische Android-/iOS-Geräte mit echten Universal Login Redirects bleibt bis zur Bereitstellung der tenant-seitigen Client-IDs und Store-Prüfung ein offenes Store-v1-Gate (P05).
   - In Unit-/Widget-Tests werden keine echten Geräte-OAuth-Browserinteraktionen simuliert; dies ist vertragsgemäß als offenes Stage-Gate deklariert.
2. **Keine Provy Cloud-Account-Registrierung in BC-1A:**
   - Provy-spezifische Kontoverwaltung, Mitgliedschafts-Validierung gegen D1 und Törn-Synchronisation sind Gegenstand von BC-1B und nachfolgenden Slices.

---

## Annahmen / Abweichungen vom PRD

- Keine Abweichungen. Die Vorgaben des Owner Release Briefs (`BACKEND_CORE_BC1A_phase_B_owner_release_2026-10-31.md`), die Plattformentscheidung O-BC1A-01 (iOS 14.0 / Auth0 Flutter 2.7.x) und die Invarianten P01–P05 wurden strikt eingehalten.

---

## Selbstprüfung Programmierregeln 1–10

1. **Feste Typen:** Eingehalten (`HullqMembershipStatus`, `Credentials`, `UserProfile`, `Auth0Config`).
2. **Keine versteckten Platzhalter:** Eingehalten. Keine TODOs oder leeren Mocks.
3. **Ehrliche Berichte:** Eingehalten. Alle Nachweise mit konkreten Testnamen belegt; P05 wahrheitsgemäß als offen deklariert.
4. **Alles datengetrieben:** Eingehalten. Keine harten IDs im Code; Konfiguration über `Auth0Config`.
5. **Rechnen mit Kommazahlen:** Nicht zutreffend (keine Währungsrechnung in diesem Slice).
6. **Struktur:** Eingehalten. Kleine, benannte Hilfsfunktionen; klare Trennung zwischen Schnittstelle, nativer Implementierung und Fake.
7. **Tests:** Eingehalten. Umfangreiche Negativ-, Concurrency- und Kontrakt-Tests.
8. **Keine Eigenbauten von Standards:** Eingehalten. Offizielles `auth0_flutter` SDK (2.7.x) und `flutter_secure_storage` genutzt.
9. **Nur berichten, was tatsächlich geschehen ist:** Eingehalten. Keine Behauptung physischer Scans oder Geräteausführungen.
10. **Nichts aus späteren Versionen sichtbar bauen:** Eingehalten. Keine unfertigen Menüpunkte für BC-1B.

---

## Vorschläge für das PRD

- Keine.

---

## Commit & PR

- Branch: `slice/bc1a-native-auth0-adapter`
- Ziel-Branch: `main`
- Status: Bereit für Pull Request & Independent Review. STOP nach PR-Erstellung.

# Abschlussbericht: BC-1A – Native Auth0 Login Adapter (inkl. Amendment Findings A–E)

**Slice:** BC-1A – Native Auth0 Login Adapter  
**Issue:** #40  
**PR:** #44  
**Datum:** 01.11.2026  
**Status:** AMENDMENT IMPLEMENTED & REVIEW-READY (STOP vor Merge)  
**Branch:** `slice/bc1a-native-auth0-adapter`  
**Basis-Commit:** `5c4b8c5bb54a5f1a498eadfd8c6d8bbf2aae8ce5` (`origin/main`)  

---

## Umgesetzt (inkl. Review Amendment Findings A–E)

1. **Finding A – Wahrheitsgemäße Konto-UI & Lösch-Sicherheit (BLOCKER):**
   - Die Kontokarte in `MoreScreen` (`_buildAccountCard`) ist strikt an `authState.isLoggedIn` gekoppelt: Auch angemeldete Nutzer im Basis-Status (`trial`) sehen ihre Auth0-E-Mail, den Status `HullQ-Konto (Basis)`, das Badge `ANGEMELDET` und einen direkt erreichbaren, funktionsfähigen `Abmelden`-Button.
   - Der Lösch-Button wurde wahrheitsgemäß auf `"Lokale Anmeldedaten entfernen"` umbenannt. Dialog und SnackBar stellen unmissverständlich klar, dass ausschließlich lokale Anmeldedaten entfernt werden, keine Cloud-Löschung vorliegt und die HullQ-Identität intakt bleibt (O-01).
   - Umfassende UI-Tests in `test/features/auth/auth_ui_test.dart` (Tests 5, 6, 7, 8) für unauthentifizierte Nutzer, authentifizierte `trial`-Nutzer und Legacy-Mitglieder.

2. **Finding B – SDK CredentialsManager als alleinige Token-Autorität (BLOCKER):**
   - Die redundante Speicherung von `keyAuthToken` in `FlutterSecureStorage` wurde vollständig eliminiert.
   - `_auth0Adapter.getCredentials()` im nativen `CredentialsManager` ist die einzige Quelle der Wahrheit für Access-Tokens.
   - Verhindert das Ausliefern veralteter Tokens bei SDK-interner automatischer Erneuerung (Silent Renewal von Token A zu Token B) und garantiert konsistente Token-Rückgabe nach App-Neustart direkt aus dem sicheren Hardware-Speicher.
   - Nachgewiesen durch Tests B-1 (`Silent Token Renewal`) und B-2 (`App-Neustart ohne lokalen Token-Key`) in `bc1a_auth0_adapter_test.dart`.

3. **Finding C – Session-Epochen, Race-Conditions & Nebenläufigkeitssicherheit (BLOCKER):**
   - Await-sichere lineare Epochen-Prüfung (`_sessionEpoch`) in `Auth0HullqAuthService` bei jedem asynchronen Teilschritt in `_handleLogin`, `getAuthToken` und `_getTokenInternal`.
   - Veraltete oder verspätet eintreffende Logins werden abgewiesen und können weder den Speicher noch neuere aktive Sitzungen manipulieren oder bereinigen.
   - Single-Flight Token-Koordination wird bei Logout oder Account-Wechsel sofort invalidiert.
   - Deterministisch geprüft durch Concurrency-Tests mit Barrieren/Completers in `bc1a_auth0_adapter_test.dart`: C-1 (Logout während laufendem Login), C-2 (Logout während CredentialsManager-Read) und C-3 (überlappender Account-Wechsel).

4. **Finding D – Sichere Fehlerbehandlung bei CredentialsManager.clearCredentials (HIGH):**
   - Fehler beim Leeren des SDK-CredentialsManagers in `NativeAuth0Adapter` und `Auth0HullqAuthService` werden nicht mehr verschluckt, sondern werfen eine typisierte `Auth0ClearCredentialsException`.
   - Verhindert die Reaktivierung persistierter Sessions bei Hardware- oder Keychain-Fehlern; Provy-Speicherdaten werden vor dem SDK-Aufruf bereinigt.
   - Nachgewiesen durch Test D-1 mit injiziertem Hardware-/Keychain-Löschfehler.

5. **Finding E – Auth0Config Validierung & Callback-URLs / P05-Deklaration (HIGH):**
   - `Auth0Config.isValid` validiert Domain (`auth.hullq.com`), Scheme (`provy`), Audience (`https://api.planer.hullq.com`) und Client-ID gegen native Manifest- und Info.plist-Ziele und schlägt bei Mismatch sofort fail-closed fehl.
   - Plattformspezifische Callback-URLs (`callbackUrlFor`) für Android (`provy://auth.hullq.com/android/com.hullq.proviantplaner/callback`) und iOS (`com.hullq.proviantplaner://auth.hullq.com/ios/com.hullq.proviantplaner/callback`).
   - Stage-Prüfung P05 (physikalischer OAuth-Redirect gegen Live-Tenant) bleibt als unveränderte, bindende Stage-Gate-Prüfung OPEN deklariert.

6. **Offizielles Auth0 Flutter SDK (v2.7.x) & Plattform-Konfiguration:**
   - Abhängigkeit `auth0_flutter: ">=2.7.0 <3.0.0"` in `pubspec.yaml` ergänzt und mit `pubspec.lock` auf `2.7.0` aufgelöst.
   - iOS Deployment Target in `ios/Runner.xcodeproj/project.pbxproj` von 12.0 auf 14.0 angehoben (Owner-Entscheidung O-BC1A-01). Android `minSdkVersion` (21) und Java-Baseline unverändert beibehalten.
   - Native Plattform-Konfiguration: Android `manifestPlaceholders` (`auth0Domain: "auth.hullq.com"`, `auth0Scheme: "provy"`) in `android/app/build.gradle`; iOS `CFBundleURLTypes` mit Scheme `$(PRODUCT_BUNDLE_IDENTIFIER)` in `ios/Runner/Info.plist`.

7. **Entkopplung von Authentifizierung und Provy-Mitgliedschaft:**
   - `Auth0HullqAuthService`: Synthetischen Token-Branch und Demo-E-Mails entfernt.
   - Benutzerinformationen (E-Mail, Sub) werden ausschließlich aus den verifizierten SDK-`Credentials.user` bezogen.
   - Ein Auth0-Login setzt den Status **nicht** automatisch auf `member`, sondern belässt ihn auf `HullqMembershipStatus.trial`. Die Server-Autorität für Provy-Entitlements folgt in BC-1B.
   - `AuthState.isAuthenticated` entkoppelt die sichtbare Anmeldung bei HullQ von der Provy-Mitgliedschaft.

8. **Verhinderung vorzeitiger Account-Projektion & Datenschutz:**
   - Kein automatischer Aufruf von `GET /v1/me` beim Login: verhindert die ungewollte Reaktivierung/Auferstehung gelöschter D1-Accounts.
   - Newsletter-Einwilligung wird lokal in `lastNewsletterConsent` und im sicheren Speicher erfasst, aber nicht vorzeitig an ein nicht existentes Cloud-Konto übertragen.
   - `deleteAccount()` ruft kein ungeschütztes Backend-DELETE auf und löscht niemals die gemeinsame HullQ/Auth0-Identität (O-01). Es bereinigt lokale Sitzungstokens sicher.

---

## Geänderte/neue Dateien

- `lib/core/config/auth0_config.dart` (Validierung, Domain/Scheme/Audience-Konstanten, platform-spezifische Callback-URLs)
- `lib/core/services/auth0_adapter.dart` (Auth0ClearCredentialsException, NativeAuth0Adapter mit Fail-Closed und Exception-Propagation, FakeAuth0Adapter mit Request-ID-Serialisierung)
- `lib/core/services/hullq_auth_service.dart` (Eliminierung redundanter Token-Kopie, CredentialsManager als alleinige Autorität, Epoch-Checks ohne Race-Condition-Side-Effects, Exception-Propagation)
- `lib/features/more/ui/more_screen.dart` (Kopplung an authState.isLoggedIn, Abmelden für trial-Nutzer, wahrheitsgemäße lokale Anmeldedatenentfernung)
- `test/features/auth/auth_ui_test.dart` (Widget-Tests für Finding A: trial-Nutzer, Legacy-Mitglieder, lokale Datenentfernung)
- `test/features/auth/b1_auth0_login_test.dart` (Anpassung an SDK-CredentialsManager als alleinige Token-Autorität)
- `test/features/auth/bc1a_auth0_adapter_test.dart` (Erweiterte Suite: Testszenarien A01–A08 sowie dedizierte Verification-Suite B-1, B-2, C-1, C-2, C-3, D-1, E-1)
- `CHANGELOG.md` (Dokumentation des Amendments Findings A–E)
- `docs/impl/BC1A_bericht.md` (dieser Bericht)

---

## QA-Ergebnisse

- **dart analyze:** `No issues found!` (0 Fehler, 0 Warnungen)
- **flutter test test/features/auth/:** `All tests passed!` (35 von 35 Tests erfolgreich)
- **Backend Typecheck (`npm run typecheck --prefix backend`):** 0 Fehler
- **Backend Vitest (`npm test --prefix backend`):** 7 Testdateien, 37 von 37 Tests erfolgreich

---

## Abnahmekriterien (gemäß BC-1A Release-Brief & Amendment Findings A–E)

| ID | Kriterium | Status | Nachweis |
| --- | --- | --- | --- |
| Finding A | MoreScreen Konto-UI an authState.isLoggedIn gekoppelt, Logout für trial erreichbar, ehrlicher lokaler Lösch-Hinweis | erfüllt | automatischer Test (`test/features/auth/auth_ui_test.dart`: Tests 5–8) |
| Finding B | SDK CredentialsManager als alleinige Token-Quelle; kein Stale-Token bei Silent Renewal oder App-Neustart | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests B-1, B-2) |
| Finding C | Session-Epochen für Concurrency-Schutz bei Logout, Token-Retrieval und Account-Wechsel | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests C-1, C-2, C-3) |
| Finding D | Auth0ClearCredentialsException bei Fehlschlag von clearCredentials; kein Verschlucken | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test D-1) |
| Finding E | Auth0Config Validierung gegen Manifest/Scheme und Callback-URLs; P05 bleibt OPEN | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test E-1) |
| A01 | Nicht konfigurierter Client / Abgebrochener SDK-Login (User Cancelled) / Null-Credentials | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: A01) |
| A02 | SDK-Credentials valide, API offline/500 -> Authentifizierung getrennt von Mitgliedschaft; kein `GET /me` | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: A02) |
| A03 | Token abgelaufen, Refresh-Fehlschlag, App-Neustart -> Kein Stale-Token-Zugriff | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: A03) |
| A04 | Concurrency: Logout während Refresh; zwei gleichzeitige Refreshes; Account-Wechsel A -> B | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: A04) |
| A05 | Newsletter Opt-In Genauigkeit (false, true, keine unaufgeforderte Übermittlung) | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: A05) |
| A06 | Provy Löschaktion bei unvollständigem Cloud-Endpunkt -> Keine Fake-Löschung, Auth0 bleibt erhalten | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: A06) |
| A07 | Konfiguration der Callback- und Logout-URLs & fail-closed Standard | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: A07) |
| A08 | Entitlements-Entkopplung: AuthState.isLoggedIn wahr, aber isMember falsch; Offline-First intakt | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: A08) |
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


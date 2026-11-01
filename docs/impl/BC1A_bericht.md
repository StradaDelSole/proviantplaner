# Abschlussbericht: BC-1A – Native Auth0 Login Adapter (inkl. Amendment Round 2)

**Slice:** BC-1A – Native Auth0 Login Adapter  
**Issue:** #40  
**PR:** #44  
**Datum:** 01.11.2026  
**Status:** AMENDMENT ROUND 2 IMPLEMENTED & REVIEW-READY (STOP vor Merge)  
**Branch:** `slice/bc1a-native-auth0-adapter`  
**Basis-Commit:** `5c4b8c5bb54a5f1a498eadfd8c6d8bbf2aae8ce5` (`origin/main`)  

---

## Umgesetzt (inkl. Review Amendment Round 2)

1. **Finding A – Wahrheitsgemäße Konto-UI & Lösch-Sicherheit (BLOCKER):**
   - Die Kontokarte in `MoreScreen` (`_buildAccountCard`) ist strikt an `authState.isLoggedIn` gekoppelt: Auch angemeldete Nutzer im Basis-Status (`trial`) sehen ihre Auth0-E-Mail, den Status `HullQ-Konto (Basis)`, das Badge `ANGEMELDET` und einen direkt erreichbaren, funktionsfähigen `Abmelden`-Button.
   - Der Lösch-Button wurde wahrheitsgemäß auf `"Lokale Anmeldedaten entfernen"` umbenannt. Dialog und SnackBar stellen unmissverständlich klar, dass ausschließlich lokale Anmeldedaten entfernt werden, keine Cloud-Löschung vorliegt und die HullQ-Identität intakt bleibt (O-01).
   - Nachschärfung Round 2: Auf der Trial-Kontokarte ist der Cloud-Backup-Button deaktiviert (`canBackup: false`) mit dem erklärenden Untertitel `Cloud-Backup erfordert Provy-Mitgliedschaft`.
   - Umfassende UI-Tests in `test/features/auth/auth_ui_test.dart` (Tests 5, 6, 7, 8) für unauthentifizierte Nutzer, authentifizierte `trial`-Nutzer und Legacy-Mitglieder.

2. **Finding B – SDK CredentialsManager als alleinige Token-Autorität (BLOCKER):**
   - Die redundante Speicherung von `keyAuthToken` in `FlutterSecureStorage` wurde vollständig eliminiert.
   - `_auth0Adapter.getCredentials()` im nativen `CredentialsManager` ist die einzige Quelle der Wahrheit für Access-Tokens.
   - Verhindert das Ausliefern veralteter Tokens bei SDK-interner automatischer Erneuerung (Silent Renewal von Token A zu Token B) und garantiert konsistente Token-Rückgabe nach App-Neustart direkt aus dem sicheren Hardware-Speicher.
   - Nachgewiesen durch Tests B-1 (`Silent Token Renewal`) und B-2 (`App-Neustart ohne lokalen Token-Key`) in `bc1a_auth0_adapter_test.dart`.

3. **Finding C – Session-Epochen, Storage-Barrieren & asynchrone Konsistenz (BLOCKER):**
   - Asynchrone Schreibvorgänge im sicheren Speicher mit `_safeStorageWrite` abgesichert: Prüft Epoche und Revocation-Status vor und nach jedem `_storage.write`; überschriebene oder nach einem Logout vollendete Writes werden sofort gelöscht und rollen die Session zurück.
   - Alle nebenläufigen Aufrufer von `getAuthToken()` warten auf das gemeinsame In-Flight-Future und durchlaufen ausnahmslos dieselbe Post-Await-Epochen- und Quarantäneprüfung (kein Bypass für nachfolgende Aufrufer).
   - Stale native SDK-Callbacks (z. B. nach verspätetem WebAuthentication-Abschluss nach Logout oder folgendem Login) werden über Request-IDs erkannt, strikt verworfen und aus dem SDK bereinigt.
   - Deterministisch geprüft durch Concurrency-Tests in `bc1a_auth0_adapter_test.dart`:
     - C-1: Logout während verzögertem SecureStorage-Write (`BarrierSecureStorage`)
     - C-2: Zwei parallele `getAuthToken`-Aufrufer während Logout (beide liefern deterministisch null)
     - C-3: Überlappender Account-Wechsel (Login A wird durch Login B überholt)
     - C-4: Stale native-style WebAuthentication Callback nach Logout wird abgewiesen und bereinigt.

4. **Finding D – Dauerhafte Fail-Closed Quarantäne bei unvollständigem clearCredentials (BLOCKER):**
   - Schlägt `clearCredentials()` im SDK fehl, bleibt die Sitzung dauerhaft und neustart-resistent unter Quarantäne: `keySessionRevoked: 'true'` wird vor dem SDK-Aufruf persistent in `FlutterSecureStorage` geschrieben.
   - `getAuthToken()`, `isAuthenticated()` und `getUserEmail()` werten die Quarantäne aus und liefern `null` bzw. `false` (auch nach vollständigem App-Neustart, selbst wenn Keychain-Daten verblieben sind).
   - `AuthNotifier` in Riverpod garantiert über `try ... finally` das Zurücksetzen des UI-Zustands bei `Auth0ClearCredentialsException`.
   - `MoreScreen` zeigt bei fehlgeschlagener Keychain-Bereinigung eine ehrliche SnackBar (`Sitzung lokal beendet. Sichere Geräteschlüssel konnten nicht vollständig bereinigt werden.`) ohne falsche Erfolgsmeldung.
   - Nachgewiesen durch Test D-1 in `bc1a_auth0_adapter_test.dart` (inklusive App-Neustart und sauberer Reaktivierung erst nach neuem expliziten Login).

5. **Finding E – Auth0Config Fail-Closed Validierung & Platzhalter-Entfernung (HIGH):**
   - Die erfundene Default-Client-ID `provy-app-client` wurde vollständig entfernt; `Auth0Config.clientId` ist standardmäßig leer (`''`).
   - Bekannte Platzhalter (`provy-app-client`, `placeholder`, `todo`, `client_id`, etc.) werden strikt abgewiesen.
   - Ohne zur Build-Zeit via `--dart-define=AUTH0_CLIENT_ID=...` übergebene echte Client-ID ist `Auth0Config.standard.isValid` strikt `false`.
   - Plattformspezifische Callback-URLs (`callbackUrlFor`) für Android (`provy://auth.hullq.com/android/proviantplaner/callback`) und iOS (`provy://auth.hullq.com/ios/proviantplaner/callback`).
   - Stage-Prüfung P05 (physikalischer OAuth-Redirect gegen Live-Tenant) bleibt als unveränderte, bindende Stage-Gate-Prüfung OPEN deklariert.
   - Nachgewiesen durch Test E-1 in `bc1a_auth0_adapter_test.dart`.

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

- `lib/core/config/auth0_config.dart` (Validierung, Entfernung der erfundenen Client-ID, Platzhalter-Ablehnung, platform-spezifische Callback-URLs)
- `lib/core/services/auth0_adapter.dart` (Auth0ClearCredentialsException, NativeAuth0Adapter mit Request-ID-Tracking, FakeAuth0Adapter mit synchronisierter Credentials-Verwaltung)
- `lib/core/services/hullq_auth_service.dart` (Dauerhafte Quarantäne bei fehlgeschlagenem Clear, `_safeStorageWrite` mit Vor- und Nachprüfung, In-Flight Token Await Guard, Revocation-Epochen)
- `lib/features/entitlements/data/entitlements_providers.dart` (Try-finally in AuthNotifier für garantiert konsistenten UI-Zustand bei Exceptions)
- `lib/features/more/ui/more_screen.dart` (Kopplung an authState.isLoggedIn, Deaktivierung des Cloud-Backups für Trial mit Untertitel, ehrliche SnackBar bei Clear-Fehler)
- `test/features/auth/auth_ui_test.dart` (Widget-Tests für Finding A: trial-Nutzer, Legacy-Mitglieder, lokale Datenentfernung, Cloud-Backup deaktiviert)
- `test/features/auth/b1_auth0_login_test.dart` (Anpassung an SDK-CredentialsManager als alleinige Token-Autorität)
- `test/features/auth/bc1a_auth0_adapter_test.dart` (Erweiterte Suite: Testszenarien A01–A08 sowie dedizierte Verification-Suite B-1, B-2, C-1, C-2, C-3, C-4, D-1, E-1)
- `CHANGELOG.md` (Dokumentation des Amendment Round 2)
- `docs/impl/BC1A_bericht.md` (dieser Bericht)

---

## QA-Ergebnisse

- **dart analyze:** `No issues found!` (0 Fehler, 0 Warnungen)
- **flutter test test/features/auth/:** `All tests passed!` (36 von 36 Tests erfolgreich)
- **Backend Typecheck (`npm run typecheck --prefix backend`):** 0 Fehler
- **Backend Vitest (`npm test --prefix backend`):** 7 Testdateien, 37 von 37 Tests erfolgreich

---

## Abnahmekriterien (gemäß BC-1A Release-Brief & Amendment Round 2)

| ID | Kriterium | Status | Nachweis |
| --- | --- | --- | --- |
| Finding A | MoreScreen Konto-UI an authState.isLoggedIn gekoppelt, Logout für trial erreichbar, ehrlicher lokaler Lösch-Hinweis, Trial Backup deaktiviert | erfüllt | automatischer Test (`test/features/auth/auth_ui_test.dart`: Tests 5–8) |
| Finding B | SDK CredentialsManager als alleinige Token-Quelle; kein Stale-Token bei Silent Renewal oder App-Neustart | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests B-1, B-2) |
| Finding C | Session-Epochen, Storage-Barrieren (`_safeStorageWrite`), Multi-Caller Await Guard, Stale SDK-Callback Schutz | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests C-1, C-2, C-3, C-4) |
| Finding D | Dauerhafte Quarantäne bei fehlgeschlagenem clearCredentials(); kein Stale-Token; kein Leak nach Neustart | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test D-1) |
| Finding E | Entfernung erfundener Client-ID (`provy-app-client`), Fail-Closed Validierung & Callback-URLs; P05 bleibt OPEN | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test E-1) |
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


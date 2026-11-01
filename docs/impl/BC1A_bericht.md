# Abschlussbericht: BC-1A – Native Auth0 Login Adapter (inkl. Amendment Round 3)

**Slice:** BC-1A – Native Auth0 Login Adapter  
**Issue:** #40  
**PR:** #44  
**Datum:** 01.11.2026  
**Status:** AMENDMENT ROUND 3 IMPLEMENTED & REVIEW-READY (STOP vor Merge)  
**Branch:** `slice/bc1a-native-auth0-adapter`  
**Basis-Commit:** `5c4b8c5bb54a5f1a498eadfd8c6d8bbf2aae8ce5` (`origin/main`)  

---

## Umgesetzt (inkl. Review Amendment Round 3)

1. **Finding A – Wahrheitsgemäße Konto-UI & Lösch-Sicherheit (GESCHLOSSEN):**
   - Die Kontokarte in `MoreScreen` (`_buildAccountCard`) ist strikt an `authState.isLoggedIn` gekoppelt: Auch angemeldete Nutzer im Basis-Status (`trial`) sehen ihre Auth0-E-Mail, den Status `HullQ-Konto (Basis)`, das Badge `ANGEMELDET` und einen direkt erreichbaren, funktionsfähigen `Abmelden`-Button.
   - Der Lösch-Button wurde wahrheitsgemäß auf `"Lokale Anmeldedaten entfernen"` umbenannt. Dialog und SnackBar stellen unmissverständlich klar, dass ausschließlich lokale Anmeldedaten entfernt werden, keine Cloud-Löschung vorliegt und die HullQ-Identität intakt bleibt (O-01).
   - Auf der Trial-Kontokarte ist der Cloud-Backup-Button deaktiviert (`canBackup: false`) mit dem erklärenden Untertitel `Cloud-Backup erfordert Provy-Mitgliedschaft`.
   - Umfassende UI-Tests in `test/features/auth/auth_ui_test.dart` (Tests 5, 6, 7, 8) für unauthentifizierte Nutzer, authentifizierte `trial`-Nutzer und Legacy-Mitglieder.

2. **Finding B – SDK CredentialsManager als alleinige Token-Autorität (GESCHLOSSEN):**
   - Die redundante Speicherung von `keyAuthToken` in `FlutterSecureStorage` wurde vollständig eliminiert.
   - `_auth0Adapter.getCredentials()` im nativen `CredentialsManager` ist die einzige Quelle der Wahrheit für Access-Tokens.
   - Verhindert das Ausliefern veralteter Tokens bei SDK-interner automatischer Erneuerung (Silent Renewal von Token A zu Token B) und garantiert konsistente Token-Rückgabe nach App-Neustart direkt aus dem sicheren Hardware-Speicher.
   - Nachgewiesen durch Tests B-1 (`Silent Token Renewal`) und B-2 (`App-Neustart ohne lokalen Token-Key`) in `bc1a_auth0_adapter_test.dart`.

3. **Finding C – Session-Eigentümerschaft, Preemption-Guards & asynchrone Konsistenz (BLOCKER – Round 3 Härtung):**
   - **Session-Ownership Fencing in `_safeStorageWrite`:** Beendet ein asynchroner Speicher-Write aus einer veralteten Epoche (z. B. nach verspätetem Await über einen Account-Wechsel hinweg), wird die neue Session nicht durch Löschen des Schlüssels beschädigt. Stattdessen wird der aktive Zustand der neuen Session (`_activeSessionEmail` etc.) unverzüglich restauriert.
   - **Strikte Epochenbindung in `_rollbackStaleLoginSession`:** Bricht ein Login ab oder schlägt fehl, während bereits eine neuere Epoche aktiv ist (`_sessionEpoch != epoch`), wird weder lokaler Speicher noch SDK-Zustand manipuliert.
   - **Asynchrone Preemption in `logout()` und `deleteAccount()`:** Jeder asynchrone Einzelschritt (nach Quarantäne-Marker, nach lokalem Cache-Clear, nach SDK-Logout) prüft `if (currentEpoch != _sessionEpoch) return;`. Ein verspäteter Logout kann eine inzwischen gestartete Session B weder lokal noch im SDK leeren.
   - **Post-Await Epochen- und Sub-Guard in `getUserEmail()`:** `creds.user.sub == expectedSub` und Epochenprüfung nach jedem Await garantieren, dass bei nebenläufigem Logout oder Account-Wechsel strikt `null` zurückgegeben wird.
   - **Nativer Callback-Schutz in `NativeAuth0Adapter` und `FakeAuth0Adapter`:** Verspätete Callbacks aus `login()` löschen niemals SDK-Credentials einer neueren Session (`_lastSuccessfulLoginRequestId <= requestId` und Sub-Gleichheit).
   - Deterministisch geprüft durch Concurrency-Tests in `bc1a_auth0_adapter_test.dart`:
     - C-1: Verzögerter Write von Session A überschreibt oder löscht niemals neuere Session B
     - C-1b: Veralteter Logout nach neuem Login B beschädigt niemals Session B
     - C-2: Verspäteter nativer SDK-Callback von Login A löscht niemals die Credentials von Login B
     - C-3: Zwei parallele `getAuthToken`-Aufrufe während Logout liefern beide deterministisch null
     - C-4: `getUserEmail` Post-Await Guard: Kein Stale-Email Leak bei parallelem Logout oder Account-Wechsel

4. **Finding D – Verifizierte Quarantäne, Fail-Closed & Recovery-Grenzen (BLOCKER – Round 3 Härtung):**
   - **Verifizierte Quarantäne-Persistenz:** Beim Setzen des Quarantänemarkers (`keySessionRevoked: 'true'`) wird der Schreibvorgang sofort durch einen Lesevorgang verifiziert. Schlägt das Schreiben oder die Leseverifikation fehl, wird `quarantinePersisted = false` deklariert und eine typisierte `Auth0RevocationException` geworfen.
   - **Ehrliche SnackBar und UI-Transparenz:** `MoreScreen` und UI fangen `Auth0RevocationException` ab und warnen wahrheitsgemäß per SnackBar (`Sicherheitswarnung: Abmelde-Quarantäne konnte nicht dauerhaft gespeichert werden.`), ohne falsche Abmeldegarantien zu suggerieren.
   - **Recovery-Grenzen dokumentiert:** Bei intaktem Speicher schützt der Quarantänemarker über den App-Neustart hinweg auch bei SDK-Clear-Fehlern (D-2). Bei dauerhaftem Hardware-/SecureStorage-Totalausfall greift die Ausnahme und informiert den Nutzer ehrlich.
   - Deterministisch geprüft durch Tests in `bc1a_auth0_adapter_test.dart`:
     - D-1: Fehlerhafte Quarantäne-Persistenz wirft `Auth0RevocationException` & ehrliche Recovery-Grenzen
     - D-2: Erfolgreicher Quarantäne-Marker garantiert Fail-Closed auch bei fehlschlagendem SDK-Clear über Neustart

5. **Finding E – Auth0Config Fail-Closed Validierung & Platzhalter-Entfernung (GESCHLOSSEN):**
   - Die erfundene Default-Client-ID `provy-app-client` wurde vollständig entfernt; `Auth0Config.clientId` ist standardmäßig leer (`''`).
   - Bekannte Platzhalter (`provy-app-client`, `placeholder`, `todo`, `client_id`, etc.) werden strikt abgewiesen.
   - Ohne zur Build-Zeit via `--dart-define=AUTH0_CLIENT_ID=...` übergebene echte Client-ID ist `Auth0Config.standard.isValid` strikt `false`.
   - Plattformspezifische Callback-URLs (`callbackUrlFor`) für Android (`provy://auth.hullq.com/android/com.hullq.proviantplaner/callback`) und iOS (`com.hullq.proviantplaner://auth.hullq.com/ios/com.hullq.proviantplaner/callback`).
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

- `lib/core/services/auth0_adapter.dart` (`Auth0RevocationException`, `_lastSuccessfulLoginRequestId`-Tracking in `NativeAuth0Adapter` und `FakeAuth0Adapter`)
- `lib/core/services/hullq_auth_service.dart` (`_safeStorageWrite` mit Wert-Restaurierung aktiver Sessions, Preemption in `logout`/`deleteAccount`, Quarantäne-Leseverifikation, `getUserEmail` Post-Await Guard)
- `lib/features/more/ui/more_screen.dart` (Abfangen von `Auth0RevocationException` mit wahrheitsgemäßer Quarantäne-Warn-SnackBar)
- `test/features/auth/bc1a_auth0_adapter_test.dart` (Erweiterte Suite mit 18 Tests: C-1, C-1b, C-2, C-3, C-4, D-1, D-2, E-1 sowie A01–A08)
- `CHANGELOG.md` (Dokumentation des Amendment Round 3)
- `docs/impl/BC1A_bericht.md` (dieser Bericht)

---

## QA-Ergebnisse

- **dart analyze:** `No issues found!` (0 Fehler, 0 Warnungen)
- **flutter test test/features/auth/:** `All tests passed!` (38 von 38 Tests erfolgreich)
- **Backend Typecheck (`npm run typecheck --prefix backend`):** 0 Fehler
- **Backend Vitest:** 7 Testdateien, alle Tests erfolgreich

---

## Abnahmekriterien (gemäß BC-1A Release-Brief & Amendment Round 3)

| ID | Kriterium | Status | Nachweis |
| --- | --- | --- | --- |
| Finding A | MoreScreen Konto-UI an authState.isLoggedIn gekoppelt, Logout für trial erreichbar, ehrlicher lokaler Lösch-Hinweis, Trial Backup deaktiviert | erfüllt | automatischer Test (`test/features/auth/auth_ui_test.dart`: Tests 5–8) |
| Finding B | SDK CredentialsManager als alleinige Token-Quelle; kein Stale-Token bei Silent Renewal oder App-Neustart | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests B-1, B-2) |
| Finding C | Session-Eigentümerschaft, `_safeStorageWrite` Restaurierung, Logout-Preemption, Stale native Callback Schutz, `getUserEmail` Guard | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests C-1, C-1b, C-2, C-3, C-4) |
| Finding D | Verifizierte Quarantäne-Persistenz, `Auth0RevocationException`, ehrliche Recovery-Grenzen, Fail-Closed über Neustart | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests D-1, D-2) |
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

1. **Feste Typen:** Eingehalten (`HullqMembershipStatus`, `Credentials`, `UserProfile`, `Auth0Config`, `Auth0RevocationException`).
2. **Keine versteckten Platzhalter:** Eingehalten. Keine TODOs oder leeren Mocks.
3. **Ehrliche Berichte:** Eingehalten. Alle Nachweise mit konkreten Testnamen belegt; P05 wahrheitsgemäß als offen deklariert.
4. **Alles datengetrieben:** Eingehalten. Keine harten IDs im Code; Konfiguration über `Auth0Config`.
5. **Rechnen mit Kommazahlen:** Nicht zutreffend (keine Währungsrechnung in diesem Slice).
6. **Struktur:** Eingehalten. Kleine, benannte Hilfsfunktionen; klare Trennung zwischen Schnittstelle, nativer Implementierung und Fake.
7. **Tests:** Eingehalten. Umfangreiche Negativ-, Concurrency- und Kontrakt-Tests (38 Tests in `test/features/auth/`).
8. **Keine Eigenbauten von Standards:** Eingehalten. Offizielles `auth0_flutter` SDK (2.7.x) und `flutter_secure_storage` genutzt.
9. **Nur berichten, was tatsächlich geschehen ist:** Eingehalten. Keine Behauptung physischer Scans oder Geräteausführungen.
10. **Nichts aus späteren Versionen sichtbar bauen:** Eingehalten. Keine unfertigen Menüpunkte für BC-1B.

---

## Commit & PR

- Branch: `slice/bc1a-native-auth0-adapter`
- Ziel-Branch: `main`
- Status: Bereit für Pull Request & Independent Review. STOP nach PR-Erstellung.

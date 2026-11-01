# Abschlussbericht: BC-1A – Native Auth0 Login Adapter (inkl. Amendment Round 4)

**Slice:** BC-1A – Native Auth0 Login Adapter  
**Issue:** #40  
**PR:** #44  
**Datum:** 01.11.2026  
**Status:** AMENDMENT ROUND 4 IMPLEMENTED & REVIEW-READY (STOP vor Merge)  
**Branch:** `slice/bc1a-native-auth0-adapter`  
**Basis-Commit:** `5c4b8c5bb54a5f1a498eadfd8c6d8bbf2aae8ce5` (`origin/main`)  

---

## Umgesetzt (inkl. Review Amendment Round 4)

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

3. **Finding C – Session Operation Coordinator & striktes Generation-Fencing (BLOCKER GESCHLOSSEN):**
   - **Exclusive Mutex-Koordination (`_runExclusive`):** Sämtliche zustandsverändernden Mutationen im sicheren Speicher (`_storage`) und im SDK-CredentialsManager werden durch eine strikte FIFO-Mutationssperre serialisiert. Es gibt keine unkoordinierten, nebenläufigen Schreib- oder Löschvorgänge im Speicher.
   - **Marker-Fencing & kein Unrevoking älterer Logins (Finding C-R3-1):** Das Löschen von `keySessionRevoked` beim Login ist generation-fenced. Wenn während des Awaits ein neuerer Logout stattfindet, restauriert der Login den Quarantänemarker sofort (`write(keySessionRevoked, 'true')`), bricht ab und liefert strikt `false`. B's Quarantäne bleibt auf Dauer und über Neustart hinweg unangreifbar.
   - **Nativer SDK-Logout und Callback-Ownership (Finding C-R3-2 & C-R3-4):**
     - `NativeAuth0Adapter` und `FakeAuth0Adapter` verwalten `_activeGeneration` und `_committedGeneration`. Wenn ein älterer Logout aus seinem asynchronen Browser-Logout (`webAuthentication.logout()`) erwacht, prüft er seine Generation und bricht ab, falls inzwischen ein neuerer Login begonnen oder committet hat.
     - Verspätete WebAuth-Callbacks für denselben (`same-sub`) oder einen anderen Account können niemals SDK-Credentials einer neueren Generation löschen.
   - **Eliminierung blinder Rewrites & Drei-Generationen-Interleaving (Finding C-R3-3 & C-R3-3b):**
     - Sämtliche blinden Lese-/Wiederherstellungsversuche (`_safeStorageWrite`) wurden vollständig entfernt.
     - Wenn ein Login A beim Schreiben merkt, dass er überholt wurde, bricht er ab. `_rollbackLocalKeys` löscht nur, wenn die Generation noch die aktive ist (`opGen == _sessionEpoch`). Bei Drei-Generationen-Interleaving A→B→C bleiben C's Daten in Storage und SDK unangetastet.

4. **Finding D – Fail-Safe Quarantäne-Persistenz & Crash-Simulation (BLOCKER GESCHLOSSEN):**
   - Schlägt das Schreiben des Quarantänemarkers fehl, bricht `logout()` unverzüglich mit `Auth0RevocationException` ab, ohne unvollständige Folgeschritte vorzutäuschen. Im Arbeitsspeicher ist die Session sofort fail-closed (`isAuthenticated() == false`).
   - Die physikalischen Grenzen unbeschreibbarer Hardware werden ehrlich ausgewiesen (keine unbelegten Behauptungen). Sobald der Speicher wieder funktionsfähig ist, heilt eine reguläre Abmeldung den Zustand sofort.
   - Nachgewiesen durch Test D-R3 (Crash-Simulation vor Cleanup und Kaltstart) und Test D-2 (erfolgreicher Quarantänemarker garantiert Fail-Closed über Neustart hinweg selbst bei fehlschlagendem SDK-Clear).

5. **Finding E – Auth0Config Fail-Closed Validierung & Platzhalter-Entfernung (GESCHLOSSEN):**
   - Die erfundene Default-Client-ID `provy-app-client` wurde vollständig entfernt; `Auth0Config.clientId` ist standardmäßig leer (`''`).
   - Bekannte Platzhalter (`provy-app-client`, `placeholder`, `todo`, `client_id`, etc.) werden strikt abgewiesen.
   - Ohne zur Build-Zeit via `--dart-define=AUTH0_CLIENT_ID=...` übergebene echte Client-ID ist `Auth0Config.standard.isValid` strikt `false`.
   - Plattformspezifische Callback-URLs (`callbackUrlFor`) für Android (`provy://auth.hullq.com/android/com.hullq.proviantplaner/callback`) und iOS (`com.hullq.proviantplaner://auth.hullq.com/ios/com.hullq.proviantplaner/callback`).
   - Stage-Prüfung P05 (physikalischer OAuth-Redirect gegen Live-Tenant) bleibt als unveränderte, bindende Stage-Gate-Prüfung OPEN deklariert.
   - Nachgewiesen durch Test E-1 in `bc1a_auth0_adapter_test.dart`.

---

## Geänderte/neue Dateien

- `lib/core/services/auth0_adapter.dart` (Generation-Fencing `_activeGeneration`/`_committedGeneration` in `NativeAuth0Adapter` und `FakeAuth0Adapter`, `webAuthLogoutCompleter` Hook)
- `lib/core/services/hullq_auth_service.dart` (`_runExclusive` Mutex, Marker-Fencing in `_handleLogin`, sofortiger Abbruch bei Quarantäne-Schreibfehler in `logout`/`deleteAccount`)
- `test/features/auth/bc1a_auth0_adapter_test.dart` (6 Pflicht-Szenarien C-R3-1, C-R3-2, C-R3-3, C-R3-3b, C-R3-4, D-R3; 41 von 41 Tests grün)
- `CHANGELOG.md` (Dokumentation Amendment Round 4)
- `docs/impl/BC1A_bericht.md` (dieser Bericht)

---

## QA-Ergebnisse

- **dart analyze:** `No issues found!` (0 Fehler, 0 Warnungen)
- **flutter test test/features/auth/:** `All tests passed!` (41 von 41 Tests erfolgreich)
- **Backend Typecheck (`npm run typecheck --prefix backend`):** 0 Fehler

---

## Abnahmekriterien (gemäß BC-1A Release-Brief & Amendment Round 4)

| ID | Kriterium | Status | Nachweis |
| --- | --- | --- | --- |
| Finding A | MoreScreen Konto-UI an authState.isLoggedIn gekoppelt, Logout für trial erreichbar, ehrlicher lokaler Lösch-Hinweis, Trial Backup deaktiviert | erfüllt | automatischer Test (`test/features/auth/auth_ui_test.dart`: Tests 5–8) |
| Finding B | SDK CredentialsManager als alleinige Token-Quelle; kein Stale-Token bei Silent Renewal oder App-Neustart | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests B-1, B-2) |
| Finding C-R3-1 | Login pending revocation-marker delete vs newer logout; Marker bleibt persistent 'true' | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test C-R3-1) |
| Finding C-R3-2 | Veralteter nativer Logout nach neuem Login B beschädigt niemals Session B's SDK-Credentials | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test C-R3-2) |
| Finding C-R3-3 | Drei-Generationen-Interleaving (A -> B -> C): Keine blinde Überschreibung von C | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test C-R3-3) |
| Finding C-R3-3b| Veralteter Rollback nach neuem Login B beschädigt Session B nicht | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test C-R3-3b) |
| Finding C-R3-4 | Verspäteter WebAuth-Callback bei erneutem Login derselben Sub-ID löscht nicht neue Credentials | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test C-R3-4) |
| Finding D-R3 | Fehlgeschlagene Quarantäne-Persistenz wirft Auth0RevocationException & simulierter Abbruch vor Cleanup | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test D-R3) |
| Finding D-2 | Erfolgreicher Quarantäne-Marker garantiert Fail-Closed auch bei fehlschlagendem SDK-Clear über Neustart | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test D-2) |
| Finding E-1 | Entfernung erfundener Client-ID (`provy-app-client`), Fail-Closed Validierung & Callback-URLs; P05 bleibt OPEN | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Test E-1) |
| A01–A08 | Negativ-, Concurrency- und Entitlements-Tests | erfüllt | automatischer Test (`test/features/auth/bc1a_auth0_adapter_test.dart`: Tests A01–A08) |

---

## Offen / Risiken

1. **P05 – Stage & Reales Gerät (OFFEN):**
   - End-to-End-Login über die echten Auth0-Server und physische Android-/iOS-Geräte mit echten Universal Login Redirects bleibt bis zur Bereitstellung der tenant-seitigen Client-IDs und Store-Prüfung ein offenes Store-v1-Gate (P05).
2. **Keine Provy Cloud-Account-Registrierung in BC-1A:**
   - Provy-spezifische Kontoverwaltung, Mitgliedschafts-Validierung gegen D1 und Törn-Synchronisation sind Gegenstand von BC-1B und nachfolgenden Slices.

---

## Annahmen / Abweichungen vom PRD

- Keine Abweichungen. Die Vorgaben des Owner Release Briefs (`BACKEND_CORE_BC1A_phase_B_owner_release_2026-10-31.md`), die Plattformentscheidung O-BC1A-01 (iOS 14.0 / Auth0 Flutter 2.7.x) und die Invarianten P01–P05 wurden strikt eingehalten.

---

## Commit & PR

- Branch: `slice/bc1a-native-auth0-adapter`
- Ziel-Branch: `main`
- Status: Bereit für Pull Request & Independent Review. STOP nach PR-Erstellung.

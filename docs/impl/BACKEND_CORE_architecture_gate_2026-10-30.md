# BACKEND-CORE – Phase A Architecture Gate (Draft)

**Stand:** 30.10.2026. **Status: HOLD – Architektur-/Owner-Entscheidungen offen. KEIN PRODUKTIONSCODE.**
**Tracking:** Issue #36. **Zielbasis:** main nach Integration der Owner-accepted RECEIPT1-Arbeit (PR #34); zum Erhebungszeitpunkt README/GEMINI/AGENTS aus dem gemergten Engineering-PR #35 und RECEIPT1-Code von reviewed HEAD fb74f4cfcd039fca0c1cfa59b36a074ffa7b987c. Vor Freigabe erneut mit origin/main reconciliieren.
**Maßgeblich:** AGENTS.md, GEMINI.md, docs/ENGINEERING_STANDARD_v1.0.md, docs/BACKEND_KONZEPT_v0.2.md, neuere Owner-Produktentscheidungen.
**Risiko:** HIGH (Login, Token, Datenschutz, Persistenz, Löschung, Cloud-Backup, mobile/Web/Worker-Integration).

## 1. Ziel und ausdrückliche Nicht-Ziele

Ziel ist ein kleines, bezahlbares, nachweisbar betriebsfähiges Provy-Core-Backend unter Beibehaltung des offline-first Flutter-Produkts. Die Cloud darf den lokalen Einkauf und die lokale Bordkasse nicht zum Online-Zwang machen.

**Innerhalb dieser Architektur-Reconciliation:**
- Echte Auth0-/OIDC-Anmeldung mit Authorization Code + PKCE für Android/iOS und klare Web-Portal-Session-Strategie.
- Serverseitig validierte JWTs, überprüfbare Identität, korrektes Mitgliedschafts-/Entitlementmodell.
- Planerlokale Account-Projektion, konsistente Datenschutz-, Einwilligungs-, Lösch- und Recovery-Semantik.
- D1/R2-Backup-Vertrag inklusive Datenabdeckung, Payloadlimits, Retention, Fehlerbehandlung, Gerätewechsel und Prüfungen.
- Produktionsfähiges Cloudflare-Worker-/Astro-Portal-Konzept, CI, Runbooks, Monitoring, Test- und Deployment-Gates.
- Schnittstellengrenzen für späteres GUEST1/B3/B4/B5 berücksichtigen, **nicht implementieren**.

**Nicht enthalten:** Guest-Shopping-API/Web-App, Charter-Admin/B3–B5, produktive Zahlungen/Abo-Billing, neue App-UX, automatische Live-Synchronisierung, eigenes SMTP, produktive Deployments, Beschaffung von Auth0-/Cloudflare-Secrets.

## 2. Repository-Reconciliation – nachprüfbare Ist-Lage

| Bereich | Vorhandene Implementierung | Verifizierte Lücke / Risiko |
| --- | --- | --- |
| Flutter Auth | HullqAuthService-Interface, Auth0HullqAuthService, lokaler Secure Storage, AuthNotifier | Ohne Token-Provider wird synthetischer auth0_*_token erzeugt; Fehlerpfade speichern teilweise Login-Status. Kein produktiv verdrahteter nativer Auth0-PKCE-Fluss nachgewiesen. |
| Flutter Entitlements | EntitlementsService / EntitlementsManager | Mitgliedsstatus lokal gecacht; Serverresponse von GET /v1/me enthält kein maßgebliches Pro-Abo-Entitlement. Präfixbasierte Törncode-Freischaltung ist deaktivierte Vorbereitung, kein realer serververifizierter Code. |
| Worker/Auth | backend/src/index.ts, auth.ts, routes/me.ts, routes/consents.ts, routes/backups.ts | Hono/Jose/JWKS-JWT-Prüfung und Routen vorhanden. Kein durchgehender End-to-End-Auth0-Nachweis, keine nachgewiesene Prod-Bindung, keine zentrale Abuse-/Rate-Limit-Strategie. |
| Identität/Löschung | Account-Projektion in D1; DELETE /v1/me löscht D1/R2 | Auth0-Identität wird nicht gelöscht. GET /v1/me ruft ensureAccount auf und kann die Planer-Projektion bei gültigem JWT wieder anlegen. Nutzerbegriff „Konto löschen“ / gemeinsame HullQ-Identität unklar. |
| Backup | B2 in Cloudflare R2 + D1, Receipt1-Inklusion in Backup v3, 5-Versionen-Retention | Keine bestätigte live getestete EU-Prod-Instanz. Separat persistierte lokale Lieferanten-/Bestelldaten gehören nach sichtbarer Serialisierung nicht zum Snapshot; Verfügbarkeit nach Gerätewechsel prüfen. Keine Live-Sync versprechen. |
| Portal | Astro (portal/) und /konto-loeschen | Seite enthält nur Platzhalter für Auth0-Login und tatsächlichen DELETE-Request. Rechtliche Live-URLs im Flutter AppConfig sind Platzhalter. |
| Betrieb | wrangler.toml, D1-Migration, Vitest/Backend-Checks | D1-ID Platzhalter; Dev-Konfiguration, kein nachgewiesenes Deployment, kein eigenständiges Portal-CI-Release-Gate und kein dokumentierter Restore-Drill. |
| B3–B5 & GUEST1 | D1-Tabellen für Charter/Crew sowie Owner-accepted Guest-Spec | Backend-APIs und Guest-Web-App existieren nicht; nicht in BACKEND-CORE vorziehen. |

Code-/Produkt-Gaps sind als Prüfaufträge und kein vorgetäuschter Live-Audit zu verstehen. Verifizierte Cloudflare-/Auth0-Account-Konfigurationen kann der Repository-Code nicht beweisen.

## 3. Architekturentscheidung: Minimales Retrofit vor Rewrite

| Option | Vorteile | Nachteile / Risiken | Entscheidung |
| --- | --- | --- | --- |
| A – Härtung des vorhandenen Flutter + Auth0 + Cloudflare Worker/D1/R2 + Astro | Wiederverwendung bestehender Routen, Migrationen, Interfaces und CI; niedrige Kosten; klar offline-first; kleiner Review-Radius | Erfordert Schließen der Mock-/Session-/Lösch- und Betriebs-Lücken; D1/R2 übergreifend nicht atomar | **Bevorzugt** |
| B – Separater zentraler Backend-Service / anderes Framework oder kompletter Auth-/Backup-Rewrite | Vereinheitlichung langfristig möglich | Erheblicher Migrations-, Kosten-, Sicherheits- und Review-Aufwand ohne bisher nachgewiesene Notwendigkeit | **Nicht empfohlen** |

**Bevorzugter Datenfluss:** Mobile-App (lokale Drift-DB) → Auth0 Universal Login/PKCE → kurzlebiges Access Token mit passender API-Audience → HTTPS zu Worker (JWT/JWKS, AuthZ, Limits) → D1-Account-Projektion/R2-Backup. Das Astro-Portal erhält einen eigenständigen sicher gestalteten Browser-Login-Flow mit CSRF-/Session-Schutz. Das Flutter-Gerät erhält nicht automatisch eine browserseitige Sitzung und umgekehrt.

**Betriebsgrundsatz:** Auth0 bleibt Identity Provider, nicht Quelle von Provy-Fachberechtigungen. Provy-/Charter-Berechtigungen müssen explizit vom zuständigen Backend oder späterer freigegebener Subscription-Authority kommen, nicht aus lokal unüberprüften Präfixcodes.

## 4. Verbindliche Invarianten

| ID | Invariante |
| --- | --- |
| I-01 | Ohne gültige Auth0-Tokenvalidierung und passende Audience erhält kein Aufrufer Cloud-Backups, Accountdaten oder Löschrechte. |
| I-02 | Die App erzeugt im produktiven Auth-Code niemals synthetische Token; API-/Login-Fehler dürfen nicht als erfolgreiche Anmeldung erscheinen. |
| I-03 | Token und Refresh-Token verbleiben in sicherer Plattform-Ablage; weder App-Logs noch Worker-Logs enthalten Zugangstoken/Secrets oder Belege. |
| I-04 | Offline-Lokalaktionen (Planung, Einkaufen, Bordkasse) bleiben ohne Backend erreichbar. Offline-Cached-Identität darf kein unbestätigtes Serverrecht vortäuschen. |
| I-05 | Ein Cloud-Backup ist entweder vollständig mit allen nach Vertrag erforderlichen Dateien/Metadaten abrufbar oder wird als fehlgeschlagen markiert; kein stilles Weglassen. |
| I-06 | Teilfehler zwischen D1 und R2 dürfen keine unkontrollierten, unendlich wachsenden Orphans oder fälschliche Erfolgsmeldung erzeugen; Retry/GC ist idempotent. |
| I-07 | Ein Restore auf einem neuen Gerät kann jeden als gesichert versprochenen Datentyp nachweisbar wiederherstellen. Nicht enthaltene Datentypen werden klar benannt. |
| I-08 | Ein Konto-/Datensatz kann durch einen alten, weiter gültigen Login nicht still nach erfolgreicher Löschung rekonstruiert werden, sofern dies dem gewählten Löschvertrag widerspricht. |
| I-09 | Eine Provy-Datenlöschung löscht nicht still eine mit HullQ gemeinsam genutzte Auth0-Identität bzw. HullQ-Daten. Die genaue Semantik muss der Owner freigeben. |
| I-10 | Einwilligungen sind widerrufbar, zweck- und textversioniert; Newsletter-Opt-in ist nicht Teil einer verpflichtenden Login-Einwilligung. |
| I-11 | Alle mandantenbezogenen D1/R2-Zugriffe sind auf die verifizierte Account-ID beschränkt; fremde Backup-IDs geben keine Daten preis. |
| I-12 | Kein öffentliches Feature/Deployment wird anhand einer nur lokal grünen Testsuite als live oder Store-ready ausgewiesen; Stage- und Prod-Beweise sind separat. |
| I-13 | GUEST1/B3/B4/B5 erhalten später eigene Owner-Entscheidungen und APIs; kein impliziter Scope-Sprung durch Datenmodellvorbereitung. |

## 5. Security-/Account-Vertrag: offene Designentscheidungen

### 5.1 Native Authentifizierung

**Empfehlung:** Offizielles Auth0-Flutter-SDK, Universal Login und PKCE; keinerlei eigene Passwortverarbeitung. Android-App-Links/Custom-Scheme und iOS-Callback/Bundle-Konfiguration, Allowed Callback/Logout URLs und Token-Audience mit echten Tenant-Einstellungen verifizieren. Token-Refresh/Logout, Callback-Cancellation, Logout/Tokenrevocation-Semantik und 401/403-/Timeout-UX einzeln festlegen. Auth0-IDs/Tenant-Domains bleiben Owner-Konfiguration, keine Secrets im Repo.

**Fehlerprinzip:** Netzwerkfehler führen zu explizitem Online-Unavailable, nicht zu synthetischem Mitgliedsstatus. Lokale Offline-Funktionen dürfen bestehen bleiben.

### 5.2 Geteilte HullQ-/Provy-Identität: Owner-Entscheidung BLOCKING

**Variante A (empfohlen):** „Provy-Daten und Provy-Zugang entfernen“ = lokale Daten (mit separater Nutzerbestätigung), D1-Provy-Projektion, Provy-R2-Backups und aktive Provy-Sitzung löschen; HullQ-Identität verbleibt. UI/Store-Löschseite muss das präzise erklären. Re-Registrierung und Schutz vor automatischer Re-Projektion definieren; unabhängige HullQ-Accountlöschung außerhalb des Provy-Dienstes.

**Variante B:** Globale Auth0/HullQ-Kontolöschung nach expliziter Kontoinhaberentscheidung und zentral verwalteter Orchestrierung über HullQ. Umfang kann andere HullQ-Daten betreffen; niemals direkt von Provy ungefragt implementieren. Erfordert eigene globale Identity-Lifecycle-Ownership, Wiederanlauf und Sicherheitsprüfung.

**Offene Frage:** Was bedeutet „Konto löschen“ in App und Web konkret? Weder das bloße Entfernen der D1-Zeile noch eine ungefragte globale HullQ-Löschung ist ausreichend definiert. Nach geklärter Entscheidung eine irreversible Löschsequenz mit Status und klaren Nutzertexten entwerfen. Alte Access Tokens, gleichzeitige Requests, R2-/D1-Teilversagen und erneuter Login müssen in Tests vorkommen.

### 5.3 Backup-Versionierung und vollständiger Datenvertrag

Erforderlich ist eine Tabelle **alle persistenten Quellen → Cloud-Backup-Feld → Restore-Ziel → Version → Risiko**. Einschließen: Drift-Tabellen, Receipt1-Belegdateien, Bootsprofile, Aufteilungen, gespeicherte lokale Lieferanten/Bestellungen, relevante Secure-Storage-Daten (aber KEINE Tokens/Passwörter/IBANs im Backup), andere Präferenzen. Daten, die bewusst gerätegebunden bleiben, offen deklarieren.

Klärung: Backup ist vollständiger Snapshot, keine laufende Geräte-Synchronisation. Keine implizite Merge-Semantik zwischen mehreren Geräten. Restore ist eine explizite Nutzeraktion mit lokaler Sicherheitskopie/Bestätigung.

### 5.4 Worker/D1/R2-Grenzen

- Pro Route AuthZ, Input Validation und bounded Payload sowie Timeout-Verhalten festlegen.
- Auf R2-Upload/Download darf D1-Metadaten-Fehler nicht zu einer als erfolgreich gemeldeten Sicherung führen; Orphan-/Cleanup-/Retry-Konzept erforderlich.
- D1/R2-Retention (maximal fünf) darf nur bestätigte vollständige Backups als wiederherstellbar ausweisen; Löschschritte dürfen nicht unbeabsichtigt den letzten gültigen Snapshot vernichten.
- EU-Jurisdiction der konkreten Bindings, Backups, Löschfristen und Logging/Privacy getrennt auf echter Stage-Instanz verifizieren; Worker-Rechenort nicht mit Speicherung verwechseln.
- Rate-Limits, Session-/Browser-CSRF, Bot-Abuse und Ressourcenbudget in einer eigenen Security-Matrix behandeln.

## 6. Failure-/Restart-Matrix (Mindestumfang)

| Trigger | Erwartung / Schutz | Testnachweis (Phase B) |
| --- | --- | --- |
| Auth0-Login abgebrochen | Kein Mitgliedsstatus/Token wird fingiert; lokale App bleibt nutzbar | A01 |
| Token abgelaufen / falsche Audience / manipulierte JWT | 401/403; keine Datenfreigabe; Refresh nach definiertem Vertrag | A02 |
| Auth0-/Worker-Netz offline | Klare Retry-/Offline-Anzeige, lokale Daten unverändert | A03 |
| App-Neustart während Tokenrefresh | Kein Logout-/Refresh-Sturm, keine stale privileges | A04 |
| D1-Account-Anlage scheitert | Login/API nicht als cloud-ready melden | A05 |
| Backup R2-Put erfolgreich, D1-Insert scheitert | Kein Erfolg; Orphan identifizierbar und bounded bereinigbar | B01 |
| D1 zeigt auf fehlendes R2-Objekt | Backup nicht als gültig abrufbar; sinnvolle Fehlerklasse | B02 |
| Backup überschreitet erlaubte Nutzlast | Vor schädlicher Allokation kontrolliert ablehnen, Bestandsbackups bleiben | B03 |
| Restore eines Altformats / unvollständigen v3-Snapshots | Ablehnen oder explizite kompatible Migration, niemals stilles Weglassen | B04 |
| Zwei Geräte schreiben Backups | Deterministische Retention/Sortierung; letzter intakter Snapshot erhalten | B05 |
| Konto gelöscht, Token weiter gültig, GET /me | Keine stille Wiederherstellung gegen Löschvertrag | D01 |
| D1-/R2-Löschung teilweise fehlgeschlagen | Klarer Zwischenstatus, retrybar/idempotent, keine falsche Löschbestätigung | D02 |
| Parallel Backup/Accountdelete | Definierte Lock-/Statussemantik; kein wieder auferstandenes Backup | D03 |
| Browserlöschung CSRF / fremdes Konto | Authenticated user+CSRF, Bestätigung und Audit ohne Geheimnisse | D04 |
| Deployment/Schema-Migration fehlschlägt | Rollback/Forward-Plan, keine irreversiblen Datenverluste | O01 |

## 7. Nebenläufigkeits-/Sicherheitsmatrix

| Operation A | Operation B | Vertrag vor Coding |
| --- | --- | --- |
| Provy Account Delete | GET /me bzw. erneute Anmeldung | Tombstone-/Status- oder äquivalenter Zustandsvertrag; Recreate nicht still erlaubt |
| Provy Account Delete | Backup Upload / Retention-Job | Keine neuen Objects nach finalisierter Löschung; Race-/Retry-Plan |
| Zwei Backup-Uploads | Retention 5 | Keine fehlerhafte D1/R2-Löschreihenfolge, letzter gültiger Snapshot bleibt |
| Restore auf Gerät | Lokale Shopping-/Kitty-Aktion | RECEIPT1 StorageOperationCoordinator-Invarianten gelten unverändert |
| Mobile OAuth / Token-Refresh | Logout / App-Kill | Keine verwaiste privilegierte Session; sichere Wiederaufnahme |
| Portal Delete | offenes Browser-Tab / CSRF | Reauth/Bestätigung, Session-Schutz, keine Löschung durch fremden Request |
| Worker Release | D1 Migration / Rollback | Kompatibler Schema-Übergang, Forward-Migration, eigene Restore-Drills |

## 8. Geplanter Test-/Evidence-Katalog

- **Flutter Unit/Widget:** Auth0-Adapter mit injizierbarem SDK, login success/cancel/expiry/refresh/logout, 401/403 und Offline-Fallback; echte Plattformintegrationen nicht durch Mocks behaupten.
- **Worker Vitest:** Test-JWKS, Audience/Issuer/Sub, Tokenablauf, Tenant-Isolation, Consent, D1-R2-Konsistenz, Retention, Delete-Recreation/Concurrent Requests.
- **Portal:** Separater Astro-Build/Test und Browser-E2E für Login/CSRF/Confirm/Delete/Redirect/Failure, auf Stage mit echten Auth0-App-Settings.
- **Backup/Restore:** in Android- oder iOS-Testinstallation einen kompletten, repräsentativen Törn inklusive Fotos, Bordkasse und separat gespeicherten Lieferantendaten sichern; auf frischem Gerät restaurieren; Byte-/Fachinvarianz prüfen.
- **CI:** vollständige Flutter Tests und Analyze, Backend Typecheck/Vitest, Portal Build und passende Contract-/Migration-Tests auf **exaktem Implementierungs-PR-HEAD**.
- **Betrieb:** Stage D1/R2-Objekte, Auth0-Audience/Callbacks, sichere Secrets, Request-Limits, Logs ohne PII, Failure-Alerts und dokumentierte Rollback-/Wiederherstellungsprobe.

**Kein Ersatz manueller Device-/Live-Tests durch eine Mock-Testsuite.** Besitzer der Cloudflare-/Auth0-Accounts führt externe Einrichtungsschritte selbst durch oder autorisiert sie explizit.

## 9. Vorgeschlagene kleine Implementierungs-Slices – NICHT freigegeben

| Vorschlag | Ziel | Abschluss-Gate |
| --- | --- | --- |
| BACKEND-CORE-A: Auth & Entitlement Contract | Native Auth0-PKCE, Token/Refresh/Logout und Worker-Account-Vertrag, keine falschen lokalen Rechte | End-to-End Auth/Forbidden/Offline Tests |
| BACKEND-CORE-B: Data Lifecycle & Delete | Owner-entschiedene Provy/HullQ-Löschsemantik, Web-Delete, Tombstone/Retry/Privacy | Browser-/Device-/Race- und Failure-Tests |
| BACKEND-CORE-C: Backup Contract & Production Readiness | Dateninventar, D1/R2-Sicherheit, CI Portal, Stage/Prod-Runbook, Restore-Drill | Prod/Stage-Evidence ohne behauptete Live-Sync |

Möglicher Dependency-Plan: A → B → C; notwendige Schutzmaßnahmen aus C ggf. vor extern exponierter B-Funktion. Vor jedem Implementierungs-Slice Gate-A-Detailbrief und Owner-Release.

## 10. Entscheidungsprotokoll und Gate

**Vorab-Architekturempfehlung (noch kein Owner-Go):**
1. Option A: vorhandenen Cloudflare-/Auth0-/Flutter-Stack härten, keinen Neuaufbau.
2. Offline-first und unveränderte RECEIPT1-Invarianten erhalten.
3. Provy-Datenlöschung und globale HullQ-Identitätslöschung ausdrücklich auseinanderhalten.
4. Backup-Snapshot nicht als geräteübergreifende Live-Synchronisation vermarkten.
5. Kostenarme Cloudflare-Nutzung bevorzugen, jedoch niemals auf Kosten von Auth-/Datenintegrität.

**Vor Implementierung zu entscheiden oder nachzuweisen:**
- **D1 – BLOCKING:** Owner bestätigt Scope der Konto-/Auth0-Identitätslöschung.
- **D2 – BLOCKING:** Auth0 Native-App, API-Audience, Callback/Logout URLs, Tenant- und Domainstrategie festlegen; echte Konfiguration durch Owner nachweisen.
- **D3 – BLOCKING:** Backup-Dateninventar vollständig prüfen und konkrete Einschluss-/Ausschlussliste akzeptieren (Lieferanten, Bestellungen, andere lokale Stores).
- **D4:** Provy-spezifische API-/Portal-Domain, Stage-/Prod-Trennung, D1/R2 EU-Ressourcen und Verantwortlichkeiten klären.
- **D5:** Public Guest-Shopping später: eigene Security-Reconciliation; kein GUEST1-Code im BACKEND-CORE-A.

**Gate A: HOLD.** Dokument ist ein risikoorientierter Vorschlag gegen den verfügbaren Repo-Stand, noch kein unabhängiger Design-Review einer von Gemini erarbeiteten Architektur und keine Implementierungsfreigabe.

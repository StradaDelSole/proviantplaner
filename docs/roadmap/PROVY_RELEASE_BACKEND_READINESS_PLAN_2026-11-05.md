# PROVY – Backend-/Release-Readiness, Risiko- und Umsetzungsgates

**Stand:** 05.11.2026 · **Dokumentstatus:** Owner-approved plan, Gate A/Phase B not automatically released.  
**Quellen:** Claude `PROVIANTPLANER_ANALYSE_v0.1.md` vom 05.11.2026 (analysiert `main@e00c01d`), direkte Code-Reconciliation derselben `main`-Version, bestehende Backend-Core Phase-A-Spikes/ADRs/P01–P05, realer Owner-Pixel-Befund und GitHub-Issues. **Nicht:** externer Audit, Penetrationstest, Live-Cloud-/iOS-Produktionsnachweis.

## A. Entscheidungsrahmen

**Jetzt zuerst** HCD-Shopping-Journey stabilisieren (#64/#66–#68); **parallel ohne Cloud-Code** Release-Plattform (#69) und Backend/Stage-Gate (#70) vorbereiten. Kein B2-„schnell deployen“, bevor BC-1B implementiert, geprüft und explicitly accepted ist. Alle High-Risk Slices befolgen `docs/ENGINEERING_STANDARD_v1.0.md` Phase A → independent Gate A → Owner → Phase B.

### A1. Release-Blocker / mobile Plattform – #69

| Risk-ID | Konkrete Source Observation `main@e00c01d` | Plan und erforderlicher Nachweis | Status |
| --- | --- | --- | --- |
| R-1 | `android/app/src/main/AndroidManifest.xml`: keine explizite INTERNET-Permission | **Merged Release Manifest** der signierten AAB/APK untersuchen; Netzwerk im release build physisch testen. Bei Fehlen explizit hinzufügen, CI Assertions. Library-Manifest kann es beitragen; tatsächlichen Ausfall nicht behaupten ohne Test. | OPEN |
| R-2 | `ios/Runner/Info.plist`: NSCamera/PhotoLibrary Texte fehlen; `expense_sheet.dart` verwendet `image_picker` | Einträge und lokalisierte `InfoPlist.strings` in sechs Sprachen; echter Kamera-/Galerietest iOS und Privacy-Review. | OPEN |
| R-3 | CI Flutter 3.24.3; Gradle `compileSdk=35`, Target aus Flutter gesetzt | **Eigenständiger kompatibilitätsgeprüfter Toolchain-Slice** für Play Target API 36 und Apple Xcode 26/iOS 26 SDK. Android AAB Manifest/Metadata und iOS Build in gehostetem macOS Runner nachweisbar machen. Versionen/Deadlines unmittelbar vor Release bei Google/Apple neu verifizieren. | OPEN |
| Security mobile | `allowBackup`/Android Data Extraction unentschieden, SQL enthält Zahlungsdaten; release `key.properties` fallback zu Debug-Signing | Owner/privacy choice on OS auto-backup + positive/negative tests; fail-closed production signing, kein Secret in Repo; release artifact cannot silently debug-sign. | OPEN |
| QA / Accessibility | CI nur `flutter analyze/test`; keine Release-Build-Artefakte und keine vollständige Gerätematrix | Build APK/AAB; iOS archive/TestFlight via macOS; Pixel + zweites Android + 1 iPhone real; 320dp, font 1.5x, dark/nightwatch, offline, startup/recovery. | OPEN |
| Rechtliches | #49 Links und Datenschutzziele offen, PROVY/HullQ Markennamen uneinheitlich | echte rechtliche Zielseiten, Konto-Löschweg, Datenflüsse und Final-Bundle-Metadaten prüfen; Store und Trademark/Name als separate Entscheidung. | OPEN |

**Quellen:** https://developer.android.com/google/play/requirements/target-sdk ; https://developer.apple.com/news/upcoming-requirements/ ; https://pub.dev/packages/image_picker. **Diese Links sind Live-Quellen bei Release erneut zu prüfen, kein statisches Gesetzesgutachten.**

### A2. Cloud/Backend – #70

| Risk-ID | Code/Evidenz | Geeignete Phase-B-Zielarchitektur / Gate | Status |
| --- | --- | --- | --- |
| B-1 IBAN | `backend/src/routes/backups.ts` prüft vollständiges `content` gegen unstrukturierte Regex, inkl. Base64-Fotos. Fehlalarme bei langen binärähnlichen Sequenzen wahrscheinlich; Claude misst >50KiB 100% bei Stichprobe. | **Strukturelle** Eingabevalidierung / Allowlist, auszuschließende Zahlungs-Felder **vor** Serialisierung, separate Bilddaten als binärer Stream. Nichts Base64-artiges mit IBAN-Regex scannen. Integrations-/Fault-Tests 300KiB und 50MiB Beleg, echte Mod-97-Validierung nur für kontrollierte Textfelder falls nötig. | OPEN – B0–B2 nicht deployen |
| S-1 Account deletion | `ensureAccount` `SELECT → INSERT`; `deleteAccountCascade` löscht Konto-Reihe endgültig; erneute gültige Token-Anfrage kann re-provisionieren, Race beim Erstlogin | Account-Tombstones / `deleted_at`, Fencing vor und nach R2 operations, idempotentes provisioning, explizite Konto-Aktivierungsregel, token reuse/restart/delayed-put Tests; DSGVO-Abwicklung mit Owner prüfen. | OPEN |
| S-2 Backup lifecycle | `R2.put` vor D1 insert; 5er-Limit durch ungebundene Schleife; kein Content-Size Limit | Bestehende Phase-A S1/S2: R2 bounded stream, D1 CAS pending→active, GC lease, ≤5 aktive, device/account fence, idempotency, orphan cleanup, D1 SQLite `datetime(...)` SQL-Formkorrektur. | OPEN |
| A-1 Client memory | Base64/JSON String wird im Client komplett materialisiert | Phase-A S3: NDJSON-v4 streaming, Version-/Checksum-Vertrag, Mobile RAM/backpressure und disk-full tests; kein brüchiger Restore. | OPEN |
| C-1 Errors | API-Client ohne einheitliche Timeouts, falsche `false/null`-Doppeldeutigkeit | Typisierte Network/Auth/Rejected/Server/NoBackups vs RestoreFailure, nachvollziehbarer Retry, UI Status ohne Secrets/PII; keine 401 aus jeder JWKS-Störung. | OPEN |
| W-1 Edge hardening | CORS fallback offen; JWT keine explizite RS256-Allowlist; Rate Limits fehlen | CORS allowlist fail-closed, standardkonforme JWT alg restriction, rate limits und IAM/minimal R2/D1 permissions; testen ohne Login-Daten zu protokollieren. | OPEN |
| E-1 Entitlements | Präfixbasierte Pro-Freischaltung im Client nur provisorisch, Feature-Flag derzeit aus | Serververifizierte Entitlements bevor Bezahlschranken/B2B Code aktiviert; kein VIP über generierbares Prefix. | GATED / NO RELEASE |
| Privacy | Cloud-Backups derzeit nicht E2EE; lokal Crew-Zahlungsdaten vorhanden | Datenminimierung, optionales clientseitiges E2EE nur nach entschiedenem Geräteverlust-/Schlüssel-Recovery-/Supportmodell; OS AutoBackup prüfbar. | OWNER DECISION |
| P05 Native Auth0 | BC-1A accepted & merged; reale EU-Tenant-Deviceprüfung noch offen #45/#50/#51 | echte Login/Refresh/Logout/Kill/Consent, Stage Account; vor BC-1B keine spekulative komplette Auth-Umbauaktion. | OPEN |

**Quelle der geplanten Architektur:** `docs/impl/BACKEND_CORE_phase_A_owner_acceptance_2026-10-31.md`, `BACKEND_CORE_targeted_technical_contract...`, `BACKEND_CORE_phase_A_decision_ledger...`, ADR-BC-003/004; diese bilden die verbindlichen Phase-A-Gates, nicht der alte B0–B2 Code.

### A3. Datenintegrität/Wartbarkeit – spätere risikoabgewogene Folgeaufgaben

- Geld `REAL` in Drift vs Integer Cent der Engine: mögliche spätere Schema-v9-Migration, aber **nicht** ohne beweisbare Roundtrip-/Rückwärts-/Backup-/Restore-Tests oder ohne gerechtfertigten Nutzen. **Kein gegenwärtig nachgewiesener Rundungsbug**.
- `replace()` statt gezielter Updates: dort prüfen, wo Lost-Update-Konflikte wirklich auftreten; Concurrency-Invarianten.
- 61 `catch (_)` und `DateTime.now()`: systematisch nur an aktiven Fehlerpfaden verbessern, keine pauschale Refactor-Welle.
- Große Widgets/Services trennen, wenn für aktuelle UX/Backend-Änderungen notwendig; nicht für bloße Dateilänge.
- PDF-Abrechnung lokalisieren (alle sechs Sprachen), richtige Zeit-/Währungsformate, produktweit keine irreführend hartkodierte Labels.
- Katalog `source=estimate` + 6 Sprachen: fachlich/linguistisch validieren und Beta-Auswertungen ohne Zwangstracking.
- Statusdokument `docs/PROJECT_STATUS.md` statt mehrerer widersprüchlicher, voll kopierter HEAD-Historien; ältere Docs historisch kennzeichnen.
- Auth0 Session-Aktor als Alternative erst erwägen, wenn P05 realen Fehler oder belegten Architekturgrund liefert, nicht wegen Review-Historie allein.

## B. Verbindliche Reihenfolge & Gate A für Folgeslices

**B0 →** Mobile Release verifizieren: echte Android Manifest-Merge-Permission; InfoPlist; Flutter/SDK target Build Plan + Geheimnisse/Signing-Schutz. Phase-A Entscheidung separat.

**B1 →** Auth0 P05 am Pixel und iPhone: Stage-Tenant, Wiederlogin/Refresh/Kill; klare Diagnosen; Issue #45 dokumentieren.

**B2 →** Backend BC-1B Phase A reconciliation: versiegelter Contract, D1/R2 Crash/Fencing & NDJSON stream, DoS limits, Backup vs Restore outcomes. Zwei Alternativen für kritische Datenflow-Grenzen und unabhängige Review.

**B3 →** Eigene Phase B Implementation erst nach expliziter Owner Freigabe; Staging-Deployment (keine Produktivnutzerdaten), echte 50-MiB-receipt Tests, mehrere Geräte und Cleanup, Accountdelete/restore.

**B4 →** Guest Shopping #22 / Crew link B3 jeweils mit separatem Privacy-/Auth-/Offline-Scope; dann Store-v1 E2E Tests und unabhängige HCD-Aufgaben.

**B5 →** Store Release-Gate: Android/iOS signierte Builds, API-SDK-Dokumentation, Rechtstexte, Löschablauf, Privacy Declarations, lokalisierte PDF/Store-Beschreibung, realer Beta-Pilot, Owner Acceptance.

Keiner dieser Schritte ist durch die Zustimmung zum **Plan** bereits als Code- oder Cloud-Deployment-Slice freigegeben.

## C. Nachweisregister / Code-to-Trust

Für jede hohe Severity eine dokumentierte Matrix: `Finding → affected user/account/data → known code path → failure injection → expected post-crash state → exact test → CI HEAD → Stage/device evidence → Owner sign-off`.

**Nicht als abgeschlossen deklarieren**, wenn nur die Dokumentation oder ein Mocktest grün ist. Andersherum ein **alter nicht-deployter** Endpunkt ist ein vor Deployment zu behebender Blocker, nicht der Beweis eines aktuellen Cloud-Produktionsausfalls.

## D. Referenzregister

- Backend & Release Audit: https://github.com/StradaDelSole/proviantplaner/issues/65
- Release platform work package: https://github.com/StradaDelSole/proviantplaner/issues/69
- Backend architecture gate: https://github.com/StradaDelSole/proviantplaner/issues/70
- Real UX beta: https://github.com/StradaDelSole/proviantplaner/issues/71
- P05 real native: https://github.com/StradaDelSole/proviantplaner/issues/45
- Existing validation #49, #50, #51, #54.

# BACKEND-CORE – Gemini Phase-A-Auftrag (Architektur ausschließlich)

**Status:** Freigegebener Recherche-/Architekturauftrag, kein Feature-Release, kein Produktionscode.  
**Tracking:** Issue #36.  
**Arbeitsgrundlage:** AGENTS.md, GEMINI.md, docs/ENGINEERING_STANDARD_v1.0.md, docs/templates/ARCHITECTURE_GATE_TEMPLATE.md und docs/impl/BACKEND_CORE_architecture_gate_2026-10-30.md.

> **STATUSUPDATE 31.10.2026 – HISTORISCHER GEMINI-AUFTRAG, NICHT ERNEUT VOLLSTÄNDIG AUSFÜHREN.** Das allgemeine Phase-A-Design und die konsolidierte v2 sind bereits geliefert und unabhängig geprüft. O-01/O-02 sind in ADR-BC-001/002 **ACCEPTED**. Für den Gate-A-Abschluss sind **nur noch** die schmalen technischen Design- und Nachweispunkte aus `docs/adr/ADR-BC-003-versioned-backup-transport.md`, `docs/adr/ADR-BC-004-d1-r2-lifecycle.md` und `docs/impl/BACKEND_CORE_phase_A_decision_ledger_2026-10-31.md` offen. Keinen dritten allgemeinen Änderungsbericht erzeugen; kein Produktionscode.

## Deine Aufgabe (historisch, Stand vor v2-Review)

Erstelle einen vollständigen, unabhängigen Phase-A-Architekturentwurf für BACKEND-CORE anhand des **dann aktuellen origin/main**, ohne Code, Package- oder Schemaänderungen. Behandle die vorhandene Architekturvorlage als kritisierbare Ausgangshypothese, nicht als bereits akzeptiertes Design.

### A. Repo-Reconciliation
- README/GEMINI/AGENTS/Engineering Standard plus Owner Product-/Backend-Konzept lesen.
- Reale Flutter Auth-/Entitlement-/Backup-Services, Auth0-/API-Client, Cloudflare Worker, D1-SQL-Migrationen, R2, Astro-Portal, Tests und CI lesen.
- Branch/Commit-SHA, Datei-/API-Inventar und Widersprüche dokumentieren.
- Unterschiede „im Repo implementiert“ vs. „live deployed“ vs. „echtes Gerät getestet“ explizit ausweisen.

### B. Architekturoptionen
- Mindestens zwei tragfähige Lösungen vergleichen, bestehendes Cloudflare/Auth0-Backend gegen unnötigen Rewrite abwägen.
- Mobile native Universal Login/PKCE und Browserkonto-Löschung mit sicherem Session-/CSRF-Konzept durchplanen.
- Shared Auth0 Identity: keine globale HullQ-Löschung ohne Owner-Entscheidung; sichere Provy-Datenlösch-Semantik inklusive GET /me-Recreation verhindern.
- Backup-Versionierung und Gerätewechsel gegen ALLE tatsächlichen Persistenzquellen prüfen.
- D1/R2-Fehler, Größenlimits, Retention, Timeouts, Netzwerkverlust, abgelaufene Tokens, parallele Zugriffe, Crash und Restart durchspielen.
- Future GUEST1 als Schnittstellengrenze, nicht als zu implementierendes Feature.

### C. Test- und Beweismatrix
- I-01 bis I-13 aus dem Phase-A-Draft kritisch prüfen/erweitern und jedem relevanten Fehlermodus einen deterministischen Test zuordnen.
- Konkrete Security-Negativtests (Issuer, Audience, forged/expired JWT, account isolation, CSRF), Token-/Delete-/Backup-Races und Orphan-/Delete-Recovery.
- Portal Build/E2E, native Device-Tests und Cloudflare/Auth0-Stage-Drills als jeweils separate Evidence-Klassen.
- Markiere, was nicht im Repository verifizierbar ist und der Owner außerhalb des Codes tun muss.

### D. Ergebnisse
1. Ein ausgefülltes Architecture Gate nach Template mit einer empfohlenen minimalen Lösung und klaren Grenzen.
2. Vollständige Failure-/Concurrency-Matrix, Architektur- und Rollout-Abhängigkeiten.
3. Präzise Owner-Entscheidungen (maximal wenige, nur echte Blocker).
4. Vorschlag für kleine umsetzbare BACKEND-CORE-A/B/C-Slices inklusive Abnahmekriterien.
5. Adversarial Self-Review: mindestens fünf gezielte mögliche Gegenbeispiele und wie das Design sie abwehrt.

**STOP:** Nach Phase A keinen Produktionscode schreiben, keinen Release-Branch für Feature-Implementierung erstellen, keine externen Ressourcen anlegen, keine PRs mergen und keine Issues schließen. Ergebnisse zur unabhängigen Architekturprüfung vorlegen.

## Verbindliche Zusatzprüfung – Independent Preflight P1–P5

**Wichtig:** Nicht nur die Architekturvorlage bestätigen. Unabhängig nach Gegenbeispielen suchen und folgende Repo-konkret belegte Probleme beantworten:

- **P1 – Backup Memory (kritisch):** `defaultMaxBackupReceiptBytes = 50 MiB` zählt nur Binärbelege; Base64 und ein zweites JSON-Envelope im HTTP-Client vergrößern den Payload. `backend/src/routes/backups.ts` benutzt `c.req.json()`. Workers haben derzeit 128 MB Memory/Isolate. Maximalgröße *aller* Repräsentationen, Limits, Speicherverdopplung und DoS-Schutz bewerten. Zwei praktikable Optionen inklusive Minimalvariante; präzise Teststrategie bei Grenzen. Quelle: https://developers.cloudflare.com/workers/platform/limits/.
- **P2 – Backup-Inventar:** `SupplierService.saved_suppliers_json`, `DeliveryOrderService.delivery_orders_json` liegen in FlutterSecureStorage und fehlen offenbar aus Backup-v3. Suchen nach allen weiteren persistenten Quellen. Entscheide explizit Einschluss/Ausschluss, Datenschutz, Gerätewechsel und Migration.
- **P3 – Delete-Identity:** `GET /v1/me` kann `ensureAccount` nach `DELETE /v1/me` erneut ausführen. Gemeinsame HullQ-Auth0-Identität und produktive Web-/App-Löschung mit Race-/Idempotenz-Garantie designen; Owner-Entscheidung sichtbar halten.
- **P4 – Reale EU-Region:** D1-/R2-Jurisdiktionen werden bei Erstellung festgelegt und müssen am tatsächlichen Account nachgewiesen werden; Repo-Config allein ist kein Beweis. Quellen: https://developers.cloudflare.com/d1/configuration/data-location/ und https://developers.cloudflare.com/r2/reference/data-location/.
- **P5 – Native Auth0:** Auth0 Flutter Universal Login/PKCE, Credentials Manager, Callback-/Logout-/Refresh-Lifecycle und Web-Portal-Session müssen auf echten Plattformen geprüft werden; JWT-JWKS-Mocks allein reichen nicht.

**Zu P1–P5 jeweils liefern:** beobachtete Dateien/Zeilen, verletzbare Invariante, Optionen, Entscheidungsvorschlag, Failure-/Concurrency-Tests, benötigter Owner-Nachweis und verbleibendes Risiko. Nicht belegt ≠ grün.

**Verbindliche Querschnittsprüfung:** Prüfe anschließend jeden API-Flow Ende-zu-Ende zwischen Flutter, Worker, D1, R2 und Portal. Suche vor allem State-Races und Fehler zwischen "R2 erledigt" und "D1 erledigt", zwischen "Daten gelöscht" und "Auth0-Sub noch gültig" sowie zwischen "Backup im Client bestätigt" und "vollständig wiederherstellbar". Phase-A-STOP bleibt erhalten.

## 31.10.2026 – Independent Gate-A-Review: verpflichtende Amendment-v2-Aufgabe

Der von Gemini vorgelegte Architekturbericht vom 31.10.2026 wurde unabhängig gegen main `2ec14c66e825078990689b5a753f1566bed13405` überprüft. **Gate A bleibt HOLD.**

**Lies zusätzlich zwingend:**
`docs/impl/BACKEND_CORE_phase_A_independent_review_2026-10-31.md`

Gemini muss **vor jeglichem Coding** einen **konsolidierten Architekturentwurf v2** liefern, der die Findings **A–H als gemeinsames Gesamtsystem** beantwortet. Es sind keine isolierten Patchvorschläge gesucht.

Pflichtstruktur:
1. Vollständiges mobiles **Upload- und Download**-Protokoll inklusive R2-/Worker-/Client-Memory- und Payloadlimits und Legacy-Backup-Kompatibilität; keine Halb-Lösung mit Streaming nur beim Upload.
2. Explizite D1/R2-Statusmaschine für Backup, Retention und Account Delete, Crash ohne `catch`, gleichzeitige Operationen, sichere Reconciliation und Garbage Collection; keine vermeintliche Cross-Resource-Atomarität durch `db.batch()`.
3. Gemessenes oder klar als ungemessen ausgewiesenes Backup-Budget. Keine stillschweigende Produktkürzung 50 MiB → 25 MB; belastbare Optionen plus Owner-Entscheidung.
4. Dokumentierter server- und clientseitiger Daten-/Privacy-Vertrag für strukturierte und ggf. opake Backup-Inhalte; der Server darf nicht fälschlich „IBAN-frei garantiert“ behaupten.
5. EU-Jurisdiktion für **D1 ausdrücklich `--jurisdiction=eu`**, kein bloßes `--location=weur`. Tatsächliche R2-Jurisdiktion EU ownerseitig prüfen.
6. Konto-Delete-State-Machine mit geteiltem Auth0-/HullQ-Sub, Minimal-Tombstone/Retention, expliziter Re-Registration, Webaccount-Löschung, gleichzeitigen alten JWTs und idempotenten Fehlern.
7. Provy-Entitlement-Autorität und Offline-Verhalten festlegen, ohne zu behaupten, dass fachliche Entitlements in Auth0-JWTs stehen müssen.
8. Fehlerhafte/nicht belegte Aussagen (Cloudflare CPU-Limits, 25-MB-Belegzahlen, Callback-URLs, angebliche R2-Atomarität, CORS als AuthZ) korrigieren.
9. Reale Datenmigrationen und komplettes Persistenzinventar in Backup/Restore mit ID-Remapping und bestehenden Shop-Statusfeldern als Release-Gate abbilden.
10. Issue #36 und alle bisherigen Owner-Gates beachten; 1–3 konkrete Owner-Entscheidungen formulieren und ein sinnvolles, kleines Slicing für Phase B empfehlen.

**Beweisstandard:** Zu jeder relevanten Invariante tatsächlicher Codepfad, möglicher Gegenfall und geplanter automatischer Negativtest. Jeder nicht belegte Plattform-/Cloud-Wert ausdrücklich als „offen“ kennzeichnen.

**STOP:** Nur überarbeiteter Design-/Testplan (keine Implementierung, kein Merge, kein Deployment, keine Owner-Acceptance-Simulation). Bericht zur unabhängigen Gate-A-Review vorlegen.

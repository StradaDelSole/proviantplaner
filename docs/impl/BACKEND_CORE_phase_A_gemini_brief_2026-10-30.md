# BACKEND-CORE – Gemini Phase-A-Auftrag (Architektur ausschließlich)

**Status:** Freigegebener Recherche-/Architekturauftrag, kein Feature-Release, kein Produktionscode.  
**Tracking:** Issue #36.  
**Arbeitsgrundlage:** AGENTS.md, GEMINI.md, docs/ENGINEERING_STANDARD_v1.0.md, docs/templates/ARCHITECTURE_GATE_TEMPLATE.md und docs/impl/BACKEND_CORE_architecture_gate_2026-10-30.md.

## Deine Aufgabe

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
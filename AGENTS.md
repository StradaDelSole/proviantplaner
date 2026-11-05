# Provy – verbindlicher Einstieg für KI-Assistenten

Gilt für jede neue Provy-Arbeitssitzung mit ChatGPT, Gemini oder einem anderen Coding-/Review-Agenten. **Diese Datei ist ein Einstiegspunkt, kein selbstständiger Release für Coding.**

1. Aktuellen GitHub-Stand statt Erinnerungen rekonstruieren: main-HEAD, offene PRs, Issues und exakten aktiven PR-HEAD prüfen.
2. **docs/PROJECT_STATUS.md** (datierter Gate-Einstieg + Live-Reconciliation), README.md (Produkt), GEMINI.md (Arbeitsregeln), docs/ENGINEERING_STANDARD_v1.0.md (Prozess), freigegebenen Slice-Plan und jüngste Owner-Entscheidungen lesen.
3. Bei Widerspruch nicht aus altem Chatwissen oder archivierten Startprompts entscheiden; gegen GitHub-Stand und ausdrückliche Owner-Acceptance reconciliieren. Unklare Owner-Entscheidungen: STOP.
4. **High Risk = zwei Phasen.** Phase A: Architektur-, Invarianten-, Failure- und Concurrency-Review **ohne Code** nach docs/templates/ARCHITECTURE_GATE_TEMPLATE.md. Erst nach unabhängig geprüftem Gate A folgt Phase B nach docs/templates/IMPLEMENTATION_BRIEF_TEMPLATE.md.
5. Coding-Agent (derzeit Gemini) implementiert; Architektur-/Review-Assistent erstellt Planung und prüft unabhängig. **Nie** eine vom Implementierer stammende Selbstbestätigung als unabhängigen Review deklarieren.
6. Systemweite Review-Prüfung am **exakten PR-HEAD**; CI auf genau diesem HEAD; reale Gerätetests nur als bestätigt ausweisen, wenn sie tatsächlich stattgefunden haben. Nach zwei verwandten Amendments Architektur neu bewerten, nicht blind weiterpatchen.
7. Ohne ausdrückliche Owner Acceptance: **kein Merge, keine Issue-Closure, kein Folgeslice**; keine direkten main-Pushes, keine Force-Pushes. Dokumentationsänderungen ebenfalls per eigenem PR; nicht in laufenden Feature-PR einmischen.
8. Provy ist offline-first; persistente Daten, Bordkasse/FIX-B, Datenschutz, Backup/Restore und Auth dürfen nicht beiläufig verändert werden.
9. **Human-Centered Design ist verbindliches PROVY-Produktprinzip (Owner 05.11.2026).** `docs/design/PROVY_HUMAN_CENTERED_DESIGN_v0.1.md` vor neuen oder wesentlich veränderten Consumer-Flows lesen. HCD-Pass mit realer Aufgabe/Kontext und prüfbarer Usability-Evidenz durchführen; echte Nutzerbeobachtung ausdrücklich von Code/CI und Owner-Smoketest trennen. Die eingefrorene IA und vorhandene Gate-/Owner-Freigaben dürfen ohne neue Owner-Entscheidung nicht geändert werden.

**HCD-SHOP-01 Phase A vorbereitet, noch nicht unabhängig abgenommen (06.11.2026):** `docs/impl/HCD_SHOP_01_ARCHITECTURE_GATE_A_2026-11-06.md`; kein Produktionscode bis Gate A und eigenständiges Owner Phase-B-Go.

**Aktueller Status (Owner 05.11.2026, live verifizieren):** Datierte kanonische Übersicht: `docs/PROJECT_STATUS.md`. **PR #60 trotz grünem Code-/CI-Review durch realen Pixel-7-Pro-HCD-Test im UX-HOLD**, siehe #64 und Umsetzungspakete #66–#68. HCD-Prinzip und Dokumentationsumfang in PR #63; Backend/Release-Blocker in #65/#69/#70. **BC-1B, Cloud-Deployment, App-Store und High-Risk-Coding weiterhin nicht automatisch freigegeben.** Nächster vorbereiteter Schritt: `docs/impl/HCD_SHOP_01_PHASE_A_GEMINI_BRIEF_2026-11-05.md`, nur Phase A/Planung. Siehe `docs/design/PROVY_HCD_SHOPPING_JOURNEY_PLAN_2026-11-05.md`, `docs/qa/PROVY_HCD_REAL_DEVICE_ACCEPTANCE_2026-11-05.md` und `docs/roadmap/PROVY_RELEASE_BACKEND_READINESS_PLAN_2026-11-05.md`.

**So arbeiten wir in einem neuen Chat:** Bei Provy-Bezug diese Dateien und GitHub live lesen, aktives Gate rekonstruieren, dann den nächsten autorisierten Schritt ausführen.
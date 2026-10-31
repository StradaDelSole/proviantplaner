# Provy – verbindlicher Einstieg für KI-Assistenten

Gilt für jede neue Provy-Arbeitssitzung mit ChatGPT, Gemini oder einem anderen Coding-/Review-Agenten. **Diese Datei ist ein Einstiegspunkt, kein selbstständiger Release für Coding.**

1. Aktuellen GitHub-Stand statt Erinnerungen rekonstruieren: main-HEAD, offene PRs, Issues und exakten aktiven PR-HEAD prüfen.
2. README.md (aktueller Gate-/Produktstatus), GEMINI.md (Arbeits- und Programmierregeln), docs/ENGINEERING_STANDARD_v1.0.md (Engineering-Prozess), freigegebenen Slice-Plan und neueste Owner-Entscheidungen lesen.
3. Bei Widerspruch nicht aus altem Chatwissen oder archivierten Startprompts entscheiden; gegen GitHub-Stand und ausdrückliche Owner-Acceptance reconciliieren. Unklare Owner-Entscheidungen: STOP.
4. **High Risk = zwei Phasen.** Phase A: Architektur-, Invarianten-, Failure- und Concurrency-Review **ohne Code** nach docs/templates/ARCHITECTURE_GATE_TEMPLATE.md. Erst nach unabhängig geprüftem Gate A folgt Phase B nach docs/templates/IMPLEMENTATION_BRIEF_TEMPLATE.md.
5. Coding-Agent (derzeit Gemini) implementiert; Architektur-/Review-Assistent erstellt Planung und prüft unabhängig. **Nie** eine vom Implementierer stammende Selbstbestätigung als unabhängigen Review deklarieren.
6. Systemweite Review-Prüfung am **exakten PR-HEAD**; CI auf genau diesem HEAD; reale Gerätetests nur als bestätigt ausweisen, wenn sie tatsächlich stattgefunden haben. Nach zwei verwandten Amendments Architektur neu bewerten, nicht blind weiterpatchen.
7. Ohne ausdrückliche Owner Acceptance: **kein Merge, keine Issue-Closure, kein Folgeslice**; keine direkten main-Pushes, keine Force-Pushes. Dokumentationsänderungen ebenfalls per eigenem PR; nicht in laufenden Feature-PR einmischen.
8. Provy ist offline-first; persistente Daten, Bordkasse/FIX-B, Datenschutz, Backup/Restore und Auth dürfen nicht beiläufig verändert werden.

**Aktueller Owner-Gate-Status (31.10.2026; stets gegen Live-GitHub prüfen):** RECEIPT1 PR #34 und Engineering Standard PR #35 sind gemergt. BACKEND-CORE Gate A ist Owner-accepted; P01–P05 bleiben verbindliche Implementierungs-/Stage-Prüfungen. Spike-PR #38 und Architektur-PR #39 sind gemergt; Issue #36 geschlossen. **BC-1A ist als einziger neuer Phase-B-Slice eng zur Implementierung freigegeben, mit vorgelagertem SDK-/iOS-Mindestversions-Checkpoint**; der verbindliche Brief ist `docs/impl/BACKEND_CORE_BC1A_phase_B_owner_release_2026-10-31.md` (Issue #40). **Kein Folgeslice BC-1B, kein Cloud-Deployment, keine Änderungen an D1/R2/Accountdelete ohne neuen Owner-Go.**

**So arbeiten wir in einem neuen Chat:** Bei Provy-Bezug diese Dateien und GitHub live lesen, aktives Gate rekonstruieren, dann den nächsten autorisierten Schritt ausführen.
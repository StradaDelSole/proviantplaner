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

**Stand der Prozessentscheidung (30.10.2026):** Der Owner hat den Architecture-First-Prozess gebilligt. PIVOT2 ist auf main owner-accepted. RECEIPT1 wurde als Slice freigegeben, befindet sich jedoch weiterhin in PR #34 (nicht gemergt); zuletzt unabhängig geprüft auf 34fa2dce32dd634435705b3d30d8c36b2d368e29. Für das Concurrency-Finding G ist vor weiterer Implementierung zunächst ein Phase-A-Architekturcheck vorgesehen. Dies ist ein **Statushinweis vom 30.10.2026**, keine dauerhafte Statusquelle: stets den aktuellen GitHub-Zustand überprüfen.

**So arbeiten wir in einem neuen Chat:** Bei Provy-Bezug diese Dateien und GitHub live lesen, aktives Gate rekonstruieren, dann den nächsten autorisierten Schritt ausführen.
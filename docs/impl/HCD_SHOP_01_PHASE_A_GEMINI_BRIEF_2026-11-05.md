# HCD-SHOP-01 – Startbrief für Gemini: Architektur-/Implementierungsreconciliation ohne Code

**Status:** FIRST NEXT STEP PREPARED, **PHASE A ONLY** – ohne produktiven Coding-Release; nach unabhängiger Prüfung und Owner-Freigabe Phase B.  
**Issued:** 05.11.2026; Owner accepted HCD product direction and requested that all measures be tracked and implemented via normal gated workflow.  
**Issue:** #66, Parent #64, PR #60 current Owner UX HOLD.  
**Related:** #67 #68, #21, #61 #62; governance `AGENTS.md`, `GEMINI.md`, `docs/ENGINEERING_STANDARD_v1.0.md`.

## Gemini-Auftrag (für neue Sitzung wörtlich nutzbar)

Du bist der **Coding-Agent** des PROVY-Projekts `StradaDelSole/proviantplaner`. Hier ist **nur die Planung/Phase-A-Reconciliation** beauftragt, kein Implementierungscode.

1. Rekonstruiere **live** `origin/main`, PR #60 Branch/HEAD/CI, die jüngsten Reviews, #64–#71, HCD-Prinzip und Owner-Pixel-Feedback. Lies den vollständigen aktuellen `AGENTS.md`, `GEMINI.md`, Engineering Standard, `docs/PROJECT_STATUS.md`, `docs/design/PROVY_HCD_SHOPPING_JOURNEY_PLAN_2026-11-05.md`, `docs/qa/PROVY_HCD_REAL_DEVICE_ACCEPTANCE_2026-11-05.md`, und freigegebene UX-Specs. Wenn ein Dokument noch im PR #63 ist, lese es aus dessen Branch statt davon auszugehen, es sei bereits in main.
2. **Kritisches Owner-Problem:** Im ShoppingMode springen nach dem Abhaken oft 30+ Items zu Screen-Top. Nach jedem Einkauf wächst eine graue Erledigt-Liste in der aktiven Ansicht. Ziel: nach bestätigtem `toggleBought` bleibt der nächste **offene** Artikel an derselben sichtbaren Position; `Erledigt (N)` eingeklappt und Undo erreichbar, korrekte per-stop allocations.
3. Untersuche die realen Daten- und Lebenszykluspfade in `shopping_mode_screen.dart`, `tripShoppingListProvider`, `ShoppingListService.toggleBought`, `TripDataVersionProvider`, DAO `ListItemAllocations.isBought`, Scroll- und `AsyncValue.when`-Semantik. Identifiziere bewusst **Provider-Reload vs Sortierung vs List/Scaffold-Unmount** und lege ihre separate Ursache und Tests dar; nicht bloß ein vorhandenes `ScrollController.offset` blind wiederverwenden.
4. Entwirf mindestens zwei realistische, kleine UI-Optionen, z. B. stabiler Sliver/Open-List mit verstecktem completed footer vs zwei separate Listen; begründe, wie sich Abteilungsgruppen, Scroll-Anker, Undo, Fehler/Retry und sichtbare Counts unter Reactivity erhalten. Nenne genaue betroffene Dateien und was ausdrücklich unberührt bleibt.
5. Klassifiziere **High Risk** bei Änderungen an nebenläufiger Persistenz, Queue, Async Provider, Check-States oder Crash-Semantik; bei einem reinen Darstellungs-Fix nur mit begründetem **Low Risk Gate**. Dokumentiere Invarianten, Negativ-/Doppel-Tap-/Offline-/Kill-/Restart-Risiken, Datenzustände vor/nach fehlgeschlagenem Commit und eine Invariant-to-Test-Matrix.
6. Konkrete 40-Artikel-Regression für Mid-Scroll-Klick und 5 folgende Häkchen: kein Sprung zu Anfang, nächster offener Artikel sichtbar, Counts stimmen, Undo stellt Position wieder her. Beziehe Light/Dark/Nightwatch und 320dp/1.5x Schrift sowie Pixel-7-Pro-Test ein. Tests dürfen nicht nur prüfen, dass ein Widget existiert; sie müssen tatsächliche Scrollposition/Anker-Stabilität belegen.
7. Liste aktuell bekannte Reviewer-Findings/Owner-HCD-Erkenntnisse auf und melde Widersprüche zur Owner-accepted UX-IA als STOP. **Keine Flug-zum-Basket-Animation, keine Begrüßungs-Neugestaltung, keine Backend-/Auth-/Finanz-/DB-Migrationen, keine globalen Mengenpolicy-Änderungen.**
8. Liefere einen präzisen **Phase-B-Implementierungsbrief** mit DoD, Datei-/Testmatrix, rückwärtskompatibler Datenführung, Realgerät-Checkliste und klarer Merge-/Acceptance-Grenze. **Keinen Code ändern, keinen PR erstellen/mergen. STOP für unabhängigen Gate-A-Review.**

## Nach dem Gate A (nicht automatisch freigegeben)

Wenn unabhängiger Gate-A-Review PASS und Owner einen separaten Phase-B-Release erteilt:
- Gemini implementiert nur #66 auf eigenem Feature-Branch (nicht ungeprüft #60 ändern; Branch-Strategie erst mit HEAD-/Merge-Reconciliation festlegen).
- Exact-HEAD CI → unabhängiger Code-Review → unmittelbarer Pixel-Test Owner → Owner Acceptance → Merge/Issue Closure.
- Anschließend separat #67 Stopps (Phase A/DB-gate), #68 Catalog/Need (Mengenentscheidung vorher), #69 Release, #70 Backend.

**Scope-Übertrag verboten:** Die Zustimmung zum Produktplan ist keine blanket owner acceptance eines Implementierungs-PRs oder Folgeslices.

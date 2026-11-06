# PROVY – HCD-SHOP-01 / #66: Owner Phase-B Release

**Datum:** 06.11.2026  
**Status:** **OWNER-APPROVED PHASE B — STEP 0 + STEP 1 RELEASED; STOP FOR PHYSICAL PIXEL CHECK BEFORE STEP 2**  
**Owner-Nachricht im PROVY-Projektchat:** auf die explizite kombinierte Frage „Stimmst du diesen drei Entscheidungen zu und gibst damit Phase B für Gemini bei HCD-SHOP-01 frei?“ antwortete der Owner **„ich stimme zu“**. Dies ist die ausdrücklich erteilte Freigabe der drei konkreten Entscheidungen und von Phase B für **Issue #66**; keine allgemeine Produkt-/Release-/Merge-Acceptance.

## Geprüfte Ausgangslage (vor Gemini-Coding erneut live prüfen)

- Canonical Repository: `StradaDelSole/proviantplaner`.
- `main` zum Entscheidungszeitpunkt: `e00c01d35763790fe430a8c331436e120478f2dd`.
- PR #60, UX-HOLD: `af34fd9a88c3c7a4cf0e281ec187da2e5a39b855`, OPEN; **nicht mergen**.
- PR #63, Dokumentations-PR: `6e53aa51d9fad0810f612cb1a6e991c35fb81b74` vor Eintrag dieser Entscheidung; OPEN, nicht gemergt; zuletzt CI `42216433999` SUCCESS an genanntem SHA.
- Accepted Architecture Gate A v0.2: **GATE A PASS**, unabhängig durch Claude am exakten Doc-HEAD `c05329a5bdc4df1ac866b047ae5defce62afe324` (F-01–F-10 CLOSED), CI für diesen Doc-HEAD `42197854391` SUCCESS. Archiv im PROVY-Projektordner: `13_HCD_SHOP_01_INDEPENDENT_GATE_A_V02_PASS_2026-11-06.md`.
- Verbindliche Architektur: `docs/impl/HCD_SHOP_01_ARCHITECTURE_GATE_A_2026-11-06.md` **Fassung am reviewed exact SHA**. Spätere Dokumentations-Folgemeldungen sind kein neuer Architekturreview.

## Drei verbindliche Owner-Entscheidungen

1. **S1 ACCEPTED:** Beim Kauf rückt der nächste offene Artikel **natürlich an die frei werdende Zeilenposition**, statt einen Nachbarartikel an seiner alten absoluten Position festzuhalten. **Keine aktive Scroll-Offset-Korrektur:** kein `jumpTo`, `animateTo`, `correctBy` oder selbstgebautes Custom-Sliver-Ankerverfahren. Geometrische Klemmung am Listenende ist zulässig und muss getestet werden.
2. **TWO-STAGE + PIXEL CHECK ACCEPTED:** Unter dem **einzigen Issue #66** zuerst **Schritt 0: Fehler auf unverändertem `main` durch rot laufenden Test reproduzieren**, dann **Schritt 1: Stabilität, Fehlerwahrheit, Lifecycle**. **STOP nach Schritt 1**: eigener CI-/Test-/Delta-Bericht und unmittelbar echter **Pixel-7-Pro-Zwischentest** durch Owner, ohne vorhandene Test-/Törndaten zu löschen. Erst nach dokumentiertem positivem Zwischenbefund **Schritt 2: `Erledigt (N)` eingeklappt, reine Zeilenmodell-Funktion, natürliche Reihenfolge** aus demselben genehmigten Phase-B-Plan. Wenn Schritt 1 unerwartet andere Ursachen zeigt oder Pixel scheitert: STOP für Ursachen-/Architekturprüfung, kein automatischer Schritt 2.
3. **BRANCH / INTEGRATION ORDER ACCEPTED:** `slice/hcd-shop-01-stable-checkout` von **live `main`** statt Branch #60. #66 separat reviewen und auf dem Pixel testen; erst anschließend PR #60 kontrolliert integrieren/rebasen, insbesondere die sechs ARB-Dateien auf kollidierende Keys prüfen. **Nichts automatisch mergen.**

## Exakter freigegebener Coding-Umfang

**Jetzt freigegeben:** ausschließlich **#66 Schritt 0 + Schritt 1** nach **freigegebenem** `docs/impl/HCD_SHOP_01_PHASE_B_IMPLEMENTATION_BRIEF_2026-11-06.md` (ab diesem Owner-Release als bindender Phase-B-Brief mit Stop nach Step 1). Ziele: Basis-Rot-Test; stabiler Einkaufs-Scrollable bei Reload, drei Errorzustände, keine doppelte manuelle Invalidierung, truthful `toggleBought` false/exception, pro Item Pending/Undo guard, Mounted-/Recovery-Sicherheit. Codeoberfläche vorzugsweise `shopping_mode_screen.dart`, passende neue Tests; keine Service-/DAO-/Provider-/Schema-/Ledger-/Auth-/Backend-Änderung.

**Für den zweiten Teil konzeptionell freigegeben, aber am Zwischen-Gate gestoppt:** nach positivem Owner Pixel-Check `Erledigt (N)`/ListView.builder nach S1, lokale UI-Transformation, sechs ARB-Locales, Tests.

**Nicht freigegeben:** PR #60/63-Merge, Produkt-Owner-Acceptance, Issue-Closure, Cloud/BC-1B, Guest-Shopping, Katalog-/Bedarfspolicy #68, Einkaufsstoppzustände #67, Welcome-Redesign, Flight-to-Basket-Animation.

## Zuständigkeiten und Belege

- **Gemini:** implementiert nur freigegebenen Code, liefert zunächst **ROT-before** (kein erfundener Fail) und dann **Step-1** Ergebnis mit exact SHA, Tests/CI und Delta; STOP für Independent Code-Review und echten Pixel-Zwischentest.
- **ChatGPT/Architektur-Assistent:** unabhängiger Code-/Test-/CI-Review, HCD-Gates, Repo-Dokumentation, Status- und Review-Reconciliation.
- **Owner:** realer Pixel 7 Pro Test mit 40+ Positionen; entscheidet über erfolgreiche Step-1-Zwischenabnahme und spätere PR-Acceptance/Merge.
- **DoD:** Schritt 1 endet **nicht** mit „fertig“ oder Issue-Closure; nur nach späterem Step 2, exact-HEAD Review, echtem Pixel-Endtest und explizitem Owner Acceptance ist #66 DONE.

**STOP-Regel:** Ein positiver Phase-A-/Code-/CI-Review ersetzt keine echte Geräteabnahme. Wenn Ursache beim roten Test nicht reproduzierbar ist, nicht künstlich einen Fail erzeugen; mit Evidenz zurück zum Gate und keine spekulative Korrektur.

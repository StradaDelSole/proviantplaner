# Phase B – Implementation Brief: PROVY HCD-SHOP-01 / #66

**Status:** **DRAFT / NOT RELEASED** – Code erst nach expliziter Owner-Zustimmung zu S1, Zweistufenverfahren und #60-Integration.  
**Erstellt:** 06.11.2026.  
**Aktueller main-SHA zum Gate A:** `e00c01d35763790fe430a8c331436e120478f2dd` – am Implementationstag erneut verifizieren.  
**Review-Branch / PR:** Dokumentations-PR #63, `docs/hcd-product-principle-2026-11-05`; Implementierungs-Branch erst nach Owner-Release `slice/hcd-shop-01-stable-checkout` **aus live main**.  
**Owner-Release:** **PENDING** (kein Coding aus diesem Entwurf automatisch).  
**Akzeptierter Phase-A-Entwurf:** `docs/impl/HCD_SHOP_01_ARCHITECTURE_GATE_A_2026-11-06.md`, v0.2, Independent Review von Claude = **GATE A PASS** am exakt geprüften Dokumentations-HEAD `c05329a5bdc4df1ac866b047ae5defce62afe324`; vollständige Belegdatei im PROVY-Projektordner (Owner-Upload `Eingefügtes Markdown(6).md`). Änderungen am Docs-PR nach diesem HEAD sind *Status/Brief*, keine stillschweigende erneute Architekturfreigabe.  
**Explizit offene Owner-Details:** S1; zwei interne Stufen mit Pixel-Zwischentest; Integrations-/Merge-Reihenfolge von #66 gegenüber dem offenen PR #60. Bis Zustimmung STATUS DRAFT.

## 1. Präziser Scope und Einschränkungen

**Zu implementieren:**
- **Schritt 0 – Fails-before:** reproduzierbarer Widget-Test auf unmodifiziertem `main` mit 40+ Items/3 Departments, mittiger Scrollposition, mehrere `toggleBought`-Operationen, verzögerter Provider-Reload und frame-by-frame Messung. Tatsächlichen Spinner/Scrollable-Teardown oder Offset-Reset **beweisen**, bevor Ursache als sicher gilt. Bei fehlender Reproduktion keine Fake-ROT-Behauptung; unabhängiges Architekturgate nach tatsächlicher Ursache fragen. Regressionstest muss nach dem Fix identisch grün sein.
- **Schritt 1 – Stabilität/Persistenzwahrheit:** Änderungen vorzugsweise nur in `lib/features/shopping_list/ui/shopping_mode_screen.dart`. Valid vorhandene Daten über Riverpod-Re-/Refresh-Loading erhalten; drei Fehlerfälle getrennt (initialer Fehler ohne Daten; Reload-Fehler mit prior data + sichtbare Warnung und Retry; Stopp-ID nicht vorhanden). Nach Checkbox `toggleBought` **keine zusätzliche direkte Provider-Invalidierung**; bestehender Service-Callback übernimmt. Per-item Pending Guard; `true` bestätigt, `false` und Exceptions geben sichtbare Fehlermeldung und erlauben sichere Wiederholung ohne vorgezogene Erfolgsanzeige. `mounted` vor jedem `ref`/UI-Zugriff nach `await`. Bestehende `shoppingDone`-/Postpone-/Storage-Wege nicht ändern.
- **Nach Schritt 1 – Zwischen-Gate:** Flutter-Tests/Analyzer + kurzer Pixel-7-Pro-Test mit echten 40+ Positionen, fünf Checks/Undo und Reload. Beobachtetes Ergebnis dokumentieren. Bei fortbestehendem Sprung zuerst reproduzieren, **nicht** blind zusätzliche Anchor-Hacks. Schritt 2 nur, wenn Owner diese Teilung/Weiterführung bestätigt hat.
- **Schritt 2 – natürliches S1-Nachrücken und Erledigt-Footer:** reine Funktion `buildShoppingModeRows(data, stopId, {expandedCompleted})` mit `DepartmentHeader | OpenItem | CompletedHeader(N) | CompletedItem`; ein `ListView.builder` mit stabilen getrennten Keys für offen und gekauft und ggf. `findChildIndexCallback`. Reihenfolge offene Produkte je Abteilung stabil, „Erledigt (N)“ eingeklappt am Ende. Gekaufte Artikel erscheinen nur darin; Undo macht sie wieder offen. AppBar-Fortschritt und Bereichszähler sind dieselben per-Stop-Zahlen. Beim Kauf rückt der nächste offene Artikel auf den Platz der gekauften Zeile, **kein** `jumpTo`/`animateTo`/`correctBy`/Custom Sliver. Listenende darf natürlich durch `maxScrollExtent` clampen, kein Sprung zu Offset null. 44–48dp Targets, sechs Locale ARB Keys, Light/Dark/Nightwatch/Reduced Motion/320dp und Text 1,5×.

**Nicht implementieren / keine stillen Produktänderungen:**
- Keine Änderung an `ShoppingListService`, DAO/Drift, `tripShoppingListProvider`/Recovery-Gate, `isBought`-Persistenzvertrag, Stop-Zuordnung oder first-stop-Restmengenlogik. **Insbesondere NICHT `onTripDataChanged` nur bei `result==true` auslösen.**
- Keine zusätzliche UI-/Datenbank-Queue, keine Flug-zum-Korb-Animation, kein Welcome-/FlightStrip-Umbau, keine Änderung der globalen Mengenrichtlinien, keine Auth0/Backend/Bordkasse-/Cloud-Arbeit und keine Schema-Migration.
- Keine Übernahme fremder ungemergter PR-Commits in Implementierungsbranch. Keine Änderung der bestehenden UX Command-Center-Karten.

**Zulässige Dateien:** `shopping_mode_screen.dart`, neue testbare reine Zeilenmodell-Datei unter `features/shopping_list/ui/` bei Bedarf, fokussierte Testdatei `test/features/shopping_list/shopping_mode_viewport_test.dart`, plus die sechs `lib/l10n/app_*.arb`-Dateien für neue Strings. Alle weiteren Produktionsdateien nur nach dokumentiertem independent Gate-Abgleich; kein stilles Scope-Wachstum.

## 2. Bindende Architektur & Invarianten

| ID | Invariante | Implementierungsort | Test |
| --- | --- | --- | --- |
| I1 | Gekauft-Status strikt pro Einkaufsstopp | View-Filter aus bestehendem Domain-Model | 2 Stops, derselbe Artikel |
| I2 | Packungen/Restmengen durch Kauf-Check unverändert | UI-only, DAO bleibt | DB vor/nach |
| I3 | Kein Erfolg/Erledigt bei false oder Exception | Pending + Fehler-UI | delayed false/throw/retry |
| I4 | Beim 5×-Abhaken in Mitte kein Full-Scaffold-Teardown/Top-Reset | AsyncValue + ListView | Frame- und RenderBox-Geometrie |
| I5 | Keine Doppelanzeige: Offen+Erledigt=Gesamt | pure row model | Unit + Widget |
| I6 | schnelle Doppeltaps/Undo/different rows robust | local guards, existing FIFO | gated completers |
| I7 | Offline und Recovery-Gate respektiert | bestehender Service | Recovery-error scenario |
| I8 | Storage/Finish/FlightStrip/Finanzen unverändert | Out of scope | Legacy regression |
| I9 | Clamping nur natürlich am Listenende | single scrollable, no programmatic offset | near-end test |
| I10 | initial error / stale-data-error / missing stop je korrekt | error handling | three distinct tests |

**Commit-/Recovery-/Retry-/Concurrency-Vertrag:**
Ein Häkchen kann zwischen Tap und Commit „wird gespeichert“ anzeigen; finale Erledigt-Zählung erst nach bestätigtem DB-Wahrheitszustand. `false`/Exception = kein bestätigter Kauf, Hinweis/Retry, durch erneutes Laden tatsächlichen DB-Zustand herstellen. Die vorhandene Service-Benachrichtigung bleibt unverändert. Nicht naiv `skipError:true` setzen: bei `AsyncError(hasValue:true)` Liste mit sichtbarem Fehlerhinweis, bei `hasValue:false` initiales Fehlerbild. Am gepinnten Riverpod-2.x-Verhalten testen, nicht bloß vermuten.

## 3. Implementierungsfolge (mit STOP-Punkten)

1. Live `main`, #60, #63, #66, CI und Repo-Anweisungen erneut lesen. Vor Coding den **expliziten Owner Phase-B-Release** nachweisen; bei Unklarheit STOP.
2. Neuen Branch aus live `main` anlegen, keine ungemergten #60-Commits übernehmen. Test-Fixture mit 40+ Artikeln in In-Memory-DB und echten Stop-Zuordnungen, reproduzierbare ROT-Testläufe auf Baseline protokollieren (auch wenn Tests zunächst nur experimentell im Feature-Branch laufen).
3. **Schritt 1** implementieren, Analyzer/Tests, Fail-before/Pass-after-Delta und negative Fehlerpfade liefern. **STOP für kurzen echten Pixel-Zwischentest**, dokumentieren.
4. Nach dokumentiertem Zwischen-Gate **Schritt 2** implementieren: pure row model und Footer, S1 natürlicher Übergang, ARB Lokalisation. Keine komplizierten Offset-Hacks.
5. Alle S01-Tests, gesamte Flutter-/Backend-CI, Adversarial Self-Review, exakter PR HEAD, Code-Review/Owner Pixel-Test. Ggf. gezielte Amendments, keine opportunistischen Refactors.
6. Vor jedem Merge/Integration mit #60 separat **ARB-Konflikte** im Diff prüfen, alle 6 Locales und generierte L10n testen, vollständige PR-Integration und Pixel Regression durchführen. **NICHT automatisch mergen.**

## 4. Pflicht-Testmatrix

| Test | Typ | Tatsächlich erwartete Assertion | Status |
| --- | --- | --- | --- |
| S01-BASE-RED | Widget, main baseline | tatsächlicher Full-Screen-Spinner/Scrollable-Remount oder belegter Offset-Reset auf `main`, frame-by-frame | PENDING |
| S01-40-POS | Widget | 40 Artikel, 3 Departments; fünf Checkmarks in Mitte, kein programmatischer Offsetwechsel, nächster offener Artikel auf natürlicher Tap-Position | PENDING |
| S01-END-HEADER | Widget | letztes Item/Departmentheader, near-end clamp; kein Sprung zu Top | PENDING |
| S01-ASYNC | Widget | alte valide Liste während Reload, initial Load vs Reload-Fehler+Retry, missing stop | PENDING |
| S01-FALSE-THROW | Fake/DB Integration | false/Exception kein Kauf-Erfolg, Retry möglich, DB wahr | PENDING |
| S01-2TAP | Widget race | same-item Pending blockiert Duplikat, andere Items geschützt | PENDING |
| S01-UNDO | Widget+DAO | expanded Erledigt, Undo, Counts und Stop-Isolation richtig | PENDING |
| S01-RESTART | Integration | Screen remount, neuer ProviderContainer, gleiche DB; Kaufstatus bleibt | PENDING |
| S01-A11Y | Widget+Device | 320dp, 1,5×, 412×915, Nightwatch + Reduced Motion + 6 Locales | PENDING |
| S01-LEGACY | CI | unveränderte bestehende UX-B/PIVOT1/RECEIPT1/BC1A/FlightStrip Regressionen | PENDING |

**Bestehende Regressionen nicht abschwächen:** `test/features/ux/ux_b_shopping_and_delivery_test.dart`, `test/features/shopping_list/shopping_list_persistence_test.dart`, `pivot1_assisted_list_test.dart`, `fix_a_journey_test.dart`, FlightStrip F1–F6 und gesamte CI.

**Manuelle Tests (OFFEN bis physisch bestätigt):** Pixel 7 Pro nach Schritt 1 und nach vollem Slice. Einkauf mit 40+ Artikeln und Mitte-Scroll, 5× Check, Undo, Wechsel zwischen Stopps, offline, Hintergrund/Neustart; kein Clearing realer App-Daten. Prüfe eine Hand, 320dp, Nightwatch und 1,5× Text wo möglich. Device-Resultat ist keine automatisierte Testbehauptung.

## 5. Self-Review – Gegenbeispiele

- Bleibt die Liste am 1. und späteren validen Reload sichtbar? Wird ein Fehler mit alten Daten gemeldet statt verschluckt?
- Ist die Zeile noch nicht gekauft, wenn `toggleBought` false/throw ergibt? Kann ein Fall nach Commit aber vor UI-Aktualisierung unterbrochen werden, ohne dauerhaften falschen Erfolg?
- Hängt Pending an Artikel+Stop und ist nach Dispose harmlos? Was passiert bei zwei schnellen taps?
- Verschwinden Header und ScrollExtent am Ende auf natürliche Weise? Testet die Fixture wirklich verschiedene Row Heights?
- Bleiben erste Stop-Restmenge und zweiter Stop-Allokationen exakt konstant?
- Echte RenderBox-/Frame-Testassertionen oder nur pumpAndSettle/Widget-Existenz?
- ARB keys und Semantik in 6 Sprachen, semantisch nicht Bordkassen-`fundSettled` recyceln?
- Bedeckt eine SnackBar den Footer-Button `shoppingDone`?
- Kein versehentliches Beseitigen der Recovery-Gate-Sperre, keine Deep Links oder Auth0-Änderung?
- Kann eine noch nicht gemergte #60-Änderung in L10n die neuen Keys oder Values überschreiben?

## 6. Abschlussbericht / Review-Gate

- Phase-B Owner Release mit drei beschlossenen Detailpunkten: **PENDING**
- Implementierungsbranch/aktuelles main-SHA: **PENDING**
- Roter Baseline-Run `main`: **PENDING**
- Step-1 Test/CI/Owner Pixel Zwischenbefund: **PENDING**
- Step-2 PR-HEAD, Dateiliste/Delta: **PENDING**
- Test-Suite, genaue Flutter-/Backend-Actions Run/Head: **PENDING**
- Independent exact-HEAD Code-Review: **PENDING**
- Physischer Pixel Endtest: **PENDING**
- Owner Product Acceptance / Merge / Issue Closure: **PENDING**

**STOP:** Keine Gemini-Produktcodeänderung, kein Merge, kein #66-DONE und kein #60-Release, bis explizite Owner-Entscheidungen und die nachfolgenden Nachweise vorliegen.

# HCD-SHOP-01 / #66 – Schritt 1 Abschlussbericht (inkl. Amendments 1, 2 & 3)
## Checkout-Scrollstabilität, Persistenzwahrheit & Concurrency Guard

**Status:** REVIEW – SCHRITT 1 INKL. AMENDMENTS (R1–R6) VOLLSTÄNDIG IMPLEMENTIERT & VERIFIZIERT – STOP VOR SCHRITT 2 (AWAITING INDEPENDENT RE-REVIEW & PIXEL 7 PRO CHECKPOINT)  
**Datum:** 06.11.2026 / 08.11.2026  
**Tracking-Issue:** #66  
**PR:** #72  
**Branch:** `slice/hcd-shop-01-stable-checkout`  
**Basis-Commit:** `e00c01d35763790fe430a8c331436e120478f2dd` (`origin/main`)  
**Architektur- & Release-Vorgaben:**  
- `docs/impl/HCD_SHOP_01_ARCHITECTURE_GATE_A_2026-11-06.md` (v0.2)
- `docs/impl/HCD_SHOP_01_PHASE_B_IMPLEMENTATION_BRIEF_2026-11-06.md`
- `docs/impl/HCD_SHOP_01_OWNER_PHASE_B_RELEASE_2026-11-06.md`

---

## 1. Schritt 0: Reproduzierbares Red-Before-Protokoll auf `main` (R4)

Das gemeldete Fehlverhalten wurde direkt auf dem unveränderten Baseline-Commit `e00c01d35763790fe430a8c331436e120478f2dd` (`origin/main`) mit dem Test `S01-40-POS` reproduziert.

### 1.1 Reproduktionsanleitung für Reviewer (Schritt-für-Schritt)
Um das Baseline-Fehlverhalten auf einem sauberen `main`-Stand ohne Seiteneffekte nachzustellen:

```bash
# 1. Separaten Git-Worktree auf den exakten Basis-Commit auschecken:
git worktree add -d ../proviantplaner-baseline e00c01d35763790fe430a8c331436e120478f2dd
cd ../proviantplaner-baseline

# 2. Ausschließlich die neue Testdatei aus dem Feature-Branch overlayen (Produktionscode bleibt 100 % unverändert auf main):
git checkout slice/hcd-shop-01-stable-checkout -- test/features/shopping_list/shopping_mode_hcd_test.dart

# 3. Testlauf ausführen:
flutter test test/features/shopping_list/shopping_mode_hcd_test.dart --name "S01-40-POS"

# 4. Ausschließlich den temporär angelegten Baseline-Worktree sicher aufräumen
# (ohne bestehende Arbeitsstände im Haupt-Repository zu berühren):
cd ../proviantplaner
git worktree remove --force ../proviantplaner-baseline
```

### 1.2 Tatsächlich gemessene Terminal-Ausgabe auf der Baseline (Fail-Before)
```text
00:00 +0: loading test/features/shopping_list/shopping_mode_hcd_test.dart
00:00 +0: HCD-SHOP-01 Schritt 1: Stabilität, Persistenzwahrheit und Lifecycle (#66) S01-40-POS: 40+ Artikel, 5 Checkmarks in Folge, Scrollable-Identität, ListView stabil, Offset erhalten
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: no matching candidates
  Actual: _TypeWidgetFinder:<Found 1 widget with type "CircularProgressIndicator": [
            CircularProgressIndicator(<indeterminate>, state:
_CircularProgressIndicatorState#345ae(ticker active)),
          ]>
   Which: means one was found but none were expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure> (test/features/shopping_list/shopping_mode_hcd_test.dart:282:7)
<asynchronous suspension>
...
This was caught by the test expectation on the following line:
  test/features/shopping_list/shopping_mode_hcd_test.dart line 282
════════════════════════════════════════════════════
00:02 +0 -1: HCD-SHOP-01 Schritt 1: Stabilität, Persistenzwahrheit und Lifecycle (#66) S01-40-POS: 40+ Artikel, 5 Checkmarks in Folge, Scrollable-Identität, ListView stabil, Offset erhalten [E]
  Test failed. See exception logs above.
00:02 +0 -1: Some tests failed.
```

- **Technische Fehlerursache auf `main`:**  
  Auf `main` umschloss `dataAsync.when(...)` das gesamte `Scaffold`. Beim Antippen einer Checkbox ging `dataAsync` während des Reloads in `AsyncLoading`. Die Baseline-Implementierung ersetzte die gesamte Einkaufsliste durch einen zentrierten `CircularProgressIndicator`, wodurch das `ListView`-Widget und dessen `ScrollableState` vernichtet wurden. Nach Beendigung des Reloads wurde ein neues `ListView` mit Default-Scroll-Offset `0.0` konstruiert (Reset von über 300 px auf 0.0 px). Zusätzlich rief `ShoppingModeScreen` im Checkbox-Callback auf Zeile 235 ein redundantes `ref.invalidate(tripShoppingListProvider(widget.tripId))` auf.

---

## 2. Schritt 1 & Amendments: Implementierte Lösungen

### 2.1 Stabile Listenansicht während Riverpod-Reloads
- `ShoppingModeScreen` ersetzt das destruktive `dataAsync.when(...)` durch eine differenzierte Zustandshierarchie:
  - **Initiales Laden (`isLoading && !hasValue`):** Zentrierter Ladeindikator.
  - **Bestehende Daten (`hasValue`):** Das `Scaffold` und die `ListView` bleiben ununterbrochen gemountet. Bei Hintergrund-Aktualisierungen (`isLoading && hasValue`) bleibt die Liste voll interaktiv, der Scroll-Offset wird erhalten und `ScrollableState` bleibt identisch (`identical(scrollableBefore, scrollableAfter)` ist wahr).

### 2.2 Eliminierung redundanter Provider-Invalidierungen
- Das manuelle `ref.invalidate(tripShoppingListProvider(widget.tripId))` im regulären Checkbox-`onChanged` wurde ersatzlos entfernt.
- Die Reaktivität stützt sich sauber auf den bestehenden Kontrakt: `ShoppingListService.toggleBought` triggert bei erfolgreichem DB-Commit `onTripDataChanged`, wodurch `tripDataVersionProvider` inkrementiert wird. (Für isolierte Unit-Tests ohne gesetzten Callback existiert ein sicherer Fallback).

### 2.3 Differenzierte Fehlerzustände (Truthful UI)
1. **Initialer Fehler ohne vorherige Daten:**
   - Zeigt einen vollwertigen Fehlerbildschirm mit Titel (`technicalErrorTitle`), Erklärung (`technicalErrorMessage`) und Wiederholungs-Button (`retry`, Key: `shopping_mode_initial_retry_button`).
   - Beim Antippen des Buttons wird der Ladevorgang tatsächlich wiederholt und die Liste bei Erfolg gerendert.
2. **Reload-Fehler bei bestehenden Daten:**
   - Die bestehende Einkaufsliste bleibt sichtbar und benutzbar.
   - Am oberen Rand erscheint ein diskretes Fehlerbanner (`shopping_mode_reload_error_banner`) mit Wiederholungs-Button (`shopping_mode_reload_retry_button`).
3. **Ungültige Stopp-ID:**
   - Führt gezielt zu `NotFoundScreen` mit `shoppingStopNotFound`.

### 2.4 Echter Retry bei Kaufoperationen (R1)
- `_showToggleErrorSnackBar`: Schlägt `toggleBought` fehl (durch Rückgabe von `false` oder eine Exception), wird eine SnackBar mit der Aktion `l10n.retry` angezeigt.
- Die Aktion führt keine bloße Listenaktualisierung durch, sondern ruft `_handleToggleBought(listItemId, stopId, desiredIsBought, l10n)` auf. Dadurch wird die beabsichtigte Mutation bei Wiederholung tatsächlich erneut ausgeführt.
- Es entsteht kein Scheinerfolg: Solange der Schreibvorgang nicht bestätigt ist, bleibt die Checkbox `false`, der Zähler unverändert und die Datenbank auf `isBought = false`. Nach erfolgreichem Retry wird die Checkbox auf `true` gesetzt, der Fortschrittszähler aktualisiert und der Eintrag in SQLite auf `isBought = true` persistiert.

### 2.5 Per-Item Concurrency Guard (`_pendingItemIds`)
- Schnelle Mehrfach-Taps auf denselben Artikel werden über ein In-Memory `Set<int> _pendingItemIds` synchron abgefangen:
  - Während des Schreibvorgangs ist `Checkbox.onChanged` auf `null` gesetzt (deaktiviert) und die Zeilen-Deckkraft wird dezent gedimmt (`0.6`).
  - Redundante gleichzeitige SQLite-Transaktionen werden verhindert.
- Nach Beendigung (Erfolg oder Fehler) wird die ID im `finally`-Block zuverlässig freigegeben.

### 2.6 Lifecycle- & Accessibility-Sicherheit (R3)
- Vor jedem `ref`-, `setState`- oder `ScaffoldMessenger`-Zugriff wird strikt `if (!mounted) return;` geprüft.
- Responsives `AppBar`-Layout: Bei schmalen Displays (320 logical px) oder vergrößerter Schrift (1.5x) schaltet der Aktions-Button ("Ausgabe erfassen") auf ein kompaktes `IconButton` mit Tooltip um, wodurch RenderFlex-Overflows verhindert werden.
- Verifiziert sowohl im `AppTheme.darkTheme` als auch im echten `AppTheme.nightwatchTheme`.

### 2.7 Retry-Lifecycle & Intent-Generationsschutz (R5)
- Um zu verhindern, dass eine veraltete SnackBar-Retry-Aktion eine neuere Nutzerabsicht überschreibt oder nach Verlassen des Screens auf disposed State zugreift:
  1. **Generationszähler pro Artikel (`_itemMutationGenerations`):** Jede Nutzeraktion auf einen Artikel inkrementiert dessen Generation.
  2. **Generation Binding:** Der Retry-Button der SnackBar bindet sich fest an die `generation`, bei der der Fehler auftrat.
  3. **Stale Intent Guard:** Hat der Nutzer den Artikel zwischenzeitlich manuell geändert (z. B. gekauft und wieder entkauft), weicht die aktuelle Generation ab (`currentGen != generation`) $\rightarrow$ der veraltete Retry wird verworfen.
  4. **Disposal Guard:** Beim Unmounten von `ShoppingModeScreen` schützt `if (!mounted) return;` zuverlässig vor State- oder Riverpod-Zugriffen. Kein Flutter-Lifecycle-Fehler (`setState after dispose`).

### 2.8 Fail-Closed Allokationsvalidierung & Schutz vor Geister-Allokationen (R6)
- **Problemursache vor R6:**  
  Ein naiver Check `currentItem?.isBoughtAtStop(stopId) ?? false` setzte fälschlicherweise unterschiedliche Zustände gleich (Artikel nicht gekauft vs. Artikel existiert nicht mehr vs. Stopp existiert nicht mehr vs. Allokation auf einen anderen Hafen verschoben vs. Daten im Lade-/Fehlerzustand). Da `ListItemDao.toggleBought()` bei fehlender Zuordnung eine neue Allokation anlegt (und bei 0 Restmenge auf mindestens 1 Packung aufrundet), konnte ein veralteter Retry nach einer zwischenzeitlichen Mengenverschiebung zu Stopp 2 am Stopp 1 eine unerwünschte Geister-Allokation erzeugen und die Gesamtpackungszahl aufblähen.
- **Fail-Closed Validierung in `_showToggleErrorSnackBar.onPressed`:**
  1. **Warten auf laufende Provider-Reloads:** Ist `asyncState.isLoading`, wird `await ref.read(tripShoppingListProvider(widget.tripId).future)` abgewartet. Schlägt das Laden fehl $\rightarrow$ Abbruch ohne Mutation (Fail-closed).
  2. **Stale Generation Re-Check:** Nach dem asynchronen Laden wird erneut geprüft, ob eine neuere Nutzeraktion stattgefunden hat (`currentGen != generation`) $\rightarrow$ Abbruch.
  3. **Positiver Stopp-Check:** Es wird positiv geprüft, ob der Einkaufsstopp im Törn (`currentData.stops`) noch existiert.
  4. **Positiver Artikel-Check:** Es wird positiv geprüft, ob der Artikel existiert und auf der Liste ausgewählt ist (`isOnList`).
  5. **Positiver Mengen-/Allokations-Check:** Unter strikter Wiederverwendung der etablierten fachlichen Mengenlogik (`packagesAtStop(stopId, isFirstStop: isFirstStop, totalOtherAllocated: totalOtherAlloc)`) wird geprüft, ob dem Stopp eine Menge `> 0` zugeordnet ist. Dies berücksichtigt automatisch sowohl explizite Allokationen als auch implizite Restmengen am Ersteinkauf. Ist `countAtStop <= 0` (z. B. weil alle Packungen zu Stopp 2 verschoben wurden), bricht der Retry sofort fail-closed ab.
  6. **Reconciliation Check:** Befindet sich der Artikel bereits im Zielzustand (`currentIsBought == desiredIsBought`), wird keine redundante Mutation ausgelöst.
  7. **Ausführung:** Erst nach erfolgreicher Verifizierung aller Vorbedingungen wird `_handleToggleBought` mit `expectedGeneration: generation` aufgerufen.

---

## 3. Nachweise & Testabdeckung (R1–R6)

### A. Automatisierte Testsuite [`test/features/shopping_list/shopping_mode_hcd_test.dart`](file:///c:/Users/Lenovo/Desktop/proviantplaner/test/features/shopping_list/shopping_mode_hcd_test.dart)
Alle 13 dedizierten Tests bestanden:

| Testfall | Beschreibung & Verifikation | Nachweis |
|---|---|---|
| `S01-40-POS` | 40+ Artikel, 5 Checkmarks in Folge in der Listenmitte. Prüft `identical(scrollableBefore, scrollableAfter)`, ListView bleibt gemountet, Scroll-Offset stabil, Fortschrittszähler steigt von 1 auf 5, DB-Status aller 5 Artikel in SQLite verifiziert. | `automatischer Test (S01-40-POS)` |
| `S01-ASYNC-INITIAL-ERROR` | Initialer Fehler ohne Daten zeigt Fehlerbildschirm mit Retry-Button. Drücken von `shopping_mode_initial_retry_button` führt echten Retry aus; Fehlerbildschirm verschwindet, ListView rendert erfolgreich. | `automatischer Test (S01-ASYNC-INITIAL-ERROR)` |
| `S01-ASYNC-RELOAD-ERROR` | Reload-Fehler mit vorhandenen Daten belässt Liste und zeigt Warnbanner. Drücken von `shopping_mode_reload_retry_button` behebt den Fehler; Banner verschwindet. | `automatischer Test (S01-ASYNC-RELOAD-ERROR)` |
| `S01-ASYNC-MISSING-STOP` | Ungültige Stopp-ID zeigt gezielt `NotFoundScreen(shoppingStopNotFound)`. | `automatischer Test (S01-ASYNC-MISSING-STOP)` |
| `S01-FALSE-THROW` | Differenziert `false` und `Exception`. Nach Fehlschlag: kein Scheinerfolg (Checkbox unchecked, Zähler unverändert, DB false). Drücken von `Erneut versuchen` auf SnackBar führt echten Retry aus $\rightarrow$ Checkbox checked, Zähler erhöht, DB true. | `automatischer Test (S01-FALSE-THROW)` |
| `S01-RETRY-STALE-SUPERSEDED` | **R5 Regression 1 & 3:** Fehlgeschlagener Schreibvorgang $\rightarrow$ manuell kaufen $\rightarrow$ manuell entkaufen $\rightarrow$ alter SnackBar-Retry führt keinen heimlichen Neukauf aus. Generation Fencing verwirft den veralteten Request; DB bleibt konsistent. | `automatischer Test (S01-RETRY-STALE-SUPERSEDED)` |
| `S01-RETRY-DISPOSED-LIFECYCLE` | **R5 Regression 2:** Fehlgeschlagener Schreibvorgang $\rightarrow$ Screen verlassen (Widget disposed) $\rightarrow$ Drücken der veralteten SnackBar-Action wirft keinen Flutter-Lifecycle-Fehler. | `automatischer Test (S01-RETRY-DISPOSED-LIFECYCLE)` |
| `S01-2TAP` | Doppel-Tap auf selbe Checkbox während in-flight Mutation blockiert zweiten Aufruf durch Pending-Guard. | `automatischer Test (S01-2TAP)` |
| `S01-A11Y-DARK` | Schmaler 320dp-Screen und Dark-Theme mit 1.5x Textskalierung rendert ohne RenderFlex-Overflow. | `automatischer Test (S01-A11Y-DARK)` |
| `S01-A11Y-NIGHTWATCH` | Schmaler 320dp-Screen und echtes Nightwatch-Theme (`nightwatchTheme`) mit 1.5x Textskalierung rendert ohne RenderFlex-Overflow. | `automatischer Test (S01-A11Y-NIGHTWATCH)` |
| `S01-R6-A-MOVED-ALLOCATION` | **R6 Regression A:** Artikel initial Stopp 1 zugeordnet $\rightarrow$ Kauf scheitert $\rightarrow$ Artikelmenge vollständig auf Stopp 2 verschoben $\rightarrow$ alter Retry ausgelöst $\rightarrow$ verifiziert in SQLite: keine neue Allokation an Stopp 1, keine Überschreitung der Gesamtpackungszahl, Zuordnung an Stopp 2 unverändert, kein Fehlkauf. | `automatischer Test (S01-R6-A-MOVED-ALLOCATION)` |
| `S01-R6-B-UNAVAILABLE-DATA` | **R6 Regression B:** Kauf scheitert $\rightarrow$ Provider-Reload schlägt fehl/nicht verfügbar $\rightarrow$ Retry ausgelöst $\rightarrow$ Fail-closed: keine ungesicherte Mutation, kein Absturz. | `automatischer Test (S01-R6-B-UNAVAILABLE-DATA)` |
| `S01-R6-C-VALID-RETRY` | **R6 Regression C:** Gewöhnlicher fehlgeschlagener Kauf mit weiterhin gültiger Zuordnung wird anschließend per Retry korrekt wiederholt; Erfolg in SQLite nachweisbar. | `automatischer Test (S01-R6-C-VALID-RETRY)` |

### B. Bestehende Suiten & Linters
- `test/features/shopping_list/shopping_mode_hcd_test.dart`: **13/13 Tests bestanden**
- `test/features/ux/fix_a_journey_test.dart`: **17/17 Tests bestanden**
- `flutter analyze`: **0 Issues (No issues found!)**
- `npm run typecheck --prefix backend`: **0 Errors**

---

## 4. Unberührte Verträge & Null-Konflikt-Oberfläche
- Keine Änderungen an `ShoppingListService`, `TripDao`, Drift-Tabellen oder Provider-Signaturen.
- Keine Änderungen an ARB-Dateien (`app_*.arb`), wodurch keinerlei Merge-Konflikte zu offenen PRs entstehen.
- Keine Änderungen an Schritt 2 („Erledigt (N)“-Bereich / Filterung).

---

## 5. Verbindlicher Stopp-Checkpoint (Phase B Step 1)
Gemäß Owner-Release (`docs/impl/HCD_SHOP_01_OWNER_PHASE_B_RELEASE_2026-11-06.md`):

- **Status: REVIEW**
- **Kein Code für Schritt 2 (Footer/Filterung).**
- **Kein automatischer Merge.**
- **Bereit für unabhängigen Exact-HEAD-Re-Review und physische Verifikation auf dem Google Pixel 7 Pro durch den Owner.**

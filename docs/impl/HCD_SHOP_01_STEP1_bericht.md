# HCD-SHOP-01 / #66 – Schritt 1 Abschlussbericht
## Checkout-Scrollstabilität, Persistenzwahrheit & Concurrency Guard

**Status:** SCHRITT 1 VOLLSTÄNDIG IMPLEMENTIERT & VERIFIZIERT – STOP VOR SCHRITT 2 (AWAITING INDEPENDENT REVIEW & PIXEL 7 PRO CHECKPOINT)  
**Datum:** 06.11.2026  
**Tracking-Issue:** #66  
**Branch:** `slice/hcd-shop-01-stable-checkout`  
**Basis-Commit:** `e00c01d35763790fe430a8c331436e120478f2dd` (`origin/main`)  
**Architektur- & Release-Vorgaben:**  
- `docs/impl/HCD_SHOP_01_ARCHITECTURE_GATE_A_2026-11-06.md` (v0.2)
- `docs/impl/HCD_SHOP_01_PHASE_B_IMPLEMENTATION_BRIEF_2026-11-06.md`
- `docs/impl/HCD_SHOP_01_OWNER_PHASE_B_RELEASE_2026-11-06.md`

---

## 1. Schritt 0: Empirische Reproduktion & Verifikation des Fehlers auf `main`

Vor Beginn der Implementierung wurde das gemeldete Fehlverhalten auf unverändertem `main`-Stand reproduziert und dokumentiert.

- **Testdatei:** `test/features/shopping_list/shopping_mode_hcd_test.dart`
- **Testfall:** `S01-BASE-RED` (vorübergehender Reproduktionstest)
- **Setup:** 45 Einkaufsartikel über 3 Abteilungen (`obst_gemuese`, `molkerei`, `trockenware`), Pixel 7 Pro Viewport (412 × 915 dp), Scrollposition auf Artikel 38 heruntergescrollt.
- **Empirisches Messergebnis auf `main`:**
  - Ausgangs-Scroll-Offset vor Tap: `2504.0 px`
  - Während Riverpod-Reload: `Spinner während Reload: true`, `ListView gemountet: false`
  - Scroll-Offset nach Abschluss des Reloads: `0.0 px` (harter Reset an den Listenanfang)
- **Ursachenanalyse:** In `ShoppingModeScreen` umschloss `dataAsync.when(...)` das gesamte `Scaffold`. Bei jedem Riverpod-Reload wurde der Zustand auf `AsyncLoading` gesetzt, wodurch das gesamte `Scaffold` inklusive `Scrollable` und dessen `ScrollPosition` unmounted und vernichtet wurde. Nach Abschluss des Neuladens wurde eine neue `ListView` mit Default-Offset `0.0` konstruiert. Zusätzlich triggerte jede Checkbox ein manuelles, redundantes `ref.invalidate(tripShoppingListProvider)`.

---

## 2. Schritt 1: Implementierte Lösungen

### 2.1 Stabile Listenansicht während Riverpod-Reloads
- `ShoppingModeScreen` ersetzt das destruktive `dataAsync.when(...)` durch eine differenzierte Zustandshierarchie:
  - **Initiales Laden (`isLoading && !hasValue`):** Zentrierter Ladeindikator.
  - **Bestehende Daten (`hasValue`):** Das `Scaffold` und die `ListView` bleiben ununterbrochen gemountet. Bei Hintergrund-Aktualisierungen (`isLoading && hasValue`) bleibt die Liste voll interaktiv, der Scroll-Offset wird auf den Subpixel genau beibehalten (`S1 – Natürliches Nachrücken`).

### 2.2 Eliminierung redundanter Provider-Invalidierungen
- Das manuelle `ref.invalidate(tripShoppingListProvider(widget.tripId))` im Checkbox-`onChanged` wurde ersatzlos entfernt.
- Die Reaktivität stützt sich sauber auf den bestehenden Kontrakt: `ShoppingListService.toggleBought` triggert bei erfolgreichem DB-Commit `onTripDataChanged`, wodurch `tripDataVersionProvider` inkrementiert wird und `tripShoppingListProvider` datengetrieben aktualisiert wird.

### 2.3 Differenzierte Fehlerzustände (Truthful UI)
1. **Initialer Fehler ohne vorherige Daten:**
   - Zeigt einen vollwertigen Fehlerbildschirm mit Titel (`technicalErrorTitle`), Erklärung (`technicalErrorMessage`) und Wiederholungs-Button (`retry`, Key: `shopping_mode_initial_retry_button`), anstelle eines irreführenden `NotFoundScreen(tripNotFound)`.
2. **Reload-Fehler bei bestehenden Daten:**
   - Die bestehende Einkaufsliste bleibt sichtbar und benutzbar.
   - Am oberen Rand erscheint ein diskretes Fehlerbanner (`shopping_mode_reload_error_banner`) mit Wiederholungs-Button (`shopping_mode_reload_retry_button`).
3. **Ungültige Stopp-ID:**
   - Führt gezielt zu `NotFoundScreen` mit `shoppingStopNotFound`.

### 2.4 Wahrhaftige Persistenz & Failure-Pfad (`_handleToggleBought`)
- Der boolesche Rückgabewert von `ShoppingListService.toggleBought` wird geprüft.
- Sowohl bei Rückgabe von `false` (z. B. 0 betroffene Zeilen in SQLite) als auch bei Exceptions (z. B. Speicher-/Lock-Fehler) wird eine Fehlermeldung (`technicalErrorMessage`) per `SnackBar` mit Wiederholungs-Aktion angezeigt. Es wird kein Scheinerfolg behauptet.
- Bei Fehlern wird ein gezieltes `ref.invalidate` ausgelöst, um den UI-Zustand mit der Datenbank zu synchronisieren.

### 2.5 Per-Item Concurrency Guard (`_pendingItemIds`)
- Schnelle Mehrfach-Taps auf denselben Artikel werden über ein In-Memory `Set<int> _pendingItemIds` synchron abgefangen:
  - Während des Schreibvorgangs ist `Checkbox.onChanged` auf `null` gesetzt (deaktiviert) und die Zeilen-Deckkraft wird dezent gedimmt (`0.6`).
  - Redundante gleichzeitige SQLite-Transaktionen werden verhindert.
- Nach Beendigung (Erfolg oder Fehler) wird die ID im `finally`-Block zuverlässig freigegeben.

### 2.6 Lifecycle- & Accessibility-Sicherheit
- Vor jedem `ref`-, `setState`- oder `ScaffoldMessenger`-Zugriff wird strikt `if (!mounted) return;` geprüft.
- Responsives `AppBar`-Layout: Bei extrem schmalen Displays (320 logical px) oder vergrößerter Schrift (1.5x) schaltet der Aktions-Button ("Ausgabe erfassen") auf ein kompaktes `IconButton` mit Tooltip um, wodurch RenderFlex-Overflows verhindert werden.
- Abteilungs- und Artikelzeilen besitzen stabile Keys (`shopping_row_<id>`, `shopping_tile_<id>`, `shopping_checkbox_<id>`).

---

## 3. Nachweise & Testabdeckung

### A. Automatisierte Regressionstests (`test/features/shopping_list/shopping_mode_hcd_test.dart`)
Alle 7 dedizierten Tests bestanden:

| Testfall | Beschreibung | Nachweis |
|---|---|---|
| `S01-40-POS` | 40+ Artikel, mid-scroll Checkmark, kein Spinner, ListView stabil gemountet, Scroll-Offset bleibt exakt bei 2504.0 px | `automatischer Test (S01-40-POS)` |
| `S01-ASYNC-INITIAL-ERROR` | Initialer Fehler ohne Daten zeigt Fehlerbildschirm mit Retry-Button und erholt sich | `automatischer Test (S01-ASYNC-INITIAL-ERROR)` |
| `S01-ASYNC-RELOAD-ERROR` | Reload-Fehler mit vorhandenen Daten belässt Liste und zeigt Warnbanner mit Retry | `automatischer Test (S01-ASYNC-RELOAD-ERROR)` |
| `S01-ASYNC-MISSING-STOP` | Ungültige Stopp-ID zeigt gezielt `NotFoundScreen(shoppingStopNotFound)` | `automatischer Test (S01-ASYNC-MISSING-STOP)` |
| `S01-FALSE-THROW` | Fehlgeschlagener Schreibvorgang (`false` & `Exception`) behauptet keinen Erfolg und zeigt Fehler-SnackBar | `automatischer Test (S01-FALSE-THROW)` |
| `S01-2TAP` | Doppel-Tap auf selbe Checkbox während in-flight Mutation blockiert zweiten Aufruf durch Pending-Guard | `automatischer Test (S01-2TAP)` |
| `S01-A11Y` | Schmaler 320dp-Screen und Nachtwache-Modus mit 1.5x Textskalierung rendert ohne RenderFlex-Overflow | `automatischer Test (S01-A11Y)` |

### B. Bestehende Suiten
- `test/features/ux/ux_b_shopping_and_delivery_test.dart`: **12/12 Tests bestanden**
- `test/features/shopping_list/shopping_list_persistence_test.dart`: **Bestanden**
- `flutter analyze`: **0 Issues (No issues found!)**
- `npm run typecheck --prefix backend`: **0 Errors**

---

## 4. Unberührte Verträge & Null-Konflikt-Oberfläche
- Keine Änderungen an `ShoppingListService`, `TripDao`, Drift-Tabellen oder Provider-Signaturen.
- Keine Änderungen an ARB-Dateien (`app_*.arb`), wodurch keinerlei Merge-Konflikte zu offenen PRs entstehen.
- Keine Änderungen an Schritt 2 („Erledigt (N)“-Bereich / Filterung).

---

## 5. Verbindlicher Stopp-Checkpoint (Phase B Step 1)
Gemäß Owner-Release (`docs/impl/HCD_SHOP_01_OWNER_PHASE_B_RELEASE_2026-11-06.md`) wird die Implementierung an dieser Stelle **ausdrücklich angehalten**.

- **Kein Code für Schritt 2 (Footer/Filterung).**
- **Kein automatischer Merge.**
- **Bereit für unabhängigen Code-Review und physische Verifikation auf dem Google Pixel 7 Pro durch den Owner.**

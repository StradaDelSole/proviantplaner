# FLIGHT-STRIP-01 – Abschlussbericht (Flight-Strip-Board für Vorratsliste)

**Status:** IMPLEMENTIERT & VOLLSTÄNDIG GETESTET – BEREIT FÜR REVIEW  
**Datum:** 04.11.2026  
**Tracking-Issue:** #56 (Owner-freigegebene Spezifikation)  
**Branch:** `slice/flight-strip-board-01`  
**Basis-Commit:** `e00c01d35763790fe430a8c331436e120478f2dd` (`origin/main`)

---

## 1. Übersicht der Implementierung

Gemäß der Owner-Vorgabe aus Issue #56 wurde ein echtes, voll funktionsfähiges Flutter Flight-Strip-Board zur Zusammenstellung der Vorratsliste implementiert (ohne Mockups/Figma, direkt im Code). Die drei logischen Ebenen wurden für Smartphones optimiert umgesetzt:

### Ebene 1: Basket Tray (`BasketTrayWidget`)
- Sticky am unteren Bildschirmrand platziert; zu jedem Zeitpunkt während der Vorratsplanung erreichbar.
- Zeigt die Anzahl der Artikel im Korb (`l10n.basketSummary`), das Gesamtgewicht und -volumen (`l10n.totalWeightVolumeSummary`) sowie einen Aufklapp-Button.
- Im ausgeklappten Zustand:
  - Vollständige, übersichtliche Liste aller übernommenen Positionen mit Farbpunkt der Warengruppe.
  - Direkt bedienbare Stepper (`− / +`) zur Mengenanpassung im Korb (`setPackages`).
  - Lösch-Schaltfläche (`unadoptItem`) zum Entfernen einzelner Posten.
  - Primärer Aktionsbutton „Einkauf starten“, der nahtlos in den bestehenden In-Store Shopping Mode führt.

### Ebene 2: Farbcodierte Produktgruppen & Subgruppen-Stacks
- **10 Hauptkategorien:** Horizontal scrollbare Filter-Chips mit stabiler, maritimer Material-3-Farbpalette (`FlightStripColors`), dedizierten Ikonen zur Barrierefreiheit und dynamischem In-Basket-Zähler (z. B. `Frühstück (2)`).
- **47 Subgruppen:** Sobald eine Kategorie aktiv ist, wird eine Subgruppen-Leiste mit „Alle“ sowie den spezifischen Untergruppen (z. B. *Brot und Backwaren*, *Aufstriche*, *Müsli*) eingeblendet, um gezieltes Durchstöbern ohne endlose Listen zu ermöglichen.

### Ebene 3: Einzelne Produkt-Strips (`ProductStripWidget`)
- Kompaktes ATC-Flugstreifen-Design mit linksseitigem Farbbalken der Kategorie, Ikonografie, Produktname, Gebindegröße und Kühlwarenhinweis (falls relevant).
- **Mengensteuerung direkt auf dem Streifen:**
  - Linker Minus-Button (`[-]`), mittlere sichtbare Anzahl und Einheit, rechter Plus-Button (`[+]`).
  - Barrierefreie Touch-Targets: Alle Schaltflächen verfügen über mindestens 44x44 dp Klickfläche.
  - Das Antippen von Minus oder Plus ist strikt von der Wisch-Geste entkoppelt.
- **Swipe-Right (In den Korb – Owner Decision A):**
  - Horizontale Wischgeste nach rechts übernimmt den Artikel **sofort mit der exakt sichtbaren Menge und Gebindegröße in den Korb — ohne Bestätigungsdialog**.
  - Grüner Hintergrund mit Warenkorb-Symbol während des Wischens.
  - Haptisches Feedback (`mediumImpact`) und SnackBar mit `Rückgängig`-Aktion.
- **Swipe-Left (Überspringen):**
  - Horizontale Wischgeste nach links blendet den Streifen für den aktuellen Durchlauf aus (nicht gelöscht).
  - Statuszeile mit Zähler (`X übersprungene Artikel anzeigen`) und `Alle wiederherstellen`-Schaltfläche.
  - SnackBar mit `Rückgängig`-Aktion.
- **Barrierefreie Alternativen:**
  - Auf jedem Streifen befindet sich neben dem Stepper eine sichtbare „In den Korb“-Schaltfläche mit Warenkorb-Icon (`Icons.add_shopping_cart`), sodass Nutzer niemals auf Wischgesten festgelegt sind.
- **Detail-Inspektion:**
  - Ein Antippen des Streifens (außerhalb der Mengenknöpfe) öffnet das `AddOrEditItemSheet` für erweiterte Gebindegrößen- oder Stopp-Zuweisungen.

---

## 2. Suche, A/B-Umschalter und Barrierefreiheit

1. **Prominente Suche:**
   - Direkt über den Kategorien befindet sich ein Suchfeld, das unmittelbar alle 232 Varianten des Katalogs nach Produktname, Tags, Warengruppe und Abteilung filtert und als Strips bereitstellt.
2. **Interner A/B-Umschalter (`toggle_flight_strip_board_button`):**
   - In der `AppBar` der Vorratsliste befindet sich ein Ansicht-Umschalter, mit dem der Tester jederzeit zwischen dem neuen Flight-Strip-Board und der klassischen hierarchischen `PlanningView` hin- und herwechseln kann.
3. **Nachtwache-Modus & kleine Bildschirme:**
   - Im Nachtwache-Modus werden alle Strips, Korb-Elemente und Hintergründe strikt in Rot auf Schwarz gerendert (`#FFFF3B30`), um die Dunkeladaption der Crew auf See zu schützen (Designregel 13).
   - Auf 320 logical px schmalen Bildschirmen brechen alle Texte und Badges mittels `Wrap` sauber um; es treten keinerlei RenderFlex-Overflows auf.

---

## 3. Datenintegrität und Leitplanken

- **Keine Datenbankschema-Änderung / Migration:** Sämtliche Funktionen nutzen die bestehenden Tabellen `ListItem`, `ShoppingStop`, `ListItemAllocation` und den bestehenden `ShoppingListService`.
- **Echte Persistenz:** Das Übernehmen in den Korb setzt `isAdopted = true` und `overriddenPackages` via Drift. „Im Korb“ ist strikt von „Gekauft“ (`isBought`) getrennt.
- **PIVOT1-Mengenschutz:** Präferenzprodukte starten sichtbar bei 1 Packung (keine automatische `crew × days` Hochrechnung). Bedarfsbasierte Artikel zeigen ihren berechneten Richtwert.

---

## 4. Testabdeckung und Qualitätssicherung

### A. Statische Analyse
- `dart analyze lib test`: **0 Issues (No issues found!)**
- `npm run typecheck --prefix backend`: **0 Errors**

### B. Neue dedizierte Testsuite
`test/features/shopping_list/flight_strip_board_test.dart` (15 Tests, alle grün):
1. `Strip-Board rendert mit Basket-Tray, Kategorie-Chips und Strips`
2. `Mengensteuerung auf dem Strip (− / Count / +) mit barrierefreien Touch-Targets`
3. `SWIPE RIGHT übernimmt Artikel sofort in den Korb OHNE Bestätigungsdialog (Owner Decision A)`
4. `Undo auf Swipe-Right entfernt Artikel wieder aus dem Korb`
5. `Barrierefreie Schnell-Hinzufügen-Schaltfläche übernimmt ohne Wisch-Geste`
6. `SWIPE LEFT überspringt Artikel temporär mit Wiederherstellungsoption`
7. `Korb aufklappen, Inhalte einsehen und Mengen im Korb bearbeiten`
8. `Suche filtert sofort über den gesamten 232-Varianten-Katalog`
9. `Interner Schalter schaltet nahtlos zwischen Flight-Strip-Board und PlanningView um`
10. `Nachtwache-Modus rendert strikt in Rot/Schwarz ohne bunte Fremdfarben`
11. `Schmaler 320px-Viewport verursacht keinen RenderFlex-Overflow` (Empty-State-Banner als List-Item in der scrollbaren Ansicht integriert, um festen Header-Overflow auf Kleinstgeräten zuverlässig zu verhindern)

### C. Bestehende Regressionstests (alle grün)
- `shopping_list_ui_test.dart` (4/4 Tests bestanden)
- `pivot1_assisted_list_test.dart` (17/17 Tests bestanden)
- `fb2_b_ui_test.dart` (13/13 Tests bestanden)
- `qa_rapid_01_android_fixes_test.dart` (9/9 Tests bestanden)

---

## 5. Manuelle Testanleitung für physisches Google Pixel 7 Pro (nach Merge/APK)

1. **Board aufrufen:**
   - Beliebigen Törn öffnen → Vorratsliste („Liste“) antippen → In die Kategorie-Sicht wechseln.
   - Prüfen, dass das Flight-Strip-Board mit horizontalen Kategorie-Chips oben und dem Basket-Tray unten erscheint.
2. **Kategorien und Mengen:**
   - Auf „Frische Lebensmittel“ tippen, dann auf eine Subgruppe.
   - Bei einem Artikel auf `+` tippen: Zahl erhöht sich sichtbar von 1 auf 2.
3. **Swipe-Right (Korb):**
   - Den Streifen nach rechts wischen: Er gleitet mit grünem Feedback in den Korb.
   - Prüfen, dass KEIN Dialog erscheint und der Zähler im Basket-Tray sofort um 1 steigt.
   - Auf „RÜCKGÄNGIG“ im SnackBar tippen: Artikel wird wieder aus dem Korb entfernt.
4. **Swipe-Left (Skip):**
   - Einen Artikel nach links wischen: Er wird ausgeblendet, Statuszeile für übersprungene Artikel erscheint.
   - Auf „Alle wiederherstellen“ tippen: Artikel ist wieder da.
5. **Basket-Tray:**
   - Auf den Tray unten tippen: Korb klappt auf, zeigt übernommene Artikel mit `- / +` Steppern und „Einkauf starten“.
6. **A/B-Umschalter:**
   - Oben in der Leiste auf das Listen-Icon tippen: Ansicht schaltet nahtlos zur klassischen Baum-Ansicht (`PlanningView`) um. Erneut tippen: Zurück zum Strip-Board.

---

## 6. Review Amendment 1 (Review 5777458856, Findings F1-F4)

**Datum:** 05.11.2026  
**PR:** #60  
**Status:** IMPLEMENTIERT & VOLLSTÄNDIG GETESTET – BEREIT FÜR RE-REVIEW

### Behebung der Findings F1-F4:

1. **F1 - Bestehende Basket-Einträge schützen:**
   - *Idempotenz:* Bei erneutem Rechts-Swipe auf einen bereits im Korb liegenden Streifen mit gleicher Menge wird kein Re-Adopt ausgeführt und keine Stopp-Allokation zurückgesetzt. Es erscheint ein informativer SnackBar (`alreadyInBasketMessage`), und der Streifen schnappt zurück.
   - *Erhaltungs-Undo:* Tappt der Nutzer bei einem bereits im Korb liegenden Artikel nach Mengenänderung auf "Rückgängig", wird die vorherige Packungsmenge (`priorOverriddenPackages ?? priorEffectivePackages`) wiederhergestellt - der Artikel wird nicht destruktiv gelöscht. Nur für neu übernommene Artikel ruft Undo `unadoptItem` auf.
2. **F2 - Strip wieder sichtbar machen:**
   - Nach dem Löschen eines Artikels im Basket Tray (`Icons.delete_outline`) wird der Streifen über die `onItemRemoved`-Rückmeldung und einen generationenbasierten Dismissible-Lifecycle (`ValueKey('strip_dismissible_${item.id}_${gen}')`) sofort wieder im Katalog und in der Suche eingeblendet, ohne Neuladen oder Navigation.
3. **F3 - Persistenz-Fehlerbehandlung & Parallelitätsschutz:**
   - Ein asynchrones Operationen-Tracking (`_pendingOperations`) verhindert Doppel-Aktionen und Race Conditions bei schnellem Mehrfachwischen.
   - Bei Persistenzfehlern fängt `confirmDismiss` die Exception ab, lässt den Streifen in die Ausgangsposition zurückschnappen (`return false`), und zeigt einen Fehler-SnackBar (`errorSavingItem`) mit "Erneut versuchen" (`retry`), sodass kein Artikel verloren geht und kein falscher Transfer gemeldet wird.
4. **F4 - Robuste Mengensteuerung:**
   - Minus (`-`) bei Menge 1 auf dem Produktstreifen sowie im Basket Tray belässt den Wert auf 1 (Mindestmenge) und löscht den Artikel niemals stillschweigend. Die Löschung erfolgt ausschließlich über das Mülleimer-Symbol im Korb.

### Testsuite-Erweiterung:
`test/features/shopping_list/flight_strip_board_test.dart` (15 Tests, alle bestanden):
- Tests 1-11: Kerninteraktionen, Barrierefreiheit, Nachtwache, Suche, Umschaltung.
- Test 12 (F1): `Bestehende Basket-Einträge schützen - Erneuter Rechts-Swipe & Undo bewahren Originalmenge, Override & Stopp-Allokation`
- Test 13 (F2): `Strip wieder sichtbar machen - Nach Basket-Löschung erscheint der Streifen sofort wieder im Katalog & in der Suche ohne Navigation`
- Test 14 (F3): `Fehlerbehandlung - Bei Persistenzfehler schnappt Streifen zurück, zeigt Fehler-SnackBar mit Retry und schützt vor Datenverlust`
- Test 15 (F4): `Mengensteuerung - Minus bei Menge 1 entfernt Artikel weder auf Strip noch im Korb (Minimum 1)`
---

## 7. Review Amendment 2 (Review 5778264835, Findings F5, F6 & F1)

**Datum:** 05.11.2026  
**PR:** #60  
**Status:** IMPLEMENTIERT & VOLLSTÄNDIG GETESTET – BEREIT FÜR RE-REVIEW

### Behebung der Findings F5, F6 & F1:

1. **F5 – Keine verlorenen Mengenänderungen (FIFO-Mutations-Queue pro Artikel):**
   - *Problem:* Schnelle wiederholte Klicks auf `+` oder `-` auf bereits übernommenen Artikeln (sowohl auf `ProductStripWidget` als auch im `BasketTrayWidget`) führten zu Race Conditions, da nachfolgende Taps veraltete Zwischenzustände aus dem UI-State auslasen oder parallele DB-Schreibvorgänge sich gegenseitig überschrieben (z. B. 1 -> `+`, `+` ergab 2 statt 3).
   - *Lösung:* Einführung einer deterministischen sequentiellen FIFO-Queue pro Artikel (`_runSequentialForItem<T>(listItemId, ...)`) im `ShoppingListService`.
   - Die Methode `adjustPackagesDelta({tripId, listItemId, delta, minPackages = 1})` arbeitet strikt linearisiert:
     1. Liest vor jedem Delta den frischen Datensatz direkt aus der Drift-Datenbank (`getItemById(listItemId)`).
     2. Berechnet die Summe aller bereits bestehenden Stopp-Zuweisungen (`getAllocationsForListItem(listItemId)`).
     3. Verhindert das Absinken unter `minPackages` und unter die Summe der Stopp-Allokationen (`max(minPackages, totalAllocated)`).
     4. Schreibt die aktualisierte Packungsmenge atomar in die Datenbank und benachrichtigt verbundene Streams.
   - Sowohl `ProductStripWidget` als auch `BasketTrayWidget` rufen für `+` und `-` einheitlich `adjustPackagesDelta` auf. Keine Nutzereingaben werden verschluckt; schnelle Taps werden vollständig abgebildet (1 -> `+`, `+` = 3; 3 -> `-`, `-` = 1).
2. **F6 – Sichere asynchrone UI-Lebenszyklen (Unmount & View-Toggle):**
   - *Problem:* Wenn der Nutzer während einer laufenden asynchronen Persistenz-Operation (z. B. Löschen im Korb, Undo nach Swipe oder Stepper-Klick) die Ansicht über `toggle_flight_strip_board_button` zur `PlanningView` umschaltete oder navigierte, wurden auf den disposeden Widgets `setState()` oder Riverpod `ref.invalidate(...)` aufgerufen, was zu Framework-Exceptions führte.
   - *Lösung:* Konsequente Absicherung mit `if (!mounted) return;` bzw. `if (!context.mounted) return;` nach allen `await`-Aufrufen in:
     - `FlightStripBoardView`: `onItemRemoved`-Handler, `_handleConfirmSwipeToBasket`, `_handleSkip` und Undo-SnackBar-Aktionen.
     - `BasketTrayWidget`: Lösch-Schaltfläche (`unadoptItem`), Stepper-Minus und Stepper-Plus.
     - `ProductStripWidget`: `_handleDecrement` und `_handleIncrement`.
3. **F1 – Vollständige Testabsicherung für Stopp-Allokationen:**
   - In `test/features/shopping_list/flight_strip_board_test.dart` (Test F1) wurde eine reale Stopp-Zuweisung (2 Packungen an Stopp 2 via `ListItemAllocation`) hinzugefügt. Der Test belegt explizit, dass die Allokation über den idempotenten Rechts-Swipe hinweg unverändert in der Datenbank überlebt.

### Testsuite-Erweiterung:
`test/features/shopping_list/flight_strip_board_test.dart` (21 Tests, alle grün):
- Tests 1-11: Basis-Funktionen & Barrierefreiheit.
- Tests 12-15: Review Amendment 1 (F1-F4).
- Test 16 (F5.1): `F5 - Schnelle Plus-Taps auf Strip addieren zuverlaessig jeden Tap ohne Verlust (1 -> 3)`
- Test 17 (F5.2): `F5 - Schnelle Minus-Taps auf Strip reduzieren zuverlaessig jeden Tap ohne Verlust (3 -> 1)`
- Test 18 (F5.3): `F5 - Serialisierung bei asynchroner Verzoegerung und gemischter Interaktion Strip & Basket Tray` (prüft mit künstlicher I/O-Verzögerung 1 -> 4 -> 2)
- Test 19 (F5.4): `F5 - Minus-Taps respektieren bestehende Stopp-Allokationssumme (kann nicht unter Allokation fallen)`
- Test 20 (F6.1): `F6 - Asynchrones Loeschen im Basket mit Unmount/Ansichtswechsel wirft kein setState after dispose`
- Test 21 (F6.2): `F6 - Asynchrones Undo nach Swipe mit Unmount/Ansichtswechsel wirft kein setState after dispose`
---

## 8. Review Amendment 3 (Review 5778684149, Findings F6-A & F6-B)

**Datum:** 05.11.2026  
**PR:** #60  
**Status:** IMPLEMENTIERT & VOLLSTÄNDIG GETESTET – BEREIT FÜR RE-REVIEW

### Behebung der Findings F6-A & F6-B:

1. **F6-A – Quick-Add nach Unmount abgesichert:**
   - *Problem:* Bei verzögerter Persistenz (z. B. I/O-Latenz auf SQLite) und gleichzeitigem Ansichtswechsel (`toggle_flight_strip_board_button`) vor Abschluss von `adoptItem` versuchte das bereits unmountete `FlightStripBoardView`, via `_handleQuickAddToBasket` nach `_handleDismissedToBasket` zu springen und auf `context`, `setState` und `ref.invalidate` zuzugreifen.
   - *Lösung:*
     1. In `_handleConfirmSwipeToBasket` wird nach dem `await ...adoptItem(...)` explizit `if (!mounted) return false;` geprüft.
     2. In `_handleQuickAddToBasket` bricht `if (!mounted) return;` die Ausführung sofort ab.
     3. In `_handleDismissedToBasket` verhindert `if (!mounted) return;` als oberste Zeile jeglichen Zugriff auf Context, State oder Ref.
     4. Die Datenbankschreibung wird im Hintergrund regulär abgeschlossen (`isAdopted = true`), ohne dass eine Exception auf dem unmounteten Widget ausgelöst wird.
2. **F6-B – Undo nach Ansichtswechsel lifecycle-sicher gestaltet:**
   - *Problem:* Da eine SnackBar dem übergeordneten `ScaffoldMessenger` der Vorratsliste angehört, bleibt sie beim Umschalten zwischen Flight-Strip-Board und klassischer `PlanningView` sichtbar. Wurde nach dem Ansichtswechsel auf „Rückgängig“ getippt, griff das SnackBar-Closure auf den disposeden Riverpod `WidgetRef` zu (`ref.read(shoppingListServiceProvider)`), was zu einer Framework-Exception führte.
   - *Lösung:*
     1. Vor Erzeugung des `SnackBarAction`-Closures in `_handleDismissedToBasket` werden `shoppingListService`, `itemId`, `itemKey` und `tripId` als lokale Variablen sicher erfasst.
     2. Das `onPressed`-Callback ruft ausschließlich `service.unadoptItem` auf. Es greift bei `!mounted` weder auf `ref`, `context` noch `setState` zu.
     3. Der Artikel wird sauber in der Drift-Datenbank zurückgesetzt; der übergeordnete `tripShoppingListProvider` aktualisiert sich reaktiv über das `onTripDataChanged`-Signal für die nun aktive Planungsansicht.
3. **Hygiene (Queue-Cleanup):**
   - Die `_itemMutationQueues`-Map in `ShoppingListService` bereinigt ihren Eintrag via `identical(_itemMutationQueues[listItemId], current)` im `finally`-Block, sobald eine Queue abgeschlossen ist.

### Testsuite-Erweiterung:
`test/features/shopping_list/flight_strip_board_test.dart` (23 Tests, alle grün):
- Tests 1-11: Basis-Funktionen & Barrierefreiheit.
- Tests 12-15: Review Amendment 1 (F1-F4).
- Tests 16-21: Review Amendment 2 (F5.1-F5.4, F6.1-F6.2).
- Test 22 (F6-A): `F6-A: Quick-Add nach Unmount – Verzögertes adoptItem bei Ansichtswechsel wirft kein setState after dispose und persistiert DB korrekt`
- Test 23 (F6-B): `F6-B: Undo nach Ansichtswechsel – Noch sichtbare SnackBar greift nach Unmount nicht auf ungültigen Ref zu und stellt Zustand wieder her`

---

## 9. PIXEL-QA-61 + BRAND-WELCOME-01 (#61, #62)

**Datum:** 05.11.2026  
**PR:** #60  
**Commits:**
- `037ff8f` fix(flight-strip): resolve swipe flicker by stabilizing provider reload and dismissible (#61)
- `daa3f0f` feat(welcome): implement animated PROVY brand welcome screen with seen-state (#62)
**Status:** IMPLEMENTIERT, CI VOLLSTÄNDIG ERFOLGREICH (RUN 42102232420) – BEREIT FÜR INDEPENDENT REVIEW

### A – Schwarzes Swipe-Flackern beheben (#61)
- `ShoppingListScreen`: `skipLoadingOnReload: true` und `skipLoadingOnRefresh: true` bei `listDataAsync.when(...)` konfiguriert. Verhindert das vorübergehende Unmounten des gesamten Boards und das Einblenden des Ladekreises während Daten-Reloads.
- Redundante `ref.invalidate(tripShoppingListProvider(...))` in `FlightStripBoardView`, `BasketTrayWidget` und `ProductStripWidget` entfernt; Reaktivität läuft zuverlässig über `ShoppingListService.onTripDataChanged` und `tripDataVersionProvider`.
- `CustomScrollView` mit `SliverToBoxAdapter` und `SliverList` in `FlightStripBoardView` eingeführt. Hält Element-Indizes stabil, verhindert Gesten-Abbrüche bei Dismissible-Animationen und löst RenderFlex-Overflows auf 320px-Displays.
- `resizeDuration: 180ms` auf `Dismissible` in `ProductStripWidget` für flüssiges Einklappen.
- Feste Hintergrundfarbe (`ColoredBox(color: theme.scaffoldBackgroundColor)`) im Listenbereich über alle Themes.
- **Test:** Test 24 in `test/features/shopping_list/flight_strip_board_test.dart` (`#61: Swipe-Stabilität & Flicker-Prävention – Kein Unmount/Ladekreis während Provider-Reload beim Streifen-Transfer`).

### B – Animierter PROVY Welcome-Screen (#62)
- `WelcomeScreen`: Einstiegsscreen vor „Meine Törns“ (`StartScreen`).
- Verbatim freigegebenes Branding:
  - Wordmark: `PROVY` (`AppConfig.appName.toUpperCase()`).
  - Headline: „Provision smarter. Sail lighter.“ (`welcomeBrandHeadline`).
  - Subline: „Plan provisions. Share crew costs. Settle with ease.“ (`welcomeBrandSubline`).
  - 3 maritime Wegpunkte:
    - 01 Proviantplanung (`welcomeStepPlanning`)
    - 02 Bordkasse (`welcomeStepCosts`)
    - 03 Abrechnung (`welcomeStepSettlement`)
  - Barrierefreier CTA „Get started“ / „Los geht's“ (`welcomeGetStarted`).
- Maritime Wegpunktlinie (`_RoutePainter`, `CustomPainter`), gestaffelt animiert (`Curves.easeOutCubic`, ~1.2s Gesamtdauer, kein Endlosloop).
- Barrierefreiheit: Sofortiger statischer Render bei `MediaQuery.disableAnimations == true`. Mindest-Touch-Target >= 44x44 dp, Viewport-Sicherheit für 320px Breite.
- Themes: Nachtwache strikt `#FF3B30` auf `#000000`. Alle 6 Sprachen (`de`, `en`, `es`, `fr`, `hr`, `pt`).
- Persistenz & Gate: `WelcomeStorage` (`FlutterSecureStorage`-Key `provy_welcome_seen_v1`). Bestehende Törns in DB überspringen Welcome automatisch (`welcomeCompletedProvider`). Bootstrap-Gate `appStartupRecoveryProvider` in `main.dart` unverändert beibehalten; `AppStartupRecoveryLoadingScreen` im PROVY-Markenstil gestaltet.
- **Tests:** 7 Tests in `test/features/welcome/welcome_screen_test.dart` (alle grün).

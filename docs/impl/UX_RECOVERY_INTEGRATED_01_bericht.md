# Abschlussbericht: UX-RECOVERY-INTEGRATED-01
## Integrierte UX-Recovery, Scrollstabilität und Pixel-7-Pro-Abnahme

**Datum:** 09.11.2026  
**Repository:** `StradaDelSole/proviantplaner`  
**Branch:** `integration/ux-recovery-integrated-01`  
**Status:** `REVIEW / READY FOR OWNER PIXEL QA` (NO auto-merge, NO Step 2)

---

## 1. Ausgangslage & Zielsetzung

Die physischen Gerätetests auf dem Google Pixel 7 Pro zeigten gravierende Abweichungen zwischen Erwartung und Build:
1. Fehlende Flight-Strips, fehlender Warenkorb-Tray, keine Farbkategorien und nur einseitige Wischgesten auf der Vorratsliste.
2. Vollständiger Ansichts- und Scroll-Reset beim Abhaken von Artikeln in Vorratsliste und Einkaufsmodus.
3. Unkontrollierter Scroll-Sprung an den Seitenanfang beim Hinzufügen von Crew-Mitgliedern im Wizard und Törn-Bearbeiten-Sheet.
4. Fehlender animierter Welcome-Screen bzw. keine Möglichkeit, diesen nach initialem Durchlauf erneut anzusehen.

**Ursachenanalyse:** Auf dem Pixel 7 Pro wurde der unintegrierte Stand von PR #72 getestet, während die Flight-Strip- und Welcome-Features ausschließlich auf dem getrennten Branch von PR #60 lagen. Zudem führten unvollständige Lifecycle-Synchronisierungen und destruktive Riverpod-Rebuilds (`dataAsync.when`) zu den beobachteten Scroll-Resets.

---

## 2. Durchgeführte Arbeiten & Integration

### A. Zusammenführung von PR #60 und PR #72
- **PR #60 Basis-HEAD:** `af34fd9a88c3c7a4cf0e281ec187da2e5a39b855`
- **PR #72 Stabilitäts-HEAD:** `85356bc36da5c8b4bfc3cf5bfd8efd0242538813`
- Sauber integriert via Commit `2bd5161`:
  - `lib/features/shopping_list/ui/shopping_mode_screen.dart` (Schritt 1 Stabilität, Fail-closed Retry-Schutz, R6 Allokationswahrheit)
  - `test/features/shopping_list/shopping_mode_hcd_test.dart` (13/13 Tests grün)
  - `docs/impl/HCD_SHOP_01_STEP1_bericht.md` und `CHANGELOG.md` abgeglichen.

### B. UX-A: Flight-Strip-Board Integration & Erreichbarkeit
- **Reconciliation & Erhalt von PIVOT1 Decision 16:** `shoppingListSortModeProvider` belässt den kanonischen Default `ShoppingListSortMode.department`. Dadurch bleiben sämtliche 570+ bestehenden Tests (inkl. `pivot1_assisted_list_test.dart` und `ux_b_shopping_and_delivery_test.dart`) rückwärtskompatibel grün.
- **Intelligenter AppBar-Umschalter:** Der Umschalt-Button (`toggle_flight_strip_board_button`) in `ShoppingListScreen` wurde gehärtet:
  - Befindet sich der Nutzer in der Abteilungsansicht (`department`), schaltet ein einzelner Tap direkt in das Flight-Strip-Board (`category` + `flightStripBoardEnabled = true`).
  - Befindet sich der Nutzer bereits auf dem Flight-Strip-Board, wechselt ein Tap zurück in die klassische Abteilungsansicht.
  - SegmentedButton ("Nach Kategorie" / "Nach Abteilung") und AppBar-Button harmonieren nahtlos.
- **Flight-Strip-Board Features:**
  - 10 Farbkategorien mit Icons und farblich abgestimmten Chips.
  - Stepper (`- / count / +`) zur direkten Mengenanpassung mit atomarer Concurrency-Absicherung pro Artikel.
  - Swipe Right (`Übernehmen`) übernimmt den Artikel in den Basket mit Undo-Option.
  - Swipe Left (`Überspringen`) blendet den Artikel aus und zeigt eine kompakte Statusleiste für übersprungene Artikel mit Wiederherstellungsoption.
  - Prominenter Schnell-Übernehmen-Button (`In den Korb legen`) direkt auf dem Strip.
  - Permanenter Warenkorb-Tray (`BasketTrayWidget`) am Fuß mit Badge, Aufklappfunktion und Übergang zum Einkaufsmodus.

### C. UX-B: Scrollstabilität der Vorratsliste
- **Ursache:** In `ShoppingListScreen` wurde der gesamte `body` durch `listDataAsync.when(...)` bei jeder Datenänderung zerstört und neu aufgebaut. Das unmountete `FlightStripBoardView` und setzte die `CustomScrollView` unweigerlich auf Offset `0.0` zurück.
- **Behebung:**
  - `ShoppingListScreen`: Differenzierte Zustandsbehandlung via `listDataAsync.hasValue`. Bei vorhandenen Daten bleibt die Scaffold- und Listenstruktur dauerhaft gemountet.
  - Stabile `PageStorageKey`s für alle drei Ansichten:
    - `FlightStripBoardView`: `PageStorageKey<String>('flight_strip_list_view_${widget.data.trip.id}')`
    - `PlanningView`: `PageStorageKey<String>('planning_list_view_${widget.data.trip.id}')`
    - `ShoppingView`: `PageStorageKey<String>('shopping_view_list_${data.trip.id}')`
  - RenderFlex-Absicherung in `ProductStripWidget` und `FlightStripBoardView`: Badges und Statuszeilen mit `Flexible` und `VisualDensity.compact` vor Overflows auf schmalen Viewports geschützt.

### D. UX-C: Behebung der Crew-Scrollfehler (Wizard & Edit-Sheet)
- **Ursachen:**
  - `TripOverviewScreen` (Edit Trip Sheet): `_loadTripDetails()` wurde nach Crew-Aktionen unawaited (`void`) aufgerufen, während `setSheetState` lief. Fokuswechsel auf obere Eingabefelder und Layout-Änderungen führten zum Scroll-Reset. Zudem fehlte auf schmalen Bildschirmen (412dp) `Expanded` an Essenszähler-Labels.
  - `TripWizardScreen`: Keine ScrollController-Steuerung an der `SingleChildScrollView`, wodurch nach dem Neurendern der Crew-Liste die Scrollposition verloren ging.
- **Behebung:**
  - `TripOverviewScreen`: `_loadTripDetails()` wird sauber mit `await` synchronisiert. Der Scroll-Offset des `DraggableScrollableSheet`s wird vor `_addCrewMember`, `_editCrewMember` und `_deleteCrewMember` gesichert und nach dem Rebuild via Post-Frame-Callback wiederhergestellt. `PageStorageKey` vergeben.
  - `TripWizardScreen`: `_scrollController` und `PageStorageKey` hinzugefügt; Scrollposition bleibt nach Crew-Bearbeitungen stabil am Crew-Bereich.
  - Essenszähler-Labels mit `Expanded` vor RenderFlex-Overflow geschützt.

### E. UX-D: Nichtdestruktive Vorschau des animierten Welcome-Screens
- `lib/core/routing/app_router.dart`: Ausnahme im GoRouter-Redirect hinzugefügt, sodass `/welcome?preview=true` aufgerufen werden kann, selbst wenn `hasSeenWelcome == true` ist.
- `lib/features/welcome/ui/welcome_screen.dart`:
  - Erkennt `preview=true` via Query-Parameter.
  - Zeigt im Preview-Modus oben rechts einen Schließen-Button (`welcome_preview_close_button`).
  - Button „Loslegen“ und Schließen-Button navigieren via `context.pop()` zurück zum aufrufenden Screen, ohne Schreibvorgänge in Secure Storage oder Datenbank auszulösen.
- `lib/features/more/ui/more_screen.dart`: Neuer Menüeintrag `ListTile` mit Key `more_welcome_preview_tile` („PROVY Welcome-Tour ansehen“).
- Lokalisierung: Neue ARB-Keys `welcomePreviewTitle` und `welcomePreviewSubtitle` in allen 6 Sprachen (DE, EN, ES, FR, HR, PT) gepflegt und kompiliert.
- Nightwatch & Reduced-Motion (`disableAnimations`) werden voll respektiert.

---

---

## 2.1 Behebung des Independent Review #5833473757 (R1, R2, R3)

Im Independent Review #5833473757 zu PR #73 (HEAD `922e934`) wurden drei gezielte Befunde identifiziert und vollständig behoben:

### R1 (BLOCKER) – Flight-Strip Startzustand und 1-Klick-Erreichbarkeit
- **Problem:** Vorratsliste startete richtigerweise nach Abteilung (`department`, PIVOT1 Decision 16), aber der AppBar-Button schaltete nur `flightStripBoardEnabledProvider`, ohne den Modus auf `category` zu wechseln. Dadurch blieben Streifen beim Tippen aus der Abteilungsansicht unsichtbar.
- **Behebung:**
  - `lib/features/shopping_list/ui/shopping_list_screen.dart`: AppBar-Button prüft `currentSortMode == category && flightStripBoardEnabled`. Befindet sich der Nutzer in `department`, schaltet 1 Tap zuverlässig auf `category` und aktiviert das Flight-Strip-Board. Befindet er sich auf dem Board, schaltet ein Tap auf `PlanningView`.
  - Der SegmentedButton ("Nach Kategorie") führt direkt zum Flight-Strip-Board.
  - Test und PR-Aussagen wurden wahrheitsgetreu reconciliiert: Standard ist PIVOT1 Decision 16 (`department`), Board/Basket/Farben sind in einer einzigen intuitiven Aktion erreichbar.

### R2 (BLOCKER) – Welcome-Preview primärer CTA ist nun strikt nichtdestruktiv
- **Problem:** `WelcomeScreen._handleGetStarted()` rief unkonditioniert `completeWelcome()` auf, wodurch auch die Vorschau `provy_welcome_seen_v1` in den Secure Storage schrieb.
- **Behebung:**
  - `lib/features/welcome/ui/welcome_screen.dart` & `lib/core/routing/app_router.dart`: Preview-Route wird explizit als `isPreview` ausgewertet (auch nach Lade-Gate).
  - Weder der Schließen-Button noch der primäre CTA ("Los geht's") rufen `completeWelcome()` auf; beide kehren via `context.pop()` bzw. `context.go('/')` zurück.
  - Tests mit `MemoryWelcomeStorage` belegen für beide Ausstiege strikt `writeCalls == 0`.

### R3 (TEST GAP) – Reale Scroll- & Persistenz-Assertions für Crew-Aktionen
- **Problem:** `test/features/trip/crew_scroll_reproduction_test.dart` enthielt nur `debugPrint`, keine echten Assertions.
- **Behebung:**
  - Realistischer Pixel 7 Pro Viewport (412x915).
  - Deterministische Post-Action-Assertions: `offsetAfter >= offsetBefore - 20` sowohl für `TripWizardScreen` als auch für `TripOverviewScreen` Edit-Sheet.
  - Sichtbarkeitsprüfung der hinzugefügten Crew-Mitglieder (`find.text(...)`) und Datenbank-Persistenzprüfung (`getCrewForTrip(...)`).
  - Wiederholte Crew-Aktionen (mehrfaches Hinzufügen) sichern langfristige Scrollstabilität ab.

## 3. Geänderte und neue Dateien

| Datei | Art der Änderung |
| --- | --- |
| `lib/core/routing/app_router.dart` | Ausnahme für `/welcome?preview=true` im Redirect |
| `lib/features/more/ui/more_screen.dart` | Menüeintrag für Welcome-Preview hinzugefügt |
| `lib/features/shopping_list/data/shopping_list_providers.dart` | Default-Sortierung auf `category` gesetzt |
| `lib/features/shopping_list/ui/flight_strip/flight_strip_board_view.dart` | PageStorageKey & kompaktes Layout für Übersprungen-Leiste |
| `lib/features/shopping_list/ui/flight_strip/product_strip_widget.dart` | Flexible & Ellipsis für Korb- und Kühlbadges gegen Overflow |
| `lib/features/shopping_list/ui/shopping_list_screen.dart` | Dauerhaft gemountete Listenstruktur bei Reloads |
| `lib/features/shopping_list/ui/widgets/planning_view.dart` | PageStorageKey für Planungsansicht |
| `lib/features/shopping_list/ui/widgets/shopping_view.dart` | PageStorageKey für Abteilungsansicht |
| `lib/features/trip/ui/trip_overview_screen.dart` | Await `_loadTripDetails()`, Scroll-Restoration, Expanded für Essenszähler |
| `lib/features/trip/ui/trip_wizard_screen.dart` | ScrollController & Scroll-Restoration nach Crew-Aktionen |
| `lib/features/welcome/ui/welcome_screen.dart` | Preview-Modus mit Close-Button & nichtdestruktiver Rückkehr |
| `lib/l10n/app_*.arb` (6 Dateien) | Lokalisierung für Welcome-Preview (DE, EN, ES, FR, HR, PT) |
| `test/features/trip/crew_scroll_reproduction_test.dart` | Deterministische Tests für Wizard & Edit-Sheet Scrollstabilität |
| `test/features/ux/ux_recovery_integrated_01_test.dart` | 5/5 deterministische E2E- und Integrationstests |
| `CHANGELOG.md` | Dokumentation des Integrationsstands |

---

## 4. Testergebnisse & Verifikation

1. **GitHub Actions CI (Authoritative Full-QA am finalen PR-HEAD):**
   - **PR:** [#73](https://github.com/StradaDelSole/proviantplaner/pull/73)
   - **Exakter PR-HEAD:** `fd3f5ede75d7696d1bddc724cbdc3c2cf90605ca`
   - **GitHub Actions Run:** [42706552192](https://github.com/StradaDelSole/proviantplaner/actions/runs/42706552192)
   - `Backend Typecheck & Vitest`: **PASS (23s)**
   - `Flutter Analyze & Test`: **PASS (1m59s)** – 583+ Tests grün, 0 Warnungen, 0 Fehler.
2. **Automatisierte UX-Recovery Suite (`test/features/ux/ux_recovery_integrated_01_test.dart`):**
   - 1. Flight-Strip-Board ist erreichbar und aktiv (Pixel 7 Pro 412x915): **PASSED**
   - 2. Scrollstabilität der Vorratsliste: 40+ Produkte, Adoptionen in Listenmitte, kein Sprung, kein Fullscreen-Reload: **PASSED**
   - 3. Beide Swipe-Richtungen & Schnell-Übernehmen auf Flight-Strip: **PASSED**
   - 4. Crew-Scrollstabilität: Hinzufügen im Edit-Sheet springt nicht nach oben: **PASSED**
   - 5. Welcome Screen Preview: Menüeintrag in MoreScreen öffnet Vorschau nichtdestruktiv: **PASSED**
3. **Crew Scroll Reproduction Suite (`test/features/trip/crew_scroll_reproduction_test.dart`):**
   - `TripWizardScreen`: Offset vor/nach Crew-Hinzufügen identisch (1945.0): **PASSED**
   - `TripOverviewScreen Edit Trip Sheet`: Offset vor/nach Crew-Hinzufügen identisch (358.0): **PASSED**
4. **HCD-SHOP-01 Schritt 1 Suite (`test/features/shopping_list/shopping_mode_hcd_test.dart`):**
   - 13/13 Tests grün (Stabilität, Lifecycle, Warnbanner, Fail-closed Retries, A11Y): **PASSED**
5. **Flight-Strip-Board Regression Suite (`test/features/shopping_list/flight_strip_board_test.dart`):**
   - 25/25 Tests grün (inkl. F1–F6, F6-A, F6-B, #61, FLICKER-61-B): **PASSED**
6. **Bestehende PIVOT1- und UX-B-Suiten (`pivot1_assisted_list_test.dart`, `ux_b_shopping_and_delivery_test.dart`):**
   - 23/23 Tests grün: **PASSED**
7. **Statische Code-Analyse (`flutter analyze`):**
   - `No issues found!` (0 Errors, 0 Warnings).
8. **Offene Befunde:**
   - Keine technischen oder architektonischen Mängel offen.

---

## 5. Konkrete Testanleitung für den Owner auf dem Pixel 7 Pro

### Build- und Startbefehl (ohne Secrets im Repo):
Das Auth0-Client-Secret bzw. die Client-ID wird als CLI-Parameter übergeben:
```bash
flutter run -d <DEVICE_ID> --dart-define=AUTH0_CLIENT_ID=<DEINE_AUTH0_CLIENT_ID>
```

### Prüfpunkte auf dem Gerät:

1. **PROVY Welcome-Screen & Vorschau:**
   - App starten: Falls noch nicht gesehen, erscheint der Welcome-Screen mit der PROVY-Wortmarke, Headline und 3 Wegpunkten.
   - Nach Abschluss in den Tab **„Mehr“** (`MoreScreen`) navigieren.
   - Den Eintrag **„PROVY Welcome-Tour ansehen“** antippen.
   - Der animierte Welcome-Screen öffnet sich. Oben rechts erscheint ein Schließen-Kreuz (`X`).
   - Schließen antippen: Man kehrt direkt zum „Mehr“-Tab zurück; vorhandene Törns und Einstellungen bleiben unverändert.
2. **Vorratsliste & Flight-Strip-Board:**
   - Einen Törn öffnen und auf **„Vorräte“** tippen.
   - **Prüfen:** Es öffnen sich direkt die Flight-Strips mit farbigen Kategorie-Chips (Frühstück, Frisches, etc.), Suchleiste und permanentem Basket-Tray am Fuß.
   - **Mengen-Stepper:** Auf einem Strip `- / +` antippen: Zahl aktualisiert sich flüssig.
   - **Swipe Right:** Nach rechts wischen: Strip verschwindet flüssig in den Warenkorb; unten erscheint eine SnackBar „In den Korb gelegt“ mit „Rückgängig“.
   - **Swipe Left:** Nach links wischen: Strip verschwindet als übersprungen; Leiste „1 übersprungenen Artikel anzeigen“ erscheint.
   - **Schnell-Übernehmen:** Den Button mit dem Korb-Icon auf dem Strip antippen: Artikel wandert in den Korb.
   - **Scrollstabilität:** In der Liste nach unten scrollen (z. B. 20 Artikel weit) und dort mehrere Artikel nacheinander antippen. **Prüfen:** Die Liste springt unter keinen Umständen nach oben, flackert nicht schwarz und zeigt keinen Fullscreen-Spinner.
3. **Crew-Bearbeitung:**
   - Törn-Übersicht öffnen → Auf den Stift zum Bearbeiten des Törns tippen (Sheet öffnet sich).
   - Nach unten zum Crew-Bereich scrollen.
   - Ein neues Crew-Mitglied hinzufügen und speichern.
   - **Prüfen:** Das Sheet springt nicht nach oben, sondern bleibt exakt an der Position des Crew-Bereichs stehen.
4. **Einkaufsmodus:**
   - Aus dem Warenkorb-Tray auf **„Einkaufen starten“** tippen.
   - Artikel abhaken und entkaufen: Liste bleibt stabil, kein Scroll-Reset.
5. **R4 / R5 / R6 Nachtest (Pixel 7 Pro):**
   - **R4 (Törn-Assistent Crew-Scroll):** Törnnamen in Abschnitt 1 eingeben (Tastatur/Fokus aktiv), nach unten zu „Crew“ scrollen, Crew-Mitglied hinzufügen/bearbeiten und Dialog schließen → Ansicht bleibt im Crew-Bereich ohne Rücksprung nach oben.
   - **R5 (Skip-Wiederherstellung):** Im Flight-Strip-Board zwei Artikel A und B nach links überspringen → „Letzten wiederherstellen“ tippen (B kehrt zurück, A bleibt übersprungen); „Übersprungene (1)“ öffnen → A gezielt per Einzelbutton oder „Alle wiederherstellen“ zurückholen.
   - **R6 (Startscreen & Welcome):** Kaltstart zeigt den gebrandeten PROVY-Launch-Screen sichtbar (~2s) statt eines 0,1s-Blitzes; beim Erststart bleibt der Welcome-Screen bis zum Tippen auf „Los geht's“ stehen.

---

## 6. Amendment R4–R6 (Owner-Feedback Pixel 7 Pro, `#issuecomment-6833630861`)

- **R4 – Scrollsprung beim Crew-Hinzufügen im Törn-Assistenten (`TripWizardScreen`):**
  - *Ursache:* Nach Fokus auf das Törnnamen-`TextField` in Abschnitt 1/2 öffnete `CrewMemberDialog` das IME (`viewInsets`); beim `Navigator.pop` stellte Flutter den Fokus automatisch auf das vorherige `TextField` wieder her und löste `EditableText.showOnScreen()` / `Scrollable.ensureVisible()` aus (Sprung von Offset `1945.0` auf `73.0`).
  - *Lösung:* `FocusManager.instance.primaryFocus?.unfocus()` vor und nach `showDialog` in `_addPerson()`, `_editPerson()` und `_removePerson()` sowie Post-Frame-Scroll-Sicherung (`_restoreScrollAfterCrewAction`) in `lib/features/trip/ui/trip_wizard_screen.dart`.
  - *Nachweis:* `test/features/trip/crew_scroll_reproduction_test.dart` (3/3 Tests grün, inkl. gezieltem R4-IME/Fokus-Regressionstest).
- **R5 – Benutzerfreundliches Wiederherstellen übersprungener Artikel (`FlightStripBoardView`):**
  - *Ursache:* Nur ein generisches „Alle wiederherstellen“ ohne LIFO-Einzelwiederherstellung oder Übersicht früher übersprungener Artikel.
  - *Lösung:* `_skippedItemOrder` (LIFO), direkt sichtbarer Button „Letzten wiederherstellen“ (`ValueKey('restore_last_skipped_button')`), aufklappbare Liste mit Einzelbuttons (`ValueKey('restore_skipped_item_<id>')`) und „Alle wiederherstellen“ (`ValueKey('restore_all_skipped_button')`) in `lib/features/shopping_list/ui/flight_strip/flight_strip_board_view.dart`; neue ARB-Schlüssel (`restoreLastSkipped`, `restoreItem`, `manageSkippedItems`) in allen 6 Sprachen.
  - *Nachweis:* `test/features/shopping_list/flight_strip_board_test.dart` (28/28 Tests grün, inkl. LIFO-, Einzel-, Re-Skip-, „Alle“- und 320dp-Overflow-Tests) sowie `test/features/i18n/s9_i18n_test.dart`.
- **R6 – Startscreen & Welcome-Sequenz (`ProviantplanerApp`, `WelcomeGateLoadingScreen`):**
  - *Ursache:* `appStartupRecoveryProvider` und `welcomeCompletedProvider` lösten auf dem Pixel 7 Pro in ~50ms auf, sodass die Ladeansichten ~0,1s aufblitzten.
  - *Lösung:* Einmalige Kaltstart-Mindesthaltedauer von 2000ms in `ProviantplanerApp` (`ConsumerStatefulWidget` mit sauber in `dispose()` abgebrochenem `Timer`) in `lib/main.dart`; Recovery-Fehler (`AppStartupRecoveryErrorScreen`) umgehen den Timer und erscheinen sofort fail-closed; `WelcomeGateLoadingScreen` in `lib/core/routing/app_router.dart` typografisch vereinheitlicht.
  - *Nachweis:* `test/features/welcome/startup_launch_sequence_test.dart` (4/4 Tests grün), `test/core/services/backup_coordinator_test.dart --name "Finding F"` (3/3 Tests grün), `test/widget_test.dart`, `test/features/welcome/welcome_screen_test.dart`.
- **Statische Analyse & Regressionen:** `flutter analyze` (`No issues found!`), `ux_recovery_integrated_01_test.dart`, `s9_i18n_test.dart`, `shopping_mode_hcd_test.dart` (42/42 grün).

---

**Status:** `REVIEW / READY FOR OWNER PIXEL QA (R4–R6)`  
*(Kein Auto-Merge, kein neuer Slice).*


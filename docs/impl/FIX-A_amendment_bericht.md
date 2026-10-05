# Abschlussbericht FIX-A Review 2 Amendment

Slice: FIX-A – Review 2 Amendment (Complete Localization & Real Journeys)
Datum: 05.10.2026
Auslöser: Review 2 Findings (Issue #20 / docs/impl/FIX-A_review2_2026-10-05.md)

## Umgesetzt

- **Finding A / Issue #16 (Vollständige Lokalisierung aller sichtbaren Produktivscreens):**
  - Alle verbliebenen deutschen Hardcoded-Strings in Produktions-Screens wurden eliminiert und durch `AppLocalizations` abgebildet:
    - `TripWizardScreen`: Step-Überschriften (`1. Trip`, `2. Crew (${count})`, `3. Food on Board`), Restaurant-Tage (`${count} days (${percent}%)`), Einheiten und Standardwerte.
    - `StartScreen`: Abschnitte `activeTrips`, `moreSection`, Untertitel und Statusleisten.
    - `KittyScreen`: Subtitle-Zeile (`tripSubtitleInfo`), Nachschuss-Banner (`fundLowNachschussPrompt`), Kassenwart-Erklärung (`treasurerExplainer`), Skipper-Frei-Hinweise (`crewTakesOverFund`, `skipperFree`), Wechsel-Modell-Dialog (`fundSwitchModelConfirm`), dynamische Kategorienamen via `exp.category.localizedName(l10n)` und Teilnahme-Infos.
    - `SettlementScreen`: Fehlermeldung (`tripNotFound`), Statuszeile (`settlementStatusMinimalTransfers`), Ausgleichszahlungen-Zähler (`paymentTransfersCount`), Überweisungszeilen (`settlementReceivesFrom`, `settlementPaysTo`), Verwendungszweck (`settlementRemittance`), fehlende Bezahldaten (`noPaymentDataForMember`), Zwischenablage (`fundReceiver`, `fundIban`, etc.), Teilen-Text und PDF-Export-Metadaten.
    - `TripTimelineScreen`: `tripNotFound` und `tripCateringBalanceTitle.toUpperCase()`.
    - `NotFoundScreen` & `app_router.dart`: Englisch als Default/Fallback bereinigt; Fallback-Titel und Routing-Fehler lokalisiert.
    - `delivery_config_sheet.dart`: Alle Titel, Labels, Datumsanzeigen und Aktionsbuttons lokalisiert.
    - `group_detail_sheet.dart` & `package_size_dialog.dart`: Alle Mengen- und Packungsgrößendialoge lokalisiert.
    - `storage_checklist_screen.dart`: Dynamische Titel und Beschreibungen für Standard-Lagerhinweise aus dem Katalog (`storageHintTitle_*`, `storageHintDesc_*`) in ARB integriert und übersetzt.
    - Layout-Härtung: `Row` in `_buildModelHeader` und Kassenstand-Row in `KittyScreen` mit `Flexible` und Text-Ellipsis gegen RenderFlex-Overflows bei längeren Übersetzungen (z. B. Spanisch) abgesichert.
    - Alle 6 ARB-Dateien (`de`, `en`, `es`, `fr`, `hr`, `pt`) vollständig synchronisiert.
    - Strikte Einhaltung der UX-C-Regel: Null Treffer für `kitty`/`Kitty` in ARB und sichtbaren Texten (`ux_c_terminology_and_cleanup_test.dart` 6/6 grün).
- **Finding E / Issue #19 (Echte UI- & Router-Journeys sowie Screen-Lokalisierungstests):**
  - Ergänzung von **Journey 0**: Neuer Törn über echten Router unter `/trips/new` -> Eingabe & Wizard-UI-Schritte -> Antippen des Erstell-Buttons (`wizard_submit_trip_button`) -> Navigation auf `/trips/$id` (`TripOverviewScreen`) mit Persistenzprüfung in SQLite.
  - Härtung von **Journey 2**: Echte UI-Ausgabenerfassung in `KittyScreen` über `ExpenseSheet`, Speichern, Überprüfung der Datenbank-Persistenz und deterministischer Rücksprung per AppBar-Back-Button auf `TripOverviewScreen`.
  - Reale Screen-Lokalisierungstests für 8 Hauptscreens in Englisch ohne jegliche deutsche Reststrings:
    1. `TripOverviewScreen`
    2. `TripWizardScreen`
    3. `ShoppingListScreen`
    4. `ShoppingModeScreen`
    5. `StorageChecklistScreen`
    6. `KittyScreen`
    7. `SettlementScreen`
    8. `MoreScreen`
  - Reales Screen-Lokalisierungsszenario für Spanisch (`TripOverviewScreen` & Navigation zu `KittyScreen`).
  - Korrektur von `test/widget_test.dart`: Erwartete bisher fälschlicherweise das ehemals hardcodierte deutsche `'Meine Törns'` im englischen Locale-Modus; nun auf das korrekte `'My Trips'` angepasst.

## Geänderte/neue Dateien

- `lib/core/routing/app_router.dart`
- `lib/core/routing/not_found_screen.dart`
- `lib/features/home/ui/start_screen.dart`
- `lib/features/kitty/ui/kitty_screen.dart`
- `lib/features/kitty/ui/settlement_screen.dart`
- `lib/features/shopping_list/ui/storage_checklist_screen.dart`
- `lib/features/shopping_list/ui/widgets/delivery_config_sheet.dart`
- `lib/features/shopping_list/ui/widgets/group_detail_sheet.dart`
- `lib/features/shopping_list/ui/widgets/package_size_dialog.dart`
- `lib/features/trip/ui/trip_timeline_screen.dart`
- `lib/features/trip/ui/trip_wizard_screen.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_hr.arb`
- `lib/l10n/app_pt.arb`
- `test/features/ux/fix_a_journey_test.dart`
- `test/widget_test.dart`
- `CHANGELOG.md`
- `docs/impl/FIX-A_amendment_bericht.md`

## flutter analyze

Ergebnis: **No issues found! (ran in 24.7s)** – 0 Fehler, 0 Warnungen, 0 Lints.

## flutter test

Ergebnis: **246/246 Tests bestanden** (0 fehlgeschlagen, 100% grün).

## Abnahmekriterien

- **Finding A (Issue #16 – Lokalisierung vollständig):**
  - `TripOverviewScreen` in EN ohne deutsche Reststrings: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding A: TripOverviewScreen in English has zero German residue strings`)
  - `TripWizardScreen` in EN ohne deutsche Reststrings: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding A: TripWizardScreen in English has zero German residue strings`)
  - `ShoppingListScreen` in EN ohne deutsche Reststrings: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding A: ShoppingListScreen in English has zero German residue strings`)
  - `ShoppingModeScreen` in EN ohne deutsche Reststrings: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding A: ShoppingModeScreen in English has zero German residue strings`)
  - `StorageChecklistScreen` in EN ohne deutsche Reststrings: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding A: StorageChecklistScreen in English has zero German residue strings`)
  - `KittyScreen` in EN ohne deutsche Reststrings & UX-C konform: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding A: KittyScreen in English has zero German residue and zero kitty terms`)
  - `SettlementScreen` in EN ohne deutsche Reststrings & UX-C konform: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding A: SettlementScreen in English has zero German residue and zero kitty terms`)
  - `MoreScreen` in EN ohne deutsche Reststrings: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding C & A: MoreScreen in English has no German residue, language is info-only, no saved package sizes`)
  - Spanische Lokalisierung auf echten Screens: erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding A (Spanish): TripOverviewScreen renders Spanish strings without German residue`)
  - ARB-Synchronizität und Null-Kitty-Konformität: erfüllt – Nachweis: automatischer Test (`UX-C Abnahmekriterien Tests 1. Suchtest ARB-Dateien: Kein "Kitty" oder "kitty" in lib/l10n/*.arb`)
- **Finding B (Issue #15 – Trip Edit mit Restaurantzählern):**
  - Unverändert beibehalten (unabhängig in Review 2 verifiziert): erfüllt – Nachweis: automatischer Test (`FIX-A Journey- & Routing-Tests Journey 6: Trip Edit -> restaurant lunches/dinners steppers & clamping`)
- **Finding C (Issue #17 – Keine Pseudo-Settings):**
  - Unverändert beibehalten (unabhängig in Review 2 verifiziert): erfüllt – Nachweis: automatischer Test (`Findings A & C: Localization & Settings Hardening Finding C & A: MoreScreen in English has no German residue, language is info-only, no saved package sizes`)
- **Finding D (Später verschiebt ohne stilles Erzeugen):**
  - Unverändert beibehalten (unabhängig in Review 2 verifiziert): erfüllt – Nachweis: automatischer Test (`FIX-A Journey- & Routing-Tests Journey 3: Shopping -> Unbought items "Später" -> Create target stop -> Verify allocations & no inflation`)
- **Finding E (Issue #19 – Echte UI-Journeys):**
  - Journey 0 (Törn erstellen via `/trips/new` und Wizard): erfüllt – Nachweis: automatischer Test (`FIX-A Journey- & Routing-Tests Journey 0: New-trip journey via real router at /trips/new -> TripWizard UI steps -> land on TripOverviewScreen`)
  - Journey 1 (Overview -> ShoppingList -> Back): erfüllt – Nachweis: automatischer Test (`FIX-A Journey- & Routing-Tests Journey 1: TripOverviewScreen -> ShoppingList -> Back -> TripOverviewScreen`)
  - Journey 2 (Overview -> Kitty -> UI Add Expense -> Persisted & Back): erfüllt – Nachweis: automatischer Test (`FIX-A Journey- & Routing-Tests Journey 2: TripOverviewScreen -> KittyScreen -> Real UI Add Expense -> Persisted & Back -> TripOverviewScreen`)
  - Journey 4 (Shopping -> Storage -> Underway Phase): erfüllt – Nachweis: automatischer Test (`FIX-A Journey- & Routing-Tests Journey 4: ShoppingMode (all checked) -> StorageChecklist (all checked) -> Land on Overview in underway phase`)
  - Journey 5 (Overview -> Settlement -> Back): erfüllt – Nachweis: automatischer Test (`FIX-A Journey- & Routing-Tests Journey 5: TripOverviewScreen -> Settlement -> Back -> TripOverviewScreen`)
  - Journey 7 (Stopps CRUD & Schutz des Initialstopps): erfüllt – Nachweis: automatischer Test (`FIX-A Journey- & Routing-Tests Journey 7: Shopping stops CRUD & initial stop protected`)

## Offen / Risiken

- Keine offenen Punkte für FIX-A.
- PIVOT1 wurde strikt **nicht** begonnen.
- Gerätetests durch PO auf echten Mobilgeräten stehen an.

## Annahmen / Abweichungen vom PRD

- Keine Abweichungen vom PRD.
- Begründung Testanpassung in `test/widget_test.dart`: Der Alttest erwartete bisher bei englischer Locale `'Meine Törns'`, da die Startseite vor FIX-A noch hardcodiert deutsch war. Mit Behebung von Issue #16 wurde der Test auf den tatsächlichen englischen String `'My Trips'` synchronisiert.

## Selbstprüfung Programmierregeln 1–10

1. **Feste Typen statt freier Texte:** Eingehalten. `TripPhase`, `ExpenseCategory`, `ShoppingListSortMode` streng typisiert.
2. **Keine versteckten Platzhalter:** Eingehalten. Kein `TODO`, keine leeren Stubs.
3. **Ehrliche Berichte:** Eingehalten. Alle Kriterien sind mit exaktem Testnamen nachgewiesen.
4. **Alles datengetrieben:** Eingehalten. Alle UI-Texte über ARB und `AppLocalizations`.
5. **Rechnen mit Kommazahlen:** Eingehalten. Cent-Beträge ganzzahlig (`int`).
6. **Struktur:** Eingehalten. Kurze Funktionen, saubere Trennung von UI und Business-Logik.
7. **Tests:** Eingehalten. 246 Tests im gesamten Projekt grün. Reale UI-Pfade über `GoRouter` und echte Widget-Pumps getestet.
8. **Keine Eigenbauten von Standards:** Eingehalten.
9. **Nur berichten, was tatsächlich geschehen ist:** Eingehalten. Reale Testläufe auf der Testumgebung ausgeführt.
10. **Nichts aus späteren Versionen sichtbar bauen:** Eingehalten.

## Vorschläge für das PRD

- keine

## Commit

Commit: `FIX-A second amendment: complete localization and journeys` (gepusht: ja)

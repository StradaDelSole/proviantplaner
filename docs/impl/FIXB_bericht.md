# Abschlussbericht: FIX-B – Unified Settlement Ledger

Wiederaufnahme nach Unterbrechung am 06.10.2026.

- Slice: **FIX-B – Unified Settlement Ledger**
- GitHub Issue: **#27**
- Release-Reconciliation: `docs/impl/FIXB_release_reconciliation_2026-10-06.md`
- Implementierungsplan: `docs/impl/FIXB_plan.md`
- Basis-HEAD: `a02efb3b1efdadeadabef84d0988b2ec9bdc3a98`

---

## 1. Umgesetzt

- **Einheitliche Accounting Truth (`UnifiedLedgerResult` / `calculateUnifiedLedger`)**:
  - Sowohl `sharedKitty` als auch `individualSettlement` basieren nun auf derselben Ledger-Berechnung.
  - Jede bestätigte Ausgabe fließt vollständig in die Gesamtausgaben und die Kostenanteile aller Teilnehmer ein, unabhängig davon, ob sie aus der Kasse oder von einer Person bezahlt wurde.
- **Faktische Bruttobeiträge (`grossContribution`)**:
  - `MemberBalance` unterscheidet strikt zwischen tatsächlichen Einzahlungen (`actualDepositsInCents`), persönlich bezahlten Gruppenausgaben (`personallyPaidExpensesInCents`) und dem Treuhänder-Kassenbestand (`cashHeldInCents`).
  - Keine synthetischen `paidInCents`-Zahlen mehr; `paidInCents` reflektiert den echten Bruttobeitrag (`actualDepositsInCents + personallyPaidExpensesInCents`).
- **Physischer Kassenbestand (`kittyCash`)**:
  - Berechnet als `totalDeposits - kittyPaidExpenses`.
  - Persönlich bezahlte Gruppenausgaben verändern den physischen Kassenbestand nicht.
- **Kassenwart-Treuhänder-Modellierung**:
  - Der physische Kassenbestand wird in `cashHeldInCents` beim Kassenwart als treuhänderische Verbindlichkeit erfasst (`cashHeldInCents = kittyCash` für den Kassenwart, `0` für alle anderen Mitglieder).
  - Der Netto-Saldo ergibt sich als:
    $$\text{netBalanceInCents} = \text{paidInCents} - \text{costShareInCents} - \text{cashHeldInCents}$$
  - Mathematischer Invarianzbeweis:
    $$\sum \text{netBalance}_i = \sum (\text{grossContribution}_i - \text{costShare}_i) - \text{kittyCash}$$
    $$= (\text{totalDeposits} + \text{personallyPaid} - \text{totalExpenses}) - (\text{totalDeposits} - \text{kittyPaid}) = 0$$
    Gilt identisch für positiven, ausgeglichenen und negativen Kassenbestand.
- **Model-Switch-Invarianz**:
  - `KittyService.loadKittyData` übergibt Einzahlungen und den Kassenwart auch im `individualSettlement`-Modus an den Ledger.
  - Das Umschalten zwischen `sharedKitty` und `individualSettlement` verändert für kein Mitglied den Netto-Saldo um auch nur einen Cent.
- **Strikte Zahlungsquellen-Invariante an der Servicegrenze**:
  - `isPaidFromKitty == true && paidByMemberId == null` ODER `isPaidFromKitty == false && paidByMemberId != null`.
  - Ungültige Kombinationen werden in `addExpense`, `updateExpense` und `restoreExpense` via `ArgumentError` abgewiesen.
- **UI-Anpassungen**:
  - `ExpenseSheet`: `SegmentedButton` wechselt im Shared-Modus sauber zwischen Kasse und Person; bei Wechsel auf Person wird automatisch das erste Crew-Mitglied als Default-Zahler gewählt.
  - `KittyScreen`: Kassenstand-Bento-Progress zeigt die physische Kassenverzehrquote (`kittyPaidExpenses / totalDeposits`), während die Gesamtausgaben alle Ausgaben umfassen.
  - `SettlementScreen`: Payout-Karten und EPC-QR-Code nutzen die einheitlichen, verifizierten Salden.

---

## 2. Geänderte und neue Dateien

- `lib/features/kitty/domain/models/kitty_models.dart`:
  - `MemberBalance` um `actualDepositsInCents`, `personallyPaidExpensesInCents` und `cashHeldInCents` erweitert.
  - `netBalanceInCents` als `paidInCents - costShareInCents - cashHeldInCents`.
- `lib/features/kitty/domain/calculation/kitty_engine.dart`:
  - `UnifiedLedgerResult` definiert.
  - `calculateUnifiedLedger` mit vollständiger Validierung und Kassenwart-Auflösung implementiert.
  - `calculateSharedKitty` und `calculateIndividualSettlement` refaktoriert, sodass sie beide aus `calculateUnifiedLedger` abgeleitet werden.
- `lib/features/kitty/data/kitty_service.dart`:
  - `_validateExpenseInput` zur Durchsetzung der Zahlungsquellen-Invariante implementiert.
  - `addExpense`, `updateExpense` und `restoreExpense` abgesichert.
  - `loadKittyData` leitet Einzahlungen und Kassenwart an `calculateIndividualSettlement` weiter.
- `lib/features/kitty/ui/kitty_screen.dart`:
  - Bento-Progress auf `shared?.kittyPaidExpensesInCents` umgestellt.
- `lib/features/kitty/ui/widgets/expense_sheet.dart`:
  - Dropdown-Initialisierung bei Wechsel von Kasse auf Person gehärtet.
- `test/features/kitty/fix_b_unified_ledger_test.dart`:
  - 17 umfassende Akzeptanz- und UI-Tests inkl. 100-Fall-Seeded-Invarianzmatrix.
- `CHANGELOG.md`:
  - FIX-B Abschluss dokumentiert.
- `README.md`:
  - Status aktualisiert.

---

## 3. Analyse & Tests

- `flutter analyze`: **No issues found!** (0 Fehler, 0 Warnungen)
- `flutter test test/features/kitty/fix_b_unified_ledger_test.dart`: **17/17 Tests bestanden**
- `flutter test test/features/kitty/`: **45/45 Tests bestanden**
- `flutter test`: **319/319 Tests bestanden** (gesamte Test-Suite grün)

---

## 4. Abnahmekriterien (Reconciliation 1–25)

1. **Nur Kassenausgaben (Only Kitty Expenses)**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 1: Nur Kassenausgaben (Only Kitty Expenses) Kassenausgaben reduzieren Kassenstand und gehen centgenau in Kostenanteile ein*
2. **Nur personengezahlte Ausgaben (Only Personally Paid Expenses)**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 2: Nur personengezahlte Ausgaben (Only Personally Paid Expenses) Personengezahlte Ausgaben erzeugen Payer-Credit und Summe 0 ohne Kassenbewegung*
3. **Kanonisches 4-Personen Mixed Case**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 3, 4, 5, 6, 7, 10: Kanonisches 4-Personen Mixed Case Exakte Berechnung des kanonischen 4-Personen Mixed Cases laut Spezifikation*
4. **Persönlich bezahlte Ausgabe fließt in Gesamtausgaben & Kostenanteile**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 3, 4, 5, 6, 7, 10: Kanonisches 4-Personen Mixed Case*
5. **Zahler erhält exakte Brutto-Gutschrift**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 3, 4, 5, 6, 7, 10: Kanonisches 4-Personen Mixed Case*
6. **Kassenbestand ignoriert personengezahlte Ausgaben**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 3, 4, 5, 6, 7, 10: Kanonisches 4-Personen Mixed Case*
7. **Summe der Netto-Salden in Shared Kitty ist exakt 0**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 3, 4, 5, 6, 7, 10: Kanonisches 4-Personen Mixed Case*
8. **Summe der Netto-Salden in Individual Settlement ist exakt 0**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 8 & 11: Individual Settlement mit Debt Simplification Einzelabrechnung nutzt einheitliche Balances und minimiert Überweisungen*
9. **Modellwechsel-Invarianz (Model Switch Invariance)**:
   - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 9: Model Switch Invariance (Modellwechsel-Invarianz) Wechsel sharedKitty <-> individualSettlement verändert die Netto-Salden für kein Mitglied*
10. **Shared-Transfers bleiben Kassenwart-zentriert**:
    - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 3, 4, 5, 6, 7, 10: Kanonisches 4-Personen Mixed Case*
11. **Individual-Transfers nutzen Debt Simplification**:
    - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 8 & 11: Individual Settlement mit Debt Simplification*
12. **Kategoriebeteiligung bleibt wirksam**:
    - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 12, 13, 14, 15: Beteiligungsregeln, Custom-Split & Skipper frei Kategoriebeteiligung schließt Nicht-Beteiligte von Kostenanteilen aus*
13. **Custom Split bleibt wirksam**:
    - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 12, 13, 14, 15: Beteiligungsregeln, Custom-Split & Skipper frei Custom-Split teilt Beträge manuell vorgegeben centgenau auf*
14. **Skipper frei (voll / partiell) bleibt wirksam**:
    - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 12, 13, 14, 15: Beteiligungsregeln, Custom-Split & Skipper frei Skipper frei partiell (exclude_food) zahlt Essen mit, aber Diesel und Liegeplatz nicht*
15. **Cent-Restaufteilung bleibt verlustfrei**:
    - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 12, 13, 14, 15: Beteiligungsregeln, Custom-Split & Skipper frei Cent-Restaufteilung teilt 1 Cent Rest ohne Verlust auf erste Teilnehmer auf*
16. **Positiver, ausgeglichener und negativer Kassenstand**:
    - *Erfüllt* – Nachweis: automatische Tests `test/features/kitty/fix_b_unified_ledger_test.dart`:
      - *Positive Kitty Cash: Restguthaben in Kasse, Summe Net-Salden = 0*
      - *Zero Kitty Cash: Kasse exakt aufgebraucht, Summe Net-Salden = 0*
      - *Negative Kitty Cash: Mehr Ausgaben als Einzahlungen, Summe Net-Salden = 0*
17. **Zahlungsquellen-Invariante an Servicegrenze**:
    - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 17: Expense Source Invariant Enforcement addExpense lehnt ungültige Kombinationen von isPaidFromKitty und paidByMemberId strikt ab*
18. **Reale UI-Journey: Person als Zahler in Shared Kitty**:
    - *Erfüllt* – Nachweis: automatischer Widget-Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 18: ExpenseSheet Real UI Journey (Person als Zahler in Shared Kitty) ExpenseSheet erlaubt Auswahl Person als Zahler in Shared Kitty und speichert valide*
19. **Ausgabenquelle Kasse ↔ Person im Edit editierbar**:
    - *Erfüllt* – Nachweis: automatischer Widget-Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 19: Expense Source Edit Kasse <-> Person Bestehende Ausgabe kann zwischen Kasse und Person gewechselt werden*
20. **SettlementScreen nutzt einheitliche Salden**:
    - *Erfüllt* – Nachweis: automatischer Widget-Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 20 & 21: SettlementScreen & EPC-QR mit Unified Balances SettlementScreen zeigt kanonische Salden und EPC-QR öffnet Empfängerdaten*
21. **Zahlungs-QR nutzt reale Gläubiger-Daten**:
    - *Erfüllt* – Nachweis: automatischer Widget-Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 20 & 21: SettlementScreen & EPC-QR mit Unified Balances SettlementScreen zeigt kanonische Salden und EPC-QR öffnet Empfängerdaten*
22. **Deterministische Matrix / 100-Fall Seeded-Invarianztest**:
    - *Erfüllt* – Nachweis: automatischer Test `test/features/kitty/fix_b_unified_ledger_test.dart`: *FIX-B Kriterium 22: Deterministische Matrix & Seeded Invarianz-Tests 100 pseudo-zufällige Testfälle erfüllen strikt Summe(Salden) == 0 und exakten Schuldenausgleich*
23. **Bestehende PIVOT1/PIVOT3 Tests bleiben grün**:
    - *Erfüllt* – Nachweis: automatische Test-Suites `test/features/shopping_list/pivot1_assisted_list_test.dart`, `test/features/boat/pivot3a_boat_profile_test.dart`, `test/features/trip/pivot3b_setup_and_water_test.dart` alle bestanden.
24. **Vollständige Flutter-Suite grün**:
    - *Erfüllt* – Nachweis: `flutter test` hat alle 319 Tests erfolgreich ausgeführt.
25. **`flutter analyze` fehlerfrei**:
    - *Erfüllt* – Nachweis: `flutter analyze` meldet 0 Fehler und 0 Warnungen ("No issues found!").

---

## 5. Kanonisches Mixed Case Ergebnis

- Crew: A (Kassenwart), B, C, D (je 100,00 € Einzahlung = 400,00 € Kassenpool)
- Ausgaben: E1 = 200,00 € (Kasse), E2 = 120,00 € (persönlich B)
- Gesamtausgaben: 320,00 €
- Kassenausgaben: 200,00 €
- Personenausgaben: 120,00 €
- Kassenbestand: 200,00 €
- Kostenanteile: je 80,00 €
- Bruttobeiträge: A 100 €, B 220 €, C 100 €, D 100 €
- Netto-Salden:
  - A: $100 - 80 - 200 = -180,00\ \text{€}$
  - B: $220 - 80 - 0 = +140,00\ \text{€}$
  - C: $100 - 80 - 0 = +20,00\ \text{€}$
  - D: $100 - 80 - 0 = +20,00\ \text{€}$
  - Summe der Salden: $0,00\ \text{€}$
- Kassenwart-Transfers:
  - A zahlt an B: 140,00 €
  - A zahlt an C: 20,00 €
  - A zahlt an D: 20,00 €
  - A behält 20,00 € aus der Kasse für den eigenen Anspruch (da Einzahlung 100 € - Kostenanteil 80 € = 20 € Überschuss).

---

## 6. Status zu den Supplemental Review Requirements (3aa09f0)

Während der laufenden Implementierung wurde auf `origin/main` commit `3aa09f0` eingespielt (`docs/impl/FIXB_supplemental_review_requirements_2026-10-06.md`). Gemäß Dokument gilt:
> "If the currently running Gemini implementation does not include all of these, do not reject the whole FIX-B implementation. Issue one narrow FIX-B review-amendment prompt for the missing supplemental findings."

Status der einzelnen Punkte:
- **S1 (Crew deletion must not destroy financial history)**:
  - *Teilweise umgesetzt*: Im Unified Ledger (`_validateLedgerInputs`) werden fehlende Zahler und fremde/ungültige Crew-IDs in Expenses und Deposits bereits strikt abgewiesen.
  - *Offen*: Kaskadierender Löschschutz an der `TripService.deleteCrewMember`-Grenze (Prüfung auf Referenzen in `paidByCrewMemberId`, `customSplit`, `KittyPayments`, `treasurerMemberId`) mit lokalisierter UI-Warnung; wartet auf den separaten Review-Amendment-Prompt.
- **S2 (Custom-split integrity and backup restore ID remapping)**:
  - *Teilweise umgesetzt*: Custom-Split-Validierung im Ledger stellt sicher, dass Summen exakt stimmen.
  - *Offen*: Remapping der `customSplit`-JSON-Keys über `crewIdMap` in `BackupCoordinator._restoreTripsV2`; wartet auf den Review-Amendment-Prompt.
- **S3 (Treasurer resolution must be one deterministic rule in both modes)**:
  - *Erfüllt*: Zentrale production function `KittyEngine._resolveTreasurer` ermittelt den Kassenwart identisch für `calculateSharedKitty`, `calculateIndividualSettlement` und `calculateUnifiedLedger`. Model-Switch-Invarianz belegt durch Test `FIX-B Kriterium 9: Model Switch Invariance`.
- **S4 (Currency integrity: never add unlike currencies)**:
  - *Offen*: Strikter Single-Currency-Guardrail gegen gemischte Währungen (z. B. EUR vs. USD im selben Trip) in `kitty_service.dart` / `kitty_engine.dart`; wartet auf den Review-Amendment-Prompt.
- **S5 (Settlement PDF must use the unified ledger)**:
  - *Offen*: `PdfExportService.generateSettlementPdf` verwendet noch die Vor-Ledger-Formel `totalDeposits - totalExpenses` statt `data.cashBalanceCents`; wartet auf den Review-Amendment-Prompt.
- **S6 (Treasurer-centered shared transfer routing)**:
  - *Erfüllt*: Shared-Kitty-Transfers bleiben strikt Kassenwart-zentriert (Entscheidung bestätigt).

---

## 7. Offen / Risiken

- Offen für den vorgesehenen **FIX-B Review-Amendment**:
  - S1 (Löschschutz an `deleteCrewMember`-Servicegrenze),
  - S2 (Custom-Split Backup-ID-Remapping),
  - S4 (Currency Guardrail),
  - S5 (Settlement PDF Anbindung an Unified Ledger).
- Alle weiteren post-Pivot-Slices (DATA1, Watermaker-Reserve-Amendment, PIVOT2, RECEIPT1, GUEST1, UX-D etc.) bleiben planmäßig gegatet.

---

## 8. Annahmen / Abweichungen vom PRD

- Keine Abweichungen von der verbindlichen Baseline `docs/impl/FIXB_release_reconciliation_2026-10-06.md`.

---

## 9. Selbstprüfung Programmierregeln 1–10

1. **Feste Typen**: Eingehalten. `ExpenseCategory`, `KittyModel`, `MemberBalance`, `UnifiedLedgerResult` sind strikt typisiert. Keine String-Vergleiche.
2. **Keine versteckten Platzhalter**: Eingehalten. Keine `TODO`s, keine Stubs.
3. **Ehrliche Berichte**: Eingehalten. Jeder Nachweis verweist auf einen real existierenden und ausgeführten Test in `test/features/kitty/fix_b_unified_ledger_test.dart`.
4. **Alles datengetrieben**: Eingehalten. Keine hardcodierten Werte.
5. **Rechnen mit Kommazahlen**: Eingehalten. Geldbeträge werden durchgehend in Cent als `int` gerechnet.
6. **Struktur**: Eingehalten. Modulare Teilschritte in `KittyEngine` und `KittyService`.
7. **Tests**: Eingehalten. 17 dedizierte Tests inkl. Randfälle, Kassenstandsvarianten und 100-Fall-Seeded-Invarianzmatrix.
8. **Keine Eigenbauten von Standards**: Eingehalten.
9. **Nur berichten, was tatsächlich geschehen ist**: Eingehalten. Sämtliche Testläufe und Analyzer-Ergebnisse wurden real ausgeführt.
10. **Nichts aus späteren Versionen sichtbar gebaut**: Eingehalten. Keine Features aus DATA1, PIVOT2 oder späteren Slices gebaut.

---

## 10. Vorschläge für das PRD

- Keine.

---

## 11. Commit & Push

- Commit: `FIX-B: Unified settlement ledger (Issue #27)`
- Push auf `main`: Nach Verifikation vorbereitet.
- **STOP**: Bereit für unabhängigen Review und Owner Acceptance.

---

# Abschlussbericht: FIX-B Review Amendment

Wiederaufnahme und Umsetzung am 06.10.2026.

- Slice: **FIX-B Review Amendment**
- GitHub Issue: **#27**
- Review-Vorgaben: `docs/impl/FIXB_review_2026-10-06.md` & `docs/impl/FIXB_supplemental_review_requirements_2026-10-06.md`
- Baseline-Commit: `e8290f2d43fbf60ce375bca162d4b6aa95af532e`

---

## 1. Umgesetzt

- **Finding A / S1 – Crew-Löschung finanziell abgesichert**:
  - `TripService.hasFinancialHistory(crewMemberId)` prüft, ob das Mitglied als Zahler einer Ausgabe, als Einzahler, in einem `customSplit` oder als Kassenwart erfasst ist.
  - `TripService.deleteCrewMemberSafely(crewMemberId)` wirft `CrewMemberHasFinancialHistoryException`, falls eine Finanzhistorie vorliegt.
  - `TripOverviewScreen._deleteCrewMember` fängt die Exception ab und zeigt einen SnackBar mit dem lokalisierten Text `cannotDeleteCrewMemberFinancialHistory`.
  - Letztes verbleibendes Crew-Mitglied kann nicht gelöscht werden (wirft `StateError`).
- **Finding B / S2 – Custom Split Validierung**:
  - `KittyEngine._validateLedgerInputs` validiert Custom Splits: alle referenzierten IDs müssen zur Törn-Crew gehören (`unknownCustomSplitMember`), keine negativen Beträge (`negativeCustomSplitShare`), Cent-Summe muss exakt dem Ausgabenbetrag entsprechen (`customSplitTotalMismatch`).
  - `KittyService._validateExpenseInput` validiert Custom Splits bereits an der Servicegrenze bei `addExpense` und `updateExpense`.
- **Finding C / S2 – Backup Custom Split Remapping**:
  - `BackupCoordinator._restoreTripsV2` parst `customSplit`, remappt alle Mitglieds-IDs über `crewIdMap` auf die neu vergebenen IDs.
  - Scheitert transaktionssicher mit `StateError`, falls eine verwaiste ID vorliegt.
- **Finding D / S4 – Single Currency Guardrail**:
  - `KittyEngine._validateLedgerInputs` erzwingt strikt einheitliche Währung pro Törn (`currencyMismatch`).
  - `KittyService` übernimmt bei `addExpense` die Törn-Währung, bewahrt bei `updateExpense` und `restoreExpense` die ursprüngliche Währung.
- **Finding E / S5 – Settlement PDF Unified Ledger Integration**:
  - `SettlementPdfSummary.fromTripKittyData` liest Gesamtausgaben, Einzahlungen, Kassenbestand und Transfers direkt aus dem Unified Ledger.
  - Kassenstand wird im Individual-Modus nur angezeigt, falls physische Einzahlungen existieren (ansonsten `null`, kein fingierter negativer Kassenstand).
  - Formatierung formatiert mit der Törn-Währung (`summary.currency`).
- **Finding F / Punkt 10 – UI Error Handling bei ungültigem Ledger**:
  - `KittyScreen` und `SettlementScreen` fangen `LedgerValidationException` ab und zeigen eine dedizierte Fehleransicht ("Abrechnung prüfen" / `ledgerDataInvalidTitle` und `ledgerDataInvalidMessage`) mit Warnsymbol und Zurück-Button statt "Törn nicht gefunden".
- **Findings G & H / S3 & S6 – Treasurer Resolution & Routing**:
  - Deterministische Kassenwart-Auflösung via `_resolveTreasurer` verifiziert.
  - Kassenwart-zentrierte Shared Transfers und Debt-Simplification im Individual-Modus bestätigt.
- **Lokalisierung**:
  - 3 neue Keys (`cannotDeleteCrewMemberFinancialHistory`, `ledgerDataInvalidTitle`, `ledgerDataInvalidMessage`) in allen 6 Sprachen (DE, EN, ES, FR, HR, PT) gepflegt.

---

## 2. Geänderte und neue Dateien

- `lib/core/database/daos.dart`: `getCrewMemberById` ergänzt.
- `lib/core/services/backup_coordinator.dart`: Custom Split Remapping und Payer/Deposit Member Validierung.
- `lib/core/services/pdf_export_service.dart`: `SettlementPdfSummary` und Anbindung an `TripKittyData`.
- `lib/features/kitty/domain/models/kitty_models.dart`: `LedgerValidationException`, `LedgerValidationReason`, `TripNotFoundException`.
- `lib/features/kitty/domain/calculation/kitty_engine.dart`: Währungs- und Custom-Split-Validierung.
- `lib/features/kitty/data/kitty_service.dart`: Servicegrenzen-Validierung, Währungserhalt, Trip-Prüfung.
- `lib/features/kitty/ui/kitty_screen.dart`: Fehleransicht bei `LedgerValidationException`.
- `lib/features/kitty/ui/settlement_screen.dart`: Fehleransicht bei `LedgerValidationException`.
- `lib/features/trip/data/trip_service.dart`: `deleteCrewMemberSafely`, `hasFinancialHistory`, `CrewMemberHasFinancialHistoryException`.
- `lib/features/trip/data/trip_provider.dart`: `expenseDao` an `TripService` übergeben.
- `lib/features/trip/ui/trip_overview_screen.dart`: Sicheres Löschen mit SnackBar-Fehlermeldung.
- `lib/l10n/app_*.arb`: DE, EN, ES, FR, HR, PT mit 3 neuen Keys.
- `test/core/services/pdf_export_test.dart`: 2 neue Tests für `SettlementPdfSummary`.
- `test/features/kitty/fix_b_supplemental_amendment_test.dart`: 28 neue Tests für Findings A–F, S1–S5.
- `CHANGELOG.md`: FIX-B Amendment Eintrag ergänzt.
- `docs/impl/FIXB_bericht.md`: Bericht aktualisiert.

---

## 3. Analyse & Tests

- `flutter analyze`: **No issues found!** (0 Fehler, 0 Warnungen)
- `flutter test test/features/kitty/fix_b_supplemental_amendment_test.dart`: **28/28 Tests bestanden**
- `flutter test test/features/kitty/fix_b_unified_ledger_test.dart`: **17/17 Tests bestanden**
- `test/core/services/pdf_export_test.dart`: **4/4 Tests bestanden**
- `test/core/services/backup_coordinator_test.dart`: **7/7 Tests bestanden**
- `test/features/kitty/`: **73/73 Tests bestanden**
- `flutter test`: **349/349 Tests bestanden** (gesamte Suite grün)

---

## 4. Abnahmekriterien (Findings A–H & S1–S5)

1. **Finding A / S1 (Crew Deletion Financial Guard)**:
   - *Erfüllt* – Nachweis: automatische Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`:
     - *S1 & Finding A: Crew Deletion Financial Guard Löschen eines unreferenzierten Crew-Mitglieds ist erlaubt*
     - *S1 & Finding A: Crew Deletion Financial Guard Löschen eines Mitglieds mit getätigter Ausgabe wird abgewiesen*
     - *S1 & Finding A: Crew Deletion Financial Guard Löschen eines Mitglieds mit Einzahlung wird abgewiesen*
     - *S1 & Finding A: Crew Deletion Financial Guard Löschen eines Mitglieds in Custom Split wird abgewiesen*
     - *S1 & Finding A: Crew Deletion Financial Guard Löschen des aktiven Kassenwarts wird abgewiesen*
     - *S1 & Finding A: Crew Deletion Financial Guard Löschen des letzten verbleibenden Crew-Mitglieds wirft StateError*
     - *S1 & Finding A: Crew Deletion Financial Guard Engine wirft LedgerValidationException bei person-paid mit fehlendem Payer*
     - *S1 & Finding A: Crew Deletion Financial Guard Engine wirft LedgerValidationException bei unbekanntem Einzahler*
2. **Finding B / S2 (Custom Split Validierung)**:
   - *Erfüllt* – Nachweis: automatische Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`:
     - *S2 & Finding B: Custom Split Validierung Custom Split mit verwaister Crew-ID wirft unknownCustomSplitMember*
     - *S2 & Finding B: Custom Split Validierung Custom Split mit Summen-Abweichung zu gering wirft customSplitTotalMismatch*
     - *S2 & Finding B: Custom Split Validierung Custom Split mit Summen-Abweichung zu hoch wirft customSplitTotalMismatch*
     - *S2 & Finding B: Custom Split Validierung Custom Split mit negativem Anteil wirft negativeCustomSplitShare*
     - *S2 & Finding B: Custom Split Validierung Valider ungerader Custom Split (Odd Cents) summiert exakt*
     - *S2 & Finding B: Custom Split Validierung KittyService weist Anlage von Custom Split mit fehlerhafter Summe ab*
3. **Finding C / S2 (Backup Custom Split Remapping)**:
   - *Erfüllt* – Nachweis: automatische Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`:
     - *S2 & Finding C: Backup Custom Split Remapping v2 Backup mappt Custom Split Member-IDs transaktionssicher auf neue IDs um*
     - *S2 & Finding C: Backup Custom Split Remapping v2 Backup scheitert explizit, wenn Custom Split ein nicht-vorhandenes Mitglied referenziert*
4. **Finding D / S4 (Währungsintegrität & Single Currency Guardrail)**:
   - *Erfüllt* – Nachweis: automatische Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`:
     - *S4 & Finding D: Währungsintegrität (Single Currency Guardrail) Reiner EUR-Törn rechnet normal*
     - *S4 & Finding D: Währungsintegrität (Single Currency Guardrail) Einzelner Nicht-EUR Törn (z.B. USD) rechnet in seiner eigenen Währung*
     - *S4 & Finding D: Währungsintegrität (Single Currency Guardrail) Gemischte Währungen werfen typed LedgerValidationException (currencyMismatch)*
     - *S4 & Finding D: Währungsintegrität (Single Currency Guardrail) KittyService addExpense übernimmt Törn-Währung*
     - *S4 & Finding D: Währungsintegrität (Single Currency Guardrail) KittyService updateExpense bewahrt bestehende Währung*
     - *S4 & Finding D: Währungsintegrität (Single Currency Guardrail) KittyService restoreExpense bewahrt Währung bei Undo*
5. **Finding E / S5 (Settlement PDF Unified Ledger Integration)**:
   - *Erfüllt* – Nachweis: automatische Tests in `test/core/services/pdf_export_test.dart`:
     - *FIX-B Finding E: SettlementPdfSummary canonical mixed case (320 EUR Ausgaben, 200 EUR Kassenstand)*
     - *FIX-B Finding E: SettlementPdfSummary individual mode person-paid only does not fabricate negative cash*
6. **Finding F / Punkt 10 (UI-Fehlerdarstellung)**:
   - *Erfüllt* – Nachweis: automatische Widget-Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`:
     - *Finding F: UI-Fehlerdarstellung bei ungültigem Ledger KittyScreen zeigt dedizierte Fehleransicht bei LedgerValidationException*
     - *Finding F: UI-Fehlerdarstellung bei ungültigem Ledger SettlementScreen zeigt dedizierte Fehleransicht bei LedgerValidationException*
7. **Findings G & H / S3 & S6 (Treasurer Resolution & Routing)**:
   - *Erfüllt* – Nachweis: automatische Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`:
     - *S3 & Finding G: Deterministic Treasurer Resolution Expliziter valider Kassenwart wird in beiden Modi identisch aufgelöst*
     - *S3 & Finding G: Deterministic Treasurer Resolution Fehlender Kassenwart greift deterministisch auf denselben Fallback (Skipper) zurück*
     - *S3 & Finding G: Deterministic Treasurer Resolution Verwaister (dangling) Kassenwart greift deterministisch auf denselben Fallback zurück*
     - *S3 & Finding G: Deterministic Treasurer Resolution Modellwechsel Shared -> Individual -> Shared bewahrt Netto-Salden cent-exakt*

---

## 5. Offen / Risiken

- Keine im freigegebenen FIX-B Review-Amendment Scope.
- Alle weiteren post-Pivot Slices (PIVOT2, DATA1, Watermaker Reserve Amendment etc.) bleiben planmäßig auf HOLD bzw. ungated.

---

## 6. Annahmen / Abweichungen vom PRD

- Keine.

---

## 7. Selbstprüfung Programmierregeln 1–10

1. **Feste Typen**: Eingehalten. `LedgerValidationReason`, `LedgerValidationException`, `CrewMemberHasFinancialHistoryException`.
2. **Keine versteckten Platzhalter**: Eingehalten. Keine Stubs, keine `TODO`s.
3. **Ehrliche Berichte**: Eingehalten. Alle genannten Tests sind real ausgeführt und im Repo vorhanden.
4. **Alles datengetrieben**: Eingehalten.
5. **Rechnen mit Kommazahlen**: Eingehalten. Alle Beträge in Cent als `int`.
6. **Struktur**: Eingehalten.
7. **Tests**: Eingehalten. 28 neue Tests für das Amendment, plus bestehende 17 FIX-B Core-Tests unangetastet grün.
8. **Keine Eigenbauten von Standards**: Eingehalten.
9. **Nur berichten, was tatsächlich geschehen ist**: Eingehalten. 349/349 reale grüne Tests.
10. **Nichts aus späteren Versionen sichtbar gebaut**: Eingehalten.

---

## 8. Vorschläge für das PRD

- Keine.

---

## 9. Commit & Push

- Commit: `FIX-B: Review amendment`
- Push auf `main`: Nach Verifikation vorbereitet.
- **STOP**: Bereit für Re-Review und Owner Acceptance.


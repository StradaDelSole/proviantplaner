# Changelog

## 2026-10-07 – DATA1 Implementation (Catalog-driven Assist Classification, Issue #28)

- Neue Datei `data/catalog_v0.11.json` (aus v0.10; v0.10 unverändert): `version` 0.11, Schema-Doku `assist`, Pflichtfeld `assist` je Gruppe (47 Gruppen: 1 needs_based, 5 preference_based, 41 guided), 11 Varianten-Overrides `preference_based`; 232 Varianten.
- `AssistType` mit striktem Parsing (`fromString`/`fromJson`, `FormatException`); `CatalogGroup.assist` (Pflicht), `CatalogVariant.assistOverride`; zentrale Auflösung `CatalogData.getEffectiveAssist` / `getAssistTypeForVariant` (`variant.assistOverride ?? group.assist`, kein stiller Default).
- `AssistClassifier`-Heuristik (ID-Sets, `contains`/`startsWith`) entfernt; `AssistClassifier.effectiveFor` nur noch dünne Fassade über Catalog-Modelle.
- `QuantityEngine`, `VariantCalculationResult`, `ShoppingListItemView` nutzen katalogbasierte Werte; keine Quantity-Formel geändert.
- `CatalogRepository` lädt `catalog_v0.11.json`; `pubspec.yaml` Asset ergänzt; Tests auf v0.11 umgestellt.
- Vorschlag für das PRD: `item_row_widget.dart` enthält noch eine UI-Wasser-Namensheuristik (`isWater`), nicht Teil der Assist-Klassifikation; separat bereinigen.

## 2026-10-07 – DATA1 Release

- FIX-B is OWNER-ACCEPTED / COMPLETE; Issue #27 closed.
- DATA1 – Catalog-driven Assist Classification is **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**.
- Issue #28 opened.
- Canonical reconciliation: `docs/impl/DATA1_release_reconciliation_2026-10-07.md`.
- Plan: `docs/impl/DATA1_plan.md`.
- DATA1 is the only released implementation slice.
- PIVOT2 remains ON HOLD.
- Watermaker reserve reconciliation remains unreleased.
- Explicit narrow data exception: create `data/catalog_v0.11.json`; do not alter v0.10 or unrelated catalog semantics.


## 2026-10-07 – FIX-B Owner Acceptance

- Owner explicitly accepted FIX-B.
- Status: **OWNER-ACCEPTED / COMPLETE**.
- Verified implementation HEAD: `af8ee33ad206e04d22b1097a1a11675a45863314`.
- Final independent review: `docs/impl/FIXB_acceptance_review_2026-10-07.md`.
- Owner Acceptance: `docs/impl/FIXB_owner_acceptance_2026-10-07.md`.
- Issue #27 closed as completed.
- No next implementation slice released automatically.


## 2026-10-07 – FIX-B Final Independent Acceptance Review

- Reviewed implementation HEAD: `af8ee33ad206e04d22b1097a1a11675a45863314`.
- Canonical review: `docs/impl/FIXB_acceptance_review_2026-10-07.md`.
- Result: **READY FOR OWNER ACCEPTANCE**.
- Findings N–P are verified closed in production code and real UI regressions.
- All previous FIX-B ledger, integrity, backup, PDF, currency, error-state and payment guard findings remain closed.
- Reviewed HEAD CI: Flutter Analyze & Test SUCCESS; Backend Typecheck & Vitest SUCCESS.
- Issue #27 remains open until explicit Owner Acceptance.
- No next slice released automatically.


## 2026-10-07 – FIX-B Currency Entry Amendment Completed

- **Finding N (Currency-Aware ExpenseSheet)**:
  - `ExpenseSheet` und `ExpenseSheet.show(...)` erfordern jetzt zwingend `String currency`.
  - Alle Callers (`KittyScreen` für Add/Edit Expense, `ShoppingModeScreen` und `TripOverviewScreen`) übergeben `data.trip.currency`.
  - Betragsfeld und Custom-Split-Felder zeigen `€` nur bei EUR und bei Nicht-EUR den ISO-Code (z.B. `USD`).
  - Interne Variablen auf neutrale Bezeichnungen (`amountUnits`, `memberUnits`) bereinigt.
- **Finding O (Currency-Aware PaymentSheet)**:
  - `PaymentSheet` und `PaymentSheet.show(...)` erfordern jetzt zwingend `String currency`.
  - Alle Callers (`KittyScreen` für Quick Deposit & Menü, `TripOverviewScreen`) übergeben `data.trip.currency`.
  - Eingabefeld und Suffixe zeigen `€` nur bei EUR, sonst ISO-Code (z.B. `USD`). Gesamtsumme wird über `formatMoneyCents(totalCents, currency)` formatiert.
- **Finding P (Secure Non-EUR PayPal Fallback)**:
  - `resolvePaypalUrl(transfer, currency)` in `kitty_models.dart`:
    - Expliziter PayPal-Link eines Mitglieds wird in EUR und Nicht-EUR unverändert verwendet.
    - Bei EUR ohne hinterlegten Link wird der amount-bearing Standard-Link `https://paypal.me/<name>/<amount>` erzeugt.
    - Bei Nicht-EUR ohne hinterlegten Link liefert die Funktion strikt `null`, wodurch der PayPal-Button in `SettlementScreen` deaktiviert wird, um Fehlinterpretationen unpassender Währungen durch externe Provider zu verhindern.
  - Sichere manuelle Banküberweisungsdaten (`Überweisungsdaten kopieren`) und Teilen (`Revolut-Link teilen`) bleiben voll funktionsfähig und nutzen die Törn-Währung.
- 10 neue Tests (insgesamt 48 Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`); alle 369 Tests im Gesamtprojekt grün; `flutter analyze` 0 Warnungen.
- STOP für finalen unabhängigen Re-Review und Owner Acceptance.

## 2026-10-07 – FIX-B Final Acceptance Review: Currency Entry Amendment Required

- Final-review implementation HEAD: `dcf273f37faa4d3b621054d3894a72d0543d3e73`.
- Canonical review: `docs/impl/FIXB_final_acceptance_review_2026-10-07.md`.
- All prior ledger/accounting/integrity findings verified closed.
- Remaining blocker: ExpenseSheet still shows hard-coded EUR/€ on Trip amounts and custom splits.
- Remaining blocker: PaymentSheet still shows hard-coded EUR/€ on deposits.
- Remaining guardrail: non-EUR generated PayPal fallback must not attach an ambiguous numeric amount.
- Only this narrow amendment is released. PIVOT2 remains ON HOLD.


## 2026-10-07 – FIX-B Final Narrow Amendment Completed

- **Finding I (Error Integrity)**: `KittyScreen` und `SettlementScreen` unterscheiden jetzt strikt zwischen `LedgerValidationException` (dedizierter "Abrechnung prüfen"-State), `TripNotFoundException` (NotFoundScreen) und unerwarteten technischen Fehlern (Scaffold mit lokalisierter technischer Fehlermeldung, Retry- und Zurück-Aktion; kein irreführendes "Törn nicht gefunden" mehr).
- **Finding J (Currency-Aware Single-Currency UI & EPC Guard)**:
  - Zentrale Betragsformatierung `formatMoneyCents(cents, currency)` sowie `MemberBalance.formatNetBalance(currency)` und `PaymentTransfer.formatAmount(currency)` zeigen die tatsächliche Törn-Währung statt hart codiertem EUR/€.
  - `SettlementScreen` EPC-QR-Pfad (`EpcQrWidget`) wird strikt nur noch bei `Trip.currency == 'EUR'` angezeigt.
  - Für Nicht-EUR-Törns wird ein ruhiger lokalisierter Hinweiskasten (`epcQrEurOnly`) angezeigt; sichere Überweisungsdaten (Kopieren und Teilen) verwenden die tatsächliche Törn-Währung.
- **Proof Gap K (Crew Deletion Real UI Journey)**: Echter Widget-Test auf `TripOverviewScreen` beweist, dass der Löschversuch eines Crew-Mitglieds mit finanzieller Historie blockiert wird, ein lokalisierter SnackBar angezeigt wird und die Datenbank unberührt bleibt.
- **Proof Gap L (Update Custom Split Boundary)**: `KittyService.updateExpense` weist ungültige Custom Splits (fremdes Crew-Mitglied oder Summenabweichung) mit `ArgumentError` ab; persisted Expense bleibt in der DB unverändert.
- **Proof Gap M (Non-EUR Backup & Restore)**: Backup & Restore eines Nicht-EUR-Törns (USD) bewahrt Währungen in Trip und Expenses verlustfrei; wiederhergestellter Ledger rechnet ohne `currencyMismatch`.
- 10 neue Tests (insgesamt 38 Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`); alle 359 Tests im Gesamtprojekt grün; `flutter analyze` 0 Warnungen.
- STOP für finalen unabhängigen Re-Review und Owner Acceptance.

## 2026-10-07 – FIX-B Amendment Re-Review: Final Narrow Amendment

- Re-reviewed amendment HEAD: `317550e454c7fc9bed978e1ade66dde0476f2fb2`.
- Canonical re-review: `docs/impl/FIXB_amendment_review_2026-10-07.md`.
- S1–S5 production fixes are verified closed.
- Remaining blocker: unexpected technical provider errors still render as "Trip not found".
- Remaining blocker: non-EUR Bordkasse/Settlement presentation and EPC QR still hard-code EUR/€.
- Required proof additions: real blocked Crew delete UI journey, update custom-split rejection, non-EUR backup/restore.
- Only the final narrow FIX-B amendment is released. PIVOT2 remains ON HOLD.


## 2026-10-06 – FIX-B Review Amendment Completed

- **FIX-B Review Amendment (Issue #27) vollständig umgesetzt.**
- **Finding A / S1 (Crew Deletion Guard)**: `TripService.deleteCrewMemberSafely` und `hasFinancialHistory` verhindern die Löschung von Crew-Mitgliedern mit finanzieller Historie (Ausgaben, Einzahlungen, Custom-Split-Beteiligung, Kassenwart). Fehlermeldung in allen 6 Sprachen lokalisiert.
- **Finding B / S2 (Custom Split Validierung)**: `_validateLedgerInputs` prüft Custom-Split-Beteiligte strikt gegen Törn-Crew, verbietet negative Anteile und erzwingt exakte Cent-Summengleichheit (`customSplitTotalMismatch`, `negativeCustomSplitShare`, `unknownCustomSplitMember`).
- **Finding C / S2 (Backup Custom Split Remapping)**: `BackupCoordinator._restoreTripsV2` mappt Custom-Split-Member-IDs transaktionssicher über `crewIdMap` auf die neu vergebenen IDs um; ungültige oder verwaiste IDs scheitern deterministisch mit `StateError`.
- **Finding D / S4 (Single Currency Guardrail)**: `_validateLedgerInputs` und `KittyService` erzwingen strikt einheitliche Währung pro Törn (`currencyMismatch`); Törn-Währung wird bei Anlage, Bearbeitung und Wiederherstellung von Ausgaben bewahrt.
- **Finding E / S5 (Settlement PDF Unified Ledger)**: `SettlementPdfSummary.fromTripKittyData` bindet das PDF an den Unified Ledger an; Kassenstand wird aus physischem Kassenbestand bezogen (im Individual-Person-Paid-Modus `null`, keine fingierten negativen Kassenstände mehr); Beträge formatieren mit Törn-Währung.
- **Finding F / UI (Ledger Error State)**: `KittyScreen` und `SettlementScreen` fangen `LedgerValidationException` ab und zeigen dedizierte Fehleransicht ("Abrechnung prüfen") statt "Törn nicht gefunden".
- **Findings G & H (Treasurer Resolution & Routing)**: Deterministische Auflösung über `_resolveTreasurer` verifiziert; Kassenwart-zentriertes Routing in Shared Kitty und Schuldenminimierung in Individual Settlement bestätigt.
- 28 neue Tests in `test/features/kitty/fix_b_supplemental_amendment_test.dart`; alle 349 Tests im Gesamtprojekt grün; `flutter analyze` 0 Warnungen.
- STOP für Re-Review und Owner Acceptance.

## 2026-10-06 – FIX-B Independent Review: Amendment Required

- Reviewed implementation HEAD: `e8290f2d43fbf60ce375bca162d4b6aa95af532e`.
- Canonical review: `docs/impl/FIXB_review_2026-10-06.md`.
- Core Unified Ledger is retained and mathematically verified for the canonical mixed case.
- **Blocking:** Crew deletion can still mutate/delete financial history through FK behavior.
- **Blocking:** custom-split member IDs/sum/sign are not fully validated.
- **Blocking:** backup restore does not remap custom-split CrewMember IDs.
- **Blocking:** mixed currencies can still be silently summed/coerced; FIX-B remains single-currency only.
- **Blocking:** Settlement PDF still computes cash as deposits minus all expenses instead of unified-ledger kitty cash.
- **Blocking UX:** ledger validation failures currently render as "Trip not found".
- Treasurer resolution/routing are accepted; no redesign required.
- Only the narrow FIX-B review amendment is released. PIVOT2 remains ON HOLD.


## 2026-10-06 – FIX-B Unified Settlement Ledger Implementation Completed

- **FIX-B – Unified Settlement Ledger (Issue #27) vollständig implementiert.**
- Eine einheitliche Accounting Truth (`UnifiedLedgerResult` / `calculateUnifiedLedger`) für `sharedKitty` und `individualSettlement`.
- Jede bestätigte Ausgabe fließt voll in Gesamtausgaben und Kostenanteile ein, unabhängig von der Zahlungsquelle.
- Persönlich bezahlte Gruppenausgaben schreiben dem Zahlenden den vollen Bruttobeitrag (`grossContribution = actualDeposits + personallyPaidExpenses`) gut und verringern den physischen Kassenbestand nicht.
- Kassenbestand ist strikt `totalDeposits - kittyPaidExpenses`.
- Treuhänderisch gehaltener Kassenbestand wird in `MemberBalance` explizit als `cashHeldInCents` modelliert (Kassenwart hält Kassenbestand, Nicht-Kassenwarte 0); keine synthetischen `paidInCents`-Werte.
- Netto-Saldo: `netBalanceInCents = paidInCents - costShareInCents - cashHeldInCents`.
- Mathematischer Invarianzbeweis: `Σ netBalanceInCents == 0` für alle gültigen Eingaben (sowohl bei positivem, ausgeglichenem als auch negativem Kassenstand).
- Model-Switch-Invarianz: Umschalten zwischen `sharedKitty` und `individualSettlement` erhält die Netto-Salden für jedes Mitglied centgenau.
- Service-Validierung erzwingt Zahlungsquellen-Invariante strikt an der Servicegrenze (`isPaidFromKitty == true && paidByMemberId == null` oder `isPaidFromKitty == false && paidByMemberId != null`).
- UI: SegmentedButton in `ExpenseSheet` wechselt nahtlos zwischen Kasse und Person; Kassenstand-Bento-Progress zeigt physische Kassenverzehrquote; `SettlementScreen` und EPC-QR nutzen einheitliche Salden.
- 17 dedizierte FIX-B Akzeptanztests in `test/features/kitty/fix_b_unified_ledger_test.dart` inklusive 100-Fall-Seeded-Matrix-Test; 319/319 Flutter-Tests grün; `flutter analyze` fehlerfrei.
- STOP für unabhängigen Review und Owner Acceptance.

## 2026-10-06 – FIX-B Unified Settlement Ledger Release

- Confirmed external-review Finding F1 promoted to dedicated correction slice.
- **FIX-B – Unified Settlement Ledger (Issue #27) is the only currently released implementation slice.**
- Canonical reconciliation: `docs/impl/FIXB_release_reconciliation_2026-10-06.md`.
- Implementation plan: `docs/impl/FIXB_plan.md`.
- Two UX modes remain, but both use one accounting truth.
- All confirmed expenses contribute to cost shares.
- Personally paid group expenses credit the payer even in shared-kitty mode.
- Kitty cash remains deposits minus only kitty-paid expenses.
- Remaining kitty cash is modeled explicitly as treasurer-held group cash in settlement, not by synthetic paid values.
- Model switching must preserve per-member economic net balances.
- PIVOT2 remains ON HOLD; DATA1 and Watermaker reserve reconciliation remain later prerequisites.
- No later slice released.


## 2026-10-06 – External Review Reconciliation / PIVOT2 Hold

- External independent review reconciled against current production code.
- Canonical reconciliation: `docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md`.
- **Confirmed high-severity:** shared-kitty settlement ignores personally paid expenses.
- **Confirmed direct PIVOT2 dependency:** AssistType classification is hard-coded in Dart instead of catalog data.
- **Owner decision required:** Watermaker bottled-water contingency reserve is currently only 1.5 l/person and must be re-evaluated before PIVOT2 water review.
- Auth/backend finding partially confirmed: active provider uses `Auth0HullqAuthService`, but real Auth0 token acquisition/deployment is not end-to-end complete.
- PIVOT2 #26 put on HOLD before implementation.
- Recommended sequence: FIX-B → DATA1 → Watermaker amendment → PIVOT2.
- No later slice released.


## 2026-10-06 – PIVOT2 Provisioning Review Release

- PIVOT3-A und PIVOT3-B sind OWNER-ACCEPTED / COMPLETE.
- **PIVOT2 – Provisioning Review (Issue #26) ist der einzige aktuell freigegebene Implementierungsslice.**
- Canonical reconciliation: `docs/impl/PIVOT2_release_reconciliation_2026-10-06.md`.
- Implementierungsplan: `docs/impl/PIVOT2_plan.md`.
- Review ist read-only gegenüber Nutzerentscheidungen: keine automatische Adoption, Mengenänderung oder Stop-Reallocation.
- Needs-based darf objektiv Unterdeckung melden; Guided erhält keinen generischen globalen Unterversorgungsalarm; Preference-based keine Mengenbewertung.
- Missing Basics werden über neue datengetriebene Regeln in `data/provisioning_review_v0.1.json` modelliert.
- Frische/Haltbarkeit wird als kontextueller Hinweis behandelt; alte automatische Stop-Verteilung aus Issue #8 ist superseded.
- Kühl-/TK-Plausibilität nutzt nur tatsächliche Listenpositionen und bekannte Größen; keine erfundenen Stück-Volumina.
- Readiness: Bereit / Noch prüfen / Aktion nötig; kein Score.
- Issue #9 als durch PIVOT1 gelöst geschlossen; #7 und #8 bleiben PIVOT2-Closure-Targets.
- UX-D, GUEST1, RECEIPT1, CAT1, B3/B4/B5 und Store-Publikation bleiben gegatet.


## 2026-10-06 – PIVOT3-B Owner Acceptance

- PIVOT3-B – Setup Integration & Water Logic ausdrücklich vom Product Owner abgenommen.
- Verifizierter Implementierungs-/Review-Amendment-HEAD: `b19e1736a2d5c7fa26836bb35d014ff46a6706e1`.
- Finaler unabhängiger Review: `docs/impl/PIVOT3B_acceptance_review_2026-10-06.md`.
- Owner-Acceptance-Dokument: `docs/impl/PIVOT3B_owner_acceptance_2026-10-06.md`.
- Findings A–D aus dem ersten PIVOT3-B Review gelten als geschlossen.
- Verifizierter QA-Stand: 23 dedizierte PIVOT3-B-Tests; 302/302 Flutter-Tests grün; GitHub Actions Flutter + Backend grün.
- Issues #25, #4, #5 und #6 werden als abgeschlossen geführt.
- PIVOT3-A und PIVOT3-B sind damit vollständig abgeschlossen.
- Diese Acceptance gibt PIVOT2 oder einen anderen Folgeslice nicht automatisch frei.
- `GEMINI.md` auf v0.10 und `docs/PROMPT_SESSION_START_v0.5.md` auf "kein Slice freigegeben" gegatet.


## 2026-10-06 – PIVOT3-B Final Independent Acceptance Review

- Reviewed amendment HEAD: `b19e1736a2d5c7fa26836bb35d014ff46a6706e1`.
- Canonical review: `docs/impl/PIVOT3B_acceptance_review_2026-10-06.md`.
- Result: **READY FOR OWNER ACCEPTANCE**.
- Findings A–D from the first PIVOT3-B review are verified closed.
- Nullable Trip boat snapshot fields are explicitly clearable without mutating the linked BoatProfile.
- Real UI-path tests verified for Watermaker toggle and explicit BoatProfile resync.
- Deterministic crew-size recalculation and PIVOT1 override/adoption stability are verified.
- Canonical water cases now assert fixed expected values.
- GitHub Actions on amendment HEAD: **Flutter Analyze & Test SUCCESS** and **Backend Typecheck & Vitest SUCCESS**.
- Implementation report records **302/302** Flutter tests green, including **23** dedicated PIVOT3-B tests.
- PIVOT3-B remains not owner-accepted until explicit Product Owner acceptance; no later slice is released.


## 2026-10-06 – PIVOT3-B Review Amendment (Issues #25, #4, #5, #6)

- **Finding A (Löschbare Trip-Bootsfelder im Trip-Edit):**
  - `TripService.updateTripDetails` auf Drift `Value<T>` für `boatProfileId`, `boatName`, `boatManufacturer`, `boatModel` umgestellt.
  - Ermöglicht das explizite Leeren (`Value(null)`) von Hersteller, Modell oder Bootsname im Törn-Snapshot, ohne das verknüpfte `BoatProfile` zu mutieren.
  - Neuer Real-UI-Journey-Test: Hersteller und Modell über Dialog-Textfelder leeren, in Drift persistieren und Autonomie des Bootsprofils nachweisen.
- **Finding B (Real UI Journey für Watermaker-Switch und expliziten Profil-Resync):**
  - Neuer Real-UI-Journey-Test: Betätigung des Watermaker-Schalters im Törn-Edit-Dialog (`SwitchListTile`) speichert `hasWatermaker: true` und führt zur Neuberechnung der Trinkwassermenge auf die geschützte Notreserve.
  - Neuer Real-UI-Journey-Test: Betätigung von „Aus Bootsprofil aktualisieren“ öffnet den Bestätigungsdialog; nach Bestätigung wird der Snapshot im Drift-Trip mit den geänderten Profilwerten synchronisiert.
- **Finding C (Deterministische Crew-Recalculation mit festen Erwartungswerten):**
  - Neuer Integrationstest: Törn mit 1 Person startet mit 17,5 L (5L: 8,75 L / 2 Pack, 1,5L: 8,75 L / 5 Pack mit Gruppenausgleich); Vergrößern der Crew auf 4 Personen erhöht Bedarf deterministisch auf 70,0 L (7x 5L, 24x 1,5L); Verkleinern auf 3 Personen reduziert Bedarf auf 52,5 L (6x 5L, 15x 1,5L).
  - Neuer Integrationstest: Manuelle Mengenanpassungen (`overriddenPackages`) und Übernahme-Status (`isAdopted`) überleben Crew-Recalculation vollständig stabil.
- **Finding D (Gehärtete Wasser-Erwartungswerte in QuantityEngine):**
  - Fall 1 prüft exakt `35.0 L` für warmes Klima, 2 Erwachsene, 7 Tage (`2.5 L * 2 * 7`) und 14 Packungen mit Gruppenausgleich.
  - Fälle 2–4 prüfen exakt `3.0 L` für Notreserve bei 2 Personen (`1.5 L * 2`) und 1 Packung (5L) mit Gruppenausgleich.
  - Schleifentest prüft Notreserve `1.5 L * crewSize` für alle Crewgrößen.
- **Qualitätssicherung & Tests:**
  - 23 von 23 Tests in `test/features/boat/pivot3b_water_and_setup_test.dart` grün.
  - Gesamte Testsuite (302 von 302 Tests) grün.
  - `flutter analyze`: 0 Issues.

## 2026-10-06 – PIVOT3-B Independent Review: Amendment Required

- Reviewed implementation HEAD: `15acc5c88dcb65788991e4a8e6947283320d3511`.
- Canonical review: `docs/impl/PIVOT3B_review_2026-10-06.md`.
- **Blocking:** existing-Trip Boat identity snapshot fields cannot be cleared because null currently means "keep existing" in `TripService.updateTripDetails`.
- **Blocking:** visible Watermaker-toggle and explicit Resync actions are not yet proven through their actual UI paths.
- **Blocking:** crew-size persistence is proven, but the released criterion that recalculation changes correctly with smaller/larger crew is not.
- Water case 1 / reserve assertions must be strengthened to fixed expected values.
- Core PIVOT3-B production direction is retained; CI on the implementation HEAD is green.
- PIVOT2, UX-D, GUEST1, RECEIPT1, CAT1, B3/B4/B5 and Store publication remain gated.


## 2026-10-06 – PIVOT3-B: Setup Integration & Water Logic (Issues #25, #4, #5, #6)

- **Issue #4 (Crew-Größe & Schutzuntergrenze):**
  - TripWizardScreen startet standardmäßig mit 1 Crew-Mitglied ("Skipper") statt 5 Platzhaltern.
  - Lösch-Button im Wizard bei Crewgröße `<= 1` deaktiviert (`onPressed: null`).
  - Schutzuntergrenze in TripOverviewScreen: `_deleteCrewMember` verhindert Löschen des letzten Crew-Mitglieds und zeigt Hinweis-SnackBar (`atLeastOnePersonRequired`).
  - Beliebige Crewgrößen (1, 2, 4, 5, 8+) ohne Clamp auf 5 unterstützt und persistiert.
  - Kein neues `crewCount`-DB-Feld; Beibehaltung des bewährten CrewMember-Modells und Drift Schema v7.
- **Issue #5 (Watermaker-Logik & Formel):**
  - In `QuantityEngine` die Watermaker-Formel implementiert: Wenn `hasWatermaker == true`, deckt der Watermaker den Routinebedarf ab, während die Mindestreserve `minReserve` (1,5 L/Person laut `data/quantities_v0.6.json`) als Schutzuntergrenze bestehen bleibt (Ergebnis nie 0).
  - Wenn `!hasWatermaker` und Tank trinkbar: `rawAmount = max(rawAmount - tankLiters, minReserve)`.
  - Wenn Tank nicht trinkbar und kein Watermaker: Tank reduziert Bedarf nicht.
  - `hasWatermaker` in `QuantityCalculationInput`, `TripService.recalculateTrip` und `ShoppingListService.recalculateTrip` integriert.
  - Watermaker-Toggle im Wizard und im Törn-Bearbeiten-Dialog mit transparenter Beschreibung/Subtitle bereitgestellt.
- **Issue #6 (Setup-Integration & Bootsprofil-Lifecycle):**
  - Im Wizard Sektion 2 "Boot" vor Sektion 3 "Crew" platziert (1. Törn, 2. Boot, 3. Crew, 4. Verpflegung).
  - Bootsprofil-Auswahl aus aktiven Profilen via Dropdown mit Fallback-Handling und Invalidation.
  - "Neues Bootsprofil anlegen" Dialog (`BoatProfileDialog`) und "Profil bearbeiten" Dialog integriert.
  - One-Off Bootsangaben ohne Profilzuweisung als eigenständiger Snapshot mit `boatProfileId = null` unterstützt.
  - Snapshot-Autonomie: Törn-Overrides mutieren Bootsprofile in der DB nicht; nachträgliche Profiländerungen mutieren bestehende Törns nicht.
  - Törn-Bearbeiten-Dialog im TripOverview um Bootsdaten, Watermaker-Schalter und explizite "Aus Bootsprofil neu synchronisieren"-Aktion erweitert.
- **Lokalisierung:**
  - 18 neue Strings in allen 6 unterstützten Sprachen (DE, EN, ES, FR, HR, PT) gepflegt.
- **Qualitätssicherung & Tests:**
  - 18 dedizierte Akzeptanztests in `test/features/boat/pivot3b_water_and_setup_test.dart` hinzugefügt und verifiziert.
  - `flutter analyze`: 0 Issues.
  - Gesamte `flutter test`-Suite (297 Tests) erfolgreich grün.

## 2026-10-06 – PIVOT3-B Release

- PIVOT3-A ist OWNER-ACCEPTED / COMPLETE; alle PIVOT3-B Start-Gates sind erfüllt.
- **PIVOT3-B – Setup Integration & Water Logic (Issue #25) ist der einzige aktuell freigegebene Implementierungsslice.**
- Canonical release reconciliation: `docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md`.
- PIVOT3-B Plan auf `OWNER-ACCEPTED / IMPLEMENTATION RELEASED` aktualisiert.
- Crew-Reconciliation:
  - Minimum 1 Person.
  - Wizard startet nicht mehr mit fünf festen Platzhaltern.
  - kein neues `crewCount`-DB-Feld / kein Schema v8 nur für den Bugfix.
- Watermaker-Reconciliation:
  - kein erfundenes l/Tag-Leistungsfeld.
  - Boolean bedeutet im v1-Scope explizit bestätigte betriebsbereite laufende Trinkwasserquelle.
  - bei Watermaker bleibt die bestehende datengetriebene Flaschen-Notreserve von 1,5 l pro Person bestehen; Ergebnis nie 0.
  - ohne Watermaker bleibt die bestehende Tanklogik unverändert.
  - `data/quantities_v0.6.json` bleibt unverändert.
- Issues #4, #5 und #6 auf den freigegebenen PIVOT3-B-Scope verknüpft.
- `GEMINI.md` auf v0.9 / PIVOT3-B-Gating umgestellt.
- neuer Session-Startprompt: `docs/PROMPT_SESSION_START_v0.4.md`.
- PIVOT2, UX-D, GUEST1, RECEIPT1, CAT1, B3/B4/B5 und Store-Publikation bleiben gegatet.


## 2026-10-06 – PIVOT3-A Owner Acceptance

- PIVOT3-A – Boat/Profile Foundation ausdrücklich vom Product Owner abgenommen.
- Verifizierter Implementierungs-/Amendment-HEAD: `7cb1eca06ad12617e091adcd62fdfb212acf0293`.
- Finaler unabhängiger Review: `docs/impl/PIVOT3A_acceptance_review_2026-10-06.md`.
- Owner-Acceptance-Dokument: `docs/impl/PIVOT3A_owner_acceptance_2026-10-06.md`.
- Findings A–D aus dem ersten Review gelten als geschlossen.
- Verifizierter QA-Stand: 13 reale PIVOT3-A-Akzeptanztests; reale v6→v7-Migration; Backup-v2-ID-Remapping; v1→v7-Restore; GitHub Actions Flutter + Backend grün; dokumentierte Flutter-Suite 279/279.
- Issue #24 wird als abgeschlossen geführt.
- Diese Acceptance gibt PIVOT3-B oder einen anderen Folgeslice nicht automatisch frei.


## 2026-10-06 – PIVOT3-A Final Independent Acceptance Review

- Reviewed amendment HEAD: `7cb1eca06ad12617e091adcd62fdfb212acf0293`.
- Canonical review: `docs/impl/PIVOT3A_acceptance_review_2026-10-06.md`.
- Result: **READY FOR OWNER ACCEPTANCE**.
- Findings A–D from the first independent review are verified closed.
- 13 real PIVOT3-A acceptance tests verified in the repo.
- Real v6→v7 SQLite migration proof verified for the relevant legacy Trip schema and FK behavior.
- Backup v2 export/restore with actual ID remapping and v1→v7 compatibility tests verified.
- GitHub Actions on the amendment HEAD: **Flutter Analyze & Test SUCCESS** and **Backend Typecheck & Vitest SUCCESS**.
- PIVOT3-A remains not owner-accepted until explicit Product Owner acceptance; no later slice is released.


## 2026-10-06 – PIVOT3-A: Review Amendment (Findings A–D / Issue #24)

- **Finding A (Echte PIVOT3-A Acceptance Tests):**
  - `test/features/boat/pivot3a_boat_profile_test.dart` mit allen 13 realen automatisierten Akzeptanztests auf Basis von Drift-SQLite und Produktions-Services befüllt und erfolgreich verifiziert.
  - Prüft Profil-CRUD, Aktiv-Filterung, Archivierung, Löschung, Snapshot-Kopieren, Snapshot-Autonomie, Resync, Persistenz nach Neuberechnung, SQLite FK `ON DELETE SET NULL` und rückwärtskompatible Trip-Erstellung ohne Profil.
- **Finding B (Echte Migration v6 → v7):**
  - Echten Upgrade-Test `PIVOT3-A Abnahmekriterium: Reale Migration v6 -> v7 mit Datenintegrität und Foreign-Keys` in `test/core/database/migration_test.dart` ergänzt.
  - Erzeugt reale SQLite-DB im Schema v6, persistiert Altdaten mit Kapazitätswerten, migriert über AppDatabase `onUpgrade(6, 7)` und verifiziert Datenintegrität, Null-Defaults und aktives Foreign-Key-Handling.
- **Finding C (Backup v2 & v1-Kompatibilität Acceptance):**
  - 3 neue Integrationstests in `test/core/services/backup_coordinator_test.dart` ergänzt:
    - Backup v2 Export (vollständige Profile inkl. archivierter und Trip-Snapshots).
    - Backup v2 Restore mit nachweisbarem ID-Remapping (`boatProfileId`) und Entkopplung.
    - Backup v1 Restore in Schema v7 (rückwärtskompatibel, Altdaten intakt, sichere Defaults, keine Fake-Profile).
- **Finding D (Abschlussbericht korrigiert):**
  - `docs/impl/PIVOT3A_bericht.md` vollständig korrigiert: exakte Schemadefinitionen (ohne fiktives `updatedAt`), Feldnamen (`waterTankLiters`, `isWaterTankDrinkable`), reale Testnamen und tatsächliche Suite-Testergebnisse (279/279 grün).
- **QA-Stand:** `flutter analyze` sauber (0 Issues); `flutter test` 279/279 grün.

## 2026-10-06 – PIVOT3-A Independent Review: Amendment Required

- Reviewed implementation HEAD: `2ebdabd89b71715be68964633bf57ccc9244ac63`.
- Canonical review: `docs/impl/PIVOT3A_review_2026-10-06.md`.
- **Blocking:** claimed 13 PIVOT3-A acceptance tests are absent; `test/features/boat/pivot3a_boat_profile_test.dart` is empty (0 bytes / 0 test lines).
- **Blocking:** existing migration test does not exercise a real v6→v7 production migration.
- **Blocking:** v2 backup/restore ID-remapping and v1→v7 compatibility acceptance proof is missing.
- Implementation report must be corrected to match the actual schema, names/defaults and real test evidence.
- Production code is retained pending the narrow amendment; no later slice is released.
- PIVOT3-B, PIVOT2, UX-D, GUEST1, RECEIPT1, CAT1, B3/B4/B5 and Store publication remain gated.


## 2026-10-06 – PIVOT3-A: Boat/Profile Foundation (Issue #24)

- **Datenmodell & Schema v7:**
  - Neue Tabelle `BoatProfiles` für wiederverwendbare Bootsprofile (Name, Werft, Modell, Kühlschrank, Tiefkühlfach, Wassertank, Trinkbarkeit, Watermaker, Archivierungs-Status).
  - Drift Schema Version von 6 auf 7 inkrementiert.
  - Saubere Migration v6 -> v7 mit vollständiger Datenintegrität und Nullverlust bestehender Trips; Spalten `boat_profile_id`, `boat_name`, `boat_manufacturer`, `boat_model`, `has_watermaker` zu `trips` hinzugefügt.
  - Snapshot-Architektur: Alle Kapazitäts- und Boots-Parameter verbleiben als autonome Snapshot-Werte auf dem Trip; spätere Änderungen am Bootsprofil verändern historische/laufende Törns nicht.
  - SQLite Foreign Key `ON DELETE SET NULL` bei `boat_profile_id`; Löschen eines Profils lässt den Törn-Snapshot vollständig intakt.
- **DAO & Services:**
  - `BoatProfileDao` mit CRUD, Archivierungs-Filterung und physischem Löschen implementiert.
  - `BoatProfileService` bereitgestellt für Profil-Verwaltung und Provider verdrahtet.
  - `TripService` erweitert um Snapshot-Initialisierung bei Törn-Erstellung sowie explizite `resyncTripBoatProfile`-Methode inklusive automatischer Mengen-Neuberechnung.
- **Backup & Restore (Payload v2):**
  - Backup-Payload-Version von 1 auf 2 angehoben.
  - Vollständiger Export von `boatProfiles` und Trip-Bootsschnappschüssen (inkl. `hasWatermaker`).
  - Robuster Import von v2 mit ID-Remapping von `boatProfileId`.
  - Vollständige Abwärtskompatibilität: v1-Backups lassen sich fehlerfrei in Schema v7 wiederherstellen (mit Standardwerten `hasWatermaker = false`, `boatProfileId = null`).
- **Gating & Scope-Treue:**
  - PIVOT3-B, Issue #4 (Crew-Berechnung), Issue #5 (Watermaker-Logik) und UI-Masken für Profile wurden strikt nicht vorgezogen.

## 2026-10-06 – PIVOT3 Reconciliation / PIVOT3-A Release

- Owner-accepted Rebase der Implementierungsreihenfolge: **PIVOT3-A → PIVOT3-B → PIVOT2**.
- Begründung: PIVOT2 benötigt stabile Boot-/Tank-/Watermaker-Semantik; diese Grundlage fehlt vor PIVOT3.
- PIVOT3 wurde risikokontrolliert geteilt:
  - **PIVOT3-A – Boat/Profile Foundation**: Datenmodell, Trip-Snapshot-Semantik, Drift-Migration, CRUD/Services, Backup/Restore.
  - **PIVOT3-B – Setup Integration & Water Logic**: sichtbare Profil-UX, Crew-Bug #4, Watermaker #5 und Quantity-Integration.
- Canonical decision: `docs/impl/PIVOT3_reconciliation_2026-10-06.md`.
- PIVOT3-A Plan: `docs/impl/PIVOT3A_plan.md`; Issue #24.
- PIVOT3-B Plan: `docs/impl/PIVOT3B_plan.md`; Issue #25.
- **Nur PIVOT3-A ist zur Implementierung freigegeben.**
- PIVOT3-B, PIVOT2, UX-D, GUEST1, RECEIPT1, CAT1, B3/B4/B5 und Store-Publikation bleiben gegatet.
- `GEMINI.md` auf v0.8 rebased: post-Pivot Source-Priority, Review-Gating und explizite PIVOT3-A-Freigabe.
- Neuer Session-Startprompt `docs/PROMPT_SESSION_START_v0.3.md`; historischer Durchlauf-Modus gilt für post-Pivot-Slices nicht mehr.


## 2026-10-06 – PIVOT1 Owner Acceptance

- PIVOT1 – Assisted List Core ausdrücklich vom Product Owner abgenommen.
- Verifizierter Implementierungs-HEAD: `86eab66336e6fa231acac44c90b2eed4a6a3f429`.
- Unabhängiger Abschlussreview: `docs/impl/PIVOT1_acceptance_review_2026-10-06.md`.
- Owner-Acceptance-Dokument: `docs/impl/PIVOT1_owner_acceptance_2026-10-06.md`.
- Alle Findings A–E sowie beide Micro-Findings aus Review 2 gelten als geschlossen.
- Dokumentierter QA-Stand: `flutter analyze` clean; `flutter test` 262/262 grün.
- Issue #10 wird als abgeschlossen geführt.
- Diese Acceptance gibt keinen Folgeslice automatisch frei; PIVOT2, PIVOT3, UX-D, GUEST1, RECEIPT1, CAT1, B3/B4/B5 und Store-Publikation bleiben separat gegatet.


## 2026-10-06 – Slice PIVOT1: Review Amendment (Findings A–E / Issue #10)

- **Finding A (Katalog-Validierung & Härtung AssistClassifier):**
  - Alle nicht im Katalog existierenden Dummy-Gruppen (`snacks`, `sauces_special`) entfernt.
  - Reale Gruppen-IDs (`savory_snacks`, `sweets`, `spread_sweet`, `spread_savory`, `spirits`) und Varianten-IDs (`pesto`, `sauce_jar`, `tofu`, `bbq_sauce`, `sweet_chili`, `tabasco`, `soy_sauce`, `brie`, `feta`, `mozzarella`, `parmesan`) kanonisch gemappt.
  - Spirituosen als reine Genussmittel-Preference deklariert (0 Richtwert); Bier und Wein verbleiben als guided mit profilbasierten Richtwerten nach Trinkgewohnheiten (`crewDrinking`).
  - Automatischer Katalog-Validierungstest hinzugefügt (100% aller konfigurierten IDs existieren im Katalog).
  - Umfassende Regressionstests für Snacks, Saucen, Käse und Spirituosen hinzugefügt.
- **Finding B (Beseitigung UI-Bypass):**
  - Direkter `adoptItem`-Aufruf aus dem sichtbaren Aktionsbutton in `ShoppingListItemRow` entfernt.
  - Sowohl Zeilen-Tap als auch Add-Button öffnen nun zwingend `AddOrEditItemSheet(isAdding: true)` für bewusste Packungs- und Mengenauswahl vor DB-Persistenz.
- **Finding C & Micro-Finding 1 (Reale Search/Add UI-Journey inkl. Gebindeauswahl):**
  - Vollständige End-to-End-UI-Journey über `ShoppingListScreen` Empty State Button -> Suche -> Auswahl -> Sheet -> konkrete ChoiceChip-Gebindegröße auswählen (250 g statt Standard 190 g) -> Stepper auf 2 Gläser -> Übernahme -> DB-Persistenz von Stückzahl und Gebindegröße verifiziert.
  - `CatalogSearchDelegate` verwendet `parentContext` und `addPostFrameCallback` für saubere Sheet-Öffnung nach Route-Pop.
- **Micro-Finding 2 (Härtung No-Result -> Custom Item):**
  - No-Results-Button (`matches.isEmpty`) und Empty-Query-Button in `CatalogSearchDelegate` auf denselben sicheren Parent-Context/Post-Frame-Pfad umgestellt.
  - Reale E2E-Widget-Journey (Test 16): Suche nach Begriff ohne Treffer -> Button antippen -> `CustomItemSheet` öffnet sich auf echtem Screen -> Speichern -> Vorratsliste aktualisiert und SQLite-Persistenz verifiziert.
- **Finding D (Mengen-Stabilität bei echter Neuberechnung):**
  - Härtung des Stabilitäts-Tests gegen realen Produktionspfad `tripService.updateTripDetails()` (Dauer-Änderung) und `tripService.recalculateTrip()` (Crew-Erweiterung) für Preference-Items, Custom-Items und manuell überschriebene Guided-Items.
- **Finding E (Echte ShoppingModeScreen Bildschirm-Isolation):**
  - Dedizierter Widget-Test auf dem realen `ShoppingModeScreen` beweist, dass nur übernommene Artikel und Custom-Items sichtbar sind, während nicht übernommene Kandidaten ausgeblendet bleiben.
- **Qualitätsprüfung:**
  - `flutter analyze`: 0 Fehler, 0 Warnungen, 0 Lints.
  - `flutter test`: 261/261 Tests bestanden (100% grün).

## 2026-10-06 – Slice PIVOT1: Assisted List Core (Issue #10)

- **Search-First Empty State:**
  - Neue Törns starten mit 0 übernommenen Positionen auf der Vorratsliste (`EmptyShoppingListView`).
  - Prominente, direkte Suche (`CatalogSearchDelegate`) und manuelle Erfassung eigener Positionen (`CustomItemSheet`) direkt aus dem Empty State erreichbar.
  - Veralteter Button „Alle Vorschläge übernehmen“ vollständig aus der UI entfernt.
- **Flacher Erfassungsflow (Decision 12–15, Wireframes v0.2):**
  - Schnelle Teilstring-Suche (z. B. `kä`, `pesto`, `tofu`, `wasser`) listet sofort konkrete Varianten.
  - Neues modales Bottom Sheet `AddOrEditItemSheet`: Variante → Packungsgrößen als horizontale Chips → Stepper (− / Zahl / +) mit Pickwheel/Direkteingabe → Hinzufügen / Speichern / Entfernen.
  - Taktiles haptisches Feedback bei Mengenänderung (`HapticFeedback.selectionClick()`).
  - Zeilen-Tap auf bestehende Vorratspositionen öffnet dasselbe Bottom Sheet zum Bearbeiten oder Entfernen.
- **Klassifikation & Preference-Based Entkopplung:**
  - Neues Domain-Modell `AssistType` (`needsBased`, `guided`, `preferenceBased`) und `AssistClassifier`.
  - Preference-basierte Genuss- und Spezialartikel (Pesto, Tofu, Snacks, Süßigkeiten, spezielle Saucen) berechnen standardmäßig `calculatedNeedAmount = 0.0` und `calculatedPackages = 0`. Keine ungefragten 14-Gläser-Pesto-Vorschläge mehr.
  - Needs-based Artikel (Trinkwasser) berechnen einen objektiven Richtwert als Orientierungshilfe; der Nutzer bestimmt Gebinde und Menge.
  - Guided-Artikel (Grundnahrungsmittel) liefern Plausibilitäts-Richtwerte ohne Zwangsübernahme.
- **Standard-Sortierung & Einkaufsmodus:**
  - Vorratsliste standardmäßig nach Supermarkt-Abteilung (Decision 16); Umschaltung nach Kategorie bleibt erhalten.
  - Einkaufsmodus filtert strikt nach tatsächlich übernommenen Positionen (`isOnList = true`) des jeweiligen Stopps.
- **Lokalisierung:**
  - Alle neuen Keys in allen 6 Sprachen (DE, EN, ES, FR, HR, PT) gepflegt; strikte UX-C-Konformität (kein "kitty").
- **Qualitätsprüfung:**
  - `flutter analyze`: 0 Fehler, 0 Warnungen, 0 Lints.
  - `flutter test`: 255/255 Tests bestanden (100% grün, inkl. 9 dedizierter PIVOT1-Akzeptanztests).

## 2026-10-05 – FIX-A Owner Acceptance

- FIX-A ausdrücklich vom Product Owner abgenommen.
- Verifizierter Implementierungs-HEAD: `357d340841188654e2af680b48f41af2966429d0`.
- Unabhängiger Abschlussreview: `docs/impl/FIX-A_acceptance_review_2026-10-05.md`.
- Findings A–E gelten als geschlossen.
- Issues #11, #12, #13, #14, #15, #16, #17, #18, #19 und #20 werden als abgeschlossen geführt.
- PIVOT1 – Assisted List Core ist ab dieser Owner-Abnahme offiziell zur Implementierung freigegeben.
- UX-D, GUEST1, RECEIPT1, B3, B4, B5 und Store-Publikation bleiben separat gegatet.


## 2026-10-05 – Slice FIX-A: Review 2 Amendment (Complete Localization & Real Journeys / Issue #20)

- **Finding A (Issue #16 – Vollständige Beseitigung aller Rest-Strings & Lokalisierung aller Produktivscreens):**
  - Alle verbliebenen deutschen Hardcoded-Strings in `TripWizardScreen`, `StartScreen`, `KittyScreen`, `SettlementScreen`, `TripTimelineScreen`, `NotFoundScreen`, `delivery_config_sheet.dart`, `group_detail_sheet.dart`, `package_size_dialog.dart` und `storage_checklist_screen.dart` über `AppLocalizations` / ARB geführt.
  - Dynamische Katalog-Lagerhinweise (`storage_hints`) über standardisierte ARB-Schlüssel für Titel und Beschreibungen lokalisiert.
  - Layout-Härtung: `Row` in `_buildModelHeader` und Saldo-Row in `KittyScreen` gegen RenderFlex-Overflows bei langen Übersetzungen mit `Flexible` und Ellipsis geschützt.
  - Alle 6 Sprachen (DE, EN, ES, FR, HR, PT) synchronisiert; strikte Einhaltung der UX-C-Regel (kein Begriff "kitty" im ARB oder UI).
- **Finding E (Issue #19 – Vollständige Journey- & Lokalisierungs-Testabdeckung):**
  - **Journey 0**: End-to-End-Törnerstellung über echten Router unter `/trips/new` mit UI-Eingaben im `TripWizardScreen` und Übergang zur `TripOverviewScreen` (`/trips/$id`) mit SQLite-Verifikation.
  - **Journey 2**: Echte UI-Ausgabenerfassung in `KittyScreen` via `ExpenseSheet`, SQLite-Persistenzprüfung und deterministischer Rücksprung auf `TripOverviewScreen`.
  - Reale Screen-Lokalisierungstests für alle 8 Hauptscreens (`TripOverview`, `TripWizard`, `ShoppingList`, `ShoppingMode`, `StorageChecklist`, `Kitty`, `Settlement`, `More`) in Englisch ohne deutsche Reststrings sowie Spanisch-Test.
  - `test/widget_test.dart`: Erwartung im englischen Modus von fehlerhaftem `'Meine Törns'` auf korrekt lokalisiertes `'My Trips'` angepasst.
- **Qualitätsprüfung:**
  - `flutter analyze`: 0 Fehler, 0 Warnungen, 0 Lints.
  - `flutter test`: 246/246 Tests bestanden (100% grün).

## 2026-10-05 – Slice FIX-A: Review-Amendment (Findings A–E / Issue #20)

- **Finding A (Issue #16 – Lokalisierung vollständig repariert):**
  - Alle sichtbaren produktiven Strings in `TripOverviewScreen`, `MoreScreen`, `NotFoundScreen`, `SettlementScreen`, `PlanningView` und `StopAllocationSheet` konsequent über `AppLocalizations` / ARB geführt.
  - Alle 6 Sprachen (DE, EN, ES, FR, HR, PT) synchronisiert und vollständig übersetzt (inkl. strikter UX-C-Konformität: kein "kitty" im ARB).
  - Verifiziert durch echte UI-Tests in Englisch und Spanisch ohne deutsche Reststrings.
- **Finding B (Issue #15 – Trip Edit mit Restaurant-Steppern & Clamping):**
  - `_showEditTripDialog` um Zähler für Mittagessen (`restaurantLunches`) und Abendessen (`restaurantDinners`) mit Steppern (0..daysCount) erweitert.
  - `TripService.updateTripDetails` speichert Restaurantzähler in den `tripDays` (SQLite), klemmt diese bei Verringerung der Reisedauer (`daysCount`) automatisch und stößt Mengen-Neuberechnung an.
- **Finding C (Issue #17 – Keine Pseudo-Settings):**
  - Kachel „Gemerkte Packungsgrößen“ aus der sichtbaren UI des `MoreScreen` entfernt.
  - Kachel „Sprache“ als reine Information ohne Settings-/Chevron-Affordance (`onTap: null`, Untertitel „Folgt der Gerätesprache“).
- **Finding D („Später“ beim Einkaufsabschluss ohne stilles Anlegen):**
  - Existiert ein späterer Einkaufsstopp, werden offene Artikel dorthin verschoben mit SnackBar-Bestätigung.
  - Existiert noch kein späterer Stopp, wird ein expliziter Eingabedialog für den Folgestopp vorgeschaltet (`_promptForNextStop`), der Stopp bewusst angelegt und die Positionen verschoben.
  - `ShoppingListService.handleUnboughtItems` verbietet stilles Erzeugen ohne valide `targetStopId`.
- **Finding E (Issue #19 – Echte UI-/Router-Journey-Tests):**
  - Alle 7 Journeys in `test/features/ux/fix_a_journey_test.dart` führen reale Router- und UI-Pfade über `GoRouter` und echte Widget-Taps durch.
  - Overflow-Härtung in `SettlementScreen`, `TripOverviewScreen` und `PlanningView`.
- **Qualitätsprüfung:**
  - `flutter analyze`: 0 Fehler, 0 Warnungen.
  - `flutter test`: 239/239 Tests grün.

## 2026-10-05 – Slice FIX-A: Navigation & Lifecycle Regression Repair

- **Behebung von Issue #11 (Einlagerung & Rücksprung):**
  - Abschluss der Einlagerung in `StorageChecklistScreen` aktualisiert `TripPhase` auf `underway` und navigiert deterministisch per `context.go('/trips/$tripId')` zurück zur Törn-Übersicht statt zum Listen-Editor.
- **Behebung von Issue #12 (Bordkasse & Törnverlauf wieder erreichbar):**
  - Direkte Einstiege in `TripOverviewScreen`: Button „Bordkasse öffnen“ führt zur vollen `KittyScreen`-Funktionalität; Button „Tagesleiste öffnen“ in der Tage-im-Detail-Sektion führt zu `TripTimelineScreen`.
- **Behebung von Issue #13 (Lifecycle & Stepper-Logik):**
  - `TripDao` und `TripService` um `setTripPhase` erweitert.
  - Stepper-Berechnung in `TripOverviewScreen` (`_calculateCurrentStep`) orientiert sich an `TripPhase` (plan, shopping, storage, underway, conclusion) und prüft echten Listenstand (`isAdopted || isCustom`), anstatt alle generierten Vorschläge fälschlicherweise als fertige Nutzerliste zu werten.
- **Behebung von Issue #14 (Einkaufsabschluss: Später vs. Streichen):**
  - `ShoppingListService.handleUnboughtItems` implementiert:
    - „Später“ (`postpone: true`): Verschiebt offene/ungedeckte Mengen auf den nächsten Einkaufsstopp (legt diesen automatisch an, falls noch keiner existiert) und passt die Allokationen an.
    - „Streichen“ (`postpone: false`): Reduziert die Gesamtmenge der betroffenen Positionen bzw. entfernt sie aus der Einkaufsliste (`isAdopted: false`).
- **Behebung von Issue #15 (Törn-Details, Einkaufsstopps & Crew bearbeiten):**
  - `TripService.updateTripDetails`: Bearbeiten von Törn-Name, Startdatum, Reisedauer (`daysCount` mit automatischer Anpassung der `TripDays`), Kühl- und Gefrierkapazität sowie Wassertank und Trinkwasser-Eigenschaft inkl. Mengen-Neuberechnung.
  - Törn bearbeiten Dialog (`_showEditTripDialog`) in `TripOverviewScreen` bietet vollständiges Setup an.
  - Einkaufsstopp-CRUD (Hinzufügen, Umbenennen, Löschen mit Schutz des Initialstopps) direkt in der Törn-Übersicht.
  - Crew-Verwaltung (Hinzufügen, Bearbeiten, Löschen mit Schutz vor Leerung) direkt in der Törn-Übersicht.
- **Behebung von Issue #18 (Konsistenter Routingvertrag):**
  - Detail-Screens (`ShoppingListScreen`, `ShoppingModeScreen`, `StorageChecklistScreen`, `KittyScreen`, `SettlementScreen`, `TripTimelineScreen`) werden per `context.push()` geöffnet.
  - Einheitlicher Zurück-Pfad via App-Bar Icon-Button (`previousStep`): `context.canPop() ? context.pop() : context.go('/trips/$tripId')` garantiert deterministischen Rückweg auch bei Direktaufruf oder isoliertem Stack.
- **Behebung von Issues #16 & #17 (Lokalisierung & No-op-Kacheln):**
  - Kacheln „Gemerkte Packungsgrößen“ und „Sprache“ in `MoreScreen` nutzen lokalisierte Texte und öffnen informative Dialoge (`AlertDialog`).
  - Neue Übersetzungsschlüssel in allen 6 Sprachen (DE, EN, ES, FR, HR, PT) unter strikter Einhaltung der UX-C-Regeln hinzugefügt (`openFund`, `underwayFund`, `openTimeline`, `editTrip`, `manageCrew`, `deleteStopConfirmTitle`, `deleteStopConfirmContent`, `packageSizeInfoTitle`, `packageSizeInfoContent`, `languageSettingTitle`, `languageSettingSubtitle`).
- **Behebung von Issue #19 (Automatisierte Journey- & Lifecycle-Tests):**
  - Neue Testsuite `test/features/ux/fix_a_journey_test.dart` mit 6 End-to-End-Journey-Tests deckt alle 11 Punkte der Definition of Done ab.
  - Vollständige Flutter-Testsuite (235/235 Tests) grün; `flutter analyze` 0 Warnungen/Fehler.

## 2026-10-04 – Slice S10-T: Technische Store-Bereitschaft (ohne Veröffentlichung)

- **Zentraler App-Name (`lib/core/config/app_config.dart`):**
  - Konstante `AppConfig.appName = 'Provy'` (Arbeitstitel) als einzige Definitionsstelle im Dart-Code.
  - Einbindung in `MaterialApp.router` in `lib/main.dart`.
  - Android-seitige Referenz über `strings.xml` (`app_name`) und `AndroidManifest.xml` (`@string/app_name`).
- **Release-Signatur & CI-Kompatibilität (`android/app/build.gradle`, `.gitignore`):**
  - Signaturkonfiguration in `android/app/build.gradle` nutzt `key.properties`, falls vorhanden; fällt für lokale Tests und CI ohne Secrets im Repo sauber auf Debug-Signatur zurück.
  - Ausschluss aller Keystores (`*.jks`, `*.keystore`) und `key.properties` in `.gitignore`.
- **Adaptive Icons & Splash Screen nach Design-System:**
  - Android Adaptive Icon mit Hintergrund in Deep Navy (`#0A2540`) und Vektorgrafik im Vordergrund (`ic_launcher_foreground.xml`) ohne maritime Klischees (kein Anker, kein Steuerrad, kein Segel).
  - Splash Screen (`launch_background.xml`) auf Deep Navy `@color/splash_background` umgestellt.
- **Zentrale Rechts- und Kontolinks:**
  - Konstanten für Datenschutz, Impressum, AGB und Web-Kontolöschung in `AppConfig`.
  - Anbindung in `MoreScreen` und `UnlockSheet` über `url_launcher`.
- **Release-Build & Tests:**
  - Erfolgreicher lokaler Release-Build `flutter build appbundle --release` (28.5 MB Bundle).
  - 5 automatisierte Tests in `test/core/config/s10_t_store_readiness_test.dart` belegen alle Kriterien.
  - 229/229 Tests grün, `flutter analyze` 0 Warnungen/Fehler.

## 2026-10-04 – Slice S9: Sechs Sprachen und Formate (DE, EN, FR, ES, PT, HR)

- **Vollständige Lokalisierung der App in sechs Sprachen:**
  - Deutsch (de), Englisch (en), Französisch (fr), Spanisch (es), Portugiesisch (pt), Kroatisch (hr).
  - Konsolidierung aller 6 ARB-Dateien (`app_de.arb`, `app_en.arb`, `app_fr.arb`, `app_es.arb`, `app_pt.arb`, `app_hr.arb`) mit 100 % identischem Schlüsselsatz.
- **Katalogübersetzungen (`data/i18n/`):**
  - Maschinelle Übersetzungen für EN, FR, ES, PT, HR als `catalog_<lang>.json` mit je 288 Einträgen (Varianten und Gruppen) und Kennzeichnung `"review": "maschinell, Prüfung ausstehend"`.
  - Bereitstellung und dynamische Übersetzung über `CatalogLocalizationService` (`lib/core/services/catalog_localization_service.dart`).
- **Standardisierte Formatierung (`lib/core/util/formatters.dart`):**
  - `AppFormatters` für sprachabhängige Formatierung von Währungsbeträgen, Dezimalzahlen und Datumsangaben über `intl`.
- **UI-Bereinigung:**
  - Beseitigung sämtlicher hartcodierter deutscher Texte in allen Screens und Sheets (`ShoppingListScreen`, `ShoppingModeScreen`, `StorageChecklistScreen`, `TripWizardScreen`, `KittyScreen`, `SettlementScreen`, `ItemRowWidget`, `PlanningView`, `ShoppingView`, etc.).
  - Einhaltung der UX-C-Regel (kein "kitty" in ARB-Dateien, stattdessen "Crew fund").
- **Tests & Qualitätssicherung:**
  - 23 neue Tests in `test/features/i18n/s9_i18n_test.dart` belegen alle 5 Abnahmekriterien (ARB-Vollständigkeit, Katalogübersetzungen, Formatierer, Kategorien/Abteilungen, deutsche Textfreiheit).
  - 224/224 Flutter-Tests grün, `flutter analyze` fehlerfrei.

## 2026-09-26 – Slice B2: Cloud-Sicherung (R2), Mandantentrennung, 5er-Limit und IBAN-Schutz

- **Backend Endpunkte `/v1/backups` (`backend/src/routes/backups.ts`, `backend/src/db/backups.ts`):**
  - `POST /v1/backups`: Speicherung des Sicherungsinhalts in Cloudflare R2 (`BACKUPS_BUCKET`) und Metadaten in D1 `backups`.
  - `GET /v1/backups`: Abruf aller Sicherungen des authentifizierten Nutzers, absteigend nach Erstellungsdatum sortiert.
  - `GET /v1/backups/:id`: Sicherer Download von Sicherungen mit strikter Mandantentrennung (Konto A kann Sicherungen von Konto B weder einsehen noch abrufen).
  - Kontingentierung: Beschränkung auf maximal 5 Sicherungen je Konto (überzählige ältere Sicherungen werden automatisch aus D1 und R2 gelöscht).
  - Datenschutz: Serverseitige Ablehnung von Sicherungsinhalten mit IBANs (`INVALID_BACKUP_CONTENT`, Status 400).
- **App-Anbindung (`lib/core/services/`):**
  - `HttpHullqApiClient` um `uploadBackup`, `getBackups` und `downloadBackup` erweitert.
  - `HttpHullqBackupService`: Reale Cloud-Sicherung gegen die Backend-API implementiert und über `hullqBackupServiceProvider` bereitgestellt.
  - `BackupCoordinator`: Serialisierung und Wiederherstellung um FB2-B-Felder (`hasFreezer`, `freezerCapacity`, `waterTankLiters`, `isWaterTankDrinkable`) ergänzt.
- **Tests & Qualitätssicherung:**
  - 5 neue Backend-Tests in Vitest (`backend/test/backups.spec.ts`) verifizieren Upload, Download, Mandantentrennung, 5er-Limit und IBAN-Ablehnung (21/21 Backend-Tests grün).
  - 4 neue Flutter Unit- und Integrationstests in `test/features/more/b2_backup_integration_test.dart` (201/201 Flutter-Tests grün).

## 2026-09-26 – Slice B1: Login mit Auth0, /v1/me, Einwilligung und Kontolöschung

- **Backend Authentifizierung (`backend/src/auth.ts`):**
  - JWT-Validierung mit `jose` (RS256, JWKS-Abruf, Issuer-, Audience- und Expiry-Prüfung).
  - Standardisierte Ablehnung unbefugter Anfragen mit 401 UNAUTHORIZED (`{ error: { code, message } }`).
- **Endpunkte `/v1/me` und `/v1/consents` (`backend/src/routes/`):**
  - `GET /v1/me`: Projektion der Auth0-Identität `auth0_sub` in D1 `accounts`; Abruf von Profildaten, Einwilligungen und Charter-Mitgliedschaften.
  - `DELETE /v1/me`: Vollständige, kaskadierende Kontolöschung in D1 und Entfernung verknüpfter Sicherungsdateien in R2.
  - `PUT /v1/consents/boat-market-news`: Zod-validierte Speicherung der Einwilligung mit Zeitstempel und Textversion (`v1.0`).
- **Portal Kontolöschung (`portal/src/pages/konto-loeschen.astro`):**
  - Google-Play-konforme Löschseite mit Bestätigungsdialog und Erläuterung der unwiderruflichen Datenlöschung.
- **Flutter-App-Integration (`lib/core/services/`):**
  - `HullqApiClient` und `HttpHullqApiClient` für typsichere HTTP-Kommunikation mit dem Planer-Backend.
  - `Auth0HullqAuthService`: Echter Token-Lifecycle, Initialisierung des Backend-Kontos, Übermittlung der Einwilligung und Kontolöschung.
  - Checkbox "Bootsmarkt-Infos" in `UnlockSheet` bleibt standardmäßig unmarkiert (`false`).
- **Tests & Qualitätssicherung:**
  - 16 Backend-Tests in Vitest (JWT-Validierung, abgelaufene Tokens, manipulierte Signaturen, D1 CRUD & Cascade Delete).
  - 6 neue Flutter Unit- und Widget-Tests in `test/features/auth/b1_auth0_login_test.dart` (insgesamt 197/197 Flutter-Tests grün).

## 2026-09-26 – Slice B0: Planer-Backend Grundgerüst

- **Cloudflare Worker Backend (`backend/`):**
  - Worker mit Hono v4, Zod v3, Jose v5 und TypeScript im `strict`-Modus ohne `any`.
  - Standardisierte Fehlerantworten `{ error: { code, message } }` über `AppError` und Exception-Handler.
  - Endpunkte `/health` und `/v1/info` mit CORS-Unterstützung implementiert.
- **D1-Datenbank & R2-Storage:**
  - Initiale Migration `migrations/0001_initial_schema.sql` mit allen 11 Tabellen aus Backend-Konzept v0.2 Abschnitt 4 angelegt.
  - Deklarative Bindings in `wrangler.toml` für D1 (`DB`) und R2 (`BACKUPS_BUCKET`) mit EU-Jurisdiktion.
- **Tests & Qualitätssicherung:**
  - Vitest-Testsuite mit `@cloudflare/vitest-pool-workers` aufgesetzt (`singleWorker: true`, `fileParallelism: false` für Windows Miniflare-Stabilität).
  - Schema- und CRUD-Tests verifizieren alle 11 Tabellen, Foreign Keys und R2-Operationen (6/6 Tests grün).
  - Sicherheitsprüfung: 0 Geheimnisse im gesamten Repository.
- **Portal & Web (`portal/`):**
  - Cloudflare Pages Projekt mit Astro v4 und TypeScript eingerichtet (`web/` blieb unberührt).
  - Startseite und Account-Löschseite (`konto-loeschen.astro`) angelegt.
- **GitHub Actions CI:**
  - `.github/workflows/ci.yml` für automatische Builds und Tests: Flutter (`analyze`, `test`) und Backend (`typecheck`, `test`).

## 2026-09-26 – Slice FB2-B: Oberfläche – Setup, Hinweise, Bedienung, Überlauf

- **Törn-Setup UI (Tiefkühlfach & Wassertank):**
  - Schema v6: DB-Spalten `hasFreezer`, `freezerCapacity`, `waterTankLiters`, `isWaterTankDrinkable` in Trips-Tabelle und Schema-Migration.
  - `TripWizardScreen` um Stepper und Direkteingabe für Tiefkühlfach (Liter) und Wassertank (Liter) erweitert.
  - Schalter für Tiefkühlfach vorhanden und Trinkbarkeit des Tankwassers.
  - Werte werden in der Datenbank persistiert und an die `QuantityEngine` weitergegeben.
- **Hinweise in der Vorratsliste:**
  - Lagerhinweise ("braucht Kühlung", "gleich einfrieren") als farbige Badges an den Positionen.
  - Resthinweise ("Rest ca. X – bei einem späteren Einkauf einplanen") und alternative Vorschläge werden angezeigt.
- **Gesamtgewicht & -volumen:**
  - Aggregierte Anzeige von Gesamtgewicht (kg) und Gesamtvolumen (l) oberhalb der Planungsliste in `PlanningView`.
- **Bedienkonzept Zahlen:**
  - Schnellchips und Cupertino-Wählrad (Modal Bottom Sheet) ausschließlich für die Törndauer.
  - Stepper (+/-) mit Direkteingabe für Kühlkapazitäten, Tank und Crew.
- **Lieferbestellungen teilen:**
  - WhatsApp als primäre/oberste Option im Share-Sheet (`OrderPreviewSheet`).
- **Überlaufschutz:**
  - Zeilenlayout der Vorratsliste überläuft nicht bei langen Produktnamen, großen Mengen und Textskalierung 2.0 (geprüft in Hell-, Dunkel- und Nachtwache-Modus).
- **Router & Fehlerbehandlung:**
  - Unsicherer Fallback `?? 1` vollständig entfernt.
  - `NotFoundScreen` für syntaktisch fehlerhafte Routen (`/trips/abc`) und unbekannte numerische Trip- und Stopp-IDs implementiert.
- **Prüfung:** `flutter analyze` 0 Fehler, `flutter test` 191/191 Tests grün (10 dedizierte FB2-B-Tests).

## 2026-09-26 – GEMINI.md: Wiederaufnahme nach Unterbrechung

- Regeln, wie Gemini nach Kontingentpause oder neuer Sitzung am richtigen Slice weitermacht

## 2026-09-26 – Slice FB2-A: Rechenlogik Haltbarkeit, Tiefkühlfach, Bordtank

- **Katalog & Mengendaten:**
  - `pubspec.yaml` auf `data/catalog_v0.10.json` und `data/quantities_v0.6.json` umgestellt.
  - Datenmodelle erweitert: `ChillRequirement` (`none`, `fridge`, `freezer`), `shelfLifeFrozenDays` an `CatalogVariant`, `waterTankReserveLitersPerPerson` (1.5 l) an `QuantitiesData`.
- **Haltbarkeit & Vorschlagslogik:**
  - Vorschlag je Variante auf Haltbarkeit an Bord (`shelf_life_days` bzw. `shelf_life_frozen_days`) bzw. Tage bis zum nächsten Einkaufsstopp begrenzt.
  - Bei `GroupSplit.equal`: Nicht ausreichend haltbare Varianten decken nur ihren Haltbarkeitsanteil; die verbleibenden Tage werden von haltbaren Varianten der Gruppe gedeckt.
  - Resthinweis generiert ("Rest ca. X – bei einem späteren Einkauf einplanen" sowie Nennung haltbarer Alternativen aus dem Katalog).
- **Tiefkühlfach & Kühlung:**
  - Varianten mit `chill == freezer` werden ohne Tiefkühlfach nicht vorgeschlagen (`effectivePackages = 0`).
  - Mit Tiefkühlfach gilt für TK-fähige Artikel `shelfLifeFrozenDays` (z. B. Hähnchen bis 90 Tage) mit Gefrier-Hinweis.
  - Tiefkühlvolumenbedarf (`freezerLitersNeeded`) und Überlastung (`isFreezerOverloaded`) werden berechnet.
- **Bordtank-Trinkwasser:**
  - Nur wenn `isWaterTankDrinkable == true`: Bordtankinhalt wird vom Trinkwasser-Flaschenbedarf abgezogen; mindestens 1,5 l/Person Mindestreserve bleibt erhalten.
  - Wenn nicht trinkbar: voller Trinkwasserbedarf wird als Flaschenwasser berechnet.
- **Gesamtgewicht und -volumen:**
  - `QuantityEngine.calculateWeightAndVolume` berechnet Gesamtgewicht (kg) und Gesamtvolumen (l) basierend auf Packungsgrößen und erfasst Stückwaren ohne Gewichtsangabe.
- **Revier-Migration:**
  - `ClimateZone` Enum (`cool`, `warm`, `hot`) kapselt alle Legacy-Revierstrings (`temperate`, `baltic`, `mediterranean`, etc.) typsicher.
- **Prüfung:** `flutter analyze` 0 Fehler, `flutter test` 181/181 Tests grün (inklusive aller 7 FB2-A Abnahmetests).

## 2026-09-26 – Reihenfolge angepasst

- Freigegeben: FB2-A, FB2-B, B0, B1, B2, S9, S10-T; B3–B5 erst nach interner Testphase (Charter bleibt v1, vor öffentlicher Veröffentlichung)

## 2026-09-26 – Korrekturen nach externem Review

- Backend-Konzept v0.2: portal/ statt web/, D1/R2 Jurisdiktion EU, accounts als lokale Projektion, CI ab B0
- Slice-Plan v0.19: CI in B0, FB2-A lädt Katalog v0.10/Quantities v0.6, Router-Fehler (?? 1) in FB2-B
- PRD v0.21: Charter-Widersprüche bereinigt

## 2026-09-26 – Backend-Konzept, Slice-Plan v0.18, GEMINI.md v0.7

- Planer-Backend auf Cloudflare mit Auth0 (HullQ-Tenant): Login, Konto löschen, Cloud-Sicherung, Crew-Fragebogen, Törn-Codes, Admin-Seite Charterfirmen (v1)
- Slices B0–B5 freigegeben; Reihenfolge FB2-A, FB2-B, B0–B5, S9, S10-T

## 2026-09-26 – MVP-Abschluss freigegeben

- Feedback-Runde 2 v0.3 (Bedienregel Zahleneingaben, Bordtank nur trinkbar); Katalog v0.10 (Lagerung, TK-Haltbarkeit, 20 Langfahrt-/TK-Varianten); Quantities v0.6
- Slice-Plan v0.17: FB2-A, FB2-B, S9 (Katalogübersetzung durch Gemini als Ausnahme), S10-T freigegeben

## 2026-09-26 – Feedback-Runde 2 v0.2 (Entwurf)

- Haltbarkeitsgrenze für Vorschläge, haltbare Varianten bei langen Strecken, Tiefkühlfach, Katalogergänzungen, Layout-Überlauf, Übernahmen aus Wettbewerbsanalyse

## 2026-09-26 – Slice UX-C: Begriffe und Aufräumen

- **Begriffe nach UX-Konzept v0.6 Begriffstabelle:**
  - ARB-Dateien (`app_de.arb`, `app_en.arb`): Sämtliche Vorkommen und Schlüssel von "Kitty" / "kitty" restlos entfernt und durch "fund" ersetzt (`fundTitle`, `fundAddExpense`, `fundAddContribution`, `fundSettleUp`, `navFund` usw.).
  - Begriffe in Deutsch und Englisch vereinheitlicht: „Bordkasse“ / „Crew fund“, „Einzahlung erfassen“ / „Add contribution“, „Ausgabe erfassen“ / „Add expense“, „Abrechnung“ / „Settle up“, „Planen“ / „Plan“, „Einkaufen“ / „Shop“, „Vorratsliste“ / „Provision list“.
- **Startbildschirm-Untertitel:**
  - DE: „Proviant und Bordkasse – ganz einfach“
  - EN: „Provisioning & crew fund made easy“
  - Alte Platzhaltertexte wie „Trip Planning Made Easy“ und „Setup & Architektur“ restlos aus Codebase und Übersetzungen entfernt.
- **Aufräumen veralteter Widgets & Screens:**
  - `TripBottomBar` (`trip_bottom_bar.dart`) vollständig aus Navigation und Dateibaum gelöscht (durch die 5 Hauptbildschirme ohne Reiterleiste nach UX-A abgelöst).
- **Prüfung:** `flutter analyze` 0 Fehler, `flutter test` 174/174 Tests grün (inklusive aller 6 dedizierten UX-C Such- und Abnahmetests).

## 2026-09-26 – Slice UX-B: Liste, Einkaufsmodus, Liefern lassen

- **Vorratsliste (`ShoppingListScreen` & `PlanningView`):**
  - In-Place Accordion: Gruppen klappen inline auf und zu, kein modales Bottom Sheet mehr.
  - Positionen und Varianten direkt inline anpassen und übernehmen.
  - Zahl antippen öffnet ein Inline-Textfeld für schnelle Mengenanpassung.
  - Wasser-Schnellwahl-Chips (`+25% warm`, `+50% heiß`) zur dynamischen Erhöhung des Wasservorrats.
  - Wischgeste (Swipe nach links) öffnet die Zuweisung zu Einkaufsstopps als Chips.
  - Floating Action Button `+ Position` zur flexiblen Artikelsuche mit Eigene-Position-Möglichkeit.
  - Feste untere Aktionsleiste `Einkauf starten · Tag X <Stopp>` mit Stopp-Auswahl.
- **Liefern lassen & Bestellwesen:**
  - Einkaufsstopp-Art wählbar zwischen "Selbst einkaufen" und "Liefern lassen".
  - Konfigurations-Sheet `DeliveryConfigSheet` (Marina, Liegeplatz, Bootsname, Liefertermin, Ansprechpartner, Notizen, Lieferantenauswahl mit Speicheroption).
  - Lieferantenverwaltung über alle Törns hinweg (`SupplierService`, `SupplierProfile`), einseh- und pflegbar in `MoreScreen`.
  - Bestellvorschau `OrderPreviewSheet` mit Gruppierung nach Abteilungen, Stückzahlen und Packungsgrößen.
  - Teilen über Text (WhatsApp / E-Mail) und PDF-Dokument (`PdfExportService.generateDeliveryOrderPdf`).
  - Statusverfolgung ("Bestellung als gesendet markieren", Erfassung des Sendedatums und Erkennung von Nachträgen).
  - Wareneingang `DeliveryReceivedSheet` zum Abhaken gelieferter Artikel, Verschieben fehlender Artikel auf andere Stopps und Übergang zum Einlagern.
- **Einkaufsmodus:**
  - Abteilungsweise Sortierung: offene Positionen oben, erledigte Positionen durchgestrichen und transparent unten.
  - AppBar-Direktabsprung „Ausgabe erfassen“.
  - „Fertig eingekauft“-Dialog mit Angebot zur direkten Einlagerung.
- **Prüfung:** `flutter analyze` 0 Fehler, `flutter test` 168/168 Tests grün (inklusive 6 dedizierter UX-B Abnahmetests).

## 2026-09-26 – UX-Konzept v0.6

- Crew-Link optional (Hauptweg: Skipper in der App); Cloudflare als Grundlage, keine Gesundheitsdaten

## 2026-09-26 – PRD v0.19, UX-Konzept v0.5

- v1.1 vorgemerkt: Crew-Wünsche per Link (aus Wettbewerbsanalyse Victuo)

## 2026-09-26 – Wettbewerbsanalyse v0.4

- Victuo getestet; Übernahmen: Bordtank beim Wasser, Gesamtgewicht/-volumen, WhatsApp-Bestellung; Kartendienste vorgemerkt

## 2026-09-26 – Slice UX-A: Navigation, Törn anlegen, Törn-Übersicht

- **Startbildschirm („Meine Törns“):**
  - Keine untere Reiterleiste mehr (Material NavigationBar entfernt).
  - Prominenter Button „+ Neuer Törn“ (`FilledButton.icon`) stets sichtbar, auch bei vorhandenen Törns.
  - Kachel-Anzeige mit Indikator für den nächsten logischen Schritt.
  - Eingeklappter Bereich für archivierte Törns.
- **Törn anlegen (`TripWizardScreen`):**
  - Von 3-Schritt-Wizard auf eine einzige scrollbare Seite mit 3 einklappbaren Sektionen (1. Törn, 2. Crew, 3. Essen an Bord) umgestellt.
  - Unnötige Fragen entfernt: Keine Abfragen nach Bootstyp, Revier/Klimazone oder Alkoholkonsum.
  - Erfassung von Restaurant-Abenden und -Mittagen per Stepper (Zähler), die unmittelbar die berechneten Bordmahlzeiten verringern.
  - Abschluss führt ohne Umwege direkt zur neuen Törn-Übersicht (`/trips/:id`).
- **Törn-Übersicht (`TripOverviewScreen`):**
  - Neues organisatorisches Rückgrat des Törns mit vier Ablaufphasen (1. Liste, 2. Einkaufen, 3. Unterwegs / Bordkasse, 4. Abschließen).
  - Nächster ausstehender Schritt optisch durch Akzentumrandung hervorgehoben.
  - Direkte Kassen-Aktionen („Ausgabe erfassen“, „Einzahlen“, „Abrechnen“) ohne Drei-Punkte-Menü erreichbar.
  - Float Action Button „Ausgabe erfassen“ bei begonnenem Törn oder vorhandenen Buchungen.
  - Eingeklappter Detailbereich „Tage im Detail“ zur feingranularen Steuerung von Restauranttagen.
- **Navigation und Datenfluss:**
  - Strikte Begrenzung: Kein Bildschirm liegt tiefer als zwei Ebenen unter „Meine Törns“.
  - Crew-Verwaltung enthält keine Zahlungsdatenfelder mehr (IBAN, PayPal, Revolut).
  - Einzahlungen an die Kasse nutzen stets die Kontodaten des Kassenwarts für den EPC-QR-Code.
  - Auszahlungen an Crewmitglieder bieten „Bar ausgezahlt“ (direkter Saldenausgleich) und „Überweisen“ (mit Modulo-97-Validierung für Empfänger-IBAN).
- **Prüfung:** `flutter analyze` 0 Fehler/Warnungen, `flutter test` 162/162 Tests grün (inklusive 9 dedizierter UX-A Abnahmetests).

## 2026-09-26 – Wettbewerbsanalyse v0.1

- CrewMate, Armator.PRO, Victuo und allgemeine Alternativen; Differenzierung und Empfehlung

## 2026-09-26 – UX-Konzept v0.4

- Zahlungsdaten nur vom Kassenwart; Auszahlungen an andere bei Bedarf in der Abrechnungszeile (in UX-A aufgenommen)

## 2026-09-26 – UX-Konzept v0.3, Slice-Plan v0.16, Freigabe UX-A bis UX-C

- Begriffsregel: kein "Kitty" in der Oberfläche (DE Bordkasse, EN Crew fund)
- Slices UX-A (Navigation, Anlegen, Übersicht), UX-B (Liste, Einkauf, Liefern lassen), UX-C (Begriffe, Aufräumen) freigegeben

## 2026-09-26 – UX-Konzept v0.2, PRD v0.18

- Einkaufsstopp "Liefern lassen" mit Bestellung an Lieferanten (v1)
- Charterfirmen-Paket mit Törn-Code-Voreinstellungen und voreingestelltem Proviantservice (v1.1)

## 2026-09-26 – UX-Konzept v0.1

- `docs/design/UX_KONZEPT_v0.1.md`: Ablauf als Rückgrat, fünf Hauptbildschirme, verbindliche Bedienmuster, Bewegung, Platzhalter für v1.1; FEEDBACK_R2 eingearbeitet
- Keine Freigabe für Gemini bis Konzept und Prototyp abgestimmt sind

## 2026-09-26 – Entwurf Feedback-Runde 2

- `docs/impl/FEEDBACK_R2_v0.1.md` (Entwurf, nicht freigegeben): Navigation entlang des Törn-Ablaufs, Hauptaktionen sichtbar

## 2026-09-26 – FB1-D: Bordkasse neu

- **Kassenwart-Prinzip (FEEDBACK_R1 Punkt 9):**
  - "Die Kasse" ist kein eigenes Konto; alle Zahlungen an oder aus der Kasse laufen über den Kassenwart (`treasurerMemberId` in `Trips`, Drift-Schema v5 mit Migration).
  - Beim ersten Öffnen der Kasse erscheint eine Abfrage: "Wer verwaltet die Kasse? (Standard: Skipper)".
  - Kassenwart-Info-Card in der Kassenansicht mit Option zum Wechseln des Kassenwarts.
- **Einzahlen in einem Schritt:**
  - `PaymentSheet` mit einheitlichem Betragsfeld in JetBrains Mono ("Wie viel zahlt jeder ein?"), Checkliste aller Crew-Mitglieder (standardmäßig vorselektiert) und Sofortberechnung des Gesamtbetrags.
- **Ausgabe mit 3 Pflichtfeldern:**
  - `ExpenseSheet` mit 3 Kernfeldern im Fokus: Betrag, Wofür (Kategorie), Wer hat bezahlt (`SegmentedButton`: Kasse oder Person).
  - Titel/Notiz und abweichende Beteiligung/Aufteilung eingeklappt unter "Mehr Optionen".
- **Nachschuss-Hinweis:**
  - Bei niedrigem Kassenstand (< 50 €) erscheint ein Hinweisbanner: "Kasse fast leer – jeder legt 50 € nach?" mit Button "Übernehmen", der das Einzahlungs-Sheet vorbefüllt mit 50 € öffnet.
- **Abrechnung auf einem Bildschirm:**
  - Klare Zeilen je Person: "bekommt X von Y" bzw. "zahlt X an Y" mit Button "Bezahlen". Keine Zeilen "→ Kasse" oder Pseudomitglied "Bordkasse".
  - Mathematische Garantie: Die Summe aller Netto-Salden ist mathematisch immer exakt 0 Cent (`sum(netBalanceInCents) == 0`).
  - "Bezahlen"-Aktion expandiert den EPC-QR-Code (GiroCode) und Zahlungslinks mit den Daten des jeweiligen Empfängers.
  - Fehlen Zahlungsdaten für den Empfänger, erscheint ein Hinweiskasten: "Für [Name] sind keine Zahlungsdaten hinterlegt" mit Button "Jetzt eintragen".
- Validierung: `flutter analyze` 0 Fehler, `flutter test` 153/153 Tests grün (28 Kitty-Tests inkl. dediziertem FB1-D Abnahmetest).

## 2026-09-26 – FB1-C: Törn-Setup

- **Törnlänge bis 180 Tage (FEEDBACK_R1 Punkt 1):**
  - Törndauer im Setup-Wizard (`TripWizardScreen`) als Zahlenfeld (1–180 Tage) mit Slider und Schnellauswahl-Chips ("1 Woche", "2 Wochen", "1 Monat", "3 Monate", "6 Monate").
  - Tagesleiste (`TripTimelineScreen`): Ab 28 Tagen automatische Gruppierung nach Wochen (`ExpansionTile` mit "Woche X (Tag A–B)"), innerhalb derer die Tage aufklappbar sind; unter 28 Tagen weiterhin flache Tageskarten-Liste.
  - Neutraler Hinweis bei Törns >= 15 Tagen zur Anlage von Einkaufsstopps.
- **Kühlkapazität ab 0 Litern (FEEDBACK_R1 Punkt 2):**
  - Schieberegler beginnt bei 0 Litern; zusätzlicher Schalter "Kein Kühlschrank an Bord" setzt Kapazität sofort auf 0 Liter.
  - Bei 0 Litern erhalten kühlbedürftige Artikel (`isCooled` bzw. `cool_first`) den Badge "braucht Kühlung" (anstelle automatischer Abwahl).
  - Im Varianten-Detail-Sheet erscheint ein Hinweistext mit ungekühlt haltbaren Alternativen aus dem Katalog (H-Milch, gesalzene Butter, Hartkäse, Salami/Chorizo, Konserven).
- **"Wie warm wird es?" statt Revier (FEEDBACK_R1 Punkt 3):**
  - Revierabfrage durch Frage nach Temperatur ersetzt mit 3 Stufen: `kühl` (meist unter 20 °C), `warm` (20–28 °C), `heiß` (über 28 °C).
  - Dynamischer Trinkwasserbedarf je Stufe nach `data/quantities_v0.5.json`: kühl 2,0 l, warm 2,5 l, heiß 3,5 l pro Person und Tag.
  - Einlagerungs-Checkliste standardmäßig aktiviert bei "heiß".
  - Schema v4 mit SQLite-Migration: Konvertiert bestehende Revierwerte (`temperate` -> `cool`, `mediterranean`/`mediterranean_summer` -> `warm`, `hot_or_remote` -> `hot`).
- **Reiterleiste ohne Törn entfernt (FEEDBACK_R1 Punkt 4):**
  - `bottomNavigationBar` auf dem Startbildschirm ("Meine Törns") entfernt; Navigation Tabs existieren nur innerhalb eines aktiven Törns.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 144/144 Tests bestanden.

## 2026-09-26 – FB1-B: Neues Listenkonzept

- **Vorratsliste & Vorschlagssystem (FEEDBACK_R1 Punkt 3, 4, 5):**
  - Neu erstellte Vorratslisten starten leer (0 Positionen auf der Vorratsliste), während die mathematischen Mengenvorschläge der Engine im Hintergrund berechnet werden.
  - Artikel verfügen über ein explizites `isAdopted`-Flag (Drift-Schema Version 3 mit Migration).
  - Aktion "Alle Vorschläge übernehmen" in der Kopfzeile übernimmt alle Standard-Varianten (`defaultSelected == true`) mit der vorgeschlagenen Packungszahl.
  - Aktion "Vorschläge übernehmen" pro Kategorie übernimmt nur die Vorschläge der jeweiligen Kategorie.
  - Einzelne Vorschläge können per "+ übernehmen"-Button direkt übernommen werden.
  - Stepper (+ / -) mit 48 dp Tippflächen zum Erhöhen/Verringern; bei Erreichen von 0 Packungen wird der Artikel von der Liste entfernt.
  - Direkte Mengeneingabe per Tipp auf die Packungszahl.
  - Vorschlagsdifferenzanzeige: Abweichende Mengen zeigen ein dezentes "Vorschlag N"-Badge daneben.
  - Entkopplung von Crewänderung und Benutzeranpassung: Übernommene Mengen bleiben bei Änderungen der Crew oder Reisedauer unverändert, während die Vorschläge dynamisch neu berechnet werden.
  - Umschalter "Planen / Einkaufen" entfällt und wird durch einen `SegmentedButton` ("Nach Kategorie" / "Nach Abteilung") ersetzt.
  - "Einkauf starten" öffnet den dedizierten Einkaufsmodus nur mit übernommenen Artikeln (Menge > 0) und großen Checkboxen (48×48 dp).
  - Warnhinweis bei Törns mit mehr als 14 Tagen bezüglich Kühlkapazitäten und Frischeempfehlungen.
  - Statusanzeigen neutralisiert (Entfall von "knapp" und "gedeckt").
- Validierung: `flutter analyze` 0 Fehler, `flutter test` 136/136 Tests grün.

## 2026-09-26 – FB1-A: Fehler und Technik

- **Varianten-Sheet & Mengenänderung (Punkt 6):**
  - Reaktivität in `GroupDetailSheet` durch kontinuierliches Beobachten von `tripShoppingListProvider(tripId)` und Awaiting der asynchronen DAOs sichergestellt.
  - Direkte Mengeneingabe über Zahlenfeld-Dialog (`setPackages`) im Sheet sowie in der Vorratsliste.
  - Prüflisten (`mode = check`) auf 3 Zustände (`vorhanden`, `fehlt`, `nachkaufen`) per `SegmentedButton` umgestellt; Schema-Version 2 mit Migration.
- **Ausgaben bearbeiten & löschen (Punkt 8):**
  - `ExpenseSheet` unterstützt Bearbeitungsmodus und Löschen mit 5-Sekunden-Undo-SnackBar; Salden und Kassenstand berechnen sich sofort neu.
- **Zahlungsdaten & Beseitigung von IBAN-Literalen (Punkt 10):**
  - Crewmitglieder um `iban` (Modulo-97 validiert), `paypalLink` und `revolutLink` erweitert.
  - "Meine Zahlungsdaten" unter "Mehr" über `UserPaymentProfileService` verschlüsselt in `FlutterSecureStorage` abgelegt.
  - Feste Dummy-IBAN aus `settlement_screen.dart` entfernt; QR-Codes und Links speisen sich dynamisch aus Empfängerdaten.
  - Automatisierter Suchtest `test/core/no_iban_literal_test.dart` garantiert Freiheit von IBAN-Literalen in `lib/`.
- **Build-Einstellungen:**
  - `android/app/build.gradle`: `compileSdk = 35`, `ndkVersion = "26.1.10909125"`.
- Validierung: `flutter analyze` 0 Fehler, `flutter test` 133/133 Tests grün.

## 2026-09-26 – Feedback-Runde 1

- `docs/impl/FEEDBACK_R1_v0.1.md`: 10 Punkte aus dem ersten Praxistest (vorrangig)
- PRD v0.17, Design-Brief v0.5, Slice-Plan v0.15 (FB1-A bis FB1-D), Katalog v0.9, Quantities v0.5
- Manueller QR-Test: Code gelesen, Betrag und IBAN korrekt

## 2026-09-25 – S8a: Nachbesserung Ehrlichkeit und Umfang

- **Korrektur Ehrlichkeit (GEMINI.md Regel 9):**
  - In `docs/impl/S5a_bericht.md` den erfundenen manuellen Scan mit der DKB-Banking-App entfernt, die Korrektur offen als falsch deklariert und das Kriterium auf "offen – wartet auf manuellen Test durch den Menschen" mit detaillierter Anleitung gesetzt.
  - Die Abschlussberichte zu S6, S7 und S8 überarbeitet und bei jedem Abnahmekriterium die Art des Nachweises nach Regel 9 ergänzt (`automatischer Test (<Name>)` bzw. `offen – wartet auf manuellen Test durch den Menschen`).
  - Beim PDF-Export in S8 differenziert: Syntaktische und inhaltliche PDF-Erstellung ist durch Unit-Tests belegt; das interaktive Öffnen im systemweiten Plattform-Viewer/Druckdialog wartet auf manuellen Test durch den Menschen auf einem echten Endgerät.
- **Korrektur Umfang / Zukunfts-Features (GEMINI.md Regel 10):**
  - Törn-Code-Einlösebereich im Freischalten-Dialog (`UnlockSheet`, SC-ACC-01) hinter das Feature-Flag `tripCodeFeatureFlagProvider` (`FeatureFlags.enableTripCodePasses = false`) gelegt. In Version 1.0 ist keine Törn-Code-Einlösung sichtbar oder erreichbar.
  - Domänenmodell `TripCodePass` und `EntitlementsService.redeemTripCode` bleiben wie gefordert für Version 1.1 erhalten.
  - Widget-Tests in `test/features/entitlements/unlock_ui_test.dart` erweitert: Test stellt sicher, dass bei ausgeschaltetem Schalter keine Törn-Code-UI erreichbar ist, und dass bei aktiviertem Schalter die Einlösung wie geplant funktioniert.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 127/127 Tests bestanden.

## 2026-09-25 – Review S5a–S8, GEMINI.md v0.6, Slice-Plan v0.14

- Kritisch: erfundener manueller Scan im S5a-Bericht; hoch: sichtbare Törn-Code-Einlösung (v1.1) in S6
- Regel 9 (nur berichten, was tatsächlich geschehen ist), Regel 10 (nichts aus späteren Versionen sichtbar bauen)
- Korrektur-Slice S8a, nur dieser freigegeben

## 2026-09-25 – S8: Sicherung, Wiederherstellung, Export (Mock)

- `MockHullqBackupService` und `BackupCoordinator` für die transaktionssichere Sicherung und Wiederherstellung aller 8 SQLite-Tabellen (`Trips`, `TripDays`, `CrewMembers`, `ShoppingStops`, `ListItems`, `ListItemAllocations`, `Expenses`, `KittyPayments`) in strukturiertem JSON.
- Verschlüsselte Persistenz der Cloud-Sicherung in `FlutterSecureStorage` zur realistischen Simulation von Geräte- und App-Neuinstallationen.
- Relationale Integrität bei der Wiederherstellung: Automatische Neuverknüpfung aller Fremdschlüssel (`stopIdMap`, `crewIdMap`, `listItemIdMap`).
- Sicherungsberechtigung: Sicherung und Wiederherstellung stehen gemäß PRD strikt nur angemeldeten HullQ-Mitgliedern zur Verfügung.
- Automatische Wiederherstellung: Beim Login eines Mitglieds über das `UnlockSheet` nach einer Neuinstallation wird eine vorhandene Cloud-Sicherung automatisch erkannt und eingespielt.
- Bildschirm "Mehr" (SC-MORE-01):
  - Anzeige des Zeitstempels der letzten Sicherung mit formatierter Datumsangabe bzw. "Noch keine Sicherung vorhanden".
  - Button "Jetzt sichern" mit direktem Feedback per SnackBar.
  - Button "Sicherung wiederherstellen" mit Sicherheits-Bestätigungsdialog.
- PDF-Exportdienst `PdfExportService` mit Standard-Paketen `pdf` und `printing` (Regel 8) unter Verwendung von Standard-PostScript-Schriften (Helvetica, Courier) für 100% Offline-Fähigkeit ohne Netzwerkzugriff:
  - **Einkaufsliste:** Mehrseitiges, druckfertiges A4-Dokument, gegliedert nach Abteilungen, mit Packungsanzahlen, Mengenangaben, Törndetails und aktuellem Stopp.
  - **Bordkassenabrechnung:** Mehrseitiges A4-Dokument mit Bento-Zusammenfassung (Ausgaben, Einzahlungen, Saldo), Tabelle der minimalen Ausgleichszahlungen ("Wer zahlt wem") und vollständiger Saldenübersicht pro Crewmitglied.
  - **Teilen & Drucken:** Export und Übergabe an das System-Teilen-Menü via `Printing.sharePdf` / `share_plus`.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 126/126 Tests bestanden (inklusive 9 neuer Unit- und Widget-Tests für Sicherung, Wiederherstellung, PDF-Generierung und UI-Abläufe).

## 2026-09-25 – S7: HullQ-Login, Einwilligung, Konto löschen (Mock)

- `MockHullqAuthService` mit `FlutterSecureStorage` für verschlüsselte Persistenz von Tokens, E-Mail-Adresse und Mitgliedschaftsstatus.
- Offline-Toleranz: Gespeicherter Status bleibt ohne Netzwerkverbindung vollständig erhalten; `UnlockSheet` informiert über fehlende Verbindung und deaktiviert Login-Aktionen (SC-ACC-01).
- Verbindliche Designregel 4 & GEMINI.md: Checkbox für Marketing-Einwilligung ("Ja, ich möchte über den aktuellen Bootsmarkt informiert werden.") ist strikt initial unmarkiert (`false`) und wird bei Login transparent übermittelt.
- Bildschirm "Mehr" (SC-MORE-01) als Tab 3 (`/more` und `/trips/:id/more`):
  - HullQ-Konto Bento Card mit unterschiedlichen Zuständen für nicht-angemeldete (Freischalten-Button) und angemeldete Nutzer (E-Mail, Status-Badge, Hinweistext zur letzten Sicherung, Buttons für Sofortsicherung und Abmeldung).
  - Sicheres Konto-Löschen ("Konto löschen") mit irreversiblem Bestätigungsdialog: löscht alle Tokens und lokalen Kontodaten und versetzt den Zustand zurück auf den Probetörn.
  - Nachtwache-Umschalter, Platzhalter für Zahlungsdaten, Packungsgrößen und Spracheinstellungen sowie rechtliche Verlinkungen (Datenschutz, Nutzungsbedingungen, Impressum) und Versionsanzeige.
- Reaktives State-Management mit `AuthNotifier` und `AuthState` für synchrone UI-Aktualisierungen bei Authentifizierungs- und Löschvorgängen.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 117/117 Tests bestanden (inklusive 12 neuer Tests für Token Lifecycle, Persistenz und UI-Interaktionen).

## 2026-09-25 – S5a: Korrektur QR und Validierung

- Selbstgebauten QR-Generator (`qr_generator.dart`) gelöscht; EPC-QR-Code (GiroCode) mit Standard-Paketen `qr_flutter` und `qr` (Fehlerkorrektur M, UTF-8) implementiert.
- EPC-Validierung in `EpcQrPayload`: Name max. 70 Zeichen, Verwendungszweck max. 140 Zeichen, Betrag 1 Cent bis 999.999.999,99 EUR, Modulo-97-IBAN-Prüfung (`IbanValidator` mit `BigInt`), Zeilenumbruchsverbot gegen Injection.
- Zahlungs-Links und Teilen von Überweisungsdetails mit `url_launcher` und `share_plus` angebunden.
- S3: Alle String-Literale für Crew-Fragen im Setup-Wizard auf feste Enums `CrewAppetite` und `CrewDrinking` umgestellt.
- S1: Drift-`TypeConverter` für sämtliche Enum-Spalten in der lokalen SQLite-Datenbank implementiert (`TripPhaseConverter`, `KittyModelConverter`, `CrewAppetiteConverter`, `CrewDrinkingConverter`, `ExpenseCategoryConverter`).
- Katalog v0.8 (`data/catalog_v0.8.json`) eingebunden und Not-Need-Synthese für Wasser im Parser entfernt.
- Umfassende Testabdeckung: Validierungsgrenzen-Tests und verlustfreie Dekodierung mit `zxing2` (`epc_qr_zxing_test.dart`); 105/105 Tests grün.

## 2026-09-25 – Freigabe S7, S8

- Reihenfolge: S5a (Vorrang), dann S7 und S8 gegen Mocks; S9/S10 noch nicht freigegeben

## 2026-09-25 – Review S2a–S5, GEMINI.md v0.5, Slice-Plan v0.13, Katalog v0.8

- Review: S2a-Befunde behoben; kritisch: selbstgebauter QR-Generator vermutlich nicht scannbar
- Neuer Korrektur-Slice S5a (Vorrang); Regel 8 gegen Eigenbauten von Standards; freigegebene Zusatzpakete

## 2026-09-25 – S6: Freischaltungslogik

- Reine Dart-Entitlement-Engine `EntitlementsManager` in `lib/features/entitlements/domain/entitlements.dart` mit typisierten Enums (`EntitlementLevel`, `AppFeature`).
- Vollständige Abbildung aller 16 Funktionszeilen der PRD-Tabelle (PRD v0.16 Abschnitt 2) für Probetörn (trial), Mitglied (member) und Pro (pro).
- Vorbereitung für v1.1 Törn-Codes: `TripCodePass` unterstützt zeitlich begrenzte Gültigkeit (`validUntil`) und Törn-spezifische Freischaltungen (`targetTripId`) ohne Modellumbau.
- `EntitlementsService` mit Riverpod-Integration (`entitlementsServiceProvider`, `canCreateTripProvider`, `entitlementLevelProvider`).
- Freischalten-Dialog `UnlockSheet` (SC-ACC-01) gemäß Design-Brief v0.4 mit Social-Logins (Google, Apple, E-Mail), Törn-Code-Einlösung, rechtlichen Links und strikt initial nicht ausgewählter Marketing-Checkbox (Designregel 4).
- `StartScreen`-Gating: Zweiter Törn im Probetörn öffnet automatisch das `UnlockSheet` statt des Setup-Wizards.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 98/98 Tests grün (22 neue Tests für S6).

## 2026-09-25 – S5: Bordkasse und Kostenteilung

- Reine Dart-Berechnungsengine `KittyEngine` für Bordkasse und Abrechnung gemäß Programmierregel 5 strikt in ganzzahligen Cents (`int`), ohne Rundungsverluste und mit mathematischer Nullsummen-Invariante ($\sum \text{Salden} = 0$).
- Beide Berechnungsmodelle voll implementiert:
  - **Modell 1: Gemeinsame Bordkasse (Standard):** Einzahlungen je Crewmitglied, Ausgaben aus der Kasse, Kassenstand-Bilanz, Auslastungsquote und automatischer Ausgleich bei positivem/negativem Restbetrag.
  - **Modell 2: Einzelabrechnung:** Eigene Auslagen der Crewmitglieder, Netto-Saldenberechnung und Greedy Debt Simplification zur Minimierung der notwendigen Überweisungen.
- 7 feste Ausgabenkategorien (`ExpenseCategory`) und Beteiligungsprofile (`ParticipationProfile`) mit Schnellauswahl "Skipper frei" (vollständig oder ohne Verpflegung) und "Kein Alkohol".
- Reine Dart-Erzeugung standardkonformer SEPA EPC069-12 QR-Codes (GiroCode) ohne externe Drittpakete.
- Vollständige Oberflächen nach Design-Brief v0.4:
  - `KittyScreen` (SC-KAS-01): Bento-Kassenstandskarte mit JetBrains Mono Zahlen, Auslastungsbalken, Umschaltung zwischen "Ausgaben" und "Personen & Anteile", FAB für neue Ausgaben und Modellwechsel.
  - `ExpenseSheet` (SC-KAS-02): Betragseingabe in JetBrains Mono, Kategorie-Chips mit Outlined-Icons, Zahler-Auswahl (Kasse oder Crewmitglied) und Option "Anders aufteilen".
  - `PaymentSheet` (SC-KAS-03): Einzahlungsdialog mit Option "Gleicher Betrag für alle".
  - `ParticipationMatrixSheet` (SC-KAS-04): Matrix der Kategorie-Beteiligung je Crewmitglied mit Profil-Chips und Einzelschaltern.
  - `SettlementScreen` (SC-KAS-05): "Wer zahlt wem"-Liste mit minimalen Überweisungen, aufklappbarem EPC-GiroCode (240 dp mit weißer Ruhezone auch im Nachtmodus), Überweisungsdetails zum Kopieren, PayPal-/Revolut-Links und Törn-Archivierung.
  - 4-Reiter-Navigation in `TripBottomBar` (Reiter 2: Bordkasse) und Routen `/trips/:id/kitty` und `/trips/:id/kitty/settlement`.
- Validierung: `flutter analyze` 0 Probleme, `flutter test` 76/76 Tests grün (11 neue Tests für S5).

## 2026-09-25 – S4: Vorratsliste und Einlagerungs-Checkliste

- Vorratsliste mit zwei Hauptsichten gemäß SC-LST-01:
  - **Planen (5.2):** Hierarchie Kategorie → Bedarfsgruppe → Varianten mit Deckungsanzeigen (`✓ gedeckt`, `~ knapp`, `keine gewählt`, Prüflisten), Zählern und Einklapp-Funktion.
  - **Einkaufen (5.3):** Feste Supermarkt-Ladenreihenfolge nach Abteilungen mit Variantenzeilen ($\ge 72\text{ dp}$), Steppern [−]/[+] ($\ge 48\text{ dp}$), JetBrains Mono Packungszahlen (`3 × 750 g`), Bedarf/Reserve und Badges (*hält X Tage*, *gekühlt*, *überschrieben* mit Reset-Button, *eigene Position*).
- Stopp-Filter Chip im Kopf: Wechsel zwischen "Alle Stopps" und spezifischen Einkaufsstopps; Mengen passen sich dynamisch an.
- Detailkomponenten und Interaktionen:
  - `GroupDetailSheet` (SC-LST-02): Varianten an-/abwählen, Anteilsregler bei `split=equal`, Link zur Packungsgrößen-Änderung, Summenleiste mit Deckungsanzeige, Charter-Hinweis bei `visibility=owner`.
  - `PackageSizeDialog` (SC-LST-03): Packungsgröße ändern mit Option zum Speichern und automatischer Neuberechnung.
  - `StopAllocationSheet` (SC-LST-04): Teilmengen auf Einkaufsstopps verteilen; nicht-zugeordnete Mengen verbleiben beim Ersteinkauf; Sperre bei Überbelegung (`AllocationExceededException`).
  - `CustomItemSheet` (SC-LST-05): Manuelle Positionen erfassen (Name, Menge, Einheit, Abteilung, Stopp) mit Kennzeichnung "eigene Position".
  - `CatalogSearchDelegate` (SC-LST-06): Sofortsuche über Varianten, Gruppen und Kategorien mit Option "Als eigene Position anlegen".
  - `ShoppingModeScreen` (SC-SHOP-01): Abhakbare Einkaufsliste je Stopp im Laden mit Fortschrittsanzeige, gedimmten/durchgestrichenen Zeilen und Abschlussdialog bei offenen Posten.
  - `StorageChecklistScreen` (SC-STO-01): Checkliste nach `storage_hints` aus dem Katalog mit Wellpappe-Warnung und betroffenen Artikeln als Kurzliste.
  - Fester Hinweis: "Ernährungs-Tags sind kein Allergieschutz".
  - Gemeinsame 4-Reiter-Navigation `TripBottomBar` (Liste, Törn, Kasse, Mehr) integriert.
- Offline-Persistenz: Überschreibungen, Abwahlen und Häkchen bleiben nach Reload und Crewänderung vollständig in SQLite erhalten.
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 65/65 Tests grün (10 neue Tests für S4).

## 2026-09-25 – S-UI: Angleichung an Design-System und Nachtwache-Modus

- Zentrales Flutter-Theme für alle 3 Modi implementiert: Hell, Dunkel und Nachtwache (strikt Rot auf Schwarz nach Designregel 13)
- Farbtokens aus `docs/design/mockups/technical_maritime_m3/DESIGN.md` und `docs/design/DESIGN_BRIEF_v0.4.md` vollständig umgesetzt
- Lokale Offline-Schriften in `assets/fonts/` eingebunden (`IBM Plex Sans` für Fließtext/Titel, `JetBrains Mono` mit `tabularFigures` für Zahlen und Messwerte)
- `ThemeController` und `ThemeStorage` mit lokaler Offline-Persistenz via `FlutterSecureStorage` und Schnellzugriff auf Nachtwache im StartScreen-AppBar
- Bestehende Oberflächen (S0 StartScreen, S3 TripWizardScreen, TripTimelineScreen, DayCard) an das Design-System und die Designregeln 1–13 angeglichen
- Verbotene maritime Icons (Segel `Icons.sailing_outlined`, Bootssilhouette `Icons.directions_boat`) entfernt und durch technische Blueprint-Icons (`view_timeline_outlined`, `inventory_2_outlined`) ersetzt
- Mindestgrößen (Fließtext >= 14 sp, Etiketten >= 12 sp, Tippflächen >= 48 dp) konsequent eingehalten
- Nachtwache-Modus: Strikt keine Farben außerhalb des Rot/Schwarz-Spektrums in allen Theme-Komponenten (Buttons, Chips, Cards, Switch, Slider, ProgressIndicator, NavigationBar)
- Umfassende Testsuite in `test/core/theme/design_system_and_nightwatch_test.dart` (10/10 Tests grün, gesamte Suite 55/55 Tests grün)
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 55/55 Tests grün

- Detailspezifikation: Informationsarchitektur, Startbildschirm, Setup-Assistent, Hierarchie der Warengruppen, alle Bildschirme mit IDs, Tokens für drei Modi, Komponenten, Texte, Bewegung, Barrierefreiheit

## 2026-09-25 – Design-Brief v0.3, Slice-Plan v0.11

- Dritter Farbmodus "Nachtwache" (Rot auf Schwarz) zur Schonung der Nachtsicht, umgesetzt in S-UI

## 2026-09-25 – Design-Brief v0.2, Slice-Plan v0.10

- Review der Stitch-Mockups: 12 verbindliche Designregeln, Hinweise je Bildschirm, Theme aus `technical_maritime_m3/DESIGN.md`
- Neuer Slice S-UI (nach S2a): Theme zentral, bereits gebaute Oberflächen angleichen

## 2026-09-24 – GEMINI.md v0.4

- Gehärtete Programmierregeln (feste Typen, keine versteckten Platzhalter, ehrliche Berichte, datengetrieben, Toleranz bei Kommazahlen, Cent-Beträge, Struktur, Testregeln); erweiterter Abschlussbericht mit Selbstprüfung

## 2026-09-24 – S2a: Korrektur Mengen-Engine nach Review

- Befunde 1–6 aus `docs/impl/REVIEW_S2_v0.1.md` und Programmierregeln 1–7 aus `GEMINI.md v0.4` vollständig umgesetzt
- Feste Enums für alle Katalog- und Mengenkonfigurationen; `FormatException` bei unbekannten Werten
- Strenge Einheitenkompatibilität in `UnitConverter` (nur g<->kg und ml<->l; `Packung` bedeutet reine Packungszahl)
- Gruppenausgleich `_applyGroupBalancing` nach `quantities_v0.4.json` (Deckung sicherstellen, Überdeckung abbauen)
- Frische Artikel: Automatische Aufteilung entfernt, Gesamtbedarf berechnet, Rest-Hinweis bei Überschuss
- Urlaubszuschlag (1.2) datengetrieben auf `holiday_snack_drink_uplift.applies_to_groups` angewendet
- Wasserbedarfs-Berechnung generisch über `CalculationBasis.perPersonDayRegion`
- Katalog-Validierungstest `catalog_validation_test.dart` über alle Einträge von `catalog_v0.7.json` und `quantities_v0.4.json`
- Umfassende Unit-Tests mit explizit kommentierten Rechenwegen und Randfällen (1 Person, 14 Tage, 0 Bordabende, nur Kinder, alle Vegetarier, keine Trinker, überschriebene Mengen)
- Vorschlag für das PRD: In `data/catalog_vX.Y.json` Gruppe `water` mit `need: { amount: 0, unit: "l", basis: "per_person_day_region" }` ausstatten (bisher `need: null`).
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 45/45 Tests grün

## 2026-09-24 – Review S2, Korrektur-Slice S2a

- `docs/impl/REVIEW_S2_v0.1.md`: 2 kritische, 2 hohe, 1 mittlerer, 2 niedrige Befunde
- Katalog v0.7, Quantities v0.4, PRD v0.16, Slice-Plan v0.9 (S2a mit Vorrang)

## 2026-09-24 – S3: Törn anlegen und Törnverlauf

- Mehrschritt-Assistent `TripWizardScreen` zum Anlegen eines Törns implementiert (Schritt 1: Basisdaten & Reisedauer, Schritt 2: Bootstyp, Revier & Kühlkapazität, Schritt 3: Crew-Zusammenstellung mit individuellen Profilen und Crew-Fragen zu Appetit & Alkohol)
- `TripService` mit reaktiver Mengen-Neuberechnung bei Änderungen an Restaurant-Schaltern oder Crew
- Tagesleiste `TripTimelineScreen` mit Schaltern für Mittag- und Abendessen (Bordküche vs. Restaurant)
- Reine Info-Felder für Hafenname und Tagestyp ohne Pflichtangaben
- CRUD für Einkaufsstopps (Hinzufügen, Umbenennen, Löschen) mit automatischem Löschschutz für den ersten Einkaufsstopp ("Ersteinkauf Basis")
- Reaktive Kennzahlenkarte zur Törn-Bilanz (Bord-Abendessen, Bord-Mittagessen, Restaurantbesuche)
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` alle 37 Tests grün

## 2026-09-24 – S2: Mengen-Engine mit Katalog und Konsumprofilen

- Reine Dart-Rechen-Engine `QuantityEngine` ohne Flutter-Abhängigkeit implementiert
- Alle 10 Rechenbasen umgesetzt: `per_person_day`, `per_person_day_region`, `per_person_week`, `per_person_board_evening`, `per_person_board_lunch`, `per_adult_evening`, `per_crew_week`, `per_trip`, `per_person_trip`, `check`
- Konsumprofile und Crew-Fragen integriert (Appetit-Aufschlag, Trinklevel, Nicht-Trinker, Kinderfaktor 0.6) inklusive Vorrang personenspezifischer Details vor Crew-Einstellungen
- Dynamische Revier-Wasserbedarfe aus `quantities_v0.3.json` (gemäßigt 2,0 l, Mittelmeer 2,5 l, heiß/abgelegen 3,5 l)
- Aufteilung: `split=equal` (anteilig oder gleichmäßig, mit Portionsunterstützung und Gruppenausgleich) sowie `split=each`
- Rundungslogik für Packungen: haltbare Artikel immer aufrunden (ceil), frische Artikel nur bei Überschuss <= 25 % aufrunden, sonst abrunden und Rest als Nachkauf unterwegs
- Reserve-Zuschlag (+10 %) gezielt nur auf haltbare Produkte (Haltbarkeit >= 14 Tage) angewendet
- Persistenz von Mengenangaben: Vom Nutzer überschriebene Packungszahlen bleiben bei Änderungen an Crew oder Reisedauer unangetastet
- Automatische Berechnung des Kühlraum-Bedarfs für die ersten 3 Tage mit Warnung bei Überschreitung der Kühlkapazität
- `CatalogRepository` zum Laden und Parsen von `catalog_v0.6.json` und `quantities_v0.3.json`
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` alle 31 Tests grün inkl. festem PRD-Referenzszenario (5 Erwachsene, 1 veg, 1 kein Alk, 7 Tage, Mittelmeer, 4 Bordabende)

## 2026-09-24 – S1: Datenmodell und lokale Datenbank

- Alle 8 Entitäten in Drift (SQLite) modelliert: `Trip`, `TripDay`, `CrewMember`, `ShoppingStop`, `ListItem`, `ListItemAllocation`, `Expense`, `KittyPayment`
- Automatische Initialisierung des ersten Einkaufsstopps ("Ersteinkauf Basis") und der `TripDays` (1..daysCount) beim Anlegen eines Törns
- Schutz vor Löschung des initialen Einkaufsstopps
- Strenge Allokationsvalidierung: Die Summe aller zugeordneten Teilmengen eines `ListItem` kann die Gesamtpackungszahl nicht überschreiten (`AllocationExceededException`)
- Ermittlung nicht zugeordneter Restmengen, die standardmäßig dem ersten Stopp zugeordnet sind
- DAOs für Trips, Vorratsliste und Bordkasse implementiert inkl. Riverpod-Provider
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 17/17 Tests grün (CRUD, Schema-Migration, Allokations-Constraint, Persistenz über DB-Neustart)

## 2026-09-24 – S0: Projekt-Setup und Architektur

- Flutter-Projekt im Repo-Root aufgesetzt (`com.hullq.proviantplaner`)
- Technische Leitplanken integriert: Riverpod, GoRouter, Drift, Flutter Secure Storage, Intl/Localizations
- Feature-First Ordnerstruktur angelegt (`lib/core`, `lib/features/<feature>/{data,domain,ui}`, `lib/l10n`)
- Zentrales Theme mit Blueprint Navy, Petrol Akzent und Amber Hinweisen gemäß Design-Brief
- Interfaces und Mock-Implementierungen für `HullqAuthService` und `HullqBackupService`
- Startbildschirm mit App-Name, dezentem "powered by HullQ" und 4 Hauptnavigationsreitern
- Validierung: `flutter analyze` 0 Fehler/Warnungen, `flutter test` 8/8 Tests grün, Android-Debug-APK gebaut und Start im Android-Emulator verifiziert

## 2026-09-23 – GEMINI.md v0.3 (Durchlauf-Modus)

- Gemini arbeitet alle freigegebenen Slices nacheinander ab, committet und pusht nach jedem grünen Slice auf main
- Pläne und Berichte in `docs/impl/`; Review gesammelt am Ende

## 2026-09-23 – Slice-Plan v0.8

- S0: Abnahme nur auf dem Android-Emulator, Paket-ID `com.hullq.proviantplaner`

## 2026-09-23 – GEMINI.md v0.2, Startprompt v0.1

- GEMINI.md: Darf/Darf nicht, Pflichtablauf mit Plan und Freigabe, Stoppregeln, Berichtsformat, kein Commit/Push durch Gemini
- `docs/PROMPT_SESSION_START_v0.1.md`: Startprompt und Folgeprompts

## 2026-09-23 – PRD v0.15, Katalog v0.6, Slice-Plan v0.7, Freigabe S2–S6

- Mengen vorläufig (Zucker gesenkt), Baseline folgt später
- Umsetzung mit Google AI Pro
- S2 bis S6 freigegeben; UI vorläufig bis Mockups, alles datengetrieben und im Theme zentral

## 2026-09-23 – Design-Brief v0.1

- `docs/design/DESIGN_BRIEF_v0.1.md`: Stilrichtung aus HullQ-CI, globaler Stil-Prompt und 9 Bildschirm-Prompts für Stitch, Animationshinweise für Flutter
- Ordner `docs/design/mockups/` für die Entwürfe

## 2026-09-23 – PRD v0.14, Katalog v0.5, Slice-Plan v0.6, Freigabe S1

- Törnverlauf: Mittags-/Abends-Restaurant pro Tag, optional Tagestyp und Hafenname; Einkaufsstopps mit manueller Zuordnung
- Törnablauf in fünf Phasen, Navigation mit vier Reitern
- Katalog v0.5: Rechenbasis pro Mittagessen an Bord
- S1 freigegeben

## 2026-09-23 – PRD v0.13, Freigabe S0

- Android zuerst, iOS später über Cloud-Build; Umsetzung mit Antigravity im lokalen Repo
- Abschnitt "Offen vor dem Start" (10 Punkte), Start kostenlos, Abo mit v1.1
- S0 für Gemini freigegeben; S1 nach Klärung von Törnverlauf und Törnablauf

## 2026-09-23 – PRD v0.12, Slice-Plan v0.5

- Bordkasse und Kostenteilung: gemeinsame Kasse und Einzelabrechnung, Kategorien, Beteiligung pro Person, "Skipper frei"
- Zahlungen nur anstoßen: EPC-QR-Code, PayPal-/Revolut-Links; Splitwise-Export später; keine Zahlungsabwicklung

## 2026-09-23 – PRD v0.11

- B2B-Kanal Charterfirmen: Törn-Code und Bestellung an den Proviantservice der Basis (beides v1.1)
- Slice-Plan: S6 so vorbereiten, dass eine zeitlich begrenzte Freischaltung per Code später ohne Umbau möglich ist

## 2026-09-23 – PRD v0.10, Quantities v0.3, Slice-Plan v0.4

- Liste zeigt Packungen statt Rechenwerte, +/− je Packung, Packungsgröße editierbar und gemerkt
- Intelligentes Runden (haltbar immer auf, frisch nur bis 25 % Überschuss) und Ausgleich innerhalb der Gruppe
- Appetit und Trinken als Crew-Fragen mit Aufschlag, Reserve für Ankertage getrennt, Einstufung pro Person optional

## 2026-09-23 – Katalog v0.4, PRD v0.9, Slice-Plan v0.3

- `docs/KATALOG_v0.4.md`, `data/catalog_v0.4.json`: alle 10 Kategorien im Schema Bedarfsgruppe → Variante (47 Gruppen, 212 Varianten), Technik mit Sichtbarkeit (Alltag auch beim Charter) und Prüflisten-Modus, Bordapotheke als Prüfliste
- `docs/PRD_v0.9.md`, `docs/SLICES_v0.3.md`: auf Katalog v0.4 umgestellt
- Status: noch nicht bereit für S0 (Baseline der Mengen offen)

## 2026-09-23 – Katalog v0.3 (in Arbeit)

- Neues Schema Kategorie → Bedarfsgruppe → Variante mit Packungsgröße und Haltbarkeit
- Kategorie Frühstück vollständig umgestellt; übrige Kategorien folgen
- Hinweis für Gemini: Katalog noch nicht als Bauvorlage verwenden

## 2026-09-23 – PRD v0.8, Katalog v0.2, Slice-Plan v0.2

- `docs/PRD_v0.8.md`: Vorratsliste als Kern, Menüplan optional (v1.1), Konsumprofile Essen/Trinken, Mengen überschreibbar, Einlagerungs-Checkliste, Charter oder eigenes Boot, Scope 6–7 Tage
- `docs/KATALOG_v0.2.md`, `data/catalog_v0.2.json`: Profilzuordnung und Einlagerungs-Hinweise pro Position
- `data/quantities_v0.2.json`: Appetit-Faktor durch Konsumprofile ersetzt, Kinderfaktor
- `docs/SLICES_v0.2.md`: S1–S4 an das neue Konzept angepasst
- `GEMINI.md`, `README.md` auf die neuen Dateien verwiesen

## 2026-09-23 – Vorratskatalog v0.1

- `docs/KATALOG_v0.1.md` und `data/catalog_v0.1.json`: 10 Kategorien, 71 Positionen mit Rechenbasis, Abteilung, Ernährungs-Tags und Charter-Modus
- Konzeptentscheidung: Die Vorratsliste ist der Kern der App, der Menüplan wird optional (wird in PRD v0.8 und Slice-Plan v0.2 nachgezogen)

## 2026-09-23 – Repo angelegt

- PRD v0.7, Slice-Plan v0.1, Mengentabelle v0.1 und Arbeitsanleitung für Gemini abgelegt
- Noch kein Code; nächster Schritt: S0 Projekt-Setup

## Vorschläge für das PRD

- (noch keine)

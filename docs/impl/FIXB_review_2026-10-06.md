# FIX-B Independent Review – 06.10.2026

Status: **AMENDMENT REQUIRED**

Reviewed implementation HEAD:

`e8290f2d43fbf60ce375bca162d4b6aa95af532e`

Reviewed against:
- `docs/impl/FIXB_release_reconciliation_2026-10-06.md`
- `docs/impl/FIXB_plan.md`
- `docs/impl/FIXB_supplemental_review_requirements_2026-10-06.md`
- actual production code and tests on `origin/main`

## Summary

The FIX-B core implementation is directionally and mathematically correct.

Verified:
- one `UnifiedLedgerResult` drives shared and individual settlement;
- all confirmed expenses enter group costs;
- personally paid expenses credit the payer;
- physical kitty cash is deposits minus only kitty-paid expenses;
- `MemberBalance` exposes factual deposits, personal payments and treasurer-held cash separately;
- no synthetic `paidInCents` zero-sum adjustment remains;
- shared transfers remain treasurer-centered;
- individual settlement uses the same balances and debt simplification;
- payment-source invariant is enforced on normal create/update/restore writes;
- canonical 4-person mixed case is implemented and tested;
- model-switch invariance is implemented for normal valid data;
- dedicated FIX-B suite contains 17 tests and the implementation report records 319/319 Flutter tests green.

However FIX-B is **not ready for Owner Acceptance** because the supplemental financial-integrity findings S1, S2, S4 and S5 remain open in production code. The implementation report itself correctly records these as pending.

## Finding A – Crew deletion can still destroy or invalidate financial history

**Severity: BLOCKING**

Current Trip UI still calls `TripDao.deleteCrewMember(member.id)` directly.

Current persistence behavior:
- personal expense payer FK uses `ON DELETE SET NULL`;
- kitty deposits use `ON DELETE CASCADE`;
- custom-split JSON has no FK;
- `treasurerMemberId` has no FK.

Therefore deleting a financially referenced crew member can currently:
- convert a valid person-paid expense into `isPaidFromKitty=false, paidBy=null`;
- silently delete historical deposits;
- leave orphaned custom-split IDs;
- leave a dangling explicit treasurer ID.

The new ledger detects some missing payer/deposit-member states, but prevention is required: historical money records must not be silently mutated merely because a crew member was removed.

### Required fix

Introduce a production deletion boundary used by the UI.

Before deleting a CrewMember, inspect the same Trip for references in:
- `Expenses.paidByCrewMemberId`;
- `KittyPayments.crewMemberId`;
- every Expense `customSplit`;
- `Trips.treasurerMemberId`.

If any such financial reference exists:
- reject deletion;
- keep every historical row unchanged;
- return/throw a typed domain result/error;
- show a clear localized explanation in the Crew UI.

Do not silently reassign payer, delete deposits, redistribute split shares or pick a new treasurer as part of deletion.

The existing "at least one crew member" rule remains.

## Finding B – Custom-split validation is incomplete

**Severity: BLOCKING**

`KittyEngine._validateLedgerInputs` currently validates payment source, payer membership and deposit membership, but does **not** validate `customSplitInCents`.

`distributeExpense` returns a custom split unchanged.

`_calculateCostShares` then adds arbitrary map keys to its local shares map, but `MemberBalance` is created only for actual current members.

Consequences:
- an orphaned member ID can absorb a cost share that appears in no MemberBalance;
- a split whose sum differs from the expense amount can break accounting truth;
- negative split values are not rejected.

### Required fix

Validate every custom split before calculation and at create/edit service boundaries:

- every member ID exists in the current Trip crew;
- every share is >= 0;
- sum of shares equals the Expense amount exactly in cents.

Invalid data must cause a typed ledger-validation failure, not silently produce balances/transfers.

Add tests for:
- orphaned split member;
- split sum too low;
- split sum too high;
- negative split;
- valid odd-cent split.

## Finding C – Backup restore does not remap custom-split CrewMember IDs

**Severity: BLOCKING**

`BackupCoordinator` remaps:
- treasurer ID;
- expense payer ID;
- deposit member ID;

but restores `customSplit` JSON unchanged.

Restored CrewMember IDs can differ from source IDs, so the restored split can reference stale IDs.

### Required fix

During v2 restore:
1. parse each custom split;
2. remap every old CrewMember ID through `crewIdMap`;
3. preserve exact cent values;
4. reject restore explicitly if a referenced old member cannot be mapped;
5. re-encode the remapped JSON.

Required proof:
- restored split keys are the new CrewMember IDs;
- exact split cents preserved;
- pre/post restore settlement balances are identical;
- missing referenced member fails explicitly.

Keep all existing PIVOT3-A/B backup tests green.

## Finding D – Currency integrity is still unsafe

**Severity: BLOCKING**

FIX-B does not implement FX conversion, which is correct.

But current production behavior still allows currency corruption:

- `Expense.currency` is persisted and backup/restore preserves it;
- the ledger ignores currency and sums all `amountInCents`;
- `ExpenseInput` has no currency;
- `addExpense` relies on DB default EUR;
- `updateExpense` hardcodes `currency: 'EUR'`;
- `restoreExpense` does not explicitly restore `exp.currency`.

Therefore a non-EUR Trip can be coerced to EUR, and legacy/restored mixed-currency expenses can be silently added as if they were one currency.

### Required FIX-B policy

FIX-B remains **single-currency settlement only**.

Canonical ledger currency is `Trip.currency`.

For all settlement calculations:
- every Expense currency must exactly equal Trip currency;
- deposits are denominated in Trip currency;
- if any Expense differs, settlement is invalid/unsupported;
- no balances or transfers may be presented;
- no FX rate is invented.

Normal writes must use Trip currency.

Edit, undo/restore and backup/restore must preserve currency exactly.

Required tests:
- EUR Trip normal;
- non-EUR single-currency Trip normal without coercion;
- mixed EUR/USD Trip produces typed validation failure;
- edit preserves currency;
- undo restore preserves currency;
- backup restore preserves currency.

## Finding E – Settlement PDF still contains a second, wrong accounting formula

**Severity: BLOCKING**

`PdfExportService.generateSettlementPdf` currently independently calculates:

`totalExpenses = sum(all expenses)`

`totalDeposits = sum(all deposits)`

`balance = totalDeposits - totalExpenses`

This contradicts the unified ledger whenever a person paid an expense.

Canonical mixed case:
- deposits 400 EUR;
- kitty-paid expenses 200 EUR;
- person-paid expenses 120 EUR;
- correct physical kitty cash = 200 EUR;
- current PDF formula displays 80 EUR.

The PDF therefore can disagree materially with the app/engine even though the engine itself is fixed.

### Required fix

Settlement PDF must use `TripKittyData` / unified-ledger result values only.

Do not independently reimplement financial formulas in the PDF layer.

At minimum:
- total group expenses from ledger result;
- physical kitty cash from ledger result;
- member contribution/share/net from unified MemberBalances;
- transfers from unified result.

Individual person-paid-only mode must not render a fictitious negative kitty balance.

Required tests must verify actual PDF summary source values, not merely a valid `%PDF` header.

## Finding F – Invalid ledger errors currently render as "Trip not found"

**Severity: BLOCKING UX / ERROR-INTEGRITY**

The supplemental requirements explicitly require invalid historical financial data to be surfaced as a structured correction problem.

Current `KittyScreen` does:

```dart
if (asyncData.hasError) {
  return NotFoundScreen(message: l10n.tripNotFound);
}
```

So a ledger-validation failure such as a missing payer would misleadingly tell the user that the Trip does not exist.

### Required fix

Introduce a typed financial/ledger validation exception or result.

The Bordkasse and Settlement UI must distinguish:
- real Trip-not-found;
- financial-data-invalid / settlement-needs-correction.

For financial validation:
- show a clear localized non-destructive error state;
- do not display balances/transfers;
- do not pretend the Trip is missing.

Localization required in DE/EN/ES/FR/HR/PT.

## Finding G – Treasurer resolution

**Status: CLOSED**

`KittyEngine._resolveTreasurer` is now shared by unified/shared/individual calculation.

It correctly falls back:
1. valid explicit treasurer;
2. skipper/free fallback;
3. first current member.

Both calculation modes receive the same `treasurerMemberId`, and the normal model-switch test is present.

The amendment should add explicit tests for:
- no explicit treasurer;
- dangling explicit treasurer ID;
- both modes resolve the same member and preserve net balances.

This is strengthening proof, not a production redesign.

## Finding H – Treasurer-centered shared routing

**Status: CLOSED / PRODUCT DECISION**

No change required.

Shared mode remains member ↔ treasurer even when the treasurer is temporarily a pass-through.

Individual mode may use simplified direct transfers.

Record this explicitly in the final report.

## Original FIX-B core findings

The original core FIX-B implementation is accepted as the amendment baseline and should not be rewritten.

Retain:
- UnifiedLedgerResult;
- factual MemberBalance components;
- payment source invariant;
- canonical mixed case;
- positive/zero/negative kitty handling;
- model-switch accounting truth;
- shared treasurer-centered routing;
- individual debt simplification;
- real ExpenseSheet person-payer path;
- existing 17 FIX-B tests.

## Amendment boundary

The amendment is limited to:
1. crew-deletion financial-reference guard;
2. complete custom-split validation;
3. custom-split backup ID remapping;
4. deterministic treasurer fallback proof;
5. single-currency ledger guard + currency preservation;
6. settlement PDF unified-ledger sourcing;
7. typed invalid-ledger UI state;
8. tests/report/CHANGELOG.

Do not reopen ledger formulas unless a new regression proves a core defect.

Do not start DATA1, Watermaker, PIVOT2, RECEIPT1, GUEST1 or UX-D.

## Required QA

After amendment:
- dedicated FIX-B core + supplemental tests;
- all Kitty tests;
- backup coordinator tests;
- PDF export tests;
- PIVOT1;
- PIVOT3-A/B;
- `flutter analyze`;
- full `flutter test`.

Only actual executed totals may be reported.

## Gate

FIX-B remains:

**IN REVIEW / AMENDMENT REQUIRED**

PIVOT2 remains ON HOLD.

After amendment push: STOP for independent re-review.

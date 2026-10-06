# FIX-B Supplemental Review Requirements – 06.10.2026

Status: **PENDING REVIEW REQUIREMENTS — applies to the currently running FIX-B implementation**

Context:
- FIX-B implementation was already started from `docs/PROMPT_SESSION_START_v0.7.md`.
- A revised external review (Claude v0.2) identified additional financial-integrity edge cases after that implementation prompt had already started.
- These points do **not** cancel the running implementation.
- They are mandatory independent-review criteria before FIX-B can become READY FOR OWNER ACCEPTANCE.
- If the running implementation does not already cover them, they must be handled by a narrow FIX-B review amendment.

Canonical FIX-B remains:
- `docs/impl/FIXB_release_reconciliation_2026-10-06.md`
- `docs/impl/FIXB_plan.md`

## S1 – Crew deletion must not destroy financial history

Classification: **BLOCKING**

Current production behavior is unsafe:

- `Expenses.paidByCrewMemberId` uses FK `ON DELETE SET NULL`.
  Deleting a crew member who personally paid an expense turns a valid person-paid expense into:
  - `isPaidFromKitty == false`
  - `paidByCrewMemberId == null`

- `KittyPayments.crewMemberId` uses FK `ON DELETE CASCADE`.
  Deleting a member silently deletes that member's historical kitty deposits.

- expense `customSplit` is JSON keyed by CrewMember IDs and has no FK.
  Deleting a referenced member leaves an orphaned split key.

- `Trips.treasurerMemberId` is not an FK.
  Deleting the active treasurer can leave a dangling treasurer ID.

The current Trip UI calls `TripDao.deleteCrewMember` directly and performs no financial-reference guard.

### Required FIX-B policy

Historical money data must not be silently rewritten or deleted.

Before a crew member can be deleted, a production service boundary must check whether the member is referenced by any of:
- personal expense payer;
- kitty deposit;
- custom expense split;
- active treasurer.

If any financial reference exists:
- deletion is rejected;
- the UI shows a clear localized explanation;
- the user must resolve/reassign the financial relationship explicitly before deletion.

Do **not** silently:
- change historical payer;
- delete deposits;
- redistribute custom splits;
- choose a different treasurer while deleting.

If no financial reference exists and the trip still has at least one crew member, deletion may proceed normally.

### Existing invalid data

The unified ledger must explicitly detect and refuse to produce a normal settlement for invalid historical records such as:
- person-paid expense with missing payer;
- custom-split member ID that is not in the current trip crew;
- custom split whose values do not sum exactly to the expense amount;
- invalid negative split shares.

Do not silently drop missing members from a split and do not fabricate a balancing payer.

Expose a structured validation problem so the UI can show that the settlement needs correction rather than displaying false balances/transfers.

### Tests

At minimum:
1. deleting unreferenced crew member succeeds;
2. deleting member who personally paid an expense is rejected and expense remains intact;
3. deleting member with kitty deposit is rejected and deposit remains intact;
4. deleting member referenced by custom split is rejected;
5. deleting active treasurer is rejected until treasurer is explicitly changed;
6. invalid legacy person-paid expense with null payer yields settlement validation failure, not false balances;
7. orphaned custom-split key yields validation failure;
8. custom split sum mismatch yields validation failure.

## S2 – Custom-split integrity and backup restore ID remapping

Classification: **BLOCKING**

Current backup restore remaps:
- payer CrewMember ID;
- deposit CrewMember ID;
- treasurer ID;

but restores `Expenses.customSplit` JSON unchanged.

Because restored CrewMember IDs can differ from original IDs, custom split keys can point to old/nonexistent IDs after restore.

### Required fix

During backup restore:
- parse custom-split JSON;
- remap every member ID through the same `crewIdMap`;
- preserve exact cent amounts;
- fail the restore/expense restore explicitly if a referenced old member cannot be mapped;
- re-encode the remapped split.

Do not silently remove a split member.

Also validate custom splits on normal create/edit:
- member IDs belong to the same trip;
- each share is >= 0;
- total split equals `amountInCents` exactly.

### Tests

At minimum:
1. v2 backup with custom split restores to new CrewMember IDs and preserves exact shares;
2. restored custom split produces the same cost shares/net balances as before backup;
3. missing custom-split member in backup is rejected or surfaced as explicit restore validation failure;
4. create/edit custom split with wrong total is rejected;
5. create/edit custom split with foreign/nonexistent member ID is rejected.

PIVOT3-A/B backup regressions must remain green.

## S3 – Treasurer resolution must be one deterministic rule in both modes

Classification: **BLOCKING**

Shared Kitty currently has a fallback resolver:
1. explicit `treasurerMemberId` when it points to a current member;
2. otherwise first member matching the existing skipper/free fallback;
3. otherwise first member.

Individual settlement historically receives no treasurer at all.

FIX-B model-switch invariance requires the **same resolved treasurer** whenever a remaining kitty cash asset exists.

### Required fix

Centralize treasurer resolution in one deterministic production function and use it for:
- shared ledger;
- individual ledger;
- TripKittyData/UI accessor;
- model-switch calculations.

Legacy dangling explicit treasurer IDs must fall through to the same deterministic fallback rather than producing a mode-specific null/different treasurer.

### Tests

At minimum:
1. explicit valid treasurer resolves identically in both modes;
2. no explicit treasurer + mixed history resolves same fallback in both modes;
3. dangling explicit treasurer ID resolves same fallback in both modes;
4. shared → individual → shared preserves every member's cent-exact net balance in all three cases.

## S4 – Currency integrity: never add unlike currencies

Classification: **BLOCKING FINANCIAL GUARDRAIL**

FIX-B does not implement FX conversion or multi-currency settlement.

However:
- `Expense.currency` is persisted;
- backup/restore preserves arbitrary stored currencies;
- the current engine sums `amountInCents` regardless of currency;
- current edit/undo paths can normalize/lose currency information (`updateExpense` currently writes EUR and `restoreExpense` does not explicitly restore currency).

Therefore the ledger must not silently interpret, for example, 10000 EUR cents + 10000 USD cents as 20000 units of one currency.

### Required FIX-B behavior

FIX-B remains **single-currency settlement only**.

Use the Trip currency as the ledger currency.

For every calculation:
- all expenses must match `trip.currency`;
- deposits are interpreted in `trip.currency`;
- if any expense currency differs, settlement is unsupported/invalid;
- no balances or transfers are presented as if conversion had occurred;
- show a clear localized message;
- do not invent exchange rates.

Preserve stored currency through edit, undo/restore and backup/restore.

New writes must use the trip's currency rather than an unrelated implicit currency default.

This does **not** implement the future multi-currency feature.

### Tests

At minimum:
1. all-EUR trip behaves normally;
2. single non-EUR trip uses its own trip currency without coercing data to EUR;
3. mixed EUR/USD data is detected and settlement is blocked/invalid;
4. editing an expense preserves its currency;
5. undo/restore preserves its currency;
6. backup/restore preserves currency;
7. no cross-currency sum reaches member balances/transfers.

## S5 – Settlement PDF must use the unified ledger, not a second formula

Classification: **BLOCKING USER-VISIBLE OUTPUT**

Current `PdfExportService.generateSettlementPdf` independently computes:

`balance = totalDeposits - totalExpenses`

where `totalExpenses` includes all expenses.

After FIX-B this is wrong whenever an expense was paid personally.

Canonical mixed example:
- deposits = 400 EUR;
- kitty-paid expenses = 200 EUR;
- person-paid expenses = 120 EUR;
- correct kitty cash = 200 EUR;
- old PDF formula would display 80 EUR.

### Required fix

The settlement PDF must source all accounting totals from the same unified ledger/result used by the UI.

It must not reimplement settlement arithmetic independently.

At minimum:
- total group expenses = unified-ledger total expenses;
- kitty cash/end balance = unified-ledger kitty cash;
- member paid/contribution, share and net = unified member balances;
- transfers = unified transfers.

For individual mode, do not fabricate a negative "Kassen-Endstand" merely because there are expenses and no deposits.

If the PDF summary differs by mode, it still must derive from the ledger.

### Tests

At minimum:
1. canonical mixed case produces PDF summary data with group expenses 320 EUR and kitty cash 200 EUR;
2. person-paid-only individual case does not show a fictitious negative kitty cash balance;
3. PDF member balances/transfers correspond exactly to engine/TripKittyData values;
4. existing valid PDF generation/header tests remain green.

## S6 – Treasurer-centered shared transfer routing

Classification: **DECIDED / NOT A BLOCKER**

The revised external review notes that treasurer-centered routing can make the treasurer a pass-through when cash is empty.

This is already an explicit FIX-B product decision and matches the existing owner-accepted Bordkasse UX:
- shared mode transfers remain member ↔ treasurer;
- individual mode may use debt simplification.

No redesign is required in FIX-B.

The implementation report should explicitly record this choice.

## Review gate

Before FIX-B can be classified READY FOR OWNER ACCEPTANCE, independent review must verify:
- original FIX-B criteria;
- S1 crew/financial-history protection;
- S2 custom-split integrity + backup remapping;
- S3 deterministic treasurer resolution;
- S4 currency guardrail;
- S5 PDF consistency.

If the currently running Gemini implementation does not include all of these, do **not** reject the whole FIX-B implementation. Issue one narrow FIX-B review-amendment prompt for the missing supplemental findings.

PIVOT2 remains ON HOLD.
DATA1 and Watermaker reserve work remain unreleased.

# FIX-B Final Acceptance Review – 07.10.2026

Status: **READY FOR OWNER ACCEPTANCE**

Reviewed implementation HEAD:

`af8ee33ad206e04d22b1097a1a11675a45863314`

Reviewed against:
- `docs/impl/FIXB_release_reconciliation_2026-10-06.md`
- `docs/impl/FIXB_review_2026-10-06.md`
- `docs/impl/FIXB_amendment_review_2026-10-07.md`
- `docs/impl/FIXB_final_acceptance_review_2026-10-07.md`
- actual production code and tests on `origin/main`
- GitHub Actions for `af8ee33...`

## Final result

No remaining blocking finding was identified in the released FIX-B scope.

FIX-B is therefore classified:

**READY FOR OWNER ACCEPTANCE**

This is an independent review classification only. Owner Acceptance has not yet been recorded.

## Verified implementation

### Unified accounting truth
- Shared Kitty and Individual Settlement use one Unified Ledger.
- Every confirmed group expense enters total group cost.
- Personally paid group expenses credit the actual payer.
- Physical kitty cash is:
  `total deposits - kitty-paid expenses`.
- Remaining kitty cash is represented explicitly as treasurer-held group cash.
- No synthetic paid values are used to force zero-sum.
- Final member net balances remain cent-exact and sum to zero for valid input.

### Shared / Individual model behavior
- Shared transfers remain treasurer-centered.
- Individual Settlement uses debt simplification on the same balances.
- Model switching preserves economic balances.
- Deterministic treasurer resolution is shared across both modes.

### Financial-history integrity
- Crew deletion is routed through a guarded production service.
- Crew with payer/deposit/custom-split/treasurer financial references cannot be deleted.
- Historical deposits, payer identity and split participation are not silently destroyed.

### Custom splits
- member IDs must belong to the Trip crew;
- negative shares are rejected;
- split sum must equal the Expense amount exactly;
- create/update boundaries validate splits;
- backup restore remaps split member IDs through restored Crew IDs;
- missing restore mappings fail explicitly.

### Currency integrity
FIX-B remains single-currency only.

Verified:
- Trip currency is the ledger currency;
- mixed-currency expenses are rejected;
- new Expense writes use Trip currency;
- Edit/Undo preserve currency;
- Backup/Restore preserves Trip and Expense currency;
- USD ledger calculation succeeds without coercion to EUR;
- Kitty overview, Settlement, Expense entry, Expense edit and Deposit entry display the actual Trip currency;
- EUR presentation remains intact.

No FX or conversion behavior was added.

### EPC / payment safety
- EPC/GiroCode remains EUR-only.
- Non-EUR settlement never constructs a EUR EPC QR from foreign-currency cents.
- Explicit user-supplied PayPal links are retained.
- Auto-generated amount-bearing PayPal fallback is available only for EUR.
- Non-EUR without an explicit PayPal link receives no ambiguous amount-bearing generated PayPal URL.
- Manual/copy/share payment paths remain available and show actual Trip currency.

### Settlement PDF
- Settlement summary sources totals/balances/transfers from Unified Ledger results.
- Canonical mixed case:
  - total group expenses 320 EUR;
  - physical kitty cash 200 EUR.
- Pure Individual person-paid case does not fabricate negative kitty cash.
- PDF formats using Trip currency.

### Error integrity
Kitty and Settlement UI distinguish:
1. `LedgerValidationException` → settlement-data correction state;
2. `TripNotFoundException` → Trip not found;
3. unexpected technical error → generic technical error with retry/back.

Unexpected errors are not mislabeled as missing Trips and raw exception messages are not used as the primary end-user message.

## Final currency-entry findings N–P

### Finding N – ExpenseSheet currency awareness — CLOSED
Verified:
- required `currency` parameter;
- production callers provide Trip currency;
- amount field uses actual Trip currency;
- custom-split fields use actual Trip currency;
- USD Add journey stores USD;
- USD Edit journey preserves USD;
- EUR regression remains green.

### Finding O – PaymentSheet currency awareness — CLOSED
Verified:
- required `currency` parameter;
- production callers provide Trip currency;
- amount field and total use Trip currency;
- USD real UI journey persists deposits and ledger remains correct;
- EUR regression remains green.

### Finding P – PayPal non-EUR fallback guard — CLOSED
Verified helper and production Settlement behavior:
- explicit link returned unchanged;
- EUR no-link fallback can include the amount;
- non-EUR no-link returns null;
- production PayPal button is disabled for that non-EUR no-link state;
- USD Share/Bank paths remain available;
- EUR fallback regression remains green.

## Acceptance proof

Implementation report records:

- `flutter analyze`: no issues;
- `fix_b_supplemental_amendment_test.dart`: 48/48;
- `fix_b_unified_ledger_test.dart`: 17/17;
- `kitty_ui_test.dart`: 6/6;
- full Flutter suite: 369/369.

GitHub Actions on reviewed HEAD:
- Flutter Analyze & Test: **SUCCESS**
- Backend Typecheck & Vitest: **SUCCESS**

## Scope discipline

No later product slice was started as part of FIX-B.

Still not released:
- DATA1;
- Watermaker reserve amendment;
- PIVOT2;
- RECEIPT1;
- GUEST1;
- UX-D;
- CAT1;
- B3/B4/B5;
- Store publication.

## Remaining risks

No blocking risk remains inside the accepted FIX-B scope.

General future risks outside FIX-B remain subject to their own release/reconciliation gates.

## Gate

FIX-B is now:

**READY FOR OWNER ACCEPTANCE**

Do not close Issue #27 or record Owner Acceptance until the Owner explicitly accepts FIX-B.

Do not automatically release the next slice after Owner Acceptance.

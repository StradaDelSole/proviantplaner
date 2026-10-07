# FIX-B Final Acceptance Review – 07.10.2026

Status: **AMENDMENT REQUIRED — CURRENCY ENTRY SURFACES ONLY**

Reviewed final-amendment HEAD:

`dcf273f37faa4d3b621054d3894a72d0543d3e73`

Reviewed against:
- `docs/impl/FIXB_release_reconciliation_2026-10-06.md`
- `docs/impl/FIXB_review_2026-10-06.md`
- `docs/impl/FIXB_amendment_review_2026-10-07.md`
- actual production code/tests on `origin/main`
- GitHub Actions for `dcf273f...`

## Verified closed

The previous review findings are now closed in production code:

- Unified Ledger accounting truth — closed.
- Crew deletion financial-history guard — closed.
- Custom split validation — closed.
- Custom split backup ID remap — closed.
- deterministic treasurer resolution — closed.
- single-currency ledger validation — closed.
- edit/undo/backup currency preservation — closed.
- Settlement PDF unified-ledger sourcing — closed.
- LedgerValidation / TripNotFound / technical-error UI distinction — closed.
- currency-aware KittyScreen balances — closed.
- currency-aware SettlementScreen transfers/totals — closed.
- EPC QR is suppressed for non-EUR settlement — closed.
- real Crew delete UI proof — closed.
- update custom-split proof — closed.
- non-EUR backup/restore proof — closed.

CI on `dcf273f37faa4d3b621054d3894a72d0543d3e73`:
- Flutter Analyze & Test: SUCCESS.
- Backend Typecheck & Vitest: SUCCESS.

Implementation report records 359/359 full Flutter tests green and analyze clean.

## Finding N – ExpenseSheet still hard-codes EUR

**Severity: BLOCKING FINANCIAL UX CONSISTENCY**

The final amendment made the overview and settlement output currency-aware, but `ExpenseSheet` still presents every amount as Euro:

- main amount field: `suffixText: '€'`;
- every custom-split amount field: `suffixText: '€'`;
- internal variable naming remains Euro-specific, though the cent parsing itself is currency-neutral.

`ExpenseSheet.show` currently receives:
- tripId;
- kittyModel;
- members;
- optional expense;

but not the Trip currency.

Therefore a valid USD Trip can display:
- KittyScreen: USD;
- SettlementScreen: USD;
- PDF: USD;

and then open Add/Edit Expense showing `€`.

This directly violates the prior accepted requirement:

> For all Bordkasse/Settlement presentation, display Trip.currency; do not hard-code EUR/€ for Trip amounts.

### Required fix

Make ExpenseSheet explicitly currency-aware.

Preferred minimal change:
- add required `currency` argument to `ExpenseSheet` / `ExpenseSheet.show`;
- all production callers pass `data.trip.currency`;
- amount suffix uses currency-aware display:
  - EUR may show `€`;
  - non-EUR shows the currency code, e.g. `USD`;
- custom-split fields use the same currency;
- no FX logic;
- stored cents and service behavior remain unchanged.

When editing an existing valid expense, Trip currency remains authoritative because the ledger already enforces expense currency == Trip currency.

## Finding O – PaymentSheet / deposits still hard-code EUR

**Severity: BLOCKING FINANCIAL UX CONSISTENCY**

`PaymentSheet` is the production UI for common-kitty deposits.

It still contains:
- `Wie viel zahlt jeder ein? (€)`;
- `suffixText: '€'`;
- submit summary `Einzahlungen speichern (... €)`;
- Euro-specific variable names.

Deposits have no separate persisted currency because they are intentionally denominated in the Trip's single ledger currency.

Therefore the UI must display the Trip currency.

### Required fix

Make PaymentSheet explicitly currency-aware.

Preferred minimal change:
- add required `currency` argument to `PaymentSheet` / `PaymentSheet.show`;
- production caller passes `data.trip.currency`;
- amount field and total submit summary use the actual Trip currency;
- use `formatMoneyCents` or an equivalent shared formatting helper for the total;
- no DB/schema change;
- no FX.

Do not introduce multi-currency deposits.

## Finding P – non-EUR PayPal fallback must not imply an unlabelled foreign amount

**Severity: SAFETY GUARD / NARROW**

`SettlementScreen._buildShareRow` currently creates a fallback when no explicit PayPal link is stored:

`https://paypal.me/<name>/<numeric amount>`

That fallback contains the numeric amount but no explicit Trip currency in the generated URL.

For non-EUR Trips, FIX-B must not silently hand an external payment provider an ambiguous amount that may be interpreted in another/default currency.

### Required behavior

For EUR:
- keep existing behavior.

For non-EUR:
- if a user-supplied PayPal link exists, it may be opened as stored;
- do not generate an amount-bearing PayPal fallback from the transfer cents;
- either use a non-amount generic fallback/link path or disable that generated fallback and keep the existing manual/copy/share/Revolut paths;
- all displayed/shared amount text remains in actual Trip currency.

Do not implement PayPal currency conversion or provider-specific FX.

## Required proof

Add real widget tests for a USD Trip:

### ExpenseSheet
1. open Add Expense from the real KittyScreen flow;
2. amount field shows USD and no €;
3. enable custom split;
4. every split input shows USD and no €;
5. save a USD expense;
6. persisted expense currency remains USD.

### Expense edit
1. open existing USD expense;
2. edit sheet shows USD;
3. save;
4. currency remains USD.

### PaymentSheet
1. open Add Deposit from real shared-Kitty UI;
2. amount field shows USD;
3. submit summary shows USD and no €;
4. save;
5. deposit affects USD ledger normally.

### EUR regression
- ExpenseSheet and PaymentSheet continue to show EUR/€ appropriately.

### PayPal non-EUR guard
- USD transfer without explicit PayPal link does not produce/open an amount-bearing generated PayPal URL.
- EUR behavior remains unchanged.

## Accepted baseline — do not reopen

Do not change:
- Unified Ledger formulas;
- MemberBalance accounting;
- crew deletion guard;
- custom split validation/remap;
- treasurer resolution;
- currency mismatch validation;
- PDF settlement logic;
- technical error handling;
- EPC EUR-only guard;
- existing final-amendment proofs.

## Scope exclusions

Do not add:
- FX;
- exchange rates;
- multi-currency settlement;
- currency selector;
- schema changes;
- DATA1;
- Watermaker work;
- PIVOT2;
- RECEIPT1;
- GUEST1;
- UX-D.

## Gate

FIX-B remains:

**IN REVIEW / AMENDMENT REQUIRED**

Only Findings N–P and their tests are released.

After amendment push: STOP for independent final re-review / Owner Acceptance.

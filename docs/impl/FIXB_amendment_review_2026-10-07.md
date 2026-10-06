# FIX-B Amendment Independent Re-Review – 07.10.2026

Status: **FINAL NARROW AMENDMENT REQUIRED**

Reviewed amendment HEAD:

`317550e454c7fc9bed978e1ade66dde0476f2fb2`

Reviewed against:
- `docs/impl/FIXB_release_reconciliation_2026-10-06.md`
- `docs/impl/FIXB_review_2026-10-06.md`
- `docs/impl/FIXB_supplemental_review_requirements_2026-10-06.md`
- actual production code/tests on `origin/main`
- GitHub Actions for amendment HEAD

## Verified closed

The amendment successfully closes the previously blocking production findings:

### S1 / Crew deletion financial guard — CLOSED
- Production UI now calls `TripService.deleteCrewMemberSafely`.
- Financial references checked:
  - personal payer;
  - kitty deposit;
  - custom split;
  - active treasurer.
- Referenced members are not deleted.
- Existing minimum-one-person protection remains.

### S2 / Custom split validation — CLOSED
- ledger validates member IDs;
- negative shares rejected;
- exact cent sum required;
- service create/update boundary also validates valid Trip crew.

### S2 / Backup custom-split remap — CLOSED
- restore remaps custom-split member IDs through `crewIdMap`;
- missing member mapping fails restore explicitly;
- test proves pre/post restore cost shares and net balances are equal.

### S3 / Treasurer resolution — CLOSED
- one deterministic resolver is used by shared/individual calculations;
- explicit, missing and dangling treasurer IDs are tested;
- model-switch cent-exact balance invariance remains green.

### S4 / Ledger currency guard — CORE CLOSED
- ledger receives Trip currency;
- mismatching expense currency throws typed `currencyMismatch`;
- add uses Trip currency;
- update preserves existing currency;
- undo/restore preserves expense currency;
- no FX conversion introduced.

### S5 / Settlement PDF ledger sourcing — CLOSED
- `SettlementPdfSummary` uses unified calculation results;
- canonical mixed case yields 320 EUR group expense and 200 EUR kitty cash;
- pure individual mode no longer fabricates negative kitty cash;
- PDF uses Trip currency.

### Invalid-ledger financial state — CORE CLOSED
- `LedgerValidationException` is typed;
- KittyScreen and SettlementScreen show dedicated "settlement needs checking" state for ledger validation;
- false balances/transfers are not rendered for that state.

### CI
On amendment HEAD `317550e454c7fc9bed978e1ade66dde0476f2fb2`:
- Flutter Analyze & Test: SUCCESS
- Backend Typecheck & Vitest: SUCCESS

Implementation report records:
- 28/28 supplemental amendment tests;
- 17/17 FIX-B core tests;
- 73/73 Kitty tests;
- 349/349 full Flutter tests;
- analyze clean.

## Finding I – Unexpected technical errors are still mislabeled as "Trip not found"

**Severity: BLOCKING ERROR-INTEGRITY**

The prior review explicitly required the UI to distinguish at least:
1. actual Trip not found;
2. financial/ledger validation error;
3. unexpected technical error.

The amendment correctly handles case 2.

However both `KittyScreen` and `SettlementScreen` still route every non-`LedgerValidationException` provider error to:

`NotFoundScreen(message: l10n.tripNotFound)`

`TripNotFoundException` exists but is not used as the explicit discriminator in the UI.

Consequences:
- database/read failure;
- parser failure;
- unexpected service exception;

can still be presented as if the Trip itself does not exist.

### Required fix

In both KittyScreen and SettlementScreen:

- `LedgerValidationException` → dedicated settlement-invalid state;
- `TripNotFoundException` → NotFoundScreen;
- every other error → generic technical-error state using existing localization where possible, with safe back/retry behavior.

Do not expose raw exception text as the main user message.

### Required tests

For both screens:
1. LedgerValidationException → settlement-invalid state;
2. TripNotFoundException → Trip-not-found state;
3. generic Exception/StateError → generic technical-error state and **not** Trip-not-found.

## Finding J – Non-EUR settlement UI / EPC payment path still coerces presentation to EUR

**Severity: BLOCKING FINANCIAL CORRECTNESS**

FIX-B now explicitly supports a single non-EUR Trip currency at ledger level and preserves that currency through writes/PDF.

But current settlement UI/domain presentation still contains hard-coded Euro behavior:

### KittyScreen
- header contains `EUR (€) TABULAR`;
- local `_formatCents` always appends `€`.

### MemberBalance
- `formattedNetBalance` always formats with `€`.

### PaymentTransfer
- `formattedAmount` always formats with `€`.

### SettlementScreen
- uses `transfer.formattedAmount` throughout;
- other total formatting appends `€`.

### EPC QR
`EpcQrPayload.toEpcString()` always encodes:
`EUR<amount>`.

Therefore a restored/valid single-currency USD Trip can:
- calculate as USD correctly;
- render balances as Euro in the UI;
- create an EPC QR requesting the same numeric amount in EUR.

That is a financial correctness defect.

### Required FIX-B policy

FIX-B remains single-currency; still no FX.

For all Bordkasse/Settlement presentation:
- display `Trip.currency`;
- do not hard-code EUR/€ for Trip amounts;
- centralize a small amount formatter that accepts cents + currency.

For EPC QR:
- current EPC payload remains EUR-only;
- only expose/generate EPC QR when `Trip.currency == 'EUR'`;
- for non-EUR Trip, do **not** create a EUR QR from the foreign-currency cent amount;
- retain safe alternatives already available (manual/copy/share payment details) using the actual Trip currency;
- show a calm localized explanation that GiroCode/EPC QR is available only for EUR;
- do not implement FX or currency conversion.

Do not modify IBAN validation or EPC EUR behavior for true EUR Trips.

### Required tests

1. USD Trip KittyScreen displays USD, not € / EUR label;
2. USD SettlementScreen displays transfer amount with USD;
3. USD Trip does not construct/render `EpcQrWidget`;
4. USD Trip shows localized EUR-only QR explanation or safe non-QR payment path;
5. EUR Trip still renders EPC QR and encodes exact EUR amount;
6. PDF USD behavior remains green.

## Proof gap K – real Crew deletion UI journey missing

**Severity: ACCEPTANCE PROOF**

Production code is correctly wired to `deleteCrewMemberSafely`, but the supplemental test file tests the service boundary, not the actual TripOverview delete interaction requested by the review.

Add one real widget/integration journey:
- open TripOverview;
- attempt delete of financially referenced member;
- localized blocking Snackbar visible;
- reload DB;
- member still exists;
- referenced expense/deposit remains unchanged.

This is proof strengthening; no domain redesign.

## Proof gap L – update custom-split service boundary

**Severity: ACCEPTANCE PROOF**

The same production validator is used by add/update, but current explicit test covers invalid custom split on add.

Add a direct update regression:
- valid existing expense;
- update with foreign member / sum mismatch;
- update rejected;
- persisted expense remains unchanged.

## Proof gap M – backup currency preservation

**Severity: ACCEPTANCE PROOF**

Backup code serializes/restores currency, but the current dedicated backup tests are EUR-only.

Add one backup/restore regression:
- non-EUR Trip;
- non-EUR Expense;
- backup + restore;
- Trip currency and Expense currency unchanged;
- restored ledger computes without currencyMismatch.

## Accepted boundaries

Do not reopen:
- UnifiedLedger formulas;
- canonical mixed case;
- shared treasurer-centered transfer routing;
- individual debt simplification;
- crew-deletion financial guard;
- custom-split backup remap;
- PDF accounting formulas.

Do not add:
- FX conversion;
- multi-currency settlement;
- currency selector/product redesign;
- DATA1;
- Watermaker amendment;
- PIVOT2;
- RECEIPT1;
- GUEST1;
- UX-D.

## Gate

FIX-B remains:

**IN REVIEW / FINAL NARROW AMENDMENT REQUIRED**

Only Findings I–J plus proof gaps K–M are released.

After push: STOP for independent final re-review / Owner Acceptance.

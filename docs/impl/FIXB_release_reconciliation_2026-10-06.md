# FIX-B Release Reconciliation – Unified Settlement Ledger – 06.10.2026

Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Trigger:
- confirmed external-review Finding F1
- `docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md`
- `docs/PRODUCT_EXPENSE_RECEIPTS_v0.1.md`
- `docs/impl/FEEDBACK_R1_v0.1.md`

## Problem

The current accounting engine uses two incompatible truths.

In `sharedKitty`:
- only expenses with `isPaidFromKitty == true` are included in total expenses and cost shares;
- a person-paid group expense is omitted from settlement.

In `individualSettlement`:
- all expenses enter cost shares;
- only person-paid expenses create payer credit;
- historical/common-kitty expenses have no person payer and can make balances fail to represent the actual common-cash asset.

The UI already permits both payment sources in shared-kitty mode:
- common kitty;
- a specific person.

Therefore the accounting model must be unified before RECEIPT1.

## Owner decision

Keep the two **operating/UI modes**:
- `sharedKitty`
- `individualSettlement`

But use **one accounting ledger truth** for both.

The model changes defaults, visibility and transfer presentation; it does not change whether a confirmed group expense counts.

## Canonical accounting rules

### 1. Every confirmed expense is a group cost

For every expense, regardless of payment source:
- include its full amount in total group expenses;
- distribute its cost share using the existing participation/custom-split rules.

No confirmed expense may disappear from cost shares because it was paid personally.

### 2. Every expense has exactly one payment source

Valid states:

**Common kitty**
- `isPaidFromKitty == true`
- `paidByMemberId == null`

**Person**
- `isPaidFromKitty == false`
- `paidByMemberId != null`

New writes must enforce this invariant in the service/domain boundary.

Do not silently create a person-paid expense without a payer.

Existing valid persisted data remains compatible; no schema migration is required.

### 3. Cash kitty balance

`kittyCash = Σ deposits − Σ expenses paid from kitty`

Only actual common-kitty expenses reduce the physical kitty cash.

Person-paid expenses do not change kitty cash.

### 4. Member contributions

For member `i`:

`grossContribution_i = deposits_i + personallyPaidGroupExpenses_i`

This is a factual contribution amount and must remain separately observable from the final net settlement.

### 5. Cost share

For member `i`:

`costShare_i = Σ distributed share of ALL expenses`

Existing category participation, skipper-free semantics and custom splits remain authoritative.

### 6. Treasurer-held cash asset

The remaining `kittyCash` is physically held/managed by the treasurer and is not itself an expense.

Final economic balance:

For non-treasurer:

`net_i = grossContribution_i − costShare_i`

For treasurer:

`net_T = grossContribution_T − costShare_T − kittyCash`

Interpretation:
- positive net → member should receive money;
- negative net → member should pay money.

This ensures:

`Σ member net balances == 0`

for valid cent-exact input.

If `kittyCash < 0`, the negative cash balance represents money effectively advanced by the treasurer and therefore increases the treasurer's claim.

### 7. MemberBalance semantics

Do not fake `paidInCents` merely to force zero-sum.

Refactor the domain model so factual values and settlement adjustment remain distinguishable.

Recommended fields/semantics:
- `paidInCents` or equivalent = real gross contribution (deposit + personally paid group expenses);
- `actualDepositsInCents`;
- `personallyPaidExpensesInCents`;
- `cashHeldInCents` / equivalent treasurer adjustment;
- `costShareInCents`;
- `netBalanceInCents` computed from those explicit components.

Exact naming may differ, but the model must not present a synthetic negative "paid" amount as if it were an actual payment.

### 8. Shared-kitty result

Expose separately:
- total deposits;
- total **all** group expenses;
- total kitty-paid expenses;
- total person-paid expenses;
- current kitty cash;
- unified member balances.

The Bordkasse current-cash UI must continue to use:

`totalDeposits − kittyPaidExpenses`

A personally paid expense must not make the cash progress/balance look lower.

### 9. Transfer strategy

Accounting truth is unified; transfer presentation may remain mode-specific.

**sharedKitty**
- keep the existing treasurer-centered settlement UX;
- all transfers are between a member and the treasurer;
- no fictitious "Kasse" recipient;
- use the unified zero-sum balances.

**individualSettlement**
- use the existing debt simplification/minimal matching;
- use the same unified balances;
- if historical kitty activity exists after a model switch, the treasurer cash adjustment remains part of the ledger so switching modes cannot change economic balances.

### 10. Model switching

Switching `sharedKitty ↔ individualSettlement` must not alter the economic net balance for any member for the same underlying:
- members;
- deposits;
- expenses;
- participation/custom splits;
- treasurer.

The UI may show/hide common-kitty controls and may change default payer, but settlement truth must remain invariant.

Do not delete deposits or rewrite expense payment sources on model switch.

### 11. Expense UI

Retain current shared-kitty payer choice:
- Kasse
- Person

In individual-settlement mode:
- person payer remains required for new expenses;
- do not offer common kitty as the normal new-expense source.

Edit flows must preserve and validate the selected source.

### 12. Mixed-case canonical example

4 equal participants:
- A = treasurer
- deposits: A/B/C/D each 100 EUR → 400 EUR
- E1: 200 EUR paid from kitty
- E2: 120 EUR paid personally by B

Then:
- total group expenses = 320 EUR
- each cost share = 80 EUR
- kitty cash = 400 − 200 = 200 EUR

Gross contributions:
- A 100
- B 220
- C 100
- D 100

Final net:
- A: `100 − 80 − 200 = -180 EUR`
- B: `220 − 80 = +140 EUR`
- C: `100 − 80 = +20 EUR`
- D: `100 − 80 = +20 EUR`

Sum = 0.

Shared-kitty transfers:
- A → B: 140 EUR
- A → C: 20 EUR
- A → D: 20 EUR

A retains 20 EUR of kitty cash as A's own correct residual claim.

## Acceptance floor

At minimum prove:

1. only kitty expenses;
2. only person-paid expenses;
3. mixed canonical 4-person example above;
4. personally paid expense in shared mode contributes to total expenses and cost shares;
5. payer gets exact personal-payment credit;
6. kitty cash ignores person-paid expenses;
7. shared net balances sum exactly 0;
8. individual net balances sum exactly 0 for normal person-paid case;
9. model switch preserves member net balances for mixed historical data;
10. shared transfers remain treasurer-centered;
11. individual transfers use unified balances/debt simplification;
12. category participation still works;
13. custom split still works;
14. skipper-free full/partial still works;
15. cent remainder distribution still exact;
16. zero/positive/negative kitty cash scenarios;
17. expense source invariant enforced on create and edit;
18. shared ExpenseSheet real UI journey: choose Person → payer → save → settlement includes it;
19. edit expense source Kasse ↔ Person remains correct;
20. SettlementScreen uses unified balances;
21. payment QR still uses actual creditor payment details;
22. sum-zero property over a deterministic matrix/randomized set of valid cases;
23. existing PIVOT1/PIVOT3 tests remain green;
24. full Flutter suite green;
25. `flutter analyze` clean.

## Scope exclusions

FIX-B does not implement:
- RECEIPT1 receipt capture/PDF package;
- Guest Shopping;
- multi-currency conversion;
- new expense categories;
- new participation semantics;
- UX-D redesign;
- backend changes;
- PIVOT2;
- DATA1;
- Watermaker reserve changes.

## Gate

**FIX-B is the only currently released implementation slice.**

PIVOT2 remains ON HOLD.

After implementation:
1. report;
2. full QA;
3. push only green;
4. STOP for independent review / Owner Acceptance;
5. no automatic next slice.

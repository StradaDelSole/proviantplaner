# External Review Reconciliation – 06.10.2026

Status: **PRE-PIVOT2 HOLD / OWNER DECISIONS REQUIRED**

Source review:
- external independent Claude review supplied by Product Owner on 06.10.2026
- Claude reviewed production code at `main@73d7936`
- subsequent commits through the current review point are documentation/gating changes; the relevant production code findings remain applicable

This document reconciles the external findings against the current canonical repository.

## F1 – Settlement / shared kitty

Classification: **CONFIRMED / HIGH**

Current `KittyEngine.calculateSharedKitty` filters expenses to `isPaidFromKitty == true` before both total-expense and member-cost-share calculation.

The shared-kitty Expense UI nevertheless permits an expense to be paid by a specific person, producing `isPaidFromKitty == false`.

Result:
- a personally paid group expense in shared-kitty mode is omitted from group cost shares;
- the payer receives no credit for that payment;
- final balances and transfers are materially wrong.

The newer owner-accepted receipt/settlement product specification states:
`Saldo = für die Gruppe bezahlt − eigener Kostenanteil`
and explicitly requires a manually confirmed payer for every expense, while retaining a cash kitty only when actually used.

### Reconciliation decision proposal

Keep two **UX operating modes**, but use one accounting truth:
- every confirmed expense always contributes to total group cost and cost shares;
- payment source is either common kitty or a person;
- personal payments always count as that person's paid amount;
- cash-kitty deposits and cash-paid expenses define actual kitty cash;
- settlement balances across all members must sum to exactly zero.

Shared-kitty mode may continue to expose deposits/current cash and default payer=kitty.
Individual mode may hide deposit/cash mechanics and default payer=person.
The accounting of group costs must not diverge.

Required before RECEIPT1 acceptance.

Recommended next slice: **FIX-B – Unified Settlement Ledger**.

## F2 – Assist classification hard-coded in Dart

Classification: **CONFIRMED / MEDIUM, DIRECT PIVOT2 DEPENDENCY**

Current `AssistClassifier` contains:
- hard-coded preference group IDs;
- hard-coded preference variant IDs;
- substring heuristics for water/pesto/tofu.

This contradicts the project rule that catalog/product classification is data-driven and creates silent fallback risk for new catalog variants.

PIVOT2 relies directly on needs/guided/preference classification, so this should be corrected before PIVOT2 implementation.

### Reconciliation decision proposal

Introduce a new catalog version with:
- required group-level `assist`: `needs_based | guided | preference_based`;
- optional variant-level `assist` override.

Strict enum parsing.
Every group must define assist.
Every variant inherits its group unless explicitly overridden.
No catalog-ID or substring heuristic in `AssistClassifier`.
Validation test covers every group/variant.

Recommended prerequisite slice: **DATA1 – Catalog-driven Assist Classification**.

## F3 – Watermaker contingency reserve

Classification: **VALID OWNER DECISION / PIVOT2 BLOCKER**

Current owner-accepted PIVOT3-B behavior:
- with Watermaker: bottled-water need collapses to `1.5 L × crew count`.

That value originally functions as a reserve floor in tank subtraction and is less than one normal drinking day in warm/hot conditions.

Because PIVOT2 will present water undercoverage as an objective `ACTION_NEEDED` finding, the target reserve semantics must be settled first.

### Recommended product direction

Do not add an equipment production-rate field.

Replace the Watermaker emergency reserve meaning with a **data-driven contingency horizon**, expressed in backup days against the same climate-adjusted drinking-water baseline already used by Provy.

Candidate formula:
`watermakerBottleReserve = dailyDrinkingNeed × crew × min(tripDays, backupDays)`

No automatic reduction below this reserve.

Whether a potable tank additionally counts against this independent Watermaker-failure reserve must be an explicit Owner decision; the current PIVOT3-B semantics intentionally preserve a separate bottled reserve even when a potable tank exists.

Suggested default for discussion: **3 backup days**, stored in quantity data rather than hard-coded.

This requires an explicit Owner decision and then a narrow PIVOT3-B water amendment before PIVOT2.

## F4 – GUEST1 scope

Classification: **VALID STRATEGIC RECOMMENDATION / NOT A CURRENT BUG**

The current GUEST1 spec explicitly includes:
- online capability link;
- offline-capable guest Web/PWA;
- backend session/sync;
- fully local static offline QR/share fallback.

That is a large implementation unit and introduces a Web/PWA client.

Recommended later reconciliation:
- **GUEST1a**: local/offline share package + static/multi QR + owner reconcile;
- **GUEST1b**: capability link + guest PWA + online sync/revocation.

Also explicitly document that the guest PWA is a narrow exception to any older "mobile app only / no web" statements.

No implementation decision is made by this HOLD.

## F5 – Kitty UX

Classification: **VALID UX FOLLOW-UP**

The frozen UX says Bordkasse primary view is current kitty balance + deposit/expense actions.

That only has meaning when an actual common cash kitty is in use.

After FIX-B, UX-D should render:
- shared-cash mode: current kitty cash prominently;
- person-paid mode: total expenses / paid-by-person summary prominently.

No need to resolve before PIVOT2.

## F6 – minor cleanup

Classification: **NON-BLOCKING**
- unused `adoptAllSuggestions` localization may be removed in a cleanup;
- `updateMemberParticipation` filtering can be optimized later.

## F7 – Auth/backend

Classification: **PARTIALLY CONFIRMED, CLAUDE WORDING OUTDATED**

The active Riverpod provider currently returns `Auth0HullqAuthService`, not `MockHullqAuthService`.

However real end-to-end Auth0 is still not complete:
- no Auth0 SDK dependency in `pubspec.yaml`;
- without an injected token provider, `Auth0HullqAuthService` fabricates an `auth0_<connection>_token`;
- backend `wrangler.toml` still has placeholder D1 database ID;
- therefore production login/deployment is not end-to-end deployable today.

This blocks later cloud-dependent features such as GUEST1b and production backup/receipt sync, but not local PIVOT2.

## Revised recommended sequence

1. **FIX-B – Unified Settlement Ledger** (high-severity money correctness)
2. **DATA1 – Catalog-driven Assist Classification** (direct PIVOT2 prerequisite)
3. **WATER1 / PIVOT3-B water amendment** after explicit Owner reserve decision
4. **PIVOT2 – Provisioning Review**
5. RECEIPT1
6. GUEST1a
7. UX-D / other released priorities after reconciliation
8. GUEST1b + real Auth0/backend deployment when cloud path is ready

## Gate

PIVOT2 Issue #26 and its existing plan remain valid in principle, but implementation is **ON HOLD**.

Do not start PIVOT2 until:
- DATA1 is owner-accepted;
- Watermaker reserve decision/amendment is owner-accepted.

FIX-B is recommended first because it is a confirmed high-severity financial correctness bug, even though it is not technically required by PIVOT2.

No later slice is released by this reconciliation.

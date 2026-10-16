# WATER1 Simplification – Independent Re-Review

Stand: 17.10.2026  
Status: **DOCUMENTATION-ONLY AMENDMENT REQUIRED**

Reviewed PR:

- PR #31 — `WATER1: Minimum drinking water simplification`
- Reviewed HEAD: `d133e91e92adfa1d159f90eb2a362349241643e3`
- Base: `0c646b252470f050bf1b31d47da6d7e294a3b819`
- PR state: open, Ready for Review, clean/mergeable
- Issue #30 remains open
- PIVOT2 remains on HOLD

Canonical product basis:

- `docs/impl/WATER1_simplification_reconciliation_2026-10-16.md`
- `docs/impl/WATER1_simplification_plan.md`
- `docs/PROMPT_SESSION_START_v0.11.md`

## Result

The WATER1 Simplification **production implementation is accepted by independent review**.

No code or product-semantics defect was found.

However, the final reporting gate is not yet satisfied because the implementation report still records the prior PR head / CI run rather than the actual final review head.

Therefore status is:

**DOCUMENTATION-ONLY AMENDMENT REQUIRED**

No production-code amendment is authorized or required.

## Verified implementation

### A. Minimum drinking-water calculation

Verified in production code:

`minimumDrinkingWater = climateDailyLiters × crewFactorSum × effectiveDays`

with:

`effectiveDays = daysUntilNextStop ?? daysCount`

Existing data-driven climate defaults remain:

- cool: 2.0 l
- warm: 2.5 l
- hot: 3.5 l

Existing crew/child weighting remains in use.

### B. Tank / Watermaker independence

Verified:

- no potable-tank subtraction;
- no Watermaker reduction;
- no Watermaker contingency reserve;
- `waterTankLiters`, `isWaterTankDrinkable`, and `hasWatermaker` remain technical Trip/Boat facts but do not alter minimum drinking-water need.

Regression tests explicitly prove no tank / potable tank / non-potable tank / Watermaker / potable tank + Watermaker produce the same need for otherwise identical inputs.

### C. v0.7 rollback

Verified on reviewed HEAD:

- `data/quantities_v0.7.json` does not exist;
- `watermakerBackupDays` is absent from production;
- `CatalogRepository` loads `data/quantities_v0.6.json`;
- `pubspec.yaml` contains v0.6 only;
- v0.6 blob SHA is byte-identical to current main:
  `2db50e3280bc6dd5156328cc00fe1b820f7ca53c`.

### D. UI truth

Verified:

- water-group UI receives `calculatedGroupNeed` from `TripCalculationResult`;
- the UI does not recalculate water independently;
- `PlanningView` and `GroupDetailSheet` display the calculated minimum drinking-water total;
- the required planning notice is visible;
- the previous +25% / +50% water boost controls are removed.

Current catalog uses `per_person_day_region` only for the water group, so the current basis-based UI detection is valid. If another future group adopts the same calculation basis, this should be revisited rather than inheriting water-specific copy automatically. This is **non-blocking** for WATER1.

### E. Localization

Verified for DE / EN / FR / ES / PT / HR:

- `waterMinimumTotal`
- `waterPlanningNotice`
- neutral `waterTankDrinkableSubtitle`
- neutral `hasWatermakerSubtitle`

Obsolete water-boost keys are removed.

### F. Regression / CI

GitHub Actions run `38973635021` is verified on exact reviewed HEAD:

`d133e91e92adfa1d159f90eb2a362349241643e3`

Jobs:

- `Flutter Analyze & Test` — SUCCESS
- `Backend Typecheck & Vitest` — SUCCESS

PR is clean and mergeable against current `main`.

## Blocking Finding A — final implementation report is stale

Actual final reviewed PR HEAD:

`d133e91e92adfa1d159f90eb2a362349241643e3`

Actual authoritative final CI run:

`38973635021`

Actual jobs:

- Flutter Analyze & Test: `117217692118` — SUCCESS
- Backend Typecheck & Vitest: `117217692431` — SUCCESS

But `docs/impl/WATER1_bericht.md` currently ends with:

- `Final Implementation / Merge HEAD: d2bf2476dddccb1225190869196db4651dc63986`
- CI run `38973295879`
- earlier job IDs

and the amendment section begins with status:

`AMENDMENT IMPLEMENTED / READY FOR FULL-QA CI`

This is no longer the final state.

Required amendment:

1. update the amendment status to **READY FOR INDEPENDENT REVIEW / OWNER ACCEPTANCE** (or equivalent truthful final state);
2. retain the implementation HEAD `d2bf247...` if useful, but clearly distinguish it from the **final PR HEAD**;
3. record final PR HEAD `d133e91...`;
4. record final authoritative CI run `38973635021`;
5. record final job IDs and SUCCESS conclusions;
6. do not claim the PR is merged.

Because this requires a commit, GitHub Actions must run again on the resulting new PR HEAD. The report must then record that new final HEAD and its actual green CI run. Avoid an endless self-referential loop by wording the report so the documentation commit is identified as the final reporting commit, and after its CI succeeds no further report-content commit is needed.

## Non-blocking Finding B — PR body formatting

PR #31 correctly describes the new simplified semantics, but several inline code references contain malformed backslash escaping/control characters, e.g. around paths/identifiers.

This does not affect production or CI.

During the documentation-only amendment, clean the PR description to normal Markdown backticks so the review surface is readable.

## Existing planning-horizon note

The engine retains the accepted:

`effectiveDays = daysUntilNextStop ?? daysCount`

Production Trip-wide recalculation currently does not supply `daysUntilNextStop`, so the normal Trip planning surface uses `daysCount`. This is pre-existing architecture and was not introduced by WATER1.

The WATER1 requirement was to retain the engine planning-horizon semantics and prove it by regression test; that is satisfied.

No additional ShoppingStop architecture work is authorized in this documentation amendment.

## PIVOT2 follow-up

`docs/impl/PIVOT2_plan.md` still contains historical PIVOT3-B wording around Watermaker/Tank reserve behavior.

This is **not a WATER1 blocker** because:

- PIVOT2 is on HOLD;
- the newer WATER1 simplification reconciliation has higher priority;
- the exact PIVOT2 water semantics are explicitly deferred to PIVOT2 reconciliation.

Before PIVOT2 is released, its plan/tests must be reconciled to the accepted WATER1 semantics.

## Amendment scope

Allowed:

- `docs/impl/WATER1_bericht.md`
- PR #31 description metadata
- only any mechanically necessary documentation reference to the final report state

Not allowed:

- production code changes;
- new water semantics;
- PIVOT2 implementation;
- unrelated docs/product changes.

After the documentation-only amendment and final green CI:

**STOP for independent re-review and explicit Owner Acceptance.**

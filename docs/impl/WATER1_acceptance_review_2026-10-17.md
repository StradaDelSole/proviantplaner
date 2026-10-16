# WATER1 Acceptance Review – 17.10.2026

Status: **FINAL / OWNER-ACCEPTED IMPLEMENTATION**

Slice:

- WATER1 – Minimum Drinking Water Simplification
- Issue #30
- PR #31

## Final reviewed implementation state

- Final reviewed PR HEAD: `788f9fb608a523eaaa0163a3e743077c04b53af4`
- Merge commit: `6b206ee7cbf6ea276a642e0a4b5dc75788c68fc5`
- PR #31 merged into `main`
- Authoritative GitHub Actions run on final PR HEAD: `38977941932`

Required jobs:

- Flutter Analyze & Test — SUCCESS — Job `117231770172`
- Backend Typecheck & Vitest — SUCCESS — Job `117231769798`

## Accepted product semantics

Provy calculates only the climate-adjusted minimum drinking-water estimate:

`minimumDrinkingWater = climateDailyLiters × crewFactorSum × effectiveDays`

with:

`effectiveDays = daysUntilNextStop ?? daysCount`

Accepted existing climate defaults remain:

- cool: 2.0 l
- warm: 2.5 l
- hot: 3.5 l

Existing crew/child weighting remains in effect.

Tank and Watermaker are technical planning facts only and do not alter this minimum estimate.

No automatic calculation remains for:

- potable-tank subtraction;
- Watermaker reduction;
- Watermaker reserve;
- cooking water;
- dishwashing;
- washing;
- showers/body care;
- total freshwater requirement.

The user-facing water guidance explicitly states that tank, Watermaker, refill opportunities and additional freshwater consumption must be planned separately by the skipper.

## Accepted implementation details

Verified and accepted:

- `data/quantities_v0.7.json` removed;
- `watermakerBackupDays` removed;
- `data/quantities_v0.6.json` remains canonical and unchanged;
- production loader uses v0.6;
- water group total comes from `TripCalculationResult`, not a duplicate UI formula;
- PlanningView and GroupDetailSheet show the calculated minimum drinking-water total;
- planning notice present;
- tank/Watermaker subtitles neutralized;
- obsolete +25% / +50% water boost controls removed;
- all six supported languages updated;
- manual package overrides remain stable;
- relevant PIVOT3-B regressions remain green.

## Non-blocking future notes

1. Current UI identifies the water-specific display through `CalculationBasis.perPersonDayRegion`. Today that basis is used only by the water group. If another future group adopts the same basis, water-specific copy must be decoupled explicitly.

2. The engine retains `daysUntilNextStop`, while current trip-wide production recalculation normally uses `daysCount`. This was pre-existing architecture and is not a WATER1 defect.

3. Before PIVOT2 is released, its historical water-undercoverage acceptance wording must be reconciled against the accepted WATER1 semantics.

## Final review result

No open WATER1 findings remain.

WATER1 is accepted as complete.

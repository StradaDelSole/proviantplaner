> **SUPERSEDED – 16.10.2026:** Die hier beschriebene 3-Tage-Watermaker-Reserve wurde durch `docs/impl/WATER1_simplification_reconciliation_2026-10-16.md` ersetzt. Nicht mehr implementieren.

# WATER1 – Watermaker Contingency Reserve Reconciliation – 16.10.2026

Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Owner decision:

`WATER1 so akzeptiert – go`

This reconciliation resolves External Review Finding F3 in:

`docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md`

It supersedes only the previous PIVOT3-B Watermaker reserve semantics. All other accepted PIVOT3-B behavior remains unchanged.

## Decision / Implementation Reconciliation

### DECIDED_AND_IMPLEMENTED

- `hasWatermaker=true` means the user explicitly states that an operational onboard Watermaker is intended to provide the routine drinking-water supply during the Trip.
- No Watermaker production-rate field exists.
- Without Watermaker, existing water/tank behavior remains:
  - raw drinking-water need uses the existing climate-adjusted daily baseline;
  - a potable tank may reduce bottle need;
  - the existing 1.5 l/person reserve floor remains.
- `QuantityCalculationInput.hasWatermaker` already exists and is populated from the Trip snapshot.
- PIVOT3-B, DATA1 and FIX-B are owner-accepted / complete.

### SUPERSEDED

The previous PIVOT3-B Watermaker rule:

`bottleNeed = 1.5 l × crew count`

when `hasWatermaker=true` is superseded.

Reason: this reserve is independent of climate and Trip/leg duration and can represent less than one day of drinking water.

### OWNER-ACCEPTED WATER1 DECISION

When `hasWatermaker=true`, Provy shall calculate an independent Watermaker-failure reserve using a data-driven backup horizon.

Definitions:

- `dailyDrinkingNeed = climateDailyLiters × crewFactorSum`
- `effectiveDays = daysUntilNextStop ?? daysCount`
- `backupDays = 3`
- `reserveDays = min(effectiveDays, backupDays)`
- `watermakerBottleReserve = dailyDrinkingNeed × reserveDays`

Therefore:

`bottleNeed = climateDailyLiters × crewFactorSum × min(effectiveDays, backupDays)`

### Crew weighting

Use the **existing water calculation crew weighting**, not raw headcount.

That means the same `crewFactorSum` already used by the normal drinking-water baseline, including the existing child factor.

Do not introduce a separate WATER1 crew factor.

### Climate

Use the existing climate-adjusted default values already used for water:

- cool: 2.0 l/person/day
- warm: 2.5 l/person/day
- hot: 3.5 l/person/day

Do not introduce a second climate table.

### Backup horizon

The accepted default is **3 days**.

It must be data-driven, not hard-coded in Dart.

Create:

`data/quantities_v0.7.json`

from v0.6, preserving all existing data and adding a Watermaker contingency configuration with:

`backup_days: 3`

`data/quantities_v0.6.json` must remain byte-for-byte unchanged.

Production loading moves to v0.7.

The new value must be parsed into the typed quantities model and validated as a positive integer. No silent fallback is allowed for the production v0.7 file.

### Short legs / next provisioning stop

The reserve horizon is bounded by the same `effectiveDays` already used by the water baseline:

`effectiveDays = daysUntilNextStop ?? daysCount`

Examples:

- 1 day until next provisioning stop → 1 reserve day
- 2 days → 2 reserve days
- 3 or more days → 3 reserve days

Do not provision more Watermaker contingency days than the remaining provisioning horizon.

### Potable tank semantics with Watermaker

A potable tank does **not** reduce the Watermaker contingency bottle reserve.

Reason:
- Provy knows configured tank capacity, not actual current fill level;
- Provy cannot guarantee current potable quality;
- treating nominal tank capacity as guaranteed emergency drinking water would create false precision.

Therefore, with Watermaker:

- no tank → Watermaker reserve
- non-potable tank → Watermaker reserve
- potable tank → the same Watermaker reserve

Tank capacity is ignored only for this independent Watermaker-failure reserve.

Without Watermaker, existing potable-tank subtraction remains unchanged.

### Existing no-Watermaker semantics remain unchanged

Without Watermaker:

- if no potable tank is available:
  `bottleNeed = rawNeed`
- if a potable tank is available:
  `bottleNeed = max(rawNeed - tankCapacity, existingReserveFloor)`

where the existing reserve floor remains:

`1.5 l × crew count`

WATER1 must not redesign or reinterpret the no-Watermaker path.

## Example

Four adults, warm climate, at least three days until next provisioning stop:

- daily baseline = 2.5 l × 4 = 10 l/day
- backup horizon = 3 days
- Watermaker reserve = 30 l

The current pre-WATER1 behavior would produce only 6 l.

## Data exception

This Owner decision explicitly authorizes the narrow data change:

- add `data/quantities_v0.7.json`
- preserve `data/quantities_v0.6.json` unchanged
- update production/test asset references required to use v0.7

No unrelated quantity, catalog, profile, factor, or rounding value may change.

## Required automated proof

At minimum prove:

1. Watermaker + cool climate uses 3-day climate-adjusted reserve.
2. Watermaker + warm climate uses 3-day climate-adjusted reserve.
3. Watermaker + hot climate uses 3-day climate-adjusted reserve.
4. A one-day provisioning horizon uses one reserve day.
5. A two-day provisioning horizon uses two reserve days.
6. Four or more days are capped at three reserve days.
7. Existing child weighting is respected.
8. Potable tank + Watermaker gives the same reserve as no tank + Watermaker.
9. Non-potable tank + Watermaker gives the same reserve.
10. No-Watermaker/no-tank behavior is unchanged.
11. No-Watermaker/potable-tank subtraction and 1.5 l/person floor are unchanged.
12. User package overrides survive recalculation.
13. v0.6 remains unchanged.
14. v0.7 differs from v0.6 only by version/schema documentation and the accepted Watermaker backup configuration.
15. Full Flutter CI and analyze are green on the final review PR.

## Strict non-scope

Do not add:

- Watermaker liters/day or production percentage
- Watermaker reliability score
- tank fill-level tracking
- water-quality tracking
- extra Watermaker UI controls
- PIVOT2 readiness/review UI
- new quantity semantics outside water
- PIVOT2, RECEIPT1, GUEST1, UX-D or later features

## Gate

**WATER1 is the only implementation slice released now.**

Implementation must use a dedicated review branch and Pull Request against `main`.

GitHub Actions is authoritative Full-QA.

After green CI:

**STOP for independent review / Owner Acceptance.**

Do not merge the PR and do not start PIVOT2 automatically.

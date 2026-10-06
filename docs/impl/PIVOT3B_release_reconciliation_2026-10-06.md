# PIVOT3-B Release Reconciliation – 06.10.2026

Status: **IMPLEMENTATION RELEASED**

Supersedes only the previous PIVOT3-B gate status in:
- `docs/impl/PIVOT3_reconciliation_2026-10-06.md`
- `docs/impl/PIVOT3B_plan.md`

It does not change the accepted PIVOT3-A implementation or release any later slice.

## Starting point

PIVOT3-A – Boat/Profile Foundation is **OWNER-ACCEPTED / COMPLETE**.

Accepted implementation/amendment HEAD:
`7cb1eca06ad12617e091adcd62fdfb212acf0293`

Owner acceptance:
`docs/impl/PIVOT3A_owner_acceptance_2026-10-06.md`

All PIVOT3-B start gates are therefore satisfied except the explicit README release, which this reconciliation authorizes.

## Decision / Implementation Reconciliation

### DECIDED_AND_IMPLEMENTED
- Drift schema v7
- reusable `BoatProfiles`
- Trip `boatProfileId` source reference
- independent Trip boat snapshots
- `hasWatermaker` on BoatProfile and Trip snapshot
- explicit `resyncTripBoatProfile`
- profile delete → `boatProfileId = null` while snapshot survives
- Backup payload v2 / v1 restore compatibility

### DECIDED_NOT_IMPLEMENTED
- boat-profile selection/editing in visible Trip setup
- one-off Trip boat overrides in visible setup/editing
- visible Watermaker control
- Watermaker effect in Quantity Engine
- crew setup correction for the five-placeholder default
- Issue #4 closure
- Issue #5 closure

## Reconciled implementation decisions

### 1. Crew minimum and Issue #4

The current production domain does not impose a minimum of five.

The five-person behavior is a Wizard default:
- the Wizard currently creates five fixed `CrewMemberInput` placeholders;
- TripService and Quantity Engine already support smaller crews;
- existing Trip editing already prevents deleting the final real crew member.

For PIVOT3-B:
- **minimum supported crew size is 1**;
- the New Trip Wizard must no longer start with five fixed people;
- default to one initial skipper/person row;
- user can add/remove crew down to one and above five without a special upper clamp;
- no hidden clamp to five may exist in UI, service or Quantity Engine;
- do **not** introduce a new `crewCount` database field or schema v8 only for this fix;
- retain the existing CrewMember-row model in this slice;
- the broader frozen-UX concept of a future pure-count-first experience must not trigger a crew identity/data-model rewrite inside PIVOT3-B.

Acceptance must explicitly prove 1, 2, 4, 5 and a larger crew case through the actual Wizard/service path.

### 2. Boat profile integration

PIVOT3-B uses the PIVOT3-A model exactly as accepted.

New Trip:
- Boot section appears before Crew, consistent with frozen UX.
- user can choose an existing active BoatProfile;
- user can create a new BoatProfile;
- user can edit a BoatProfile;
- user can continue with one-off Trip boat values without saving a profile;
- selected profile values are loaded as the proposed Trip values;
- user may override the values for this Trip only;
- Trip creation stores source profile ID plus the final visible values as the Trip snapshot;
- editing a profile must never silently mutate an existing Trip.

Existing Trip:
- visible editing of current boat snapshot values;
- visible profile relationship where present;
- explicit Resync action only;
- Resync requires a clear deliberate user action and uses the accepted `resyncTripBoatProfile` service path;
- no automatic resync after profile edit.

Do not build the full UX-D Command Center or a new permanent navigation area in this slice.

### 3. Watermaker semantic contract

No production-capacity field is added in PIVOT3-B.

For v1, `hasWatermaker == true` means:
> the user explicitly states that an operational onboard Watermaker is intended to provide the routine drinking-water supply during the Trip.

This assumption must be visible in UI helper/subtitle copy. It must not be presented as a safety guarantee. Users remain responsible for actual equipment capacity, operation and water quality.

### 4. Water quantity formula

Use the existing water baseline and existing configured reserve from `data/quantities_v0.6.json`.

Definitions:
- `rawNeed = climateDailyLiters × effectiveDays × crewFactorSum`
- `reserve = waterTankReserveLitersPerPerson × crewCount`
- current configured reserve is 1.5 l/person
- `drinkableTank = waterTankLiters` only when `isWaterTankDrinkable == true`; otherwise 0

Without Watermaker:
`bottleNeed = max(rawNeed - drinkableTank, reserve)` when a drinkable tank exists;
otherwise `bottleNeed = rawNeed`, preserving current behavior.

With Watermaker:
`bottleNeed = reserve`

Rationale:
- a Boolean Watermaker has no defensible production-rate precision;
- therefore do not invent l/day, percentages or a hard-coded production factor;
- its v1 semantic is binary routine-source availability;
- the already configured emergency bottle reserve remains mandatory;
- Watermaker can never reduce the result below reserve and never to zero.

The four mandatory cases must be tested:
1. no tank, no Watermaker → normal raw water need;
2. drinkable tank, no Watermaker → existing tank subtraction with reserve floor;
3. non-drinkable tank + Watermaker → reserve only;
4. drinkable tank + Watermaker → reserve only.

Also prove that non-drinkable tank alone does not reduce bottle need.

No change to `data/quantities_v0.6.json` is needed for this formula.

### 5. Quantity Engine boundary

Add `hasWatermaker` to the typed `QuantityCalculationInput` with backward-compatible default `false`.

`TripService.recalculateTrip` must pass the Trip snapshot value.

No Watermaker effect is allowed outside the water calculation.

PIVOT1 user-selected package overrides must remain stable through recalculation.

### 6. UX and localization

Within the current Wizard / current Trip editing surfaces:
- separate/make clear the Boat section before Crew where touched by this slice;
- Boat fields: name, optional manufacturer/model, fridge, freezer, tank, tank drinkability, Watermaker;
- numeric boat values follow the frozen mechanical pattern where practical: minus / value / plus; direct numeric entry remains available;
- all new visible strings in DE, EN, ES, FR, HR, PT;
- Light/Dark/Nightwatch-compatible theme tokens only; no hard-coded theme-breaking colors;
- no new permanent main navigation;
- no PIVOT2 readiness/review UI.

## Acceptance floor

Automated proof must include at least:

### Crew
- new Wizard no longer begins at 5
- minimum 1
- create Trip with 1 person
- create Trip with 2 people
- create Trip with 4 people
- create Trip with 5 people
- create Trip with >5 people
- persisted CrewMember count matches visible selection
- recalculation reflects smaller/larger crew

### Boat/Profile UI
- real UI journey: existing profile → New Trip → persisted source ID + snapshot
- real UI journey: create new profile → New Trip
- one-off Trip boat values without saved profile
- Trip override does not mutate BoatProfile
- profile edit does not mutate existing Trip
- explicit Resync updates Trip snapshot
- archived profiles not offered by normal selector

### Watermaker
- visible toggle persists on Trip
- profile snapshot copies Watermaker
- four canonical formula cases
- reserve is never zero from Watermaker
- Watermaker false preserves current behavior
- PIVOT1 override/recalculation regression remains green

### Regression
- PIVOT3-A migration/backup tests remain green
- full Flutter suite green
- `flutter analyze` clean

## Gate

**PIVOT3-B is the only implementation slice released now.**

Do not start:
- PIVOT2
- UX-D Command Center rebuild
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store publication

After implementation:
1. implementation report;
2. push only on green QA;
3. STOP for independent review;
4. no automatic next-slice release.

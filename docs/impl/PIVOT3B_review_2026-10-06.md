# PIVOT3-B Independent Review – 06.10.2026

Status: **AMENDMENT REQUIRED**

Reviewed implementation HEAD:

`15acc5c88dcb65788991e4a8e6947283320d3511`

Canonical scope:
- `docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md`
- `docs/impl/PIVOT3B_plan.md`
- Issue #25 including Issues #4, #5 and #6

## Summary

The implementation is directionally correct and most released PIVOT3-B behavior is present:

- New Trip Wizard starts with one CrewMember instead of five.
- Boat appears before Crew.
- active BoatProfiles can be selected.
- BoatProfiles can be created and edited from the New Trip flow.
- one-off Trip boat data is supported.
- Watermaker is persisted and routed into the Quantity Engine.
- Watermaker formula matches the released v1 semantic.
- existing Crew add/edit/delete paths recalculate the Trip.
- explicit Trip resync exists.
- six-language ARB key coverage is complete.
- GitHub Actions are green.

However, PIVOT3-B is **not yet ready for Owner Acceptance** because one production edit path is incorrect and several released acceptance claims are not actually proven by the named tests.

## Finding A – Existing Trip boat identity fields cannot be cleared

**Severity: BLOCKING – production behavior**

The existing-Trip edit UI exposes editable snapshot fields:
- Boat name
- Manufacturer
- Model

The UI converts an empty field to `null` before calling `updateTripDetails`.

But `TripService.updateTripDetails` interprets `null` as "keep existing value":

```dart
boatName: boatName != null ? Value(boatName) : Value(trip.boatName),
boatManufacturer: boatManufacturer != null
    ? Value(boatManufacturer)
    : Value(trip.boatManufacturer),
boatModel: boatModel != null ? Value(boatModel) : Value(trip.boatModel),
```

Therefore a user can type a new manufacturer/model, but cannot remove an existing optional manufacturer/model again. The visible edit surface silently ignores clearing the field.

This violates the released requirement that the current Trip boat snapshot values are visibly editable.

### Required fix

Use an update boundary that distinguishes:
- parameter not supplied → keep existing value;
- explicitly supplied null/blank → clear the nullable snapshot field;
- supplied text → replace snapshot field.

Do not change PIVOT3-A snapshot semantics and do not automatically mutate the BoatProfile.

Add a real regression test through the visible existing-Trip edit flow:
1. Trip starts with manufacturer/model.
2. open edit UI;
3. clear manufacturer/model;
4. save;
5. reload from Drift;
6. fields are null/empty as intended;
7. linked BoatProfile remains unchanged.

## Finding B – Visible Watermaker toggle and explicit Resync are not proven through their UI paths

**Severity: BLOCKING – acceptance proof**

The report claims:
- "Watermaker-Toggle auf Trip persistiert ...";
- "Explizites Resync aktualisiert ...".

But the named PIVOT3-B tests for these behaviors call production services directly:
- Watermaker test calls `tripService.updateTripDetails(... hasWatermaker: true)`;
- Resync test calls `tripService.resyncTripBoatProfile(tripId)`.

Those tests prove service behavior, but not the newly released visible controls.

The release acceptance floor explicitly requires a visible Watermaker toggle and an explicit Resync action.

### Required fix

Add real widget/integration tests that use the actual existing-Trip UI:

1. **Watermaker edit UI**
   - open TripOverview;
   - open Trip edit;
   - toggle Watermaker through the actual Switch;
   - save;
   - reload Trip from Drift;
   - verify `hasWatermaker == true`;
   - verify recalculated water result reflects the reserve logic.

2. **Explicit Resync UI**
   - create linked Trip;
   - modify source BoatProfile;
   - open Trip edit;
   - tap the actual "Resync from boat profile" action;
   - confirm;
   - verify Drift Trip snapshot changed;
   - prove no resync occurs merely from profile update without that action.

Do not replace the existing service tests; retain them as lower-level regression coverage.

## Finding C – Crew recalculation acceptance criterion is not proven

**Severity: BLOCKING – acceptance proof**

The released acceptance floor requires:

> recalculation reflects smaller/larger crew

The dedicated test
`Crew-Größen 1, 2, 4, 5 und 8 werden ohne Clamp auf 5 persistiert`
only proves that CrewMember row counts persist.

It does not assert any calculated need/list quantity and therefore does not prove that changing crew size changes provisioning output correctly.

Production code does call `recalculateTrip()` after Crew add/edit/delete, which is good, but the acceptance criterion still lacks an end-result regression.

### Required fix

Add a deterministic integration test using real persistence/services:

- start with an existing Trip and a known needs-based calculated result;
- capture a deterministic calculated quantity/need;
- add CrewMember(s), trigger the production recalc path, and prove the result increases to a fixed expected value;
- remove CrewMember(s), trigger recalc, and prove it decreases to the fixed expected value;
- cover at least a small crew and a larger crew;
- prove PIVOT1 user overrides/adopted state remains stable while calculated values refresh.

Prefer an end result from persisted ListItems or another user-visible calculated output, not merely an intermediate factor.

## Finding D – Water case 1 / reserve assertions are weaker than the released fixed-value requirement

**Severity: NON-BLOCKING by itself, REQUIRED in amendment**

The release decision requires the canonical water cases with fixed calculated expected values.

Cases 2–4 assert exact `3.0 L` for a 2-person reserve.

Case 1 only asserts:
- `rawGroupNeed > 0`
- packages > 0

and the "reserve never 0" loop only asserts `> 0`.

This would not catch a wrong but positive calculation.

### Required fix

Use fixed expected values derived from the current data:

For warm climate, 2 adults, 7 days:
`2.5 L × 2 × 7 = 35.0 L`.

For Watermaker reserve:
`1.5 L × crewCount`.

Assert these exact values with appropriate floating tolerance.

## Verified / closed areas

The independent review verified the following and they do not need redesign in the amendment:

### Crew UI/domain
- Wizard default is one person.
- last CrewMember is protected in Wizard and existing Trip UI.
- add/edit/delete on existing Trip calls `recalculateTrip()`.
- no schema v8 / no `crewCount` DB field.

### Watermaker production logic
`QuantityCalculationInput.hasWatermaker` exists with default false.

For water:
- no Watermaker + drinkable tank: existing subtraction + reserve floor;
- no Watermaker + non-drinkable tank: no reduction;
- Watermaker true: configured emergency reserve only;
- no invented l/day rate;
- no change to `data/quantities_v0.6.json`.

### Boat/Profile behavior
- New Trip: profile select works.
- New Trip: new profile dialog works.
- one-off source-null snapshots are supported.
- profile-backed creation copies source + snapshot.
- profile edits do not automatically mutate an existing Trip at the persistence layer.
- archived profiles are excluded from the normal selector.
- explicit resync service remains intact.

### Localization
All ARB locales DE/EN/ES/FR/HR/PT have matching key sets for the reviewed state, including the new Boat/Watermaker/Resync strings.

### Regression / CI
GitHub Actions on `15acc5c88dcb65788991e4a8e6947283320d3511`:
- **Flutter Analyze & Test — SUCCESS**
- **Backend Typecheck & Vitest — SUCCESS**

The reported full Flutter count of 297 is consistent with the prior 279 baseline plus 18 added PIVOT3-B tests.

## Review note – mechanical numeric controls

The New Trip Boat section follows the mechanical minus/value/plus pattern.

`BoatProfileDialog` and the existing-Trip edit sheet still use direct numeric TextFields for several capacities. Because the release wording says "where practical" and direct numeric input is an accepted interaction, this is not treated as a blocking PIVOT3-B finding. It remains a UX-D consistency point and must not be used to expand this amendment.

## Amendment boundary

Keep the amendment narrow:
1. fix explicit clearing of nullable Trip boat identity snapshot fields;
2. add real UI-path tests for Watermaker and Resync;
3. add real crew-size recalculation output proof;
4. strengthen water fixed-value assertions;
5. correct the PIVOT3-B report if any test names/results change.

Do not refactor unrelated PIVOT3-B production code unless a new test exposes a defect.

## Required QA

After amendment:
- dedicated PIVOT3-B tests;
- PIVOT3-A migration/backup tests;
- PIVOT1 regression tests;
- `flutter analyze`;
- full `flutter test`.

The report must contain actual executed totals.

## Gate

PIVOT3-B remains **IN REVIEW / AMENDMENT REQUIRED**.

Do not start:
- PIVOT2
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store publication

After the amendment is pushed, STOP for independent re-review.

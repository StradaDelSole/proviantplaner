# PIVOT3-B Final Acceptance Review – 06.10.2026

Status: **READY FOR OWNER ACCEPTANCE**

Reviewed amendment HEAD:

`b19e1736a2d5c7fa26836bb35d014ff46a6706e1`

Reviewed against:
- `docs/impl/PIVOT3B_plan.md`
- `docs/impl/PIVOT3B_release_reconciliation_2026-10-06.md`
- `docs/impl/PIVOT3B_review_2026-10-06.md`
- actual production code and tests on `origin/main`

## Result

All Findings A–D from the independent PIVOT3-B review are verified closed.

### Finding A – nullable Trip boat snapshot fields

**CLOSED**

`TripService.updateTripDetails` now uses Drift `Value<T?>` parameters with `const Value.absent()` defaults for:
- `boatProfileId`
- `boatName`
- `boatManufacturer`
- `boatModel`

This correctly distinguishes:
- absent → keep existing value;
- `Value(null)` → explicitly clear nullable snapshot field;
- `Value(text)` → replace snapshot field.

The existing-Trip UI passes explicit `Value(...)` instances when saving its visible Boat identity fields.

A real UI test clears manufacturer/model through TripOverview, reloads the Trip from Drift, verifies the snapshot fields are null, and separately verifies that the linked BoatProfile remains unchanged.

### Finding B – real UI paths for Watermaker and Resync

**CLOSED**

The amendment adds true Widget/UI journeys:

1. **Watermaker**
   - opens TripOverview;
   - opens the real Trip edit surface;
   - operates the actual Watermaker `SwitchListTile`;
   - saves through the visible button;
   - reloads Drift state;
   - verifies `hasWatermaker == true`;
   - verifies total calculated water falls from 35.0 L to the exact 3.0 L emergency reserve for two people.

2. **Explicit Resync**
   - creates a linked BoatProfile + Trip;
   - changes the profile afterward;
   - proves the Trip snapshot does not change automatically;
   - opens TripOverview and the real edit surface;
   - taps the visible "Aus Bootsprofil aktualisieren" action;
   - confirms through the actual confirmation dialog;
   - reloads the Trip from Drift;
   - verifies the snapshot now contains the changed profile values.

The lower-level service tests remain as additional regression coverage.

### Finding C – crew-size recalculation output

**CLOSED**

The amendment adds deterministic persisted-output proof.

Verified sequence:
- 1 person / 7 warm days: 17.5 L total water need;
- increase to 4 people + production recalculation: 70.0 L;
- decrease to 3 people + production recalculation: 52.5 L.

The test verifies both persisted calculated quantities and calculated package counts.

A separate regression test proves PIVOT1 user state survives recalculation:
- manual `overriddenPackages` remains stable;
- `isAdopted` remains stable;
- preference item package overrides remain stable while calculated needs refresh.

Review note: the crew-recalculation test manipulates Crew rows through the production DAO and invokes the production TripService recalculation, rather than driving every add/delete through the UI. This is sufficient for this acceptance criterion because the separately reviewed existing-Trip UI methods themselves call those same production DAO operations followed by `recalculateTrip()`, and the UI floor/minimum behavior is independently widget-tested.

### Finding D – fixed water expectations

**CLOSED**

The canonical water tests now use fixed values with tolerance.

Verified:
- warm climate, 2 adults, 7 days, no tank/no Watermaker:
  `2.5 × 2 × 7 = 35.0 L`;
- large drinkable tank / no Watermaker:
  emergency reserve `1.5 × 2 = 3.0 L`;
- non-drinkable tank + Watermaker:
  `3.0 L`;
- drinkable tank + Watermaker:
  `3.0 L`;
- non-drinkable tank without Watermaker does not reduce raw need;
- Watermaker reserve loop verifies `1.5 × crewSize`, not merely a positive result.

No Watermaker production-rate assumption was introduced and `data/quantities_v0.6.json` remains unchanged.

## PIVOT3-B production review

The final reviewed implementation satisfies the released scope:

### Crew / Issue #4
- New Trip default = one CrewMember;
- minimum one person protected;
- no clamp at five;
- no `crewCount` DB field;
- schema remains v7;
- smaller/larger crew recalculates provisioning output.

### Watermaker / Issue #5
- Boolean Watermaker semantic only;
- transparent six-language helper copy;
- value persisted on Trip/Profile snapshot;
- passed through TripService and ShoppingListService quantity paths;
- with Watermaker: emergency bottle reserve only;
- never zero;
- without Watermaker: prior drinkable-tank behavior preserved.

### Boat/Profile / Issue #6
- Boat section before Crew;
- active profile selector;
- create/edit profile in New Trip flow;
- one-off Trip boat values supported;
- Trip overrides do not mutate profile;
- profile edits do not automatically mutate Trip snapshot;
- existing Trip exposes linked-profile relationship;
- explicit UI resync with confirmation;
- archived profiles excluded from normal selector;
- nullable Trip identity fields can be explicitly cleared.

### Localization / UX boundary
- DE/EN/ES/FR/HR/PT ARB key sets remain aligned.
- New Trip Boat capacity controls use the released mechanical pattern.
- No permanent navigation or UX-D Command Center scope was introduced.

## CI / QA

For amendment HEAD `b19e1736a2d5c7fa26836bb35d014ff46a6706e1`, GitHub Actions reports:
- **Flutter Analyze & Test — SUCCESS**
- **Backend Typecheck & Vitest — SUCCESS**

The implementation report records:
- `flutter analyze`: no issues;
- `flutter test`: **302/302 green**;
- dedicated PIVOT3-B file: **23 tests**.

The count is consistent with the previous 297-test state plus five amendment tests.

## Final classification

**PIVOT3-B — READY FOR OWNER ACCEPTANCE**

No blocking findings remain.

PIVOT3-B is not yet OWNER-ACCEPTED until the Product Owner explicitly accepts it.

## Gate

Do not start:
- PIVOT2
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store publication

After explicit Owner Acceptance, update the canonical repo status, close the completed PIVOT3-B/underlying issues as appropriate, and only then reconcile the next slice.

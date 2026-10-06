# PIVOT3-A Independent Review – 06.10.2026

Status: **AMENDMENT REQUIRED**

Reviewed implementation HEAD:

`2ebdabd89b71715be68964633bf57ccc9244ac63`

Canonical scope:
- `docs/impl/PIVOT3_reconciliation_2026-10-06.md`
- `docs/impl/PIVOT3A_plan.md`
- Issue #24

## Summary

The production implementation is directionally consistent with the released PIVOT3-A foundation scope:
- Drift schema v7 exists.
- `BoatProfiles` exists.
- Trip source/snapshot fields exist.
- explicit resync exists.
- backup payload was raised to v2.
- no visible PIVOT3-B UI was introduced.

However, the slice is **not ready for Owner Acceptance** because the implementation report claims acceptance evidence that is not present in the repository.

The required amendment is narrow: add the missing real automated acceptance proof, correct inaccurate reporting, run the full suite, and stop. Do not start PIVOT3-B.

## Finding A – Claimed 13 PIVOT3-A acceptance tests do not exist

**Severity: BLOCKING**

The report states that `test/features/boat/pivot3a_boat_profile_test.dart` contains 13 PIVOT3-A acceptance tests and that all 13 passed.

At reviewed HEAD, that file is empty:
- Git blob: `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391`
- additions: 0
- deletions: 0
- content length: 0 bytes

Therefore the named tests in the report are not present and cannot support the acceptance claims.

### Required fix

Populate the PIVOT3-A acceptance test file (or another clearly named test file) with real automated tests covering the plan's required behaviors, including at minimum:
- BoatProfile create/read/update/archive/delete
- active-profile filtering
- profile → new trip snapshot
- profile update does not mutate existing trip
- later new trip receives updated profile values
- explicit resync updates snapshot
- profile hard-delete nulls only `boatProfileId` and preserves snapshot values
- backward-compatible trip creation without a profile

Tests must exercise real Drift persistence/services rather than only mocks.

## Finding B – No real v6 → v7 migration test

**Severity: BLOCKING**

The modified `test/core/database/migration_test.dart` opens a fresh current-schema database and verifies schema version 7 / current columns. It does **not** create a v6 database and then exercise the actual `onUpgrade(..., 6, 7)` path.

The PIVOT3-A plan explicitly requires:
> Migration v6 → v7 without data loss.

The report's claim that this is proven by `PIVOT3-A 7. Migration v6 -> v7 ...` is unsupported because that named test is not present.

### Required fix

Add a genuine migration test that:
1. creates/opens a database at schema v6 (using the project's established Drift migration-test mechanism or an equivalent real SQLite schema fixture);
2. stores a representative existing trip with the old v6 boat fields;
3. upgrades through the production migration strategy to v7;
4. proves:
   - old trip data is unchanged;
   - `BoatProfiles` now exists;
   - `boatProfileId`, `boatName`, `boatManufacturer`, `boatModel` are null for old trips;
   - `hasWatermaker == false`;
   - existing fridge/freezer/tank/drinkability values survive;
   - foreign keys remain enabled/valid.

Also preserve the existing v1→latest migration coverage.

## Finding C – Backup v2 / v1 compatibility acceptance proof is missing

**Severity: BLOCKING**

The existing `test/core/services/backup_coordinator_test.dart` amendment only changes the expected payload version from 1 to 2 and checks that `boatProfiles` exists.

It does not prove the PIVOT3-A acceptance requirements claimed in the report:
- full BoatProfile field export;
- archived profiles;
- Trip snapshot export;
- profile ID remapping on v2 restore;
- restored Trip points to the newly generated profile ID;
- snapshot values survive independently;
- v1 payload restore into schema v7 with safe defaults.

The named tests `PIVOT3-A 8`, `PIVOT3-A 9`, and `PIVOT3-A 10` are not present at the reviewed HEAD.

### Required fix

Add real BackupCoordinator integration tests for:
1. v2 export with at least one profile + linked trip;
2. v2 restore into a clean database with profile ID remapping and preserved snapshots;
3. v1 restore into schema v7 proving `boatProfileId == null`, identity snapshots nullable/defaulted as specified, and `hasWatermaker == false`;
4. existing privacy behavior remains unchanged.

## Finding D – Implementation report contains factual inaccuracies

**Severity: NON-BLOCKING by itself, but must be corrected in the amendment report**

Examples at reviewed HEAD:
- Report claims `createdAt / updatedAt` for BoatProfiles; production schema contains `createdAt` only. The plan requires `createdAt` only.
- Report describes BoatProfile defaults inconsistently with production code (e.g. fridge capacity / water drinkability).
- Report refers to fields as `waterTankCapacity` / `waterDrinkable`, while production uses `waterTankLiters` / `isWaterTankDrinkable`.
- Report says `BoatProfileDao` updates a timestamp; there is no `updatedAt` field.
- Most importantly, the report claims 13 concrete tests and 275/275 with those tests even though the dedicated test file is empty.

### Required fix

Update `docs/impl/PIVOT3A_bericht.md` so every statement matches the actual implementation and every acceptance criterion names a test that really exists.

## Production-code review notes

No production-code rejection is issued at this stage. The following implementation choices are consistent enough with PIVOT3-A to retain during the amendment:
- profile fields and trip snapshot fields;
- nullable FK with `ON DELETE SET NULL`;
- profile values copied into trip snapshot on profile-backed creation;
- no automatic propagation after profile update;
- explicit `resyncTripBoatProfile`;
- v2 backup shape with global `boatProfiles` and trip snapshot fields;
- PIVOT3-B scope remains absent from visible UI.

The amendment should not refactor these areas unless a new real test exposes a defect.

## Required QA after amendment

Run and report:
- `flutter analyze`
- the dedicated PIVOT3-A tests
- real migration tests
- backup/restore tests
- full `flutter test`

The final report must state the actual test count from the executed suite.

## Gate

PIVOT3-A remains **IN REVIEW / AMENDMENT REQUIRED**.

Do not start:
- PIVOT3-B
- PIVOT2
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store publication

After the narrow amendment is pushed, stop for independent re-review.

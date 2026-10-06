# PIVOT3-A Final Acceptance Review – 06.10.2026

Status: **READY FOR OWNER ACCEPTANCE**

Reviewed amendment HEAD:

`7cb1eca06ad12617e091adcd62fdfb212acf0293`

Reviewed against:
- `docs/impl/PIVOT3A_plan.md`
- `docs/impl/PIVOT3A_review_2026-10-06.md`
- `docs/impl/PIVOT3_reconciliation_2026-10-06.md`
- actual production code and tests on `origin/main`

## Result

All blocking findings from the first independent review are closed.

### Finding A – real PIVOT3-A acceptance tests

**CLOSED**

`test/features/boat/pivot3a_boat_profile_test.dart` is no longer empty. It contains 13 real tests using:
- Drift/SQLite persistence
- production `BoatProfileService`
- production `TripService`
- production DAOs
- real catalog/quantity data

Verified coverage includes:
- create/read/update
- archive/unarchive
- active profile filtering
- delete
- profile → trip snapshot copy
- non-retroactive profile updates
- new trip receives updated profile values
- explicit resync
- persistence through resync/recalculation path
- FK `ON DELETE SET NULL`
- snapshot survival after profile deletion
- backward-compatible trip creation without profile

### Finding B – real v6 → v7 migration

**CLOSED**

`test/core/database/migration_test.dart` now creates a real SQLite file with:
- `PRAGMA user_version = 6`
- the relevant v6 `trips` schema and representative legacy trip data
- existing fridge/freezer/tank/drinkability values

It then opens the file through the production `AppDatabase`, exercising the real Drift `onUpgrade(6, 7)` path.

Verified:
- schema becomes v7
- existing trip survives
- old capacity values remain intact
- new source/identity fields are null
- `hasWatermaker == false`
- `BoatProfiles` exists
- FK behavior works after migration, including `ON DELETE SET NULL`

Review note: the hand-built migration fixture contains simplified/non-canonical definitions for some unrelated v6 tables. This is not blocking for PIVOT3-A because the v6→v7 production migration only creates `BoatProfiles` and alters `Trips`, and the relevant legacy `Trips` schema used by the test matches the actual pre-PIVOT3-A schema. A future migration-fixture framework would reduce maintenance risk.

### Finding C – Backup v2 / v1 compatibility

**CLOSED**

Three real BackupCoordinator integration tests are present.

Verified:
1. v2 export includes active and archived profiles plus linked trip snapshot data.
2. v2 restore proves actual profile-ID remapping using old ID `999`; the restored Trip points to the newly generated local profile ID.
3. Snapshot values remain independent after a restored profile is edited.
4. v1 payload restores into schema v7 with:
   - `boatProfileId == null`
   - identity snapshots null
   - `hasWatermaker == false`
   - previous fridge/freezer/tank/drinkability values preserved
   - no phantom profiles.

### Finding D – reporting accuracy

**CLOSED**

`docs/impl/PIVOT3A_bericht.md` now reflects the actual implementation:
- no fictitious `updatedAt`
- actual field names
- actual defaults
- actual DAO behavior
- real test names only

## Production implementation review

No new production defect was found during the amendment review.

The following PIVOT3-A behavior is accepted for Owner review:
- schema v7
- `BoatProfiles`
- nullable Trip source reference
- autonomous Trip snapshot fields
- profile updates do not mutate existing Trips
- later Trips receive updated profile values
- explicit resync updates the Trip snapshot
- profile hard-delete removes only the source reference
- v2 backup / v1 restore compatibility
- no visible PIVOT3-B feature leakage

## CI / QA

For amendment HEAD `7cb1eca06ad12617e091adcd62fdfb212acf0293`, GitHub Actions reports:
- **Flutter Analyze & Test — SUCCESS**
- **Backend Typecheck & Vitest — SUCCESS**

The implementation report records:
- `flutter analyze`: no issues
- `flutter test`: 279/279 green

The test-count increase is consistent with the added 13 PIVOT3-A tests + 1 migration test + 3 backup integration tests over the prior 262-test baseline.

## Final classification

**PIVOT3-A — READY FOR OWNER ACCEPTANCE**

No blocking findings remain.

PIVOT3-A is not yet OWNER-ACCEPTED until the Product Owner explicitly accepts it.

## Gate

Do not start:
- PIVOT3-B
- PIVOT2
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store publication

After explicit Owner Acceptance, update the canonical repo status and only then decide/release PIVOT3-B.

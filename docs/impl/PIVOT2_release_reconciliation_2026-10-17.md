# PIVOT2 Release Reconciliation – 17.10.2026

Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Owner release phrase:

`pivot2 go`

Canonical baseline at release:

`origin/main@1bdb5e55407419f16b850300104a30417b9fec4f`

This release supersedes conflicting PIVOT2 water/catalog wording in:

- `docs/impl/PIVOT2_release_reconciliation_2026-10-06.md`
- `docs/impl/PIVOT2_plan.md`

Canonical product/review basis:

- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/impl/PIVOT2_reconciliation_2026-10-17.md`
- `docs/impl/WATER1_simplification_reconciliation_2026-10-16.md`
- `docs/impl/WATER1_acceptance_review_2026-10-17.md`
- `docs/design/PROVY_UX_BENCHMARK_STRATEGY_v0.1.md`
- `docs/design/PROVY_UX_DIRECTION_v0.5.md`
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
- `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`

## 1. Release decision

PIVOT2 is now the **only released implementation slice**.

Goal:

Add a read-only Provisioning Review / Copilot layer over the skipper-built list.

The review helps the skipper notice:

- missing basics;
- drinking-water planning context;
- freshness / shelf-life concerns;
- fridge/freezer contradictions;
- known cooling capacity overload;
- total weight/volume information.

It never builds, mutates, repairs or redistributes the list automatically.

## 2. Water decision — OWNER-ACCEPTED

The owner accepted the recommendation that water undercoverage is **CHECK**, not `ACTION_NEEDED`.

Canonical WATER1 estimate:

`minimumDrinkingWater = climateDailyLiters × crewFactorSum × effectiveDays`

with:

`effectiveDays = daysUntilNextStop ?? daysCount`

If explicitly selected/adopted drinking water is below the estimate:

- finding severity: `CHECK`;
- show estimated minimum and explicit selected amount;
- show Tank/Watermaker facts as context when present;
- explain that Tank, Watermaker and refill opportunities may cover part or all of the difference;
- do not claim water supply is insufficient;
- do not calculate mandatory extra liters to buy;
- do not mathematically reduce the estimate by Tank/Watermaker.

If selected drinking water meets/exceeds the estimate:

- no water-undercoverage warning;
- optional info context may remain if useful, but must not create warning clutter.

## 3. AssistType truth

Production catalog:

`data/catalog_v0.11.json`

Production quantities:

`data/quantities_v0.6.json`

AssistType is exclusively catalog-driven via accepted DATA1 effective-assist semantics.

PIVOT2 must not:

- hard-code preference/guided/needs group IDs;
- use substring/name heuristics;
- silently default an unknown assist type.

Rules:

- needs-based: objective review may evaluate quantity, subject to domain-specific severity;
- guided: no generic global undercoverage finding;
- preference-based: no quantity finding.

Water is currently the relevant needs-based group, but PIVOT2 must consume effective AssistType rather than encode `water` as the definition of needs-based.

## 4. Missing Basics rules

Create:

`data/provisioning_review_v0.1.json`

Strict typed parsing and catalog validation are mandatory.

No UI copy in the JSON.

Initial canonical rules:

### durable_bread

Purpose: some durable bread reserve is on the actual list.

Matcher:

- group: `bread`;
- adopted/on-list item only;
- catalog variant must have `shelf_life_days >= quantities.rounding.durable_min_shelf_life_days`;
- threshold remains data-driven from quantities v0.6 (current value 14);
- finding severity when absent: `CHECK`.

Do not hard-code 14 in review logic.

### cooking_oil

Any adopted variant:

- `olive_oil`
- `sunflower_oil`

Finding severity when absent: `CHECK`.

Balsamico/vinegar do not satisfy cooking oil.

### hygiene_basic

At least one adopted catalog item from group:

- `hygiene`

Finding severity when absent: `CHECK`.

### cleaning_basic

Any adopted variant:

- `dish_soap`
- `all_purpose`

Finding severity when absent: `CHECK`.

### trash_bags

Adopted variant:

- `trash_bags`

Finding severity when absent: `CHECK`.

Custom items do not satisfy canonical catalog rules by name matching.

All referenced groups/variants must validate against catalog v0.11 at load time.

## 5. Freshness / shelf life

Only actual adopted catalog items are reviewed.

A contextual `CHECK` is valid when:

- `buy_fresh_underway == true`; or
- shelf life is shorter than the relevant trip/stop horizon.

The review may:

- explain shelf-life concern;
- mention a later existing ShoppingStop;
- open the existing stop-assignment flow.

It must not:

- reallocate automatically;
- change package count;
- invent a durable substitute;
- assume an item will be frozen just because `shelf_life_frozen_days` exists.

Issue #8 remains a closure target for PIVOT2.

## 6. Fridge / freezer

`ACTION_NEEDED` remains valid for hard technical contradictions:

- `chill=fridge` and fridge capacity is 0 l;
- `chill=freezer` and no freezer exists;
- known quantifiable chilled load > known fridge capacity;
- known quantifiable frozen load > known freezer capacity.

Accepted conversions only:

- l/ml directly;
- kg/g using the existing accepted 1 kg ≈ 1 l approximation.

Do not invent volume for piece/package items without usable volume data.

If not everything can be quantified, do not say “fits”; a calm `CHECK` may explain that capacity could not be fully assessed.

## 7. Weight / volume

Reuse the existing actual-list calculation.

Show total weight/volume as information.

Do not change readiness merely from total weight/volume without a real configured capacity limit.

## 8. Review states

Exactly:

- `READY`
- `CHECK`
- `ACTION_NEEDED`

Aggregation:

- any actionNeeded → ACTION_NEEDED;
- else any check → CHECK;
- else READY.

No score, percentage, gamification or blocking gate.

## 9. Read-only guarantee

Opening, refreshing or dismissing the review must not mutate:

- adopted state;
- selected state;
- package overrides;
- custom pack size;
- list quantities;
- custom items;
- ShoppingStop allocations;
- crew;
- trip;
- boat snapshot.

Review actions may only open existing explicit user flows.

## 10. UX release decision

PIVOT2 creates one new focused consumer surface under `Vorräte`.

Before implementing that surface, perform a scoped PIVOT2 benchmark pass and document it.

Primary North Star:

**Instacart shopping/list context patterns**

Required outcome:

- `Liste prüfen` is a visible secondary action inside the existing Vorräte surface;
- no new top-level navigation;
- findings grouped clearly by urgency/context;
- concise list rows/cards rather than a new dashboard;
- one highest-priority contextual hint maximum inline on an affected item;
- existing search/edit/stop flows reused;
- Material 3 accessibility and touch-target principles;
- Provy Off-White/Navy/Dark/Nightwatch system retained;
- no copying of Instacart brand identity.

The benchmark pass classifies relevant PIVOT2 surfaces/patterns as:

- `KEEP`
- `ADOPT_PATTERN`
- `SIMPLIFY`
- `REMOVE`

It must not reopen the frozen global information architecture.

## 11. Issue mapping

- Issue #7 remains open and is a PIVOT2 regression/closure target.
- Issue #8 remains open and is a PIVOT2 closure target.
- Issue #9 is already closed by PIVOT1 and must not be reintroduced.

Do not close #7/#8 until PIVOT2 independent review + Owner Acceptance confirms their closure criteria.

## 12. Strict non-scope

Do not implement:

- automatic list mutation;
- automatic ShoppingStop distribution;
- recipes/menu planning;
- AI review;
- Watermaker capacity/performance;
- total freshwater requirement;
- provider/vendor/assortment;
- Guest Shopping;
- receipts;
- UX-D Command Center;
- B3/B4/B5;
- Store publication.

## 13. Implementation workflow

Expected review branch:

`slice/pivot2-provisioning-review`

One PR against `main`.

GitHub Actions is authoritative Full-QA.

After final green CI:

- do not merge;
- do not close Issue #26;
- do not close #7/#8;
- do not start another slice;
- STOP for independent review / Owner Acceptance.

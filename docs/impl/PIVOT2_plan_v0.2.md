# PIVOT2 – Provisioning Review – Implementierungsplan v0.2

Stand: 17.10.2026  
Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Canonical release:

`docs/impl/PIVOT2_release_reconciliation_2026-10-17.md`

This plan supersedes conflicting content in `docs/impl/PIVOT2_plan.md`.

## A. Scoped UX Benchmark Pass first

Before UI implementation, create:

`docs/design/PIVOT2_UX_BENCHMARK_PASS_2026-10-17.md`

Use:

- Instacart as primary shopping/list reference;
- Material 3 as technical/accessibility basis;
- existing Provy frozen IA as hard boundary.

Document at minimum:

1. current `Vorräte` entry point;
2. `Liste prüfen` secondary action;
3. review summary/list;
4. grouped findings;
5. contextual inline item hint;
6. finding action handoff to existing flows.

For each classify:

- KEEP
- ADOPT_PATTERN
- SIMPLIFY
- REMOVE

No global IA change.

## B. Review domain model

Add strict typed domain models, equivalent to:

### ProvisioningReviewStatus
- ready
- check
- actionNeeded

### ProvisioningReviewSeverity
- info
- check
- actionNeeded

### ProvisioningReviewKind

At minimum:

- missingBasic
- drinkingWaterCheck
- freshness
- fridgeRequirement
- freezerRequirement
- fridgeCapacity
- freezerCapacity
- incompleteCoolingAssessment

### ProvisioningReviewActionType

At minimum:

- noAction
- searchOrAdd
- editItem
- assignShoppingStop

### ProvisioningReviewFinding

Structured fields only:

- stable finding ID
- kind
- severity
- optional catalog group/variant ID
- optional listItemId
- structured numeric values + units where relevant
- structured action
- no localized rendered sentence in domain model

### ProvisioningReviewResult

- overall status
- findings
- actual-list weight/volume info
- known/unknown cooling assessment metadata as needed

No DB persistence for review result.

## C. Review config data

Create:

`data/provisioning_review_v0.1.json`

Add to assets.

Strict parsing:
- unknown rule type → fail
- missing required fields → fail
- duplicate rule ID → fail
- unknown group/variant reference → fail
- invalid severity/type → fail

Validate against production:

`data/catalog_v0.11.json`

Initial rules:

### durable_bread
- type: shelf-life-qualified group presence
- group: bread
- threshold source: `quantities.rounding.durable_min_shelf_life_days`
- adopted items only
- absent → CHECK

### cooking_oil
- type: any adopted variant present
- variants:
  - olive_oil
  - sunflower_oil
- absent → CHECK

### hygiene_basic
- type: adopted group present
- group: hygiene
- absent → CHECK

### cleaning_basic
- type: any adopted variant present
- variants:
  - dish_soap
  - all_purpose
- absent → CHECK

### trash_bags
- type: adopted variant present
- variant:
  - trash_bags
- absent → CHECK

No custom-item string matching.

## D. Review service

Implement deterministic read-only review service/domain component.

Inputs:

- Trip snapshot
- crew
- actual current ShoppingList
- catalog v0.11
- quantities v0.6
- review config
- ShoppingStops / allocations
- current QuantityEngine result

Only actual adopted/on-list items count.

The service itself must not write through DAOs.

## E. Effective AssistType

Use DATA1 accepted effective-assist resolution.

Do not duplicate AssistType logic.

Rules:

- needs-based: may be quantity-reviewed according to domain semantics;
- guided: no generic undercoverage finding;
- preference-based: no quantity finding.

No hard-coded preference IDs or substring heuristics.

## F. Drinking water

Use WATER1 calculation truth.

Review fields should include:

- estimated minimum drinking-water need;
- actual adopted drinking-water amount;
- optional context flags:
  - potable tank present
  - Watermaker present

Actual amount:
- adopted water-group variants only;
- effective user package count;
- normalize supported volume units using existing conversion semantics;
- do not count unadopted catalog suggestions.

If actual selected amount < minimum:

- finding kind: drinkingWaterCheck
- severity: CHECK
- show actual vs estimate
- explain through localization that Tank/Watermaker/refill may cover the difference
- do not compute a mandatory purchase delta as a command
- do not set ACTION_NEEDED solely from this comparison

If actual >= minimum:
- no undercoverage CHECK required.

Tank/Watermaker must not reduce the minimum estimate mathematically.

## G. Missing Basics

Apply config only to adopted catalog items.

Absent rule → CHECK.

No auto-adopt.

No inferred fulfillment from custom item names.

## H. Freshness / shelf life

Review adopted catalog items.

CHECK when relevant:
- `buyFreshUnderway == true`; or
- shelf life shorter than relevant horizon.

Use existing shopping stops/allocations as context.

Do not:
- auto-reallocate;
- change package count;
- invent substitute;
- assume frozen storage unless explicitly required by actual chill semantics.

Issue #8 proof:
- fresh rolls/baguette on a multi-day trip produces contextual CHECK;
- quantities unchanged;
- allocations unchanged.

## I. Fridge / freezer

ACTION_NEEDED:
- fridge-required adopted item and fridge capacity = 0;
- freezer-required adopted item and no freezer;
- fully quantifiable known chilled load > fridge capacity;
- fully quantifiable known frozen load > freezer capacity.

Conversions:
- l/ml direct;
- kg/g with existing project 1kg≈1l approximation.

For piece/package units without known volumetric basis:
- do not fabricate volume;
- mark assessment incomplete;
- optional CHECK if that uncertainty matters.

No false READY based on partial known volume when unknown chilled/frozen items remain.

## J. Weight / volume

Reuse current actual-list weight/volume calculation.

Display as INFO.

No status impact without a configured capacity limit.

## K. Readiness aggregation

- any actionNeeded → actionNeeded
- else any check → check
- else ready

Info findings do not worsen readiness.

No numerical score.

## L. UI

Within existing `Vorräte`:

- visible secondary action `Liste prüfen`;
- focused Review route/screen or sheet consistent with scoped benchmark result;
- no permanent top-level navigation;
- sections in priority order:
  - Aktion nötig
  - Noch prüfen
  - Informationen
- omit empty sections;
- concise finding rows;
- at most one highest-priority contextual inline hint per affected adopted item;
- action button/link near relevant finding;
- action reuses existing explicit search/edit/stop flow.

Review opening/refreshing itself changes nothing.

Respect:
- Light Off-White/Navy
- Dark
- Nightwatch
- accessibility
- large touch targets
- color not sole status signal.

## M. Localization

All visible strings in:

- DE
- EN
- FR
- ES
- PT
- HR

ARB key parity required.

Domain models contain no localized prose.

## N. Issue regressions

### Issue #7
Prove:
- package-first representation remains primary;
- guided item does not get generic undercoverage alarm;
- preference item does not get quantity warning;
- review never overwrites manual package count.

Do not close until Owner Acceptance.

### Issue #8
Prove:
- fresh short-life item produces CHECK;
- no auto-distribution;
- allocations and package count unchanged.

Do not close until Owner Acceptance.

### Issue #9
Already closed.
No meal-frequency engine.

## O. Required automated proof

At minimum:

1. Review pure/read-only: serialized relevant DB/list/allocation state identical before/after review.
2. Strict review-config parsing.
3. All config IDs validate against catalog v0.11.
4. durable bread satisfied / missing.
5. cooking oil satisfied / missing.
6. hygiene satisfied / missing.
7. cleaning satisfied / missing.
8. trash bags satisfied / missing.
9. custom string lookalike does not satisfy catalog rule.
10. AssistType uses DATA1 effective assist.
11. guided → no generic quantity undercoverage.
12. preference → no quantity finding.
13. WATER1 estimate reused.
14. water below estimate → CHECK, not ACTION_NEEDED.
15. potable tank does not reduce water estimate.
16. Watermaker does not reduce water estimate.
17. water at/above estimate → no undercoverage CHECK.
18. fresh rolls/baguette → freshness CHECK.
19. freshness review does not change packages/allocations.
20. fridge-required + 0 capacity → ACTION_NEEDED.
21. freezer-required + no freezer → ACTION_NEEDED.
22. known fridge load > capacity → ACTION_NEEDED.
23. known freezer load > capacity → ACTION_NEEDED.
24. unknown volume does not fabricate exact number or false fit.
25. weight/volume info reuses actual-list calculation.
26. status aggregation ready/check/actionNeeded.
27. real `Liste prüfen` entry from current Vorräte surface.
28. review grouped sections render correctly.
29. max one inline highest-priority hint on affected item.
30. existing finding actions open existing flows.
31. all six locales complete.
32. Issue #7 regression.
33. Issue #8 regression.
34. PIVOT1 relevant regression green.
35. DATA1 relevant regression green.
36. PIVOT3-A/B relevant regression green.
37. WATER1 relevant regression green.
38. full GitHub Actions green on final PR HEAD.

## P. No-scope

No:
- DB schema unless strictly unavoidable and explicitly stopped for review first;
- automatic list changes;
- automatic stop redistribution;
- recipes/menu planner;
- AI;
- provider/vendor/assortment;
- receipt work;
- Guest Shopping;
- UX-D Command Center;
- B3/B4/B5;
- Store publication;
- new water formula;
- Watermaker capacity model.

## Q. Delivery / review workflow

Review branch:

`slice/pivot2-provisioning-review`

Create one PR against `main`.

Create/update:

`docs/impl/PIVOT2_bericht.md`

Report:
- baseline main SHA
- implementation commits
- files changed
- benchmark pass
- data config
- read-only proof
- each acceptance criterion
- final PR HEAD
- actual GitHub Actions run/jobs

Do not report CI success before it exists on the final PR HEAD.

After final green CI:

- PR NOT merge
- Issue #26 NOT close
- Issues #7/#8 NOT close
- no next slice
- STOP for independent review / Owner Acceptance.

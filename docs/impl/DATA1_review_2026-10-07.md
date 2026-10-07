# DATA1 Independent Review – 07.10.2026

Status: **AMENDMENT REQUIRED**

Reviewed implementation HEAD:

`73cfdecefe16721e11fa33878a18a751f092c330`

Note: the completion message reported `73cfdecefe16721e11fa33878a18aa751f092c330`; that SHA contains one extra `a` and does not exist. The canonical `origin/main` implementation HEAD is the SHA above.

Reviewed against:

- `docs/impl/DATA1_release_reconciliation_2026-10-07.md`
- `docs/impl/DATA1_plan.md`
- `docs/PROMPT_SESSION_START_v0.8.md`
- actual production code and tests
- GitHub Actions on the reviewed HEAD

## Verified good

The core migration is correct:

- `data/catalog_v0.11.json` exists and v0.10 remains unchanged.
- v0.11 contains 47 groups and 232 variants.
- Group mapping is exactly:
  - 1 needs_based: `water`
  - 5 preference_based: `spread_sweet`, `spread_savory`, `sweets`, `savory_snacks`, `spirits`
  - 41 guided
- Exactly 11 variant overrides are present:
  - brie
  - feta
  - mozzarella
  - parmesan
  - sauce_jar
  - pesto
  - soy_sauce
  - bbq_sauce
  - sweet_chili
  - tabasco
  - tofu
- Comparing v0.10 and v0.11 after removing only the allowed version/schema/assist additions yields semantic equality for all other catalog data.
- Group assist parsing is strict.
- Variant assist override parsing is strict.
- Missing group assist fails.
- Unknown assist values fail.
- Catalog lookup for unknown group/variant fails.
- CatalogRepository now loads v0.11.
- PIVOT1 preference/guided/needs-based behavior remains covered.
- Full Flutter suite reported 379 passing tests.
- GitHub Actions:
  - Flutter Analyze & Test: SUCCESS
  - Backend Typecheck & Vitest: SUCCESS

The existing `item_row_widget.dart` water-specific UI heuristic is not treated as a DATA1 blocker. It drives pre-existing water boost UI, not AssistType classification. Replacing it with `assistType.isNeedsBased` would incorrectly equate every future needs-based product with drinking water and would be a separate product/data decision.

## Finding A – Silent guided fallback remains in production

Severity: **BLOCKING / NARROW**

`VariantCalculationResult.assistType` is declared non-null but the constructor still contains:

`this.assistType = AssistType.guided`

This creates a second classification truth outside the catalog.

It is not merely theoretical. `QuantityEngine._processCheckGroup()` constructs `VariantCalculationResult` without passing `assistType`, so this production path currently relies on the silent guided fallback.

All current check-mode groups happen to be guided in v0.11, so there is no current visible behavior regression. However, the implementation violates DATA1's explicit requirement that AssistType be propagated from catalog data with no silent fallback.

### Required fix

- Make `VariantCalculationResult.assistType` a required constructor parameter.
- In `_processCheckGroup()`, pass the effective catalog-driven assist for every variant.
- Add a regression test proving a check-mode variant result receives its catalog-driven effective AssistType and cannot silently become guided.

No quantity behavior change.

## Finding B – ShoppingListItemView has the same silent default

Severity: **BLOCKING / NARROW**

`ShoppingListItemView.assistType` also contains:

`this.assistType = AssistType.guided`

Catalog item production construction currently passes the correct value explicitly, so ordinary catalog items are correct.

Custom item construction relies on the constructor default.

The DATA1 plan requires AssistType to be propagated explicitly rather than created by a hidden fallback. A constructor default can also hide future missed wiring for catalog items.

### Required fix

- Make `ShoppingListItemView.assistType` required.
- Keep catalog items explicitly catalog-driven.
- Preserve current custom-item behavior explicitly at the custom-item construction boundary. DATA1 must not invent a new custom-item product classification.
- Add/adjust a regression proving catalog items cannot omit AssistType and custom items retain the pre-DATA1 behavior intentionally.

No new UI or review behavior.

## Finding C – Effective Assist resolution is duplicated

Severity: **BLOCKING / NARROW**

DATA1 explicitly required one central deterministic rule:

`variant.assistOverride ?? group.assist`

and stated that this resolution must not be duplicated in multiple production locations.

The implementation correctly adds `CatalogData.getEffectiveAssist()`, but QuantityEngine still duplicates the raw rule at multiple lines/paths:

- equal-split selection
- equal-split computation
- each-split computation
- selected computation

A second copy also remains in `AssistClassifier.effectiveFor()`.

This weakens the purpose of DATA1: future resolution changes could diverge between engine paths even though catalog parsing is correct.

### Required fix

- Use one central production resolution API.
- Prefer `CatalogData.getEffectiveAssist(variant)` throughout QuantityEngine.
- Remove raw `assistOverride ?? group.assist` resolution from QuantityEngine.
- If `AssistClassifier` has no actual production caller, remove it and its unnecessary catalog-model import; this also removes the circular import between `assist_type.dart` and `catalog_models.dart`.
- If it is retained, it must not form an independent duplicate truth; justify and test the single resolution path.

## Non-blocking report corrections

- `catalog_validation_test.dart` was modified/expanded, not newly added.
- The completion-message SHA had a one-character typo; reviewed canonical SHA is recorded above.

Neither item requires product behavior changes.

## Amendment scope

The amendment is deliberately small.

Allowed:
- remove silent AssistType defaults;
- explicitly propagate effective AssistType;
- centralize resolution through one API;
- remove unused AssistClassifier facade/circular import if appropriate;
- targeted regression tests;
- report/changelog updates.

Not allowed:
- change v0.11 mappings;
- alter v0.10;
- change quantity formulas;
- alter water UI heuristic;
- start Watermaker work;
- start PIVOT2;
- add new catalog semantics.

## Gate

DATA1 remains **IN REVIEW / AMENDMENT REQUIRED**.

Issue #28 stays open.

After the amendment:
1. run targeted DATA1/PIVOT1 tests;
2. run full Flutter suite;
3. run `flutter analyze`;
4. push;
5. STOP for independent re-review / Owner Acceptance.

No next slice is released.

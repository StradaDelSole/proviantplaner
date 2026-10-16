# Session Start Prompt v0.12 – PIVOT2 Provisioning Review

Wir setzen `StradaDelSole/proviantplaner` mit **PIVOT2 – Provisioning Review** fort.

PIVOT2 ist der einzige aktuell freigegebene Implementierungsslice.

Nicht automatisch starten:
- RECEIPT1
- GUEST1
- UX-D
- Provider Assortment
- CAT1
- B3/B4/B5
- Store publication

## 1. Repo zuerst rekonstruieren

Vor jeder Änderung:

`git status`
`git branch --show-current`
`git fetch origin`
`git rev-parse HEAD`
`git rev-parse origin/main`
`git diff`
`git diff --cached`

`origin/main` ist kanonische Wahrheit.

Nicht von einem statischen SHA ausgehen.

Erwarteter Review-Branch:

`slice/pivot2-provisioning-review`

Wenn der Branch noch nicht existiert:
- vom aktuellen `origin/main` erstellen.

Kein Implementation-Push direkt auf `main`.

## 2. Pflichtlektüre

Vollständig lesen:

1. `README.md`
2. `GEMINI.md`
3. `docs/impl/PIVOT2_release_reconciliation_2026-10-17.md`
4. `docs/impl/PIVOT2_reconciliation_2026-10-17.md`
5. `docs/impl/PIVOT2_plan_v0.2.md`
6. `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
7. `docs/impl/WATER1_simplification_reconciliation_2026-10-16.md`
8. `docs/impl/WATER1_acceptance_review_2026-10-17.md`
9. `docs/design/PROVY_UX_BENCHMARK_STRATEGY_v0.1.md`
10. `docs/design/PROVY_UX_DIRECTION_v0.5.md`
11. `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
12. `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`

Historical only / superseded where conflicting:

- `docs/impl/PIVOT2_release_reconciliation_2026-10-06.md`
- `docs/impl/PIVOT2_plan.md`
- `docs/impl/EXTERNAL_REVIEW_RECONCILIATION_2026-10-06.md`

Newest explicit reconciliation wins.

## 3. Product principle

PIVOT2 is a read-only Copilot over the skipper-built list.

> Der Skipper baut die Liste. Provy macht sie vollständig, realistisch und bordtauglich.

The Review may:
- point out;
- explain;
- summarize;
- link into existing explicit edit/search/stop flows.

The Review must not itself:
- adopt/remove items;
- change quantities;
- change overrides;
- change custom items;
- redistribute ShoppingStops;
- mutate Crew/Trip/Boat.

## 4. First implementation action: scoped UX benchmark pass

Before coding the new review surface, create:

`docs/design/PIVOT2_UX_BENCHMARK_PASS_2026-10-17.md`

Use:
- Instacart shopping/list patterns as primary North Star;
- Material 3 as technical/accessibility basis;
- frozen Provy IA as hard boundary.

Classify at minimum:
- Vorräte entry point
- Liste prüfen CTA
- Review surface
- grouped finding rows
- contextual inline hint
- finding actions

as:
- KEEP
- ADOPT_PATTERN
- SIMPLIFY
- REMOVE

Do not reopen Home/Command Center/global navigation.

Do not copy Instacart visual brand identity.

## 5. Production data truths

Production catalog:

`data/catalog_v0.11.json`

Production quantities:

`data/quantities_v0.6.json`

DATA1 effective AssistType is authoritative.

Do not hard-code assist classification.

Do not use name/string heuristics.

## 6. Review config

Create:

`data/provisioning_review_v0.1.json`

Add it as an asset.

Strict typed parsing + validation.

Required rules:

### durable_bread
- group: `bread`
- adopted catalog item only
- shelf life >= `quantities.rounding.durable_min_shelf_life_days`
- missing → CHECK
- threshold must remain data-driven

### cooking_oil
- any adopted:
  - `olive_oil`
  - `sunflower_oil`
- missing → CHECK

### hygiene_basic
- any adopted item in group:
  - `hygiene`
- missing → CHECK

### cleaning_basic
- any adopted:
  - `dish_soap`
  - `all_purpose`
- missing → CHECK

### trash_bags
- adopted:
  - `trash_bags`
- missing → CHECK

No custom-item text matching.

Unknown config IDs/types/references must fail.

## 7. Domain model

Use strict types for:

- ProvisioningReviewStatus
  - ready
  - check
  - actionNeeded

- ProvisioningReviewSeverity
  - info
  - check
  - actionNeeded

- ProvisioningReviewKind
  - missingBasic
  - drinkingWaterCheck
  - freshness
  - fridgeRequirement
  - freezerRequirement
  - fridgeCapacity
  - freezerCapacity
  - incompleteCoolingAssessment

- ProvisioningReviewActionType
  - noAction
  - searchOrAdd
  - editItem
  - assignShoppingStop

Finding data is structured.

No localized rendered sentence inside domain logic.

No DB persistence of Review result.

## 8. Assist behavior

### needs-based
May be quantity-reviewed according to the domain-specific semantics below.

### guided
No generic global undercoverage finding.

### preference-based
No quantity finding.

Use the accepted DATA1 effective assist path; do not reimplement classification.

## 9. WATER1 behavior — binding

Canonical estimate:

`minimumDrinkingWater = climateDailyLiters × crewFactorSum × effectiveDays`

Do not create another formula.

Actual selected drinking water:
- only adopted/on-list water variants;
- effective user package count;
- normalize supported volume units using existing project conversion semantics.

If selected drinking water < estimate:

**CHECK, not ACTION_NEEDED.**

Finding must communicate:
- estimate
- explicitly selected amount
- optional Tank/Watermaker context
- Tank/Watermaker/refill options may cover some/all difference
- skipper should verify actual water plan

Do not:
- subtract Tank/Watermaker from target;
- claim the boat is under-supplied;
- require X extra liters;
- introduce Watermaker l/h or total freshwater model.

If actual >= estimate:
- no undercoverage CHECK.

## 10. Missing basics

Only adopted catalog items satisfy rules.

Missing rule → CHECK.

Never auto-add.

Custom lookalike item names do not satisfy canonical rules.

## 11. Freshness / shelf life

Review adopted catalog items.

CHECK if:
- `buyFreshUnderway == true`; or
- shelf life is shorter than relevant trip/ShoppingStop horizon.

May show/offer existing later ShoppingStop.

Must not:
- auto-reallocate;
- change packages;
- create substitute;
- assume freezing from `shelf_life_frozen_days` alone.

Issue #8 is a regression/closure target after Owner Acceptance.

## 12. Fridge / freezer

ACTION_NEEDED only for hard technical contradictions:

- fridge-required + fridge capacity 0
- freezer-required + no freezer
- fully quantifiable known fridge load > capacity
- fully quantifiable known freezer load > capacity

Conversions:
- l/ml direct
- kg/g via existing accepted 1kg≈1l approximation

Piece/package without reliable volume:
- do not invent exact volume;
- do not claim it fits;
- use incomplete assessment / CHECK where appropriate.

## 13. Weight / volume

Reuse the existing actual-list weight/volume truth.

Display as INFO.

No readiness downgrade solely from weight/volume without a configured limit.

## 14. Readiness

Overall:

- any actionNeeded → ACTION_NEEDED
- else any check → CHECK
- else READY

No score.
No percentage.
No gamification.
No blocking workflow.

## 15. UI

Within existing `Vorräte` only.

Required:
- visible secondary `Liste prüfen`
- focused review surface
- groups:
  - Aktion nötig
  - Noch prüfen
  - Informationen
- omit empty groups
- concise finding rows
- one highest-priority contextual inline hint maximum per affected adopted item
- actions open existing search/edit/ShoppingStop flows

No new top-level navigation.

Respect Light, Dark, Nightwatch, accessibility and large touch targets.

## 16. Required automated proof

At minimum all 38 criteria from:

`docs/impl/PIVOT2_plan_v0.2.md`

Must be covered.

Especially prove:

- review read-only with before/after state
- config strictness and catalog-v0.11 references
- DATA1 AssistType behavior
- water below estimate = CHECK
- Tank/Watermaker do not mathematically change target
- freshness never reallocates
- fridge/freezer hard contradictions = ACTION_NEEDED
- unknown cooling volume does not fabricate precision
- status aggregation
- real UI entry/action flows
- all six locales
- Issue #7 regression
- Issue #8 regression
- PIVOT1/DATA1/PIVOT3/WATER1 relevant regressions

## 17. No-scope

Do not implement:

- automatic list mutation
- automatic stop distribution
- recipes/menus
- AI
- provider/vendor assortment
- Watermaker capacity
- total freshwater
- receipts
- Guest Shopping
- UX-D Command Center
- B3/B4/B5
- Store publication

If a DB migration appears necessary, STOP and report why before implementing it. PIVOT2 is expected to be derived/read-only with no new DB schema.

## 18. Local QA

Do not run the full local Flutter suite on the owner's machine.

Use targeted tests only if useful and non-disruptive.

GitHub Actions is authoritative Full-QA.

## 19. Report

Create/update:

`docs/impl/PIVOT2_bericht.md`

Document:
- baseline `origin/main` SHA
- review branch
- benchmark pass
- config/data
- production architecture
- read-only proof
- all acceptance criteria
- targeted tests if run
- final PR HEAD
- actual GitHub Actions run/jobs

Do not claim success before CI actually ran on final HEAD.

## 20. PR / STOP

Open one PR against `main`:

Review branch:

`slice/pivot2-provisioning-review`

Issue #26 remains open.

Issues #7/#8 remain open.

When final HEAD has:
- Flutter Analyze & Test SUCCESS
- Backend Typecheck & Vitest SUCCESS

then:

- set PR Ready for Review
- report exact final HEAD + CI
- PR NOT merge
- Issue #26 NOT close
- #7/#8 NOT close
- no next slice
- STOP for independent review / Owner Acceptance

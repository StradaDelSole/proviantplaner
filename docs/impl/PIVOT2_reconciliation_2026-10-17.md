# PIVOT2 Reconciliation – 17.10.2026

Status: **OWNER-ACCEPTED / IMPLEMENTATION RELEASED**

Canonical repo baseline:

- `origin/main@d8c6fb81a361926e8aefc85d5d6ef7f3cdf9a025`
- FIX-B: OWNER-ACCEPTED / COMPLETE
- DATA1: OWNER-ACCEPTED / COMPLETE
- WATER1: OWNER-ACCEPTED / COMPLETE
- UX Benchmark Strategy: OWNER-ACCEPTED

This reconciliation updates the previously released-but-held PIVOT2 documents after the prerequisites were completed.

It does **not** release implementation.

## 1. Reconciliation classification

### DECIDED_AND_IMPLEMENTED

- PIVOT1 search-first, skipper-built list
- catalog-driven AssistType via DATA1
- catalog v0.11 is production truth
- quantities v0.6 is production truth
- manual package overrides survive recalculation
- preference-based items have no automatic quantity requirement
- ShoppingStops and manual allocations
- shelf-life / buy-fresh-underway metadata
- chill requirements
- fridge/freezer capacities
- Boat/Trip water facts
- WATER1 minimum drinking-water calculation
- actual list weight/volume calculation

### DECIDED_NOT_IMPLEMENTED / READY

- read-only Provisioning Review
- structured findings
- readiness states
- data-driven missing-basics rules
- freshness/shelf-life review
- cooling/freezer plausibility review
- weight/volume review summary
- contextual actions into existing edit/search/stop flows

### SUPERSEDED

- PIVOT2 references to catalog v0.10 → production catalog is v0.11
- old PIVOT3-B Watermaker/tank reserve semantics
- PIVOT2 acceptance criterion requiring “correct bottle reserve” from tank/Watermaker configuration
- any interpretation that Tank/Watermaker mathematically solve or reduce the WATER1 minimum drinking-water estimate
- automatic fresh-item reallocation
- meal-frequency / recipe logic for preference items

### UNDECIDED / OWNER DECISION REQUIRED BEFORE RELEASE

- severity of a water undercoverage finding after WATER1 simplification

## 2. Recommended water semantics for PIVOT2

WATER1 deliberately separated **need** from **supply method**.

Canonical need:

`minimumDrinkingWater = climateDailyLiters × crewFactorSum × effectiveDays`

Tank, Watermaker, refill opportunities and additional freshwater usage are not automatically modeled as coverage.

Therefore a comparison between the minimum drinking-water estimate and explicitly selected bottled water is **not sufficient evidence for ACTION_NEEDED**.

Recommended PIVOT2 behavior:

### Water finding

Show:

- estimated minimum drinking-water need;
- actual explicitly selected drinking-water amount;
- whether Watermaker exists;
- whether a potable tank exists;
- neutral planning note that other supply sources are not automatically counted.

If explicitly selected drinking water is below the minimum estimate:

**severity = CHECK**

Suggested meaning:

> The selected drinking water is below the estimated minimum drinking-water requirement. Tank, Watermaker and refill options may cover part or all of the difference; verify your actual water plan.

Do not automatically state:

- “you must buy X more liters”;
- “water supply is insufficient”;
- “ACTION_NEEDED” solely from bottled-water comparison.

If selected drinking water meets/exceeds the estimate:

- no undercoverage warning;
- water can still carry INFO context if Tank/Watermaker is relevant.

### Why CHECK instead of ACTION_NEEDED

Because Provy does not know:

- actual tank fill;
- actual Watermaker production/runtime;
- planned refill points;
- other carried potable water;
- skipper water-management strategy.

This preserves the owner-accepted WATER1 principle:

> Provy estimates the minimum drinking-water requirement. The skipper decides how it is covered.

## 3. Other PIVOT2 review semantics remain valid

### Missing basics

Data-driven `CHECK`, never auto-add:

- durable bread
- cooking oil
- hygiene basic
- cleaning/dishwashing basic
- trash bags

Use a new strict data file:

`data/provisioning_review_v0.1.json`

All references validate against **catalog v0.11**.

No name/string heuristics.

### Guided

No generic quantity-undercoverage finding.

### Preference-based

No quantity finding.

### Freshness / shelf life

CHECK only.

- no automatic reallocation
- no automatic substitute
- existing allocations unchanged
- can open existing stop-assignment flow

### Cooling / freezer

Hard technical contradictions may remain `ACTION_NEEDED`, e.g.:

- fridge-required item with 0 l fridge
- freezer-required item with no freezer
- known quantifiable chilled/frozen load clearly over known capacity

Unknown/unquantifiable volume must not produce a false “fits” statement.

### Weight / volume

Information only unless a real capacity exists.

## 4. UX benchmark application

PIVOT2 creates a new consumer-facing Review surface under `Vorräte`, so the owner-accepted UX Benchmark Strategy applies.

Primary reference: **Instacart-style list/context patterns**, not a new dashboard.

Required pattern principles:

- review is a secondary action from the existing list;
- no new top-level navigation;
- concise grouped findings;
- highest-priority item hint may appear inline;
- action is placed near the relevant finding;
- existing add/edit/stop flows are reused;
- no score/gamification;
- no modal overload;
- no permanent warning clutter;
- Material 3 accessibility/touch-target rules remain baseline.

This is a scoped benchmark pass for the PIVOT2 surface only. It does not reopen the frozen global IA and does not implement UX-D.

## 5. Data / catalog corrections to old plan

The old PIVOT2 plan says validation against `catalog_v0.10.json`.

This is superseded.

Use production catalog:

`data/catalog_v0.11.json`

AssistType must come only from the DATA1 catalog-driven effective assist resolution.

No hard-coded group-ID classification.

## 6. Revised minimum acceptance proof

If released, PIVOT2 must at minimum prove:

1. Review is read-only: no DB/list/allocation mutation from opening/refreshing review.
2. Missing-basics rules are strict, data-driven and validated against catalog v0.11.
3. Needs/guided/preference classification comes from DATA1 catalog semantics.
4. Water review shows WATER1 minimum estimate and actual selected amount.
5. Water below estimate produces `CHECK`, not `ACTION_NEEDED`, if this recommendation is owner-accepted.
6. Water Tank/Watermaker facts are informational context and do not mathematically reduce target.
7. Water review never invents required extra liters beyond the displayed difference/estimate context.
8. Guided item gets no global undercoverage finding.
9. Preference item gets no quantity finding.
10. durable bread rule satisfied/unsatisfied.
11. oil rule satisfied/unsatisfied.
12. hygiene / cleaning / trash rules.
13. fresh-roll 7-day case creates contextual freshness CHECK.
14. review does not alter fresh-item quantities or allocations.
15. fridge-required + no fridge → ACTION_NEEDED.
16. freezer-required + no freezer → ACTION_NEEDED.
17. known cooling volume > capacity → ACTION_NEEDED.
18. unquantifiable cooled item does not fabricate exact volume or false “fits”.
19. overall READY / CHECK / ACTION_NEEDED aggregation.
20. Review UI opens from real Vorräte surface.
21. one contextual highest-priority item hint max inline.
22. review actions reuse existing edit/search/stop flows.
23. DE/EN/FR/ES/PT/HR localization parity.
24. Issue #7 package-first regression.
25. Issue #8 no-auto-reallocation regression.
26. PIVOT1, DATA1, PIVOT3-A/B and WATER1 relevant suites remain green.
27. GitHub Actions Full-QA green on final PR HEAD.

## 7. Issue closure mapping

- Issue #7: remains open; PIVOT2 is still the planned regression/closure target.
- Issue #8: remains open; PIVOT2 is still the planned closure target.
- Issue #9: already closed by PIVOT1; no new meal-frequency behavior.

## 8. Strict non-scope

No:

- automatic list mutation
- automatic stop distribution
- recipes / menus
- AI review
- Watermaker capacity model
- total freshwater model
- provider / vendor / assortment
- Guest Shopping
- Receipts
- UX-D Command Center
- B3/B4/B5
- Store publication

## 9. Release recommendation

All former technical blockers are now cleared:

- FIX-B complete
- DATA1 complete
- WATER1 complete

PIVOT2 is technically next in the accepted sequence.

Before implementation release, the Product Owner should explicitly accept the revised water-review severity:

**Recommended: below-estimate drinking water = CHECK, not ACTION_NEEDED.**

After that decision, create/update the implementation plan and session prompt, mark Issue #26 IMPLEMENTATION RELEASED, and start a dedicated review branch + PR.

Owner accepted the recommended water-review severity with `pivot2 go`. Canonical release: `docs/impl/PIVOT2_release_reconciliation_2026-10-17.md`.

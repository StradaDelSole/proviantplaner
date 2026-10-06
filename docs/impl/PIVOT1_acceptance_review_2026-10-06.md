# PIVOT1 Independent Acceptance Review – 06.10.2026

Reviewed final HEAD: `86eab66336e6fa231acac44c90b2eed4a6a3f429`

Status: **READY FOR OWNER ACCEPTANCE**

This review supersedes the open acceptance findings in:
- `docs/impl/PIVOT1_review_2026-10-06.md`
- `docs/impl/PIVOT1_review2_2026-10-06.md`

## Independent verification

### Finding A — AssistClassifier — CLOSED

Verified against `data/catalog_v0.10.json` and production classifier:
- dead IDs `snacks` and `sauces_special` are removed
- real preference groups include `savory_snacks`, `sweets`, `spread_sweet`, `spread_savory`, `spirits`
- real preference variants include Pesto, Tofu, selected special sauces and selected cheeses
- water remains needs-based
- beer/wine remain intentionally guided with crew-drinking context
- configured group/variant IDs are covered by catalog validation tests
- representative preference regressions are covered

No remaining classifier/catalog mismatch from Review 1 was found.

### Finding B — visible direct-adopt bypass — CLOSED

Verified in `ShoppingListItemRow`:
- non-on-list CTA no longer calls `adoptItem()` directly
- row tap and visible add button both open `AddOrEditItemSheet(isAdding: true)`
- package and quantity choice therefore precede persistence

### Finding C — real Search/Add journey — CLOSED

Verified in production-path widget test:
- actual `ShoppingListScreen`
- actual Search-First button
- actual `CatalogSearchDelegate`
- partial query and real result tap
- actual `AddOrEditItemSheet`
- package ChoiceChip changed from default 190 g to 250 g
- quantity changed to 2
- save returns to actual list
- Pesto visible
- SQLite reload verifies:
  - adopted/on-list
  - `effectivePackages == 2`
  - `customPackageSize == 250.0`
  - `effectivePackSize == 250.0`

Micro-Finding 1 from Review 2 is therefore closed.

### Finding D — quantity stability through real recalculation — CLOSED

Verified test coverage:
- preference item Pesto explicitly set to 2
- guided item Bread explicitly overridden to 5
- custom item explicitly set to 3
- duration changed through `TripService.updateTripDetails(...)`, which recalculates
- crew increased and `TripService.recalculateTrip(...)` executed
- all three user quantities remain exactly unchanged

This now exercises real recalculation rather than only DB reload behavior.

### Finding E — ShoppingModeScreen isolation — CLOSED

Verified against actual `ShoppingModeScreen`:
- adopted catalog item visible
- custom item visible
- non-adopted candidate items absent

Production-screen isolation is therefore covered.

### Micro-Finding 2 — No-result → Custom Item route — CLOSED

Verified in production code:
- no-result action captures `targetContext = parentContext ?? context`
- closes SearchDelegate
- waits via `addPostFrameCallback`
- checks `targetContext.mounted`
- then opens `CustomItemSheet`

Verified in real UI test:
- actual ShoppingListScreen
- search with guaranteed no-result text
- no-result custom-item CTA
- actual CustomItemSheet opens
- save succeeds
- item becomes visible in actual list
- SQLite persistence verifies custom/on-list quantity 1

## Other verified PIVOT1 requirements

- fresh trip has zero on-list/adopted items
- Search-First empty state is the default
- department-first default remains active
- visible bulk `Alle Vorschläge übernehmen` path is absent
- Pesto/Tofu auto-quantity regression is fixed
- water guidance remains needs-based
- custom items remain supported
- stable ListItem/ShoppingStop/allocation model remains intact
- weight/volume uses actual on-list items
- FIX-A routing/lifecycle/localization work was not reopened
- no PIVOT2/PIVOT3/UX-D/GUEST1/RECEIPT1 scope was introduced

## QA

The final PIVOT1 report records:
- `flutter analyze`: **No issues found**
- `flutter test`: **262/262 passed**

No GitHub Actions workflow/status is exposed for final HEAD `86eab663...`; this independent review inspected the relevant production code and test assertions but did not independently execute Flutter through GitHub.

## Decision

No remaining PIVOT1 acceptance finding was identified.

**PIVOT1 is ready for explicit Product Owner acceptance.**

Until explicit owner acceptance:
- Issue #10 remains open
- README must continue to say PIVOT1 is awaiting owner acceptance
- no later slice is released

# PIVOT1 Independent Review – 06.10.2026

Reviewed implementation HEAD: `7dcc9cc058f46bc84810ac959dd415799825cfe0`

Status: **AMENDMENT REQUIRED – PIVOT1 noch nicht owner-accepted**

Binding sources:
- `docs/PRODUCT_PIVOT_ASSISTED_PROVISIONING_v0.1.md`
- `docs/impl/PIVOT1_plan.md`
- `docs/design/PROVY_UX_DIRECTION_v0.5.md`
- `docs/design/PROVY_UX_DECISIONS_2026-10-05.md`
- `docs/design/PROVY_UX_WIREFRAMES_v0.2.md`
- Issue #10

## Summary

The core pivot is materially implemented:
- fresh trips have zero adopted/on-list catalog items
- department-first view is the default
- Search-First empty state exists
- bulk "Alle Vorschläge übernehmen" is removed from the visible primary UI
- catalog candidates remain separate from user-adopted items
- Pesto and Tofu are prevented from automatic quantity recommendations
- water remains needs-based
- Shopping Mode production filtering uses actual on-list items
- no DB migration was required
- FIX-A routing/lifecycle code was not materially rewritten

However, four acceptance gaps remain.

---

## Finding A — Assist classification does not match the real catalog / Product Spec

Severity: **HIGH**

Current implementation:

`AssistClassifier.classifyGroup()` marks these group IDs preference-based:

- `snacks`
- `sweets`
- `sauces_special`

But in canonical `data/catalog_v0.10.json`:

- `snacks` does **not** exist
- `sauces_special` does **not** exist
- actual savory snack group is `savory_snacks`
- actual sauce/condiment group is `condiments`

The owner-accepted Product Pivot explicitly lists preference-based examples including:
- Pesto
- Tofu
- certain cheeses
- spreads
- snacks
- special sauces
- many drinks / Genussmittel

Current consequences:
- Pesto → preference-based: correct
- Tofu → preference-based: correct
- `sweets` → preference-based: correct
- Chips/Nuts/Crackers in `savory_snacks` → currently **guided**, therefore still automatically quantity-calculated
- special sauces in `condiments` → currently **guided**
- cheese group `cheese` → currently **guided**
- beverage/enjoyment groups default to **guided** unless separately caught

This makes the report statement that "Snacks" and "special sauces" were decoupled factually too broad.

### Amendment

Reconcile the classifier against **actual catalog_v0.10 identifiers**, not hypothetical IDs.

At minimum:
1. Remove/deprecate dead group IDs.
2. Explicitly map the currently accepted preference examples against real group/variant IDs.
3. Add regression tests beyond Pesto/Tofu, including representative real catalog items such as:
   - a savory snack (`chips` or `nuts`)
   - a special condiment/sauce (`bbq_sauce` or `sweet_chili`)
   - a cheese variant where Product Spec says preference semantics apply
   - at least one representative Genussmittel/drink case, or explicitly document why that real group remains guided
4. Test that preference-based examples have no automatic list quantity.
5. Add a catalog-classification validation test so configured group/variant IDs cannot silently point to non-existent catalog IDs.

A schema migration is **not** required for this fix. A catalog metadata field may be introduced only if it is genuinely simpler/safer than a centralized validated mapping.

---

## Finding B — Active UI still bypasses Variant → Package → Quantity → List

Severity: **HIGH**

The frozen PIVOT1 flow is:

`Search/Browse → Variant → Package → Quantity → Add`

The new `AddOrEditItemSheet` implements this.

But `ShoppingListItemRow` still renders a visible `Übernehmen` / `takeOver` button for non-on-list catalog items.

That button directly calls:

`shoppingListService.adoptItem(...)`

without opening the package/quantity sheet.

DAO behavior in `ListItemDao.adoptItem()` then silently chooses:
- existing `calculatedPackages` when > 0
- otherwise **1 package**

Consequences:
- preference-based item: direct "Übernehmen" silently chooses 1 package
- guided item: direct "Übernehmen" silently adopts the calculated package count

Both bypass the owner-accepted interaction where the skipper chooses package and amount.

### Amendment

Every visible add path for a normal catalog item must respect the PIVOT1 selection flow.

Preferred minimal fix:
- make the non-on-list row action open `AddOrEditItemSheet(isAdding: true)`
- do not directly call `adoptItem()` from a visible add control
- keep `adoptItem()` as a service primitive if useful internally/tests; the problem is the active UI shortcut

Test both:
- tapping the item row
- tapping the visible add/CTA control

Both must open the same package/quantity flow before persistence.

---

## Finding C — Required real PIVOT1 UI journey is missing

Severity: **MEDIUM/HIGH**

The implementation prompt required at least one real UI journey:

> Trip Overview / Vorräte → search → choose concrete variant → package → quantity → add → visible on actual list → verify persistence

Current PIVOT1 tests do not prove this.

- Test 2 calls `CatalogSearchDelegate.filterItems()` directly.
- Test 3 renders `AddOrEditItemSheet` directly as the test home.
- Test 4 also renders the sheet directly.

These are useful component tests, but they do not test the integrated SearchDelegate → result tap → modal sheet → list refresh path.

This matters especially because `CatalogSearchDelegate` currently calls `close(context, it)` and immediately opens `AddOrEditItemSheet.show(context, ...)`; only a real route/UI journey proves this interaction works reliably.

### Amendment

Add a real widget/router journey that:
1. starts from the actual Trip Overview or actual Vorräte/ShoppingList entry path
2. opens the real product search through UI
3. types a partial query
4. taps a concrete result
5. sees the real Add/Edit bottom sheet
6. chooses/changes package size
7. changes quantity
8. saves
9. returns to the actual list
10. sees the selected item with chosen quantity
11. verifies DB persistence

Do not replace the component tests; add this journey.

---

## Finding D — Quantity-stability acceptance test does not exercise recalculation

Severity: **MEDIUM**

Test 8 claims:

> Crew- und Dauer-Änderungen überschreiben übernommene Posten nicht

But it:
- writes `daysCount` directly through the DAO
- adds crew directly through the DAO
- then reloads the shopping list

It does **not** call the real `TripService.updateTripDetails()` path for duration and does not explicitly execute the persisted `recalculateTrip()` path after the crew mutation.

Therefore it proves that a stored override survives a reload, but not the acceptance requirement that it survives a real recalculation.

It also uses bread (guided) only.

The implementation prompt separately required:
- selected preference-based quantity survives crew-size change
- selected quantity survives duration change
- custom item survives recalculation
- manual override survives recalculation

### Amendment

Harden the tests:
1. adopt a preference-based item with explicit user quantity
2. change trip duration through the real service path that triggers recalculation
3. change crew and explicitly trigger the same production recalculation path used by the UI
4. verify the chosen preference quantity is unchanged
5. verify a manually overridden guided item remains unchanged
6. verify a custom item remains unchanged
7. keep the Pesto/Tofu zero-auto-quantity tests

---

## Finding E — Shopping Mode isolation test should prove the production screen

Severity: **LOW/MEDIUM**

Test 9 manually reconstructs the intended stop filtering logic in the test itself.

The production implementation appears to filter by `isOnList`, but duplicating the algorithm in the test can allow test and implementation to diverge.

### Amendment

Add or extend one widget/journey test that renders the actual `ShoppingModeScreen` with:
- adopted catalog item
- custom item
- non-adopted calculated candidate

Verify:
- adopted/custom assigned items are visible
- non-adopted candidate is not visible

---

## Verified positives

### Fresh list / adopted truth

`ShoppingListItemView.isOnList` is now effectively tied to user adoption/custom items and positive quantity.

Fresh trips remain technically populated with catalog candidate rows, but the default department view renders the Search-First empty state when no actual item is on the list.

This is acceptable for PIVOT1 and preserves stable IDs for later GUEST1.

### Weight / volume

`TripShoppingListData.weightAndVolume` filters to `isOnList` items before calculating totals.

`ListItemDao.adoptItem()` also sets the legacy `selected` flag, so adopted catalog items are included in the current weight/volume helper.

No candidate-only weight leakage was found in this path.

### Bulk adoption

Legacy service methods `adoptAllSuggestions()` and `adoptCategorySuggestions()` still exist internally, but no active visible call site was found in the reviewed PIVOT1 list UI.

This is allowed by the PIVOT1 scope as long as they remain non-primary/internal compatibility code.

### FIX-A preservation

No PIVOT1 change was found that reopens the previously owner-accepted FIX-A findings.

---

## QA evidence

Gemini reports in `docs/impl/PIVOT1_bericht.md`:
- `flutter analyze`: No issues found
- `flutter test`: 255/255 passed

The report matches the user-provided completion summary.

This independent review inspected the implementation and tests but did not independently execute Flutter locally through GitHub.

---

## Amendment scope

Keep the amendment narrow.

Do **not** start:
- PIVOT2
- PIVOT3
- UX-D
- GUEST1
- RECEIPT1
- CAT1
- B3/B4/B5
- Store publication

Required only:
1. correct AssistClassifier against actual catalog semantics/IDs
2. remove the visible direct-adopt bypass
3. add the real PIVOT1 search/add journey
4. harden quantity stability against real recalculation
5. harden ShoppingMode isolation with production UI proof
6. update PIVOT1 report and QA results
7. full `flutter analyze`
8. full `flutter test`
9. commit/push
10. STOP for review

## Decision

**PIVOT1 is not yet ready for owner acceptance.**

The architecture does not need to be redone. A narrow amendment should be sufficient.

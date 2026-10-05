# FIX-A Independent Acceptance Review – 05.10.2026

Reviewed implementation HEAD: `357d340841188654e2af680b48f41af2966429d0`

Status: **READY FOR OWNER ACCEPTANCE**

This review supersedes the open findings in:
- `docs/impl/FIX-A_review_2026-10-05.md`
- `docs/impl/FIX-A_review2_2026-10-05.md`

## Independent verification

### Finding A / Issue #16 — CLOSED

Verified against production source at the reviewed implementation HEAD:

- TripWizard / Setup
- TripOverview
- Shopping List
- Shopping Mode
- Storage
- Kitty / Bordkasse
- Settlement
- More
- Start
- Trip Timeline
- Router / NotFound
- delivery/group/package-size dialogs touched by the amendment

A targeted hardcoded-German sweep found no remaining German UI literals in the Issue-#16 target screens.

The only literal role/default names surfaced by the broad scan were values such as `Skipper`, `Co-Skipper` and fallback `Crew`; these are not German residue strings and are not part of the Issue-#16 regression.

All six ARB files contain the same **517 localization keys**:
- DE
- EN
- ES
- FR
- HR
- PT

All six ARBs contain **0 occurrences of `kitty` / `Kitty`**.

Spot checks of newly added keys confirm actual language-specific translations, including wizard headings, underway/fund wording, trip subtitle, treasurer explanation, transfer counts, remittance and catering-balance strings.

Real-screen tests exist for the eight required EN screens and a second non-DE locale path (ES).

### Finding B / Issue #15 — CLOSED

Previously independently verified and unchanged by the second amendment:
- restaurant lunch/dinner controls present in Trip Edit
- persistence into `tripDays`
- clamping to `daysCount`
- recalculation
- Journey 6 coverage

The second amendment did not modify `trip_service.dart` or the already-reviewed B implementation.

### Finding C / Issue #17 — CLOSED

Previously independently verified and unchanged:
- saved-package pseudo-setting removed
- language row informational
- no tap/chevron affordance

The second amendment did not reintroduce the removed pseudo-setting.

### Finding D — CLOSED

Previously independently verified and unchanged:
- existing later stop is used transparently
- if absent, user explicitly confirms creating a follow-up stop
- service does not silently create a stop
- allocation quantity is preserved

The second amendment did not modify the underlying postpone service logic.

### Finding E / Issue #19 — CLOSED

Verified in `test/features/ux/fix_a_journey_test.dart`:

#### Journey 0
Starts through the actual router at:
`/trips/new`

Then:
- renders `TripWizardScreen`
- submits using the real UI control `wizard_submit_trip_button`
- router lands on `TripOverviewScreen`
- SQLite is queried to verify the trip was actually persisted

#### Journey 2
Starts on real Trip Overview, then:
- navigates to Kitty/Bordkasse through the UI
- opens the real Expense UI
- enters amount `45.00`
- saves through the UI
- verifies the persisted expense in SQLite
- verifies visible amount
- navigates back to Trip Overview through the router/UI

Existing real journeys for Shopping List, postpone/follow-up stop, Shopping → Storage → Overview, Settlement and Shopping Stop CRUD remain present.

### Amendment report — CLOSED

`docs/impl/FIX-A_amendment_bericht.md` is now populated (127 lines in the amendment commit diff) and records:
- Findings A–E
- changed files
- QA results
- test count
- remaining risks
- explicit confirmation PIVOT1 was not started

The report itself names the commit by title rather than embedding its own SHA. This is not treated as a blocking defect because an artifact cannot reliably embed its own final commit SHA without a follow-up documentation commit. This independent review records the exact reviewed implementation SHA above.

## QA

Gemini's populated report records:
- `flutter analyze`: **No issues found**
- `flutter test`: **246/246 passed**

No GitHub Actions workflow/status is exposed for the reviewed commit, so these local command results were not independently re-executed by this review. The relevant test implementation and assertions were inspected and are consistent with the reported findings.

## Decision

No remaining FIX-A code or acceptance finding was identified.

**FIX-A is ready for explicit Product Owner acceptance.**

Until that explicit acceptance:
- Issue #20 remains open.
- PIVOT1 remains gated.
- README release state must not be changed.

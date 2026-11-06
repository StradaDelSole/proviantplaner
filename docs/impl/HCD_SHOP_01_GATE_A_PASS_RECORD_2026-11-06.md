# HCD-SHOP-01 – Independent Gate A PASS Record (06.11.2026)

**Status:** **INDEPENDENT GATE A PASS / OWNER PHASE-B DECISION OPEN**  
**Issue:** #66 (Parent #64)  
**Independent reviewer:** Claude, uploaded owner-supplied full report `PROVY – Independent Gate-A Re-Review v0.2`, archived in Provy project folder under `13_HCD_SHOP_01_INDEPENDENT_GATE_A_V02_PASS_2026-11-06.md`. This is an independent **read-only architecture review**, not implementation, physical QA or owner release.  
**Exact reviewed documentation PR #63 HEAD:** `c05329a5bdc4df1ac866b047ae5defce62afe324`  
**Reviewed file:** `docs/impl/HCD_SHOP_01_ARCHITECTURE_GATE_A_2026-11-06.md` version v0.2 **as it existed at reviewed SHA**. Later documentation commits are status/tracking and draft implementation brief; they are **not** included in Claude's exact-HEAD review.  
**Reference main:** `e00c01d35763790fe430a8c331436e120478f2dd`  
**Reference unmerged PR #60:** `af34fd9a88c3c7a4cf0e281ec187da2e5a39b855`  
**CI checked for reviewed SHA:** GitHub Actions run `42197854391`, completed success. (Doc CI is not a product/UI test.)

## Independent conclusion

**GATE A PASS – READY FOR OWNER PHASE-B DECISION.**

Claude reports the architectural Findings **F-01 to F-10 all CLOSED**, no new BLOCKER or MEDIUM findings. Scope and verification method are acceptable, in particular:

- **F-01 S1:** purchase of a visible open item naturally moves the next open item into the vacated tap position; no active scroll offset correction. Near-list-end `maxScrollExtent` clamping and disappearing department headings are explicitly tested, not misclassified as jumps.
- **F-02:** `ShoppingListService`/DAO/provider notification semantics remain unchanged; UI handles `false` and thrown failures without pretending success.
- **F-03:** strict **fails-before on original main**, then passes-after, to demonstrate actual spinner/scroll teardown causes rather than attributing based on assumptions.
- **F-04–F-06:** frame-by-frame offset/RenderBox geometry, 40+ articles/three departments, 412×915 and 320dp, delayed writes, cancellation/lifecycle, truthful Riverpod error-with-previous-data versus initial error versus missing stop.
- **F-07:** two internally separable steps: (1) reload/persistence stability and immediate device checkpoint; (2) pure `buildShoppingModeRows` view transform + `ListView.builder` and collapsed `Erledigt (N)` footer.
- **F-08–F-10:** isolated coding branch from live main; PR #60 ARB merge conflicts explicitly controlled; out-of-scope DAO/quantity integrity risks reserved for #67; exact SHA discipline preserved.

**Low/nonblocking observations for Phase B:** Keys must distinguish `open_` vs `completed_` row identities to avoid implicit Flutter state transfer; failure/Undo SnackBar should not cover persistent `shoppingDone` control.

## Owner decisions (not yet recorded as approved)

1. **S1** vs S2: recommended **S1**, natural successor row moves to tapped screen position; no programmatic scroll correction.
2. **Two steps + short real Pixel checkpoint**: recommended **yes**, fix stable Async/UI/errors first and run physical intermediate test, then implement collapsed completed section and run final independent/Pixel QA.
3. **Branch/merge order**: recommended **#66 from live main, independently code-reviewed and Pixel-tested first; then explicitly reconcile/rebase PR #60 and its six ARB files; no merge before Owner Acceptance.** The independent reviewer confirms `shopping_mode_screen.dart` is unchanged between main and current #60, while locale files overlap.

**Owners' prior general acceptance of HCD roadmap does not substitute for these three explicit decisions.**

## Phase-B preparation only

A full **DRAFT / NOT RELEASED** implementation brief exists at `docs/impl/HCD_SHOP_01_PHASE_B_IMPLEMENTATION_BRIEF_DRAFT_2026-11-06.md` on docs PR #63. It follows `docs/templates/IMPLEMENTATION_BRIEF_TEMPLATE.md` and retains red-first, two-stage, error/geometry, real-device and exact-HEAD gates.

**STOP:** Do not instruct Gemini to write code until Owner explicitly approves these three decisions **and** authorizes Phase B. Do not merge PR #63 or PR #60 without explicit Owner Acceptance; no issue closure or app release. Source tests, independent code review and real Pixel QA remain open after future Phase-B coding.

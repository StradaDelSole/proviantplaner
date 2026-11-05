# PROVY – HCD-SHOP-01: Architecture Gate A (Candidate, no production code)

**Datum:** 06.11.2026 · **Status:** ARCHITECTURE PROPOSAL – **Independent Gate A review / explicit Phase-B release OPEN**  
**Issue:** #66; Parent #64. **Owner has accepted product direction, not automatic implementation/merge.**  
**Read-only source snapshot:** `origin/main=e00c01d35763790fe430a8c331436e120478f2dd`; PR #60 actual live head `af34fd9a88c3c7a4cf0e281ec187da2e5a39b855` OPEN/Owner HCD HOLD; PR #63 docs branch OPEN. Live SHAs must be checked again at Phase B.  
**Applicable:** `AGENTS.md`, `GEMINI.md`, `docs/ENGINEERING_STANDARD_v1.0.md`, `docs/design/PROVY_UX_DIRECTION_v0.5.md`, `docs/design/PROVY_HCD_SHOPPING_JOURNEY_PLAN_2026-11-05.md`, `docs/qa/PROVY_HCD_REAL_DEVICE_ACCEPTANCE_2026-11-05.md`. Owner UX freeze kept; no new top-level navigation.

## 1. Verified current production behavior and root-cause evidence

`lib/features/shopping_list/ui/shopping_mode_screen.dart` at main and PR #60 is unchanged:
- :48–56: `ref.watch(tripShoppingListProvider(tripId))` followed by `dataAsync.when(loading: Scaffold(spinner), error: NotFoundScreen, data: Scaffold(...))`. No `skipLoadingOnReload`; a dependency-driven `tripDataVersionProvider` reload can show a full-screen spinner/unmount the list. The analogous `shopping_list_screen.dart:189–192` was hardened in PR #60, **ShoppingModeScreen was not**.
- :63–79: per-stop member allocation logic computes assigned pack count and completion progress; this must remain the single meaning of per-stop purchase.
- :125–197: full `ListView(children: data.departments.map(...Column...))`; :145–151 sorts bought and unbought **inside each department** (bought moved down, completed rows stay rendered). Departments' lengths and offsets therefore change on every purchase.
- :231–268: `AnimatedOpacity` + checkbox; :241–250 calls `await service.toggleBought(...)` then **always** `ref.invalidate(tripShoppingListProvider)`; no handling of bool result, exception, duplicate tap or transient failure.
- Provider `shopping_list_providers.dart:35–37` already wires `shoppingListService.onTripDataChanged` to `tripDataVersionProvider`; `shopping_list_service.dart:785–801` triggers it after DAO. **Double refresh** can make old/new AsyncValue transition harder to reason about.
- DAO `lib/core/database/daos.dart:380–406` returns bool on existing allocation UPDATE (`replace`) and true on newly inserted allocation. That bool can be false; the UI currently ignores it. **Important adjacent risk**: when a row has no explicit allocation, DAO uses `getUnallocatedPackages` and falls back to `1` if remaining is zero. This behavior is out of scope for a UI-only patch but must be listed as a separate invariant issue if realistically reachable, not silently 'fixed' during HCD-SHOP-01.
- `test/features/ux/ux_b_shopping_and_delivery_test.dart` tests list interactions and persistence, **not a 40-item scrolling ShoppingModeScreen scenario**. `test/features/shopping_list/shopping_list_persistence_test.dart` verifies durable isBought/undo but not pixel/scroll behavior.

**Evidence classification:** owner physically observed scroll jumps; the specific causal chain is supported by source and Flutter/Riverpod loading patterns, but no local Pixel instrumented performance log is claimed. This plan does not claim any tested fix.

## 2. Scope contract

**Goal:** Within a shopping stop, focus the entire screen on the next **open** item and never force repeated manual scrolling to find it. Show purchased results **collapsed by default in one accessible “Erledigt (N)” section below open items**. Single tap with truthful persisted state, undo, stable contextual position.

**In scope**
- Restructure per-stop view/department groups with deterministic original ordering of open items and a collapsed completed footer (not duplicated within each department).
- Stabilize loading/reload `AsyncValue` handling without displaying a global spinner over valid prior data; initial loading/error/retry remain explicit.
- Remove **only the redundant manual provider invalidation after successful checkbox toggle**; retain `onTripDataChanged`. Don't touch unrelated finish-shopping invalidations without analysis.
- Appropriate per-item UI busy guard, failure/false-result error indicator, safe retry, deliberate Undo in expanded completed section.
- Stable item identity / scroll anchoring with a small purposeful status animation. Six locale strings (or reuse existing localization keys) and 44–48dp touch targets, accessible semantics and reduced motion.
- Deterministic Widget + DAO/service integration tests on 40+ items, including mid-list scroll position, delayed write, false-return/exception, multi-stop distinction.

**Explicitly out of scope**: stop lifecycle, `TripPhase`, completing shopping / moving unbought packages, storage CTA (#67), catalog/taxonomy/need hints (#68), Welcome (#62), Flight-Strip board (#60), quantity engine, Auth0, backend, Drift schema, cloud backup, novel animation/package. No new application-level state machine.

**Non-negotiable compatibility**
- `ShoppingListItemView.packagesAtStop(...)`, `isBoughtAtStop(stopId)`, first stop unallocated residual, effective packages, expense shortcut and shopping finish flows unaffected.
- `isBought` is persisted per stop allocation; collapsed footer is only a view. No data destruction/reassignment.
- Distinguish written DB commit from in-flight UI status. Failed/false DAO result **must not display success or final completed count**.

## 3. Solution options and recommendation

### Option A – recommended: one scrollable open list, with sectioned slivers and separate collapsed completed footer

One `CustomScrollView` / stable ScrollController for the shopping task; a `SliverList` or small number of grouped slivers for **only unbought rows by department** (stable department order and stable per-row IDs); after open rows, a lazily expandable `Erledigt (N)` section. Don't retain bought rows in each department below other open work.

- Pros: a single natural scroll, discoverable progress and a single Undo location, no nested scrolling; no large gray growing purchased list in primary task, supports long lists and consistent next-item focus.
- Cons: removing an open row changes preceding sliver extents. **Stable Keys alone do not guarantee identical viewport position.** Need explicit anchor policy, verified with RenderBox geometry in widget tests. A naive `jumpTo(previousOffset)` is insufficient when varying row heights/group headings disappear.
- Proposed anchor policy: before a committed item transitions, capture a **stable logical neighbor** (prefer next open item, else previous), its pixel position relative to viewport and current stop. After data reload/layout, if the same neighbor still exists, correct to preserve its relative viewport position **only if needed**. If a whole department becomes empty, account for header removal. Do not restore a nonexisting/previously bought item; no jumping to top. For uninterrupted multi-item checking, a temporary “just bought” feedback state may hold a row until the short confirmation transition finishes, while the real durable state controls counter. Do not delay commit or invent success.
- Implementation must document how it avoids scroll correction loops, race between multiple pending writes, disposed widgets, user manual scrolling while awaiting write and text-scale changes. Manual user scroll **wins** over an obsolete anchor request; use mutation sequence/stop ID guards.

### Option B – alternate: persistent open slots / AnimatedList, with separate expandable completed section

Retain a stable viewport through an animated row removal/placeholder, progressively compact completed items to footer.

- Pros: intuitive visual handoff and less explicit anchor correction for a clicked visible row.
- Cons: difficult index ownership with rapid taps, delayed/failed DB writes, item relocation between departments, input/Animation completion races and app pause. Higher code + test complexity, more risk of ghost rows. Without careful anchoring, removal above viewport still shifts pixels.
- Not recommended for initial correction, except as fallback if Option A real-Pixel tests fail and the exact failure is characterized.

**Decision proposal:** Implement **A**, with no state beyond local widget `expandedCompleted`, `pendingItemIds` and transient viewport anchors. Keep domain/persistence semantics intact. For very long lists, prefer lazy rendering over `ListView(children: [...everything])`. Low-risk UI rendering alone would be eligible for a shortened architecture pass, **but the asynchronous checkmark/failure and scroll-identity behavior are materially stateful**, so perform the full Phase-A Gate before Phase B.

## 4. Detailed state/UX semantics

| State | Open list / UI | Persistence / outcome |
| --- | --- | --- |
| Initial loading | calm loading indicator, no fake prior items | wait for recovery + trip provider |
| Initial error | meaningful retry and proper not-found distinction | preserve data; never silently default to empty |
| Loaded, no items | empty-state and route to stop assignment (full flow #67) | no implicit allocations |
| Item unchecked | visible in correct department with pack count | `isBoughtAtStop=false` |
| Checkbox tapped | single-item pending affordance, suppress duplicate tap; keep scroll context | await `toggleBought` result |
| Commit success = true | increment progress, move from open to completed, preserve next visible anchor | one service notification; refresh with previous data retained |
| DAO false / exception | row remains open, error message + explicit retry; do not show saved or completed | no new durable checked status |
| Completed section expand | checkable purchased rows + Undo, clear count, stable main viewport | no new data changes |
| Undo success | item returns to open department at deterministic position, no surprise top reset | per-stop persisted flag false |
| Stop change, new route, dispose | reset transient item pending/anchors per stop; state from provider on entry | no stale callbacks modifying another stop |
| Reload while user manually scrolls | user scroll takes priority; correct only when same live anchor request | do not fight manual gesture |
| App killed after commit | on restart read DB and render correct checked counts | no UI-only permanent state |

**Critical technical clarification:** `service.toggleBought` calls `_notifyTripDataChanged` *after* DAO `replace`/insert. It currently does so even if an existing-row `replace` returns `false`. A production-safe UI should trust neither notification nor spinner as proof of commit. For this UI slice, confirm exact semantics of DAO result and false-condition; one narrow change to notify only on true (or verify failure semantics) may be appropriate, but **requires explicit independent Gate-A approval** because it crosses service/persistence boundary. Do not silently alter the DAO fallback allocation logic.

## 5. Invariants

- **I1 Stop isolation:** Toggle in stop A must not alter `isBoughtAtStop(B)` or B's allocated packages, even if an item exists in both.
- **I2 Quantity integrity:** `effectivePackages`, `packagesAtStop` and overall totals remain unchanged by toggling.
- **I3 Truthful persistence:** A checked result is shown as confirmed **only after successful commit**; false/throw must not advance bought count or show saved state. During in-flight state, “wird gespeichert” can be shown truthfully.
- **I4 Stable view:** After checking 5 consecutive items while scrolled to middle, next open logical item remains visible, and screen doesn't reset its Scrollable offset to 0 / replace with spinner.
- **I5 Completed accessibility:** Every bought item visible after intentional expansion, undoable and counted once; collapse affects no saved data.
- **I6 Async reliability:** pending item cannot be submitted twice; rapidly checking different rows cannot falsely clear each other's pending status; later route/dispose no setState errors.
- **I7 Offline-first:** Checkmarks work without internet; a true DB/operation error is recoverable and never falsely marked successful.
- **I8 Preservation:** existing TripPhase/store/finish workflow and #60 Flight Strip unaffected; no DB migration, recovery contract change, guest entitlement side-effect or money change.

## 6. Failure and concurrency matrix

| Situation | Expected test and observed state after | Gate |
| --- | --- | --- |
| `replace` returns false | no purchased counter; row open; explicit retry; notifier does not lie | service/DAO contract validation |
| DAO throws (disk full / transaction) | no false success, visible scoped error, retry after recovery | error injection |
| Two rapid taps on same checkbox | only one in-flight request; never double-toggle/spurious allocation | deterministic barrier test |
| Two different items concurrently | both commits follow own IDs, final counts correct, viewport correction doesn't fight user | deterministic interleaving |
| Refresh happens while tapped row animates | last valid data shown; no full-page spinner, stable sliver identity | provider-controlled reload |
| Expanded completed item Undo while user scrolls | count updates once, item returns to open, viewport doesn't reset | UI+data |
| App background/dispose during save | no context.use after dispose, DB remains truth; restart loads persisted result | lifecycle test |
| Two stops share item | stop A toggled does not mutate stop B | DAO integration |
| Change row text size/department header disappears | anchor remains visible when possible; no overflow at 320dp / 1.5x | widget + physical |
| No items at stop | explicit empty-state rather than generic all-bought | UI test |
| Existing checkout finish/open pending | no changed `handleUnboughtItems` behavior in this slice | regression |

## 7. Invariant-to-test matrix and device protocol

| Test ID | Assertion | Evidence class |
| --- | --- | --- |
| S01-40-POS | 40 items 3+ departments, scroll to physical middle, buy 5 successive visible open items; next open logical item stays in viewport after each frame/commit; row geometry stable within bounded tolerance; not merely `findsOneWidget` | C2 Widget + C3 Pixel |
| S01-40-COMPLETE | Completed footer initially collapsed, `Erledigt (N)` increases without rows growing above; expand and Undo an item, counts/pack/stop correct | C2+C3 |
| S01-ASYNC | delayed service/DAO result holds pending, shows previous rows without whole-tree loader; no premature completion | C2 |
| S01-FALSE | service returns false and exception, no success; usable retry | C2 |
| S01-2TAP | concurrent same item taps blocked; different items interleaved without overwriting each other | C2 |
| S01-2STOP | item in first and second stop: only designated `isBought` changes, total allocations constant | C2 integration |
| S01-RELOAD | provider `tripDataVersion` reload without direct invalidate, no spinner; initial error vs missing stop distinguish | C2 |
| S01-NIGHT | Light/Dark/Nightwatch, 320dp, 1.5x text, accessible checkboxes, reduced motion | C2+C3 |
| S01-RESTART | app process reentry after committed purchase, right stop count still accurate, no duplication | C3; optionally in-memory separate ProviderContainer integration |
| S01-LEGACY | full existing F1–F6, UX-B, PIVOT2, RECEIPT1 and backend CI unaffected | exact PR HEAD CI |

For physical Pixel evaluation, use **40 real adopted items** and 5 sequential checkmarks mid-scroll; test at least one undo, rapid double tap, switch stop and return, Nightwatch, normal Dark, offline. **No app data clearing** or mandatory upload of real trip receipts. Capture concise actual observations, not just “all tests green.”

## 8. Implementation file surface and branching

Likely:
- `lib/features/shopping_list/ui/shopping_mode_screen.dart` (view, local pending guards, async handling)
- `lib/l10n/app_*.arb` (new labels in six languages, if not already localized)
- a new focused `test/features/shopping_list/shopping_mode_viewport_test.dart` and at most targeted additions to `shopping_list_persistence_test.dart`
- `lib/features/shopping_list/data/shopping_list_service.dart` **only if** independent gate concludes false-return notification must be fixed; changes to DAO require a separate risk review.

**Branch strategy recommendation:** distinct `slice/hcd-shop-01-stable-checkout` branched from live `main`, avoiding accidental addition of unmerged PR #60/PR #63 commits; PR targets main, blocked until normal independent acceptance. For integrated Pixel check with PR #60, build a *temporary, non-merged integration test branch* combining both exact SHAs; never overwrite accepted branch or auto-merge. Recheck file overlap at implementation time.

**No implementation currently exists, no CI/Pixel validation claimed.**

## 9. Required independent Gate-A review and Phase-B release

An independent architectural reviewer must determine:
- Does Option A's anchor strategy truly avoid jumps when headers disappear and async data rebuilds; do tests assert row geometry?
- Is asynchronous `toggleBought` truthful for both false and throw without new race/rollback windows?
- Is the scope consistent with existing UX freeze, first-stop allocation fallback and #60's unmerged changes?
- Does the plan avoid new DB/financial/backup risk?
- If yes: mark **Gate A PASS** on exact planning commit, then obtain **explicit Owner Phase-B release** (Gemini coding). No merged product features before Pixel HCD evidence.
- If substantive new finding: revise Gate A before coding; do not accumulate blind amendments.

**Gate A now: PREPARED / REVIEW OPEN. NO CODE, NO MERGE, NO OWNER PRODUCT ACCEPTANCE CLAIMED.**

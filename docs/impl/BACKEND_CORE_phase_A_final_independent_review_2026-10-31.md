# BACKEND-CORE – Final Independent Gate-A Review of Spike Evidence

**Date:** 31.10.2026  
**Status:** **READY FOR OWNER ACCEPTANCE WITH BINDING IMPLEMENTATION / STAGE EVIDENCE GATES** – not a production implementation release.  
**Repository baseline:** `origin/main` `2ec14c66e825078990689b5a753f1566bed13405`.  
**Empirical test-only PR:** #38, verified actual **HEAD `858238286671730308716aa374d7ae71852748eb`**.  
**Important SHA correction:** Submitted report cites `8582382c448d4847e1d5a7d79b9ef3bf212f71f6`, which GitHub cannot resolve; authoritative CI and PR head both use `858238286671730308716aa374d7ae71852748eb`.  
**Authoritative CI:** GitHub Actions run `41213360372` **SUCCESS** on the actual head: Backend Typecheck + Vitest (37 tests) and Flutter Analyze + full Flutter tests (482 tests).  
**Docs-PR:** #37 (Draft) · **Tracking:** Issue #36 (open).  
**Independent review evidence:** PR #38 review `5723513470`.

## 1. Gate-A Scope and Evidence Classes

This is an *architecture and feasibility* approval recommendation, not a claim that the production backend/Flutter/Portal changes already exist. The Phase-A design is selected: owner-accepted ADR-BC-001 and ADR-BC-002 plus proposed transport/lifecycle ADR-BC-003/004 and `BACKEND_CORE_targeted_technical_contract_2026-10-31.md`.

Proved with reviewed local workerd/D1/Dart harness: accepted `FixedLengthStream` R2 writes, count-guarded copy helper success/rejection under selected conditions, direct stream download API, unique physical R2 keys isolating stale PUTs, D1 batch and CAS patterns, request ID uniqueness, 50-MiB synthetic valid JPEG NDJSON roundtrip on desktop.

Not proved by this local harness: production concurrency and GC convergence, actual R2 stage failure/lifetime behavior, real HTTP ingress under all network conditions, safe hostile NDJSON parser, full SQLite/receipt journal restore, low-memory Android/iOS, Auth0 native and Portal deletion.

## 2. Binding Design Contracts

### B1. HTTP transport / versioning
- Add `/v2/backups` raw streaming endpoints, preserve existing `/v1/backups` JSON wire contract during migration; distinguish snapshot version 4 from wire version 2.
- Count real bytes and strictly validate byte lengths, including null/missing/malformed `Content-Length`. `parseInt('6abc')` is **not** safe strict validation.
- Use the proven length-preserving Worker-R2 path or a stage-proved equivalent, handle aborted/request-cancelled streams and clean up both promises and R2 temp objects; never return success before R2 size/integrity and D1 activation.
- Maintain owner-accepted 50 MiB binary receipt payload. Total wire limit must be chosen from measured full snapshots, not guessed, and must avoid silent data loss.

### B2. D1/R2 lifecycle
- `accounts`: `active/deleting/deleted` with explicit registration; no `GET /me` auto-recreation.
- `backups`: `pending/active/deleting` plus immutable per-attempt R2 keys and `UNIQUE(account_id, request_id)`. Activation only conditional on active account and current attempt generation; retention in a transactionally consistent D1 transition, always max 5 **visible valid** snapshots.
- **GC must not treat all non-active objects as deletable.** `pending` active/slow uploads are protected; delete only validated terminal/expired/fenced candidates after suitable grace, and perform bounded, cursor-paginated independent prefix sweeps for eventual late PUT ghosts. The S1.6 test uses a naive active-set sweep and is *not* the production GC algorithm.
- Actual two-writer/reader/delete races, idempotency after lost 201, R2-put-late-after-delete, crash after R2.put before D1-commit must be injected and asserted on the real implementation. S2.4 has one writer plus reader, not concurrent writers.

### B3. Flutter storage / snapshots
- NDJSON v4 with small receipt chunks, bounded temporary files and byte-count/digest checks. Preserve full 50 MiB receipt budget (ADR-BC-002).
- **Bound line length before materialization** (pre-`LineSplitter` or equivalent bounded byte parser); validate and sanitize receipt identifiers, reject duplicate/out-of-order/too-large chunks, missing/incorrect footer, extra trailing records, unknown types and invalid relationships. S3.3 currently tests isolated handwritten `throw` examples, **not** the S3.2 actual reader; it does not prove malicious-input safety.
- Maintain RECEIPT1 `StorageOperationCoordinator`, SQLite transaction/ID-remap and receipt-file staging/journal/rollback/roll-forward semantics. Do not reuse spike JPEG test IO as production restore. Preserve legacy snapshot v1/v2/v3 compatibility where applicable; old fields missing from old backups cannot be magically reconstructed.
- Exclude Auth/JWT tokens and structured banking fields, document photos' potential sensitive contents. Store-v1 evidence needs low-memory Android/iOS restore and actual Cloudflare Stage transfer measurements, not just desktop RSS.

### B4. Account/Auth0 and privacy
- O-01 Provy-only deletion (HullQ/Auth0 identity retained) is Owner-ACCEPTED. Deletion responds with truthful pending/done states after D1/R2 processing and must survive concurrent uploads and old JWTs. Explicit opt-in re-registration only after cleanup.
- Real Auth0 Flutter Universal Login/PKCE, correct callbacks/audience and tested browser portal deletion; server-owned Provy entitlements. GDPR/Google Play privacy gates and data-minimal deletion tombstone/retention are separate acceptance criteria, not assumed from passing unit tests.

## 3. Evidence still required (release/implementation gate, not reason for another generic Phase-A essay)

| Gate | Proof required | Stage |
| --- | --- | --- |
| P01 | Exact end-to-end real HTTP request -> bounded R2 stream (including rejects/cancel, no unhandled promises) and raw stream download | Phase B implementation CI + Stage |
| P02 | Real two-writer + observer + account-delete CAS race, stable ID retry, atomic visible retention, no early cleanup of active pending | Phase B backend acceptance |
| P03 | Cursor-paginated R2 prefix GC with pending lease/grace/fencing, late-put second sweep, crash/Cron outage | Phase B backend CI + Stage |
| P04 | Same production NDJSON parser tested against oversized line, traversal, duplicates, malformed footer and partial download; 50-MiB valid JPEGs, hash/relational/receipt journal recovery | Phase B Flutter integration |
| P05 | Actual low-RAM Android/iOS performance and v3 restore, Auth0/Portal real auth, EU D1/R2 resource settings, Cloudflare CPU/cost/timeout | Stage / device / Store-v1 |

**No unsupported product claims:** local emulated R2 behavior is useful but not equivalent to deployed Cloudflare. A 64-KiB stream check is not a measurement of 0-MB Worker JS heap. Desktop RSS delta is not mobile peak RAM.

## 4. Independent decision

**Engineering judgment:** No new fundamental architectural alternative is needed based on the spike evidence. The two-phase Architecture-First method has identified the necessary invariants, chosen a bounded approach, and isolated remaining *implementation* and *real-world verification* risks. Further generic Phase-A amendment reports would not add proportionate value.

**Recommendation:** Owner may accept the constrained **Gate A** and merge test-only PR #38 plus documentation PR #37, with this evidence ledger and P01–P05 implementation/stage gates binding. **Gate A acceptance is NOT authorization to code BC-1**: that requires a separate Owner-accepted, exact-main-HEAD Phase-B brief and approved scope. No automatic issue closure, production deploy, D1/R2 creation or Cloudflare/Auth0 secret handling.

**Until Owner action:** PRs #37/#38 open, Issue #36 open, main unchanged. Gate A status **READY FOR OWNER ACCEPTANCE**, not ACCEPTED.

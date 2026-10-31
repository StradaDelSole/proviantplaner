# BACKEND-CORE – Phase A Owner Acceptance (31.10.2026)

**Decision:** OWNER-ACCEPTED FOR ARCHITECTURE WITH BINDING P01–P05 EVIDENCE GATES. This is **not** authorization for Phase-B production coding or deployment.

## Owner's decision and scope
On 31.10.2026 the Owner explicitly accepted the independent recommendation to merge test-only PR #38, merge architecture/documentation PR #37, and formally close Gate A. BC-1A may be planned but requires a separate implementation release.

Owner-accepted product decisions: **O-01** deletes Provy cloud account/data and Provy permissions without deleting shared HullQ/Auth0 identity or HullQ data; **O-02** preserves **50 MiB raw receipt-image bytes** in cloud backup. The EU jurisdiction requirement for Cloudflare D1/R2 remains mandatory.

## Verifiable evidence
- PR #38 verified actual implementation/test HEAD: `858238286671730308716aa374d7ae71852748eb`. The SHA `8582382c448d4847e1d5a7d79b9ef3bf212f71f6` in Gemini's report is **not a valid GitHub commit**.
- GitHub Actions `41213360372`: Backend Typecheck + 37 Vitest and Flutter Analyze + 482 Flutter tests all SUCCESS.
- Independent exact-HEAD review: PR #38 review `5723513470` and `BACKEND_CORE_phase_A_final_independent_review_2026-10-31.md`.
- PR #38 merge: `7adf9349ccd2bb47a23c3237280c2f5260064332` (test-only, no production code).
- The final PR #37 merge SHA must be recorded/verified **after** its merge, not guessed.

## Binding Phase-B / Stage proof gates
| Gate | Required proof, not yet performed |
| --- | --- |
| P01 | Actual bounded HTTP ingress to R2, strict content-length validation, aborted-stream/promise cleanup, correct streaming download. |
| P02 | Real **two-writer plus observer** D1 races, account deletion, idempotency, max five active backups; protect ongoing pending uploads. |
| P03 | **State-aware cursor-paginated GC** with pending/grace/fencing, second sweep for late puts, crash/Cron outage recovery. |
| P04 | Production bounded NDJSON parser (limit bytes before line allocation, reject traversal, duplicates, bad chunk order/footer/trailing records), full Drift/RECEIPT1 journal recovery, 50-MiB test, legacy compatibility. |
| P05 | Actual low-memory mobile tests, native Auth0/Portal integration, EU D1/R2 Stage settings, real Worker/R2 limits and Store-v1 evidence. |

**Important:** Test harness success does not prove production GC or concurrency safety. The S1 test sweep deletes all non-active objects and would be unsafe for live pending uploads. S2 tests one batch writer with a reader, not two writers. S3 hostile input checks are independent throw examples, not attacks on the production restore parser. These gaps are **binding implementation test criteria**, not waived.

## Gate and next step
Phase A is **ACCEPTED / CLOSED for design only**. The selected architecture is a bounded Flutter/Auth0/Cloudflare retrofit with versioned v2 streaming and NDJSON snapshot-v4, immutable R2 attempt keys, D1-CAS and state-aware reconciliation. ADR-BC-003/004 are architecture-accepted, not production-proof.

Prepare a small **BC-1A native Auth0 adapter** Phase-B brief as DRAFT on current main. No coding, D1 migration, Cloudflare resource creation, deployment, new feature-slice release or closure of other roadmap work is authorized by this acceptance.
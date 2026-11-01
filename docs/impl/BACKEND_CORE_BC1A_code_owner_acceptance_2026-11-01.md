# BACKEND-CORE BC-1A – Owner Acceptance (code-only) – 01.11.2026

**Status: CODE IMPLEMENTATION OWNER-ACCEPTED / MERGED. P05 NATIVE STAGE STILL OPEN.**  
**Owner decision:** explicit “akzeptiertr” in ChatGPT on 01.11.2026, following the independent exact-HEAD code review PASS. The accepted scope is **BC-1A native Auth0 adapter implementation only**, not a live Auth0 integration, app-store release or Phase-B release of BC-1B.

## Canonical source and acceptance evidence

| Evidence | Verified fact |
| --- | --- |
| Repository | `StradaDelSole/proviantplaner` |
| Coding PR | [#44](https://github.com/StradaDelSole/proviantplaner/pull/44) — merged |
| **Actual reviewed implementation PR HEAD** | `b592162271ec64ebc812e077a08d7073ef5c0c57` |
| Independent exact-HEAD review | [review 5729781280](https://github.com/StradaDelSole/proviantplaner/pull/44#pullrequestreview-5729781280) — **PASS / READY FOR OWNER ACCEPTANCE** |
| Authoritative GitHub Actions | [run 41339157145](https://github.com/StradaDelSole/proviantplaner/actions/runs/41339157145) — **SUCCESS at that exact HEAD** |
| CI jobs | Flutter Analyze & Test **SUCCESS**; Backend Typecheck & Vitest **SUCCESS** (37/37 backend tests) |
| Owner acceptance recorded | [PR #44 owner-decision comment](https://github.com/StradaDelSole/proviantplaner/pull/44#issuecomment-6562582594) |
| **Merge commit on `main`** | `5316791e9a66198e114f5934b83778fb0e0f1d4b` |
| Original implementation issue | [#40](https://github.com/StradaDelSole/proviantplaner/issues/40) |
| Outstanding native-stage tracking | **[#45](https://github.com/StradaDelSole/proviantplaner/issues/45)** — **OPEN** |
| Auth0 owner-setup runbook | [docs-only PR #43](https://github.com/StradaDelSole/proviantplaner/pull/43) — **OPEN, not merged as part of BC-1A code acceptance** |

The implementer-provided HEAD `b592162985392fe19672834b676f4e64849cb15d` was **not** the actual GitHub PR/CI HEAD. All acceptance and merge operations were based on the verified `b592162271ec64ebc812e077a08d7073ef5c0c57`.

## What was accepted

- Official `auth0_flutter >=2.7.0 <3.0.0` (resolved 2.7.0); minimum **iOS 14.0**, without an unapproved increase to Android or Java minimums.
- Native Universal Login/PKCE using the injectable Auth0 adapter and SDK CredentialsManager as access-token authority; no synthetic production tokens or fabricated successful account identity.
- Authentication is explicitly **not** Provy account provisioning, `member`/paid entitlement or `GET /v1/me` implicit account recreation.
- Truthful logout and local-credential-clear UX; the shared HullQ/Auth0 identity is never deleted by BC-1A.
- Deterministic concurrency, cancellation, fail-closed and SDK interoperability regression tests. Specifically, `WebAuthentication` uses **`useCredentialsManager: false`** to avoid implicit SDK auto-store/auto-clear outside the coordinated credentials manager operations, verified against official Auth0 Flutter `af-v2.7.0` source.
- Fail-closed secure-storage revocation where available. When durable secure storage itself fails, **restart safety cannot be guaranteed**; this is a documented device/OS failure limitation, not a production readiness pass.

## Explicit non-acceptance / open release gates

**P05 is OPEN and separately tracked in issue #45.** Real EU Auth0 tenant/domain, Provy Native Application public Client ID, API Audience, allowed callback/logout URIs, authorized identity connections and end-to-end Android/iOS physical-device login/logout/relaunch tests have **not** been independently validated. Vendor/unit/CI green does not substitute for native Stage evidence. Store readiness, production deployment and native Auth0 integration must not be claimed.

Backend Phase-A requirements **P01–P04** remain binding for their later implementation/Stage slices. This BC-1A acceptance does **not** authorize BC-1B, D1/R2 changes, account registration/deletion backend, Cloudflare/Auth0 resource creation, automated backup release, Store publication or any other feature slice.

**No next slice is automatically released.** A separate, explicit Owner decision and current-main reconciliation are required.

## Lessons for future high-risk implementation briefs

BC-1A required numerous successive amendments despite an initial architecture gate. The root process weakness was insufficient up-front verification of the **actual pinned SDK side effects** and inadequate mapping of every shared mutable resource/callsite to the single coordination invariant. Future Auth/Concurrency briefs should require: (a) vendor-source or contractual semantics for the exact pinned SDK before coding, (b) explicit enumeration of all storage and SDK mutations (including implicit SDK operations), (c) same-behavior production adapter and test-fake contract, (d) adversarial A→B/C transitions and failure windows derived from system invariants, and (e) a single consolidated review rather than multiple finding-specific patch loops. This is review guidance; **not** an additional coding or product release.

## Final authority

**BC-1A code: OWNER-ACCEPTED / MERGED. Native Auth0 Stage P05: OPEN. BC-1B: NOT RELEASED.**  
At the start of any later work, re-read actual GitHub `origin/main`, the acceptance above, issue #45, `AGENTS.md`, `GEMINI.md` and `docs/ENGINEERING_STANDARD_v1.0.md`.
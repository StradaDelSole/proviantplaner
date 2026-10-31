# BACKEND-CORE BC-1A – Auth0 Native Login Adapter

**Status: DRAFT / NOT RELEASED. NO PRODUCTION CODE AUTHORIZED.**  
**Owner's accepted Gate A:** `BACKEND_CORE_phase_A_owner_acceptance_2026-10-31.md`.  
**Initial source baseline:** main after test-only PR #38 merge `7adf9349ccd2bb47a23c3237280c2f5260064332`. Reconcile again with exact latest origin/main before any future BC-1A release.

## 1. Goal and narrow scope

Replace `Auth0HullqAuthService`'s synthetic `auth0_<connection>_token` production fallback with **real Auth0 Native Universal Login + PKCE**. Ensure secure credentials, correct cancellation/refresh/logout/error behavior and unchanged offline-first local app use.

This is intentionally **BC-1A**, not the entire BACKEND-CORE.

**Proposed in-scope after separate Owner release:**
- Inspect actual Flutter auth DI, state, secure storage, platform packages and available Auth0 SDK API; configure an injectable real SDK adapter for Universal Login/PKCE, with deterministic fakes only in tests.
- Support email, Apple and Google via enabled Auth0 Universal Login connections; do not build custom password processing or assume connection IDs not verified.
- Secure access/refresh tokens through platform credential manager; explicit handling of token cancellation, expiration, retry, logout, app restart, concurrent refresh and account switch.
- No token/PII/credential logging, no plaintext Preferences, no fake success after API failure. Token presence alone does not establish Provy membership or backend readiness.
- Preserve local trip, provisioning, kitty, shopping and receipt functions while offline; no new online requirement for core app functions.
- Keep Worker JWT/JWKS contract and existing backend tests intact; new credentials must be aimed at the explicitly configured API audience.

**Strictly excluded:** changing D1/SQL schema, account registration/deletion API, Portal, Entitlement source-of-truth, payments, backup streaming/NDJSON, GC, R2, cloud provisioning, guest-shopping, charter B3–B5 and store release. Those need their own scopes and reviews.

**Critical interim safety boundary:** Current `GET /v1/me` can auto-create an account and must not be used as implicit registration for users whose Provy data were deleted. BC-1B will specify explicit opt-in account registration and entitlement resolution; until then, BC-1A may not claim Provy cloud membership is active or expose new cloud data paths. If a safe isolated adapter cannot be shipped without touching BC-1B, STOP and propose a revised scope to Owner.

## 2. Mandatory architecture invariants and tests

| ID | Invariant | Required verification |
| --- | --- | --- |
| BC1A-01 | No production login success without SDK-returned credentials; synthetic fallback removed. | SDK null, thrown error, cancellation, bad token, network 401/500 |
| BC1A-02 | Never persist or log tokens except via authorized secure platform credential storage. | Log redaction tests, secure storage & backup exclusion inspection |
| BC1A-03 | PKCE/native login and audience/callback handling are actually wired. | SDK mock contracts, platform config verification, later physical device Stage |
| BC1A-04 | Auth unavailable/offline does not block local shopping, trips, ledger or receipts. | Entire Flutter regression, offline/timeout cases |
| BC1A-05 | Logout/refresh/account switch never reuses stale privileges. | concurrent refresh + logout, app restart, expired tokens, switching accounts |
| BC1A-06 | No implicit `GET /me` resurrection or false Provy membership after deletion. | API guard mocks; documented BC-1B explicit registration dependency |

**QA:** Flutter analyze + full flutter test, backend typecheck + full Vitest on exact PR head; no global lint/CI suppression. Independent exact-head code review and Owner Acceptance required before merge.

## 3. Implementation sequence (ONLY after explicit future BC-1A Owner coding release)

1. Reconcile repo/main exact SHA, current DI and platform SDK; list approved files and dependencies.
2. Implement minimal injection boundary and native Auth0 adapter with test fakes.
3. Implement credentials/refresh/logout state machine; no success on network or cancellation failure.
4. Add negative, offline, account-switch and concurrent refresh/logout tests; run full authoritative CI at exact head.
5. STOP after implementation report for independent review. No merge/BC-1B release automatically.

## 4. Setup and release gates

Owner must provide/verify a dedicated Provy **Native** Auth0 application in shared EU Auth0 tenant, actual public domain/client ID, intended API audience, enabled connections and Android/iOS callback and logout URLs. Never place client secrets in mobile app or repository; no external account changes without Owner action.

Real Auth0 callback/login/logout on Android and iOS, Cloudflare EU D1/R2 binding and browser account deletion remain **P05 Stage / Store** tests; local mocks cannot certify these.

**STOP:** This brief is **not a Gemini coding prompt** and authorizes no code, cloud resources, migration, deployment, PR merge or feature-release. Separate Owner-approved BC-1A Phase-B launch required.
# BACKEND-CORE BC-1A – Phase-B Owner Release & Gemini Implementation Brief

**Status: OWNER-RELEASED FOR BC-1A ONLY, subject to explicit platform-compatibility checkpoint.**  
**Owner authorization:** 31.10.2026, user instruction "ok weiter" immediately after the verified Phase-A acceptance and BC-1A draft. This authorizes the **bounded next BC-1A implementation**, not BC-1B, account deletion, backend provisioning, store publishing or any merge.  
**Exact baseline:** `origin/main` = `8bff7a199562be9035e6e479411d4619d35d172d` (verify anew immediately before coding).  
**Tracking:** Issue #40.  
**Phase A:** `BACKEND_CORE_phase_A_owner_acceptance_2026-10-31.md`, ADR-BC-001–004, `BACKEND_CORE_phase_A_final_independent_review_2026-10-31.md` (P01–P05 remain binding).  
**Historical preparatory draft:** `BACKEND_CORE_BC1A_implementation_brief_DRAFT_2026-10-31.md`. This file is the newer authority.

## 0. Required SDK/platform preflight – potentially blocking

**Repository evidence:** `ios/Runner.xcodeproj/project.pbxproj` sets `IPHONEOS_DEPLOYMENT_TARGET = 12.0`; `android/app/build.gradle` uses `flutter.minSdkVersion` and Java 8. There is currently **no** `auth0_flutter` dependency. Flutter SDK constraint `^3.5.3` is the Dart constraint, not proof the locally installed Flutter SDK meets the plugin minimum.

**External official package evidence (31.10.2026):**
- `auth0_flutter 2.7.0`: Flutter >=3.24, Dart >=3.5, Android API >=21 / Java 8, **iOS >=14**; https://pub.dev/packages/auth0_flutter/versions/2.7.0
- `auth0_flutter 3.1.0`: Flutter >=3.24, Android API >=26 / Java 17, **iOS >=15**; https://pub.dev/packages/auth0_flutter

**Recommended minimum-change option:** prefer the maintained 2.7.x line with an explicit <3.0.0 constraint, **subject to Owner approval of the necessary iOS minimum 14**. Do not silently raise the minimum supported iOS version (12→14 or 15) or Android/Java baseline, select an older security-unmaintained version solely to preserve iOS12, use a fake plugin/credentials manager, or weaken the Android/iOS build. Present SDK compatibility, exact installed Flutter toolchain, minimum-platform impact and the smallest safe choice; **STOP prior to any platform-minimum change until Owner accepts it.** While waiting, it is permitted to write a separately testable, SDK-agnostic auth adapter and negative tests, but not to claim native login integration complete.

**Auth0 Owner setup (separate Stage requirement):** Provy Native application inside existing HullQ EU tenant; Domain, public Client ID and API Audience, enabled identity connections, Allowed Callback/Logout URIs for real Android applicationId `com.hullq.proviantplaner` and iOS bundle ID `com.hullq.proviantplaner`. The real values must be verified, not invented or committed as secrets. `flutter_secure_storage` is already installed; SDK CredentialsManager is preferred for refresh-token lifecycle. Configured deployment and physical device OAuth callback stay P05 OPEN.

## 1. Allowed coding scope – narrow but end-to-end honest

1. Add the approved **official Auth0 Flutter SDK** after the compatibility checkpoint. Implement Native Universal Login + PKCE via a small injected adapter in `lib/core/services`. SDK fake for deterministic tests is allowed. Never use manual password collection or fake production tokens.
2. Replace the synthetic-token branch in `Auth0HullqAuthService` and its test path. Do **not** treat `getMe()` network failures or `updateConsent()` failures as valid membership. No hardcoded `apple.user@example.com`/`google.user@example.com` production identities; derive user info only from verified SDK credentials.
3. Credential handling: Auth0 SDK credential manager where supported, token renew/expiry checks, cancellation, network errors, logout and app-process recovery; secure storage/clear authenticated state on transitions. Do not duplicate refresh tokens in plain storage; no secrets in logs/backups.
4. Distinguish **Auth0 authentication** from **Provy entitlement**: a valid Auth0 token must not set `HullqMembershipStatus.member` by assumption. Current `AuthState.isLoggedIn` derives from membership, so decouple minimal presentation of "signed into Auth0" from server-verified "Provy member" without silently redesigning the entitlement model. Unknown rights default to trial/unverified.
5. Prevent `GET /v1/me` from being called as an implicit sign-up: it still uses `ensureAccount` and could resurrect a Provy projection after prior deletion. BC-1A must not expose or claim server membership; explicit Provy registration/entitlement truth belongs to BC-1B.
6. **Consent and deletion UI honesty:** do not POST newsletter consent to an automatically recreated account, and do not claim consent is registered if no backend registration exists. Existing `deleteAccount()` swallows backend failure and pretends success: BC-1A must not trigger a false successful deletion or global Auth0 deletion. It may temporarily guard/disable that unsafe UI action with accurate user-facing text and tests; implementing the actual Provy-only delete flow is **out of scope** and belongs to a later BC slice.
7. Preserve all offline-first local trip, shopping, provisioning, ledger and receipt flows, and preserve the agreed navigation/visual IA except the minimal necessary truthful auth labels and safety guards.

## 2. Out of scope, do not accidentally start

No D1 migrations, backend `GET/DELETE /me` rewrite, account-registration API, paid/member entitlement authority, R2/backup-v2/NDJSON/GC, Portal, payments, Charter B3–B5, GUEST1, release deployment, Cloudflare/Auth0 resource creation or changing product policy O-01/O-02.

**No credentials from environment/placeholders count as an actual successful native mobile login.** Unsupported platforms must fail closed with informative UI without affecting local offline functions.

## 3. Mandatory negative/edge tests

| Test ID | Scenario | Required assertion |
| --- | --- | --- |
| A01 | No configured Auth0 Native client / cancelled SDK auth / null credentials | no token, no member flag, no fake success |
| A02 | SDK credentials valid, API offline/401/500 | authentication truth separate from membership; no `GET /me` autoprojection and no fake entitlement |
| A03 | Token expired, refresh failure, app restart | no stale token access, explicit auth status and predictable offline-local behavior |
| A04 | Logout during refresh; two simultaneous refreshes; account A then B | old account token cannot leak into new session or be persisted after logout |
| A05 | Newsletter opt-in false, true, subsequent failure | no unasked grant, no pretend persisted consent, UI remains accurate |
| A06 | Provy delete action while endpoint unreleased/offline | no misleading "deleted" success; HullQ/Auth0 identity never removed |
| A07 | Android/iOS callback and logout URL config, invalid Audience/Issuer, redirect failures | config defaults fail-closed, exact native setup documented; mocked tests not called real-device proof |
| A08 | Full local shopping/trip/kitty/receipt regressions and Flutter analyze | offline-first behavior preserved |
| A09 | Existing B1 Auth0 mock tests expect `GET /me` and `member` on token only | replace obsolete assumptions with negative contract tests, do not remove whole test coverage |
| A10 | CI exact HEAD | Backend Typecheck + full Vitest, Flutter Analyze + full Flutter Test, no suppressions; review code, migrations and platform support |

**Independent review must check:** misleading auth UI, consent status, safe blocked deletion, token scope/audience, SDK storage, iOS minimum and no automatic Provy account recreation. Existing S1–S3 local spike tests are not live guarantees; P01–P04 await backup/lifecycle slices, P05 actual Auth0/device Stage stays open.

## 4. Sequence and stop

1. Gemini fetches `origin/main`, reads `AGENTS.md`, `GEMINI.md`, `docs/ENGINEERING_STANDARD_v1.0.md`, this release, issue #40 and existing B1 tests, states exact HEAD.
2. **Compatibility checkpoint:** show SDK version proposal and impact on iOS12 min / Android baseline. If changing supported OS is required and not approved, STOP for Owner decision before platform change. Keep work limited to pure injectable adapter/tests until approval.
3. Implement only allowed BC-1A changes on **feature branch**, never main; add deterministic failure/concurrency tests. If missing Auth0 real app IDs/tenant settings, isolate configuration and keep Stage-device completion OPEN.
4. Adversarial self-review, local focused tests, push feature branch, open PR. GitHub Actions full QA on exact HEAD. STOP for independent review by ChatGPT.
5. **No automatic merge or follow-on.** Only an explicit later Owner Acceptance can merge BC-1A and initiate BC-1B.

**Owner Release scope is BC-1A only, conditional platform compatibility. It is not an account-delete, Store, or cloud-production release.**

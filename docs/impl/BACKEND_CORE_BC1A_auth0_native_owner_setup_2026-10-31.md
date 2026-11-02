# BACKEND-CORE P05 – Provy Auth0 Native Owner Setup & Stage Verification

**Status: RECONCILED RUNBOOK / P05 OPEN / NO LIVE-TENANT EVIDENCE.**  
**Original:** 31.10.2026. **Reconciled:** 02.11.2026.  
**Current `main` baseline at reconciliation:** `44e5e929bc5e4965b1f3cff4f491cc76b6aa6631`.  
**Tracking:** P05 issue [#45](https://github.com/StradaDelSole/proviantplaner/issues/45); BC-1A code issue #40.  
**BC-1A:** OWNER-ACCEPTED and merged via PR #44 (implementation HEAD `b592162271ec64ebc812e077a08d7073ef5c0c57`, reviewed PASS 5729781280, CI 41339157145 SUCCESS, merge `5316791e9a66198e114f5934b83778fb0e0f1d4b`). Owner-acceptance record: `docs/impl/BACKEND_CORE_BC1A_code_owner_acceptance_2026-11-01.md`. Owner-acceptance documentation PR #46 merged at `44e5e929bc5e4965b1f3cff4f491cc76b6aa6631`.

**Purpose:** Operational read-only preflight and later Owner-controlled configuration of a *separate Provy Native Application* in the existing EU Auth0 tenant, followed by actual physical-device evidence. This runbook does **not** constitute a Phase-B coding release, permission for cloud provisioning/deployment, verified tenant configuration, or Store readiness. No change to the shared HullQ identity or HullQ application.

## 1. Verified source truth vs unknown live state (02.11.2026)

| Property | Verified current repository evidence | Live Auth0 / device evidence |
| --- | --- | --- |
| Android applicationId | `android/app/build.gradle` = `com.hullq.proviantplaner` | NOT VERIFIED |
| iOS bundle ID | `ios/Runner.xcodeproj/project.pbxproj` = `com.hullq.proviantplaner` | NOT VERIFIED |
| Android manifest placeholders | `auth0Domain: "auth.hullq.com"`, `auth0Scheme: "provy"` **already implemented** in `android/app/build.gradle` | Native browser callback NOT TESTED |
| iOS custom URL scheme | `CFBundleURLSchemes = $(PRODUCT_BUNDLE_IDENTIFIER)` **already implemented** in `ios/Runner/Info.plist` | Native browser callback NOT TESTED |
| iOS deployment target | `IPHONEOS_DEPLOYMENT_TARGET = 14.0` **already implemented** | iOS physical build NOT TESTED |
| Auth0 Flutter dependency | `auth0_flutter >=2.7.0 <3.0.0`; BC-1A acceptance records lockfile resolution to **2.7.0** | Device compatibility NOT TESTED |
| SDK domain required by accepted code | `Auth0Config.expectedNativeDomain = "auth.hullq.com"`; `isValid` rejects other domains | Whether Auth0 custom domain `auth.hullq.com` exists, is verified, TLS-ready and serves this tenant: UNKNOWN |
| SDK public client ID | `AUTH0_CLIENT_ID` compile-time `--dart-define`, default empty; empty or known placeholder fails closed | Provy Native Application and Client ID: UNKNOWN |
| Provy API audience | `https://api.planer.hullq.com` required by `Auth0Config.isValid` and configured in `backend/wrangler.toml` | Auth0 API registration and minted token `aud`: UNKNOWN |
| Backend expected issuer | `AUTH0_ISSUER_BASE_URL = "https://auth.hullq.com/"` in `backend/wrangler.toml` | Live token `iss` and issuer configuration: UNKNOWN |
| Backend D1 / R2 | `backend/wrangler.toml` contains development/placeholder resources | No cloud deployment or functional API inferred |
| Credential handling | Native `webAuthentication(useCredentialsManager: false)`, SDK store/clear within generation-checked mutation coordinator; see accepted source | Actual logout, restart and secure-storage failure behavior NOT TESTED |

**Critical gate:** Neither the presence of `auth.hullq.com` in source nor its appearance in a browser proves it is configured as the Auth0 custom domain of the *existing EU tenant*. If the tenant only exposes an ordinary `*.eu.auth0.com` hostname, **STOP**. Do not substitute it in `--dart-define`, change Worker issuer/audience, create DNS records or silently modify HullQ. Decide and separately authorize either proper custom-domain provisioning with DNS/TLS/issuer review, or a separately reviewed architecture/configuration change.

## 2. Owner read-only preflight — BEFORE creating or modifying anything

1. Sign into the **existing HullQ EU Auth0 tenant** via the official [Auth0 Dashboard](https://manage.auth0.com/). Confirm tenant name/region; do not create a second tenant.
2. Check **Branding → Custom Domains** (or the current equivalent): is the exact hostname `auth.hullq.com` present, verified and ready? Record only hostname and status. If absent/pending, STOP at the critical gate above. Do not alter Cloudflare DNS at this stage.
3. Inspect **Applications → APIs**: does an API exist whose **Identifier/Audience** is exactly `https://api.planer.hullq.com`? If absent or different, STOP and report the discrepancy. Do not create a duplicate API or silently change the Worker config.
4. Inspect **Applications → Applications**: is there already a distinct **Provy** application of **Native** type? Distinguish it from all existing HullQ applications; do not change the latter. If there is no Provy Native application, report that fact before creating it.
5. Record which identity connections are available/enabled, without changing shared tenant-wide connection behavior. A login button or an enabled connection is not evidence of successful mobile login.
6. Do not share Client Secrets, tenant admin credentials, access/refresh/ID tokens, MFA recovery codes or private signing material. A public Native Client ID and nonsecret hostname/audience may be recorded for review.

**Stop/decision:** If any domain, API audience or application mismatch exists, collect only sanitized metadata and request explicit Owner/architecture authorization before any provisioning, backend modification or native build.

## 3. Owner-controlled Provy Native setup (ONLY after read-only gate and explicit authorization)

- In the existing EU tenant, create a **distinct Native Application** named e.g. `Provy_Dev_Native` **only if one is not already present and the Owner expressly authorizes creation**. Never repurpose or edit the HullQ application.
- Verify application type Native, OIDC settings and RS256 where the UI offers them. Use a public Native Client ID, not a Client Secret inside a distributed mobile build.
- Enable only explicitly approved identity connections for this app and check any required consent / upstream provider configuration separately.
- Confirm `auth.hullq.com` is the *actual* usable Auth0 custom domain, and the API identifier is `https://api.planer.hullq.com`, before registering redirects or attempting a build.
- Register **both exact URIs** below, comma-separated, in **Allowed Callback URLs** and **Allowed Logout URLs**, but **only after the domain and actual SDK/manifest IDs have been reconfirmed**. These are source-derived intended values, **not verified tenant registrations**:

  - Android: `provy://auth.hullq.com/android/com.hullq.proviantplaner/callback`
  - iOS: `com.hullq.proviantplaner://auth.hullq.com/ios/com.hullq.proviantplaner/callback`

- The accepted BC-1A code uses the **custom-scheme** iOS flow with iOS 14 compatibility. Do **not** add an HTTPS/Universal-Link redirect and call it functional without the separately validated SDK arguments, associated-domain setup, real device and Owner decision. Be mindful that custom URL schemes carry app-impersonation risk; PKCE reduces risk but is not identical to app-verified links.
- Keep `AUTH0_CLIENT_ID` configured only through the approved build-time mechanism (`--dart-define=AUTH0_CLIENT_ID=...`), with reviewed staging practices. Do not commit operational secrets or log credentials. Domain, audience and scheme changes are **not** authorized by this document; accepted `Auth0Config` validates these strictly.

## 4. Actual Stage evidence required for P05 — issue #45 is authoritative

**Start with Android, then iOS; do not convert green CI or simulated tests into real-device evidence.**

| Gate | Required evidence | Initial state |
| --- | --- | --- |
| Tenant consistency | Verified EU tenant, functional exact custom domain, Provy Native Client ID, exact API audience, approved connections and saved callback/logout URIs | OPEN |
| Android | Real build SHA, device model/OS version and build logs; login with PKCE and browser callback, cancel, access-token audience/issuer validation, logout, re-launch, offline and account-switch behavior | OPEN |
| iOS | Real iOS 14-compatible build and physical device information; corresponding callback/logout/login/cancel/restart/offline evidence | OPEN |
| Auth semantics | No synthetic token, no automatic `GET /v1/me` account projection, no unverified `member` status or false deletion; expired credentials and secure-storage failures handled honestly | OPEN (device stage) |
| Security / privacy | No tenant secrets/tokens in logs; shared HullQ/Auth0 user preserved; record accepted limitations when durable OS secure storage fails | OPEN |
| Independent verification | Exact build/commit refs, test logs or redacted evidence, independent P05 review and **separate explicit Owner Stage acceptance** | OPEN |

P01–P04 (later backend/data/backup gates), BC-1B, Cloudflare D1/R2 provisioning, cloud deployment and Store v1 remain **out of scope and not automatically released**. P05 must not be closed simply because BC-1A code is accepted.

## 5. Sanitized Owner handoff (read-only gate)

After inspecting the dashboard, report only:

- Existing EU Auth0 tenant name or hostname (nonsecret): `...`
- `auth.hullq.com` custom domain: `ready / missing / pending / unknown`
- Provy API identifier `https://api.planer.hullq.com`: `exists and matches / different / missing`
- Separate Provy Native Application: `exists / not created`; if existing, public Client ID (optional)
- Approved/available connections: names only
- Allowed callback/logout URIs: `not configured / saved / mismatch / unknown`
- No live Android/iOS testing is implied.

## 6. Documentation and evidence precedence

- Canonical `main` + `AGENTS.md`, `GEMINI.md`, `docs/ENGINEERING_STANDARD_v1.0.md` and BC-1A accepted owner record.
- [P05 tracking issue #45](https://github.com/StradaDelSole/proviantplaner/issues/45).
- [Auth0 Flutter v2.7.0 package documentation](https://pub.dev/packages/auth0_flutter/versions/2.7.0).
- [Auth0 Flutter native callback/logout quickstart](https://developer.auth0.com/resources/guides/mobile/flutter/basic-authentication).
- [Auth0 custom domain / issuer guidance](https://auth0.com/blog/custom-domains-complete-guide/).

**Do not merge this documentation PR before exact-HEAD CI and an independent review followed by explicit Owner Acceptance. This documentation update changes no production code and does not authorize any Auth0 resource modification.**

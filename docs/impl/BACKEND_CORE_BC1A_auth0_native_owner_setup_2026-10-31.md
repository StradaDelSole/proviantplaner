# BACKEND-CORE BC-1A – Auth0 Native Application: Owner Setup & Stage Verification

**Status:** OWNER ACTION CHECKLIST / NOT PROVISIONED / NOT DEPLOYED.  
**Date:** 31.10.2026 · **Issue:** #40 · **Verified baseline:** `origin/main` `5c4b8c5bb54a5f1a498eadfd8c6d8bbf2aae8ce5`.  
**Binding release:** `docs/impl/BACKEND_CORE_BC1A_phase_B_owner_release_2026-10-31.md`; Owner accepted iOS 14.0 and `auth0_flutter >=2.7.0 <3.0.0`.  
**Purpose:** Define exactly what Owner must configure **inside Auth0** and what Gemini must verify against the repo. This is neither an app-creation claim nor permission to deploy.

## 1. Verified repo values – do not conflate with live Auth0 configuration

| Key | Repo evidence | Assessment |
| --- | --- | --- |
| Android applicationId | `android/app/build.gradle`: `com.hullq.proviantplaner` | Confirmed source value; unchanged by this checklist |
| iOS bundle ID | `ios/Runner.xcodeproj/project.pbxproj`: `com.hullq.proviantplaner` | Confirmed source value; platform target must be moved 12→14 in BC-1A implementation |
| API audience **configured** | `backend/wrangler.toml`: `https://api.planer.hullq.com` | **Not proof** that an Auth0 API with exactly this Identifier is registered |
| JWT issuer **configured** | `backend/wrangler.toml`: `https://auth.hullq.com/` | **Not proof** custom domain actually exists / is configured |
| Current API backend URL | `lib/core/services/hullq_api_client.dart`: `https://api.planer.hullq.com` | Endpoint configuration; not a verified deployed Stage API |
| Existing shared Auth0 | Existing HullQ EU tenant, region EU | Owner to confirm actual hostname, API and application in dashboard |

Do not silently use a sample `.eu.auth0.com` hostname, placeholder, or repo domain as though it has been validated. The Auth0 SDK domain host, token `iss` and backend JWT issuer validation must be consistent. Any change to Worker `AUTH0_ISSUER_BASE_URL` or `AUTH0_AUDIENCE` is **out of scope** for BC-1A unless explicitly authorized separately. The Flutter client must request an **access token for the configured Provy API audience**, not send its ID token as API bearer.

## 2. Owner-only Auth0 setup – no secret sharing

1. Log in to the **existing EU Auth0 tenant**. Do not create a separate tenant or edit HullQ's production app.
2. Go to **Applications → Applications → Create Application**, name e.g. `Provy_Dev_Native`, choose **Native**. A distinct Provy Native client in the existing shared tenant prevents accidental changes to HullQ login applications. This **name is a suggestion**, not an already existing resource.
3. In the new app's **Settings**, verify OIDC conformant/RS256 as supported. Enable only the required identity connections (email and optionally Google/Apple if actually configured); do not invent social connection IDs or imply they work until tested.
4. Record **Auth0 Domain (hostname only, no protocol)** and **Client ID**. The Client ID is a public identifier for mobile apps; **never share or commit Client Secret**, management API tokens, refresh tokens, MFA recovery codes or tenant-admin access.
5. Under **Applications → APIs**, inspect the API identifier used for Provy. Confirm whether it is **exactly** `https://api.planer.hullq.com` and whether the configured JWT Issuer (`https://auth.hullq.com/`) is correct for the tokens emitted with the chosen domain. If not, **STOP** and report a sanitized mismatch; do not silently change backend config or create a duplicate API.
6. Under **Application URIs**, register the **exact callback and logout URLs** derived from the chosen mobile SDK scheme. Use the same URLs in **Allowed Callback URLs** and **Allowed Logout URLs**, subject to the mobile SDK actually configured by Gemini. Save changes. No wildcard callbacks.
7. Keep **real Stage** login tests (including cancellation/logout/browser callback and valid audience token) open until the Native app and actual Android/iOS binaries can be exercised. Do not claim Stage passed from mocks.

## 3. Provisional URL plan – replace `<AUTH0_DOMAIN>` with the verified hostname

The exact Android scheme must be chosen and wired by Gemini as part of BC-1A. An *illustrative* unique lowercase scheme is `provy`; it is **not yet configured** in Android/Manifest or Auth0:

| Platform | Example callback **and** logout URL |
| --- | --- |
| Android (example custom scheme) | `provy://<AUTH0_DOMAIN>/android/com.hullq.proviantplaner/callback` |
| iOS 14+ (bundle ID custom scheme) | `com.hullq.proviantplaner://<AUTH0_DOMAIN>/ios/com.hullq.proviantplaner/callback` |

**Security tradeoff:** Mobile custom URL schemes are susceptible to app impersonation. Auth0 SDK uses Authorization Code + PKCE, but verifiable Android App Links / modern iOS Universal Links are preferable when correctly configured. HTTPS callbacks **must not** be enabled casually without associated-domain/app-link setup and matching device tests. iOS Universal Links on supported later OS versions may be a subsequent hardened enhancement; iOS 14 compatibility must be retained. Never copy examples as actual registered URIs without verifying the SDK's chosen scheme and signed app identifiers.

## 4. Gemini/BC-1A implementation checklist (after release already granted)

- On an isolated feature branch from verified latest `main`: pin the approved `auth0_flutter` **2.7.x** (not a broad `^2.7.0` that can cross major 3.x; use `>=2.7.0 <3.0.0`), update lockfile, verify Flutter >=3.24, Dart >=3.5, iOS target >=14, Android/Java baseline unchanged.
- Configure Android `auth0Domain` and `auth0Scheme` manifest placeholders consistent with chosen callback; iOS `CFBundleURLTypes` and all required CocoaPods/Swift Package settings; no arbitrary sample Client IDs in production builds.
- Auth0 credentials manager and production-safe DI; no hard-coded `auth0_<connection>_token`, no fake login success, no storing access/refresh tokens in ordinary preferences/logs/backups.
- Never automatically call existing `GET /v1/me` to create account, never infer `member` from Auth0 login or network errors. Cloud registration and server entitlements belong to later BC-1B.
- Deletion button must not lie about a completed remote deletion. It must not delete the common HullQ Auth0 identity.
- Test canceled/failed login, app restart, account switch, double refresh+logout, offline local operation, expired/audience-mismatch tokens. Full CI exact HEAD and independent review before merge.
- Verify real OAuth consent and Apple/Google connection behavior only when Owner has enabled them; a displayed button is not proof of connection.
- Stage physical Android/iOS callback/logout, signature/issuer/audience and Store-v1 privacy acceptance remain **P05**; do not declare them DONE until tested.

## 5. Owner handoff – nonsecret values only

To unblock **real** Stage login tests, Owner can supply a **sanitized** record with: exact Domain hostname, new Native Application Client ID, registered API Audience, which login connections were enabled, and whether proposed Android/iOS callback+logout entries were saved. Send **no Client Secret or tokens**. Config values may be copied to the approved build configuration after security review; avoid logging them alongside sensitive session data.

## Official platform docs (checked 31.10.2026)

- Pinned version requirements and callback patterns: https://pub.dev/packages/auth0_flutter/versions/2.7.0
- Auth0 Flutter login flow guide: https://developer.auth0.com/resources/guides/mobile/flutter/basic-authentication
- Auth0 Auth0 Flutter sample: https://github.com/auth0-samples/auth0-flutter-samples

# Build A plan

Branch: `mobile/build-a`. Scope: `mobile/` only. Phases stop for review.

## What exists (audit, Phase 1 start)

- 17 screens in `lib/screens`, 6 models, static `AuthService` (http + shared_preferences), 4 empty service files, `constants/` with blue theme and URL builders.
- Reachable onboarding: splash → welcome → create account → verify email (OTP) → privacy consent (registers a tenant) → role selection → tenant setup | owner setup | app tour → main shell (Home, Payments, Household, Activity, Account). Login → main shell. `verify_phone_screen.dart` is never navigated to.
- `mobile/` has no `android/`, `ios/`, `web/`, `test/` or `analysis_options.yaml`.

## Target structure

```
lib/
  main.dart, app.dart
  core/config      app config (base URL), endpoint paths
  core/network     ApiClient (single Dio), interceptors, slow-request tracker
  core/storage     SessionStore (flutter_secure_storage)
  core/errors      AppException hierarchy + Dio/parse mapping
  core/router      go_router, auth-aware redirect
  core/theme       tokens: colors, spacing, radii, typography, motion, ThemeData
  core/widgets     shared components
  core/utils       money, dates, validators
  features/<auth|onboarding|tenant|landlord|payments|maintenance|account>/
    models, data (abstract repo + impl), providers, screens, widgets
```

## Phase 1 steps

1. Dependencies: add flutter_riverpod, go_router, dio, flutter_secure_storage, mocktail (dev). Remove http, shared_preferences once unused.
2. Tokens and shared widgets per brief section 3. Contrast checked by a unit test.
3. Networking: one Dio (30s connect, 60s receive), auth interceptor (public endpoints opt out), 401 on an authenticated request ends the session, slow-request tracker drives a global "taking a little longer" banner. All failures mapped to typed `AppException` with human copy.
4. Session: token + user (+ organization when known) in secure storage; `SessionController` (Riverpod) restores, saves, clears.
5. Repositories (abstract + Dio impl + provider) for: auth/OTP/passkey link, organizations, buildings, units, tenancies, payments, maintenance, dashboard, shadow rentals, passkey generation. Models hand-written with `fromJson`.
6. Router: splash while restoring, public vs onboarding vs app routes, redirect as a pure function for testing.
7. Port onboarding screens 1:1 in sequence and behaviour, in Rentra Green, on shared widgets. Port the main shell so login/logout keep working; Home and Payments go through repositories; tenants never call dashboard endpoints.
8. Delete `lib/services/*`, `lib/constants/*`, `lib/models/*`, `lib/screens/*`.
9. Tests: error mapping, money, session store, router redirect, repository parsing (fake Dio adapter), contrast.
10. Run pub get, analyze, test; attempt a debug build; write report.

## Later phases

- Phase 2: tenant setup two paths, independent tenant shell, shadow rental view/edit/end.
- Phase 3: landlord shell (Dashboard, Properties, Payments, Operations, Account).
- Phase 4: polish, a11y, widget tests, `build-a-report.md`.

Open questions live in `docs/open-questions.md`.

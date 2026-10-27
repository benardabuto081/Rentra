# Open questions

Items found while building. Nothing here has been worked around in code. Each entry gives what was found and where, and, when a decision is needed, a recommendation.

## Needs a decision before Phase 3

### OQ-1. Landlord sign-up fails in the current flow (blocking)
- **Found:** `PrivacyConsentScreen` registers every new person as a tenant through `POST /auth/register-tenant`, sending their email. If they then choose "I own property", `OwnerSetupScreen` calls `POST /auth/register` with the same email. The backend `registerLandlord` throws `400 Email already registered` (`backend/src/auth/auth.service.ts`). A new landlord cannot finish onboarding.
- **Phase 1:** ported exactly as found. The person now sees the server reason ("Email already registered") instead of a generic error.
- **Recommendation:** create the account at the role step instead of at Privacy Consent. Privacy Consent only records consent. "I rent" calls register-tenant. "I own property" calls register (landlord), which already creates the portfolio. The screen order stays the same. The open question is what "I manage properties" and "Skip for now" should create, because caretakers cannot self-register (see OQ-8).

### OQ-2. Owner setup collects details it never sends
- **Found:** `OwnerSetupScreen` asks for a business name, city and phone, but sends none of them. The backend names the portfolio `"<FirstName>'s Organization"`.
- **Recommendation:** after a successful register, call `PATCH /organizations/:id` with these fields. The endpoint exists and is landlord-only.

## Backend gaps (not worked around)

### OQ-3. `GET /auth/passkey-preview/:code` does not exist
- The tenant setup screen calls it, so a managed-tenant passkey can never be previewed. The app shows: "We couldn't check this passkey right now. You can try again, or set up your rental yourself." It does not fake success. The old code invented a preview when the call failed.
- `POST /auth/link-passkey` requires `rentAmount` and `moveInDate`, which the tenant has no way of knowing without a preview. Linking stays blocked until the preview exists, or until the backend takes rent from the unit.
- The assumed preview shape is `{propertyName, roomName, rentAmount}`, taken from the old screen. Please confirm it when the endpoint is built.

### OQ-4. Phone numbers are matched by exact string
`register-tenant` and `tenant-login` compare phone strings exactly (`usersService.findByPhone`). The app sends the number exactly as typed, trimmed, which is what the old screens did. Someone who registers with `0712345678` must sign in with `0712345678`, not `+254712345678`. Input is now checked against Kenyan formats (`07…`, `01…`, `+254…`, `254…`) but is not normalised.

### OQ-5. Payments and maintenance routes differ from the brief and are not role-protected
- The brief lists `/payments` and `/maintenance`. The real paths are `/organizations/:organizationId/payments` and `/organizations/:organizationId/maintenance`. The code follows the source.
- Neither controller uses `RolesGuard`, so any signed-in user, including a tenant, can read any portfolio's payments if they know its id. The old Payments tab did exactly that for managed tenants. It now shows tenants a calm empty state and makes no call.

### OQ-6. `POST /auth/generate-passkey` has no JWT guard
Anyone can generate a passkey for any unit. The app sends the Authorization header anyway, as the brief asks. This needs fixing in the backend.

### OQ-7. No tenant-scoped endpoints
There is no endpoint for a managed tenant's own tenancy, payments or issues. Managed-tenant Home will show the "connected" state in Phase 2.

### OQ-8. No caretaker invitation or assignment
"I manage properties" leads into the app with a tenant account, because Privacy Consent registered one. Caretaker accounts can only be created outside the app.

### OQ-9. Other missing features
- Independent tenants cannot record payments.
- No notifications.
- No M-Pesa STK Push.
- No profile-update endpoint.
- No `GET /me` to check a restored session. A stale token is caught at its first 401, which ends the session as designed.

### OQ-10. Tenancy records have no tenant name or phone
`GET /organizations/:id/tenants` returns `userId` only, and no endpoint reads another user. In Phase 3, landlord lists can show the unit and the rent, but not the tenant's name.

### OQ-11. Email OTP is not enforced by the register endpoints
`register` and `register-tenant` do not check that an OTP was verified. The app keeps the verify step in the flow, but the server does not require it.

## Repository and tooling

### OQ-12. Root `.gitignore` hides `mobile/test/` and `mobile/analysis_options.yaml`
The patterns `test/` and `analysis_options.yaml` in the root `.gitignore` also match files under `mobile/`. I can't edit `.gitignore`, so the commit commands use `git add -f` for these paths. Consider anchoring those patterns to the root (`/test/`, `/analysis_options.yaml`).

### OQ-13. `mobile/` has no platform folders
`mobile/` has no `android/`, `ios/` or `web/`, and `flutter create` is out of bounds, so no debug build was produced:
- `flutter build apk --debug` failed with "No Android SDK found."
- `flutter build web` failed with "This project is not configured for the web."

How should Build A be run on a device? One option is to allow `flutter create . --platforms android` in `mobile/` (it keeps the existing package name `rentra`).

### OQ-14. Web URL strategy dropped
The old `main.dart` called `setUrlStrategy(PathUrlStrategy())` from `flutter_web_plugins`, which was never declared in `pubspec.yaml`. I removed the call rather than add a dependency, so web builds now use `#/` URLs. Android is unaffected.

### OQ-15. Old sessions are not migrated
Sessions saved in `shared_preferences` by the old app are not read. People sign in once more after updating. This was deliberate: tokens must not stay in plain storage.

### OQ-16. App version for Account (Phase 2)
Showing the app version without a new dependency (such as `package_info_plus`) means hard-coding a constant that mirrors `pubspec.yaml`. Which do you prefer?

## Small copy and behaviour changes made in Phase 1 (confirm or revert)
- **Username field removed:** the optional "Username" on Create Account was never sent and the backend has no such field.
- **Vocabulary:** "Room" became "Unit" in "Find My Unit", "Confirm and join this unit", "Unit: …", and "buildings, units, tenants" on the role screen. "Organization / Business Name" became "Business or Portfolio Name".
- **Form errors:** the old single "Please fill in all required fields" is now an error message on each field.
- **Resend code:** the old screen showed "Code resent successfully" even when sending failed. It now shows the real error.
- **Dead buttons removed** from the ported shell: tenant Home quick actions with no action, the Household "Create Household" and "Join with Passkey" buttons, and the Account menu items with empty handlers. These come back properly in Phases 2 and 3.
- **Sign out** now asks for confirmation.
- **Linking with no rent:** if a passkey preview ever returns no rent amount, linking is refused. The old code sent `rentAmount: 0`.
- **Unused screen deleted:** `verify_phone_screen.dart` was never navigated to.
- **Lints version:** `flutter pub add` tried to bump `flutter_lints` to ^6. I kept the existing ^3.0.0.
- **Skeleton timing:** the skeleton pulse runs on a 900 ms loop, outside the 150–250 ms transition range. It is a loading loop, not a transition.

# Open questions

Items found while building. Nothing here has been worked around in code. Each entry gives what was found and where, and, when a decision is needed, a recommendation.

## Resolved

### OQ-1. Landlord sign-up failed in the old flow (resolved in Phase 1b)
- **Was:** Privacy Consent registered everyone as a tenant, so the later landlord registration hit `400 Email already registered`.
- **Decision:** the account is now created when the person confirms their role. The screen order is unchanged.
  - Create Account holds the details in memory only (`onboardingDraftProvider`). They are cleared after registration, when the person leaves Create Account, and on sign-out.
  - Privacy Consent no longer calls the backend.
  - "I rent a property" calls `/auth/register-tenant`. "I own property" and "I manage properties" both call `/auth/register`. There is no caretaker sign-up.
  - If an email or phone is already registered, the person stays on the role screen with their choice kept and gets a Sign In action.
  - After registering, the app replaces the navigation stack with setup, so going back cannot reach the role screen again. If a session already exists, `Registration.register` returns it instead of calling the backend.
- **Consequence:** if the app is closed before the role is confirmed, no account exists and onboarding starts again from Welcome.
- **Removed:** the role screen's "Skip for now". Skipping would leave the person with no account, and an account needs a role.

### OQ-1a. `POST /auth/register` does not accept a phone number
The landlord registration body is `{firstName, lastName, email, password}` only. The phone collected on Create Account is not stored for landlords. The business phone from Owner Setup goes onto the portfolio (OQ-2), not the user. Landlords sign in by email, so this does not block sign-in. It does mean a landlord's own phone is never recorded.

### OQ-2. Owner setup discarded its input (resolved in Phase 1b)
- **Now:** Owner Setup sends `name`, `city` and `phone` with `PATCH /organizations/:id`, using the portfolio id returned by `/auth/register`, and stores the updated portfolio in the session.
- **On failure:** a calm message appears, with "Continue" and "Try again". Onboarding is never blocked.
- **Phase 3:** the same fields will be editable from landlord Account, as the brief already plans.

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
There is no endpoint for a managed tenant's own tenancy, payments or issues.
- **Phase 2:** managed-tenant Home shows "You're connected to your landlord's property. Your rent and request details are on their way." Payments shows "Your rent details are on their way". Neither makes any request; a test enforces this.
- **Needed from the backend:** a caller-scoped `GET` for the tenancy (unit, building name, rent, due day), the tenancy's payments, and its issues.

### OQ-7a. Weekly rentals have no weekday
Shadow rentals store `dueDayOfMonth` only. For a weekly cycle there is no weekday, so the app shows "You pay rent every week." and no next due date. I did not guess one from the creation date. If weekly rents should get a date, the backend needs a `dueDayOfWeek`.

### OQ-7b. Shadow rentals have no list filter
`GET /shadow-relationships` returns every rental, including ended and converted ones. The app treats the newest `unverified` rental as the current one. If a tenant could track more than one rental at a time, the product would need to say how Home should choose between them.

### OQ-8. No caretaker invitation or assignment
There is no way to invite or assign a caretaker. Since Phase 1b, "I manage properties" creates a landlord, so caretaker accounts can only be created outside the app until invitations exist.

### OQ-9. Other missing features
- Independent tenants cannot record payments.
- No notifications.
- No M-Pesa STK Push.
- No profile-update endpoint.
- No `GET /me` to check a restored session. A stale token is caught at its first 401, which ends the session as designed.

### OQ-10. Tenancy records have no tenant name or phone
`GET /organizations/:id/tenants` returns `userId` only, and no endpoint reads another user.
- **Phase 3:** tenants, payments and issues are labelled by unit and building ("A1 · Kamau Court") through a portfolio index built on the phone. The tenant's name and phone are never shown.
- **Recommendation:** have the tenants endpoint include the tenant's first name, last name and phone.

### OQ-10a. The portfolio index costs one request per building
Turning ids into "A1 · Kamau Court" needs the buildings list plus each building's units, so N+1 requests. That's fine for a few buildings but slow for large portfolios on a weak connection. A single endpoint returning units with their building names (or names embedded in tenants, payments and issues) would remove this.

### OQ-10b. Marking a unit vacant does not end its tenancy
`PATCH .../rooms/:id/vacate` only changes the room. An active tenancy on that room stays active. So in the app:
- An occupied unit with a tenancy shows "To move this tenant out, open their tenancy". Move-out goes through `PATCH .../tenants/:id/vacate`, which ends the tenancy and also frees the room.
- "Mark as vacant" (with confirmation) is offered only for units with no tenancy, such as one under repair.

Should the backend refuse to vacate a room that still has an active tenancy?

### OQ-10c. Deactivating a building leaves its tenancies active
`DELETE .../buildings/:id` only sets the building inactive. Its units and any active tenancies are untouched, so a tenant can be "active" in a building that no longer appears in My Properties. The confirmation says records are kept. Should the backend block this while tenants are active?

### OQ-10d. Issues can only come from outside the app
Landlords can assign, prioritise, resolve and cancel issues, but nobody can create one in the app. Tenant "Report an Issue" needs tenant-scoped endpoints (OQ-7) and is out of scope. Until then, Operations stays empty unless issues are created through the API directly.

### OQ-10e. "Assigned to" is free text
`PATCH .../maintenance/:id/assign` takes `assignedTo` as any string, and there are no caretaker accounts to choose from (OQ-8). The app asks "Who is handling this?" and stores the name typed, such as "Juma the plumber". If this field is meant to hold a user id, it needs to change when caretakers arrive.

### OQ-10f. Passkeys can be created but not yet used
The landlord side works: choose 7, 14 or 30 days and get a code with a copy button and an expiry date. A tenant still cannot redeem it, because the preview endpoint is missing (OQ-3). The invite screen states what the passkey is for without promising it works end to end.

### OQ-10g. Caretakers use the landlord app
Caretaker screens are out of scope, so a caretaker who signs in sees the landlord tabs. The server rejects their write actions with 403, and the app shows "Your account doesn't have access to this…". There is no way to hide those actions for caretakers until the caretaker experience is designed.

### OQ-11. Email OTP is not enforced by the register endpoints
`register` and `register-tenant` do not check that an OTP was verified. The app keeps the verify step in the flow, but the server does not require it.

## Repository and tooling

### OQ-12. Root `.gitignore` hides `mobile/test/` and `mobile/analysis_options.yaml`
The patterns `test/` and `analysis_options.yaml` in the root `.gitignore` also match files under `mobile/`. I can't edit `.gitignore`, so the commit commands use `git add -f` for these paths. Consider anchoring those patterns to the root (`/test/`, `/analysis_options.yaml`).

### OQ-13. `mobile/` had no platform folders (resolved in Phase 1b; build still blocked)
- **Done:** ran `flutter create . --platforms android` in `mobile/` as a one-time exception. `pubspec.yaml`, `lib/main.dart` and `analysis_options.yaml` are byte-identical before and after (md5 checked).
- **Cleaned up:**
  - Deleted the generated `test/widget_test.dart`, `README.md` and `mobile/.gitignore`. That last file would have changed the ignore rules, which you are handling.
  - `.idea/`, `.metadata` and `rentra.iml` were also generated; the root `.gitignore` already ignores them.
- **Still blocked:** this machine has no Android SDK. `flutter doctor -v` reports "Unable to locate Android SDK", and `flutter build apk --debug` fails with "No Android SDK found." Per instructions, I did not install anything.

### OQ-13a. Default application id
`android/app/build.gradle.kts` has `namespace` and `applicationId` set to `com.example.rentra`. These must be changed to the real id before any store release, and changing the id later means a different app on the Play Store.

### OQ-14. Web URL strategy dropped
The old `main.dart` called `setUrlStrategy(PathUrlStrategy())` from `flutter_web_plugins`, which was never declared in `pubspec.yaml`. I removed the call rather than add a dependency, so web builds now use `#/` URLs. Android is unaffected.

### OQ-15. Old sessions are not migrated
Sessions saved in `shared_preferences` by the old app are not read. People sign in once more after updating. This was deliberate: tokens must not stay in plain storage.

### OQ-16. App version for Account (Phase 2, decided by default)
There was no answer, so I took the no-new-dependency option. `AppConfig.appVersion` mirrors `version` in `pubspec.yaml`, and `test/core/app_version_test.dart` fails if they drift. Account shows "1.0.0 (build 1)". If you prefer `package_info_plus`, say so and I'll swap it.

## Small copy and behaviour changes made in Phase 1 (confirm or revert)
- **Username field removed:** the optional "Username" on Create Account was never sent and the backend has no such field.
- **Vocabulary:** "Room" became "Unit" in "Find My Unit", "Confirm and join this unit", "Unit: …", and "buildings, units, tenants" on the role screen. "Organization / Business Name" became "Business or Portfolio Name".
- **Form errors:** the old single "Please fill in all required fields" is now an error message on each field.
- **Resend code:** the old screen showed "Code resent successfully" even when sending failed. It now shows the real error.
- **Dead buttons removed** from the ported shell: tenant Home quick actions with no action, the Household "Create Household" and "Join with Passkey" buttons, and the Account menu items with empty handlers. These come back properly in Phases 2 and 3.
- **Sign out** now asks for confirmation.

## Copy and behaviour changes made in Phase 1b
- **Privacy Consent button:** "Create My Account" became "Continue", because it no longer creates the account.
- **Role screen:** the cards are now a single choice, confirmed with a "Continue" button. Registration happens on that button.
- **"I manage properties" subtitle:** "I was invited to manage properties on behalf of an owner." described caretakers. It is now "Manage buildings, units and tenants on behalf of owners.", because this path creates a landlord.
- **Owner Setup success:** now ends with "Your portfolio is set up."
- **Linking with no rent:** if a passkey preview ever returns no rent amount, linking is refused. The old code sent `rentAmount: 0`.
- **Unused screen deleted:** `verify_phone_screen.dart` was never navigated to.
- **Lints version:** `flutter pub add` tried to bump `flutter_lints` to ^6. I kept the existing ^3.0.0.
- **Skeleton timing:** the skeleton pulse runs on a 900 ms loop, outside the 150–250 ms transition range. It is a loading loop, not a transition.

## Copy and behaviour changes made in Phase 2
- **Tenant setup choices:** now read "My landlord gave me a passkey" and "My landlord isn’t on Rentra", as in the brief. "Skip for now" only appears during onboarding.
- **Rental form:**
  - Adds "How often do you pay?" (Monthly default, Weekly, Daily).
  - The due day shows only for monthly rent and defaults to today's day, capped at the 28th.
  - The rent label changed from "Monthly Rent" to "Rent amount".
  - The reference field has helper text.
  - Paybill, till and bank numbers accept digits only.
- **Editing:** clearing the optional address or reference sends an empty string, so the old value is removed. A null would be ignored by the backend.
- **Household and Activity:** both are calm empty states with no buttons. The copy changed so it no longer implies something is missing.
- **Account:** read-only profile, email, phone, role, app version and sign out.
- **Role-based tabs:** landlords and caretakers still see the Phase 1 landlord Home and Payments in the same five tabs until Phase 3.

## Copy and behaviour changes made in Phase 3
- **Separate tab bars by role:**
  - Landlords now have their own tabs (Dashboard, Properties, Payments, Operations, Account) under `/landlord/...`.
  - Tenants keep Home, Payments, Household, Activity, Account.
  - The router moves anyone who reaches the other role's area back to their own home.
- **Role label:** landlords now see "Landlord" instead of "Property Owner", because property managers register as landlords too.
- **Dashboard:**
  - A list under "What needs my attention today?" covers open issues, money still to collect, tenants on notice and vacant units. When the list is empty it says "Nothing needs your attention today. Everything is up to date."
  - "Outstanding (all months)" comes from the backend's arrears total, which is not limited to the current month.
- **Record a payment:**
  - The year can be last year, this year or next year, to allow advance payments.
  - Amount paid can be 0, which records the payment as not paid.
  - The M-Pesa code field appears only when the method is M-Pesa. It is upper-cased as you type and must be exactly 10 letters and digits when present.
- **Settling a payment:** "Update amount paid" asks for the total paid so far and offers the full amount by default. The app never subtracts amounts; the server works out the status.
- **Several units:** names are a prefix plus a running number (default "A" from 1). Units are created one after another. If one fails, the app reports how many were added and offers to add the rest.
- **Sheets and snackbars:** opening a bottom sheet now hides any success message still showing, so it cannot cover the sheet's button.

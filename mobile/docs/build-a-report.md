# Build A report

Branch `mobile/build-a`. Flutter 3.44.1, Dart 3.12.1. The Flutter app lives in `mobile/`; nothing outside it was changed.

Status at the end of Phase 4:
- `flutter analyze`: no issues.
- `flutter test`: 150 tests, all passing.
- `flutter build apk --debug`: blocked, because this machine has no Android SDK (`flutter doctor -v`: "Unable to locate Android SDK"). The app has never been run on a device or emulator. The manual script in section 4 is the first real-device check.

## 1. What exists

### Foundation
- **State and navigation:** Riverpod, and go_router with a redirect based on sign-in state and role. Tenants and landlords each have their own five-tab shell, and the router sends anyone who reaches the other role's area back to their own home.
- **Networking:** one Dio client (`core/network`) with 30 s connect and 60 s receive timeouts.
  - An auth interceptor adds the token. Public endpoints opt out.
  - After 5 s, a calm banner says "This is taking a little longer than usual…".
  - Every failure becomes a typed `AppException` with human copy. Backend words are rewritten, for example Room becomes Unit.
  - A 401 on a signed-in request ends the session, and Welcome shows "Your session has ended. Please sign in again."
- **Storage:** the session (token, user, portfolio) is kept in `flutter_secure_storage`. The onboarding password is held in memory only.
- **Repositories:** every backend resource has an abstract repository with an implementation, exposed through a provider. Models are hand-written with `fromJson`. Money arrives as decimal strings and is parsed by one defensive helper; it is formatted as `KES 12,500` and `KES 12,500.50`.
- **Design tokens and shared components:** tokens are exactly as in the brief, except one contrast fix: warning text uses `#AB5E05`. Shared components cover:
  - buttons (one filled primary per screen, 0.98 scale when pressed)
  - card, stat tile, status chip (always icon plus text), money text, section header, detail row, list card
  - empty, error-with-retry, inline message and skeleton states
  - text, password, email, Kenyan phone, OTP, money, dropdown and date fields
  - confirm dialog, bottom-sheet forms, success and error snackbars, copy row

### Onboarding (all roles)
The order is Splash → Welcome → Create Account → email code → Privacy Consent → "How do you use Rentra?" → setup → tour → app.
- The account is created only when the role is confirmed. Renters become tenants; owners and property managers become landlords.
- If the email or phone is already registered, the person stays on the role screen and is offered Sign In.
- Owner setup saves the business name, city and phone to the portfolio. If that fails, onboarding still continues.
- Sign-in takes a phone number for tenants and an email for landlords, as before.

### Tenant
- **Setup:** "My landlord gave me a passkey" or "My landlord isn't on Rentra". The own-rental form uses selectors and defaults and ends with "Your rental is set up."
- **Home:** the rental card with a calm next-due sentence and one action, "How to pay". Editing and ending the rental (with confirmation) are also here.
- **Managed tenants:** a calm "connected" state with no backend calls.
- **Payments:** paybill, till or bank details with copy buttons, the billing schedule, and an honest note that payment tracking isn't available yet.
- **Household and Activity:** calm empty states.
- **Account:** read-only profile, role, app version and sign out.
- A test confirms no tenant screen calls a landlord endpoint.

### Landlord
- **Dashboard:** built around "What needs my attention today?" (open issues, money to collect, tenants on notice, vacant units), plus this month's money and portfolio tiles. Pull to refresh.
- **Properties:**
  - Buildings: add, edit, and deactivate with confirmation.
  - Units: add one or several (prefix, first number, count, shared rent, created one after another with resume on failure); edit; mark vacant with confirmation.
  - Inviting a tenant creates a passkey: choose 7, 14 or 30 days, then see the code large with copy and an expiry date.
  - Tenants: a list and a detail screen with update rent, record notice, move out and payment history.
- **Payments:**
  - A month selector with that month's totals and payments, and an Outstanding list.
  - Record a payment with defaults: tenant from a list, type Rent, method M-Pesa, amount from the tenant's rent, amount paid the same, current month and year. The optional M-Pesa code is checked for 10 letters and digits.
  - Settle a partial payment.
- **Operations:** issues filtered by status, with assign, change priority, resolve (notes required), and cancel with confirmation.
- **Account:** view and edit portfolio details, app version, sign out.

### Quality work done in Phase 4
- **Automated accessibility sweep:** every screen, as tenant, landlord and signed out, on a 360×640 screen at 1.3× text. Each is checked for layout overflow, 48 dp tap targets, labelled tap targets and text contrast. It found and fixed:
  - a payment row that could not wrap
  - a 30 px long-press target on copyable values
- **Skeletons:** loading on every list and dashboard, including small sections that previously left blank space.
- **Builder lists:** used where lists grow (buildings, month payments, a tenant's payment history).
- **Dead code:** removed the unused icon-size token, and put the brief's disabled colour to use on disabled outlined and text buttons.
- **Widget tests:** for all shared components and both navigation shells.

### Tests (150)
- **Unit tests:** error mapping, money parsing and formatting, the session store, redirects for both roles, repository parsing through a fake Dio adapter, colour contrast, the due-date helper, registration, and the app version matching `pubspec.yaml`.
- **Widget tests:**
  - every tenant and landlord journey, driven through an in-memory fake backend and the real repositories
  - the shared components
  - both shells
  - the accessibility sweep
- **Architecture checks:** only `core/network` and `core/errors` import Dio, no screen builds URLs, and nothing logs.

Repository methods that no screen uses yet are kept because the brief asked for a repository covering every endpoint: `PaymentRepository.list`, `TenancyRepository.active`, `UnitRepository.vacant`, `MaintenanceRepository.pending` and `forTenant`, and `ShadowRentalRepository.get`.

## 2. Deliberately not built

From the brief's out-of-scope list:
- caretaker experience and invitations
- managed-tenant tenancy, payments and issues screens
- notifications and push
- M-Pesa STK Push
- Household features
- Rental Passport, Rentra Score, Marketplace
- profile editing
- dark mode, translations, iOS-specific work, the website
- any backend change, CI
- removal of the root `lib/` and `pubspec.yaml`

Not built because the backend doesn't support it yet (nothing is faked):
- **Redeeming a passkey:** the preview endpoint is missing, so tenants see a calm failure and the other path (OQ-3).
- **Tenant "Report an Issue":** there are no tenant-scoped endpoints (OQ-7). Landlords therefore only see issues created through the API (OQ-10d).
- **Payment tracking for independent tenants** (OQ-9).
- **Tenant names in landlord lists** (OQ-10).

## 3. Open questions

Full details, evidence and recommendations are in `docs/open-questions.md`.

| ID | Summary | State |
|---|---|---|
| OQ-1 | Landlord sign-up failed when Privacy registered a tenant | Resolved in 1b: register at the role step |
| OQ-1a | `/auth/register` takes no phone, so a landlord's phone is never stored | Open (backend) |
| OQ-2 | Owner setup discarded its input | Resolved in 1b: PATCH to the portfolio |
| OQ-3 | `GET /auth/passkey-preview/:code` missing; linking needs rent | Open (backend) |
| OQ-4 | Phone numbers matched by exact string | Open (backend) |
| OQ-5 | Payments and maintenance not role-protected | You are handling it |
| OQ-6 | `generate-passkey` has no JWT guard | You are handling it |
| OQ-7 | No tenant-scoped endpoints for managed tenants | Open (backend) |
| OQ-7a | Weekly rentals have no weekday, so no next due date | Open (backend) |
| OQ-7b | Shadow rentals have no list filter; app uses the newest unverified one | Open (product) |
| OQ-8 | No caretaker invitation or assignment | Open (backend and product) |
| OQ-9 | No tenant payment recording, notifications, STK Push, profile update or `/me` | Open (backend) |
| OQ-10 | Tenancies carry no tenant name or phone | Open (backend) |
| OQ-10a | Portfolio index needs one request per building | Open (backend) |
| OQ-10b | Marking a unit vacant doesn't end its tenancy; app moves tenants out through the tenancy | Open (backend) |
| OQ-10c | Deactivating a building leaves its tenancies active | Open (backend) |
| OQ-10d | No one can create an issue in the app | Open (backend) |
| OQ-10e | "Assigned to" is free text | Open (product) |
| OQ-10f | Passkeys can be created but not redeemed | Depends on OQ-3 |
| OQ-10g | Caretakers see the landlord tabs; the server rejects their write actions | Open (product) |
| OQ-11 | Register endpoints don't require a verified OTP | Open (backend) |
| OQ-12 | Root `.gitignore` hides `mobile/test/` and `mobile/analysis_options.yaml` | You are handling it |
| OQ-13 | No platform folders | Resolved in 1b (Android generated); build blocked by the missing SDK |
| OQ-13a | Application id is still `com.example.rentra` | Must change before any store release |
| OQ-14 | Web URL strategy dropped | Accepted |
| OQ-15 | Old `shared_preferences` sessions not migrated | Accepted |
| OQ-16 | App version is a constant mirrored from `pubspec.yaml`, guarded by a test | Decided by default |

One limit of the automated checks: widget tests draw text in the Ahem test font, where every character is a full square. That makes overflow checks stricter than real fonts, but it cannot reproduce Android font rendering, OEM font scaling or real keyboards. Section 4 covers those on a device.

## 4. Manual test script

**Setup.** Install the Android SDK (for example through Android Studio) and connect an affordable Android phone or start an emulator. Then, from `mobile/`:

```
flutter pub get
flutter run
```

To use another backend, add `--dart-define=API_BASE_URL=https://your-host`. The first request after the hosted backend has been idle can be slow, and the "taking a little longer" banner should appear.

Use a fresh email and phone for each new account. Expected results are in quotes.

### A. Tenant, independent
1. On first launch you see a green splash, then Welcome.
2. Create Account. Enter names, phone `07…`, email, and password twice, then Continue.
   - Before that, check the validation: an invalid phone like `12345` shows "Enter a Kenyan phone number…", and mismatched passwords show "Passwords do not match."
3. Enter the 6-digit email code. Pasting the code, or SMS-style autofill, should fill all six boxes. Resend shows "Code resent successfully". A wrong code shows the server's reason.
4. Privacy: tap Continue without ticking anything and you see "Please agree to both terms to continue." Tick both, then Continue.
5. Role: Continue is disabled until you choose. Choose "I rent a property", then Continue.
6. Choose "My landlord isn't on Rentra". Fill in a name, rent 7000, Monthly, a due day, Paybill 522522 and a reference, then Save. You see "Your rental is set up.", then the tour.
7. Tour: Next through the pages, then Get Started. Home shows the rental card and "Next rent is due …, on …".
8. How to pay: tap copy on the paybill number. You see "Paybill Number copied."; paste it into another app to confirm.
9. Edit the rental:
   - Home, Edit rental details. Switch to Weekly: the due-day field disappears. Save; you see "Rental details saved." and Home says "You pay rent every week."
   - Edit again. End this rental, Cancel, then End rental. You see "Your rental has ended." and Home shows "Add your rental".
10. Household and Activity are calm and have no buttons.
11. Account shows Tenant and the app version "1.0.0 (build 1)". Sign Out, then confirm, and you are on Welcome.
12. Sign In with the same phone number. You see "Signing in as tenant" and land on Home.

### B. Tenant passkey path
1. Signed in as a tenant with no rental: Home, Set up my rental, then "My landlord gave me a passkey".
2. Entering `ABC` shows the format message. Entering `RTR-ABC123` then Find My Unit shows "We couldn't check this passkey right now…", and "Set up my rental myself" opens the form. This failure is expected until OQ-3 is fixed.

### C. Landlord
1. Register with a new email and choose "I manage properties", then Continue. You land on Owner Setup.
   - Fill in the business name, city and phone, then Complete Setup. You see "Your portfolio is set up.", then the tour, then the Dashboard showing "Add your first building".
2. Repeat C1 with an email that is already registered. You stay on the role screen with your choice kept and see "That email is already registered. Try signing in instead.", with Sign In opening the login screen.
3. Add a building called "Kamau Court". You see "Building added." and then "Now add the units in Kamau Court". Choose Several units, A, from 1, count 4, rent 12000. The preview reads "We will add A1, A2 … A4." Then you see "4 units added." and "0 of 4 units occupied".
4. Open A1 and choose Invite a tenant. Pick 14 days, then Create passkey. You see a large code, copy works, and "Works until <date 14 days ahead>".
5. Open A2 and edit the rent to 12500. You see "Unit details saved."
6. Building menu: Edit building (save shows "Building details saved."). Deactivate building, confirm, and you see "Kamau Court deactivated." Add a new building before continuing.
7. **Payments, Outstanding and Operations need data:** a tenancy and an issue, created through the API because tenant linking is blocked (OQ-3, OQ-10d). With a tenancy in place:
   - Record payment: the tenant is preselected and the amount is the tenant's rent. Set amount paid to 5000 and the M-Pesa code to `abc`: you see the code error. Change the code to `QJK3XY7ZAB` and record. You see "Payment recorded as partly paid." The Outstanding tab lists it.
   - Open the payment, Update amount paid, then Save. You see "Payment updated. It is now fully paid."
   - Use the month selector: going back shows earlier months, and Next stops at the current month.
   - Tenants, then the tenant: Update rent shows "Rent updated to KES …". Record notice shows "Notice recorded." Move out shows "Tenant moved out. … is now vacant."
   - Operations, then the issue: Assign to "Juma" shows "Assigned to Juma." Change priority to Urgent shows "Priority updated." Mark resolved with a note and a cost shows "Issue resolved." Cancelling a second issue (Keep it, then Cancel issue) shows "Issue cancelled."
8. Account: Edit details, change the city, then Save. You see "Portfolio details saved."
9. Dashboard: pull to refresh, and check the counts match what you did.

### D. Resilience
1. With airplane mode on, open any list. You see "You're offline" and "Try again". Turn data on again and retry; the list loads.
2. Sign in on the device, then expire the token on the server (or wait 7 days). The next action returns you to Welcome with "Your session has ended. Please sign in again."
3. Close the app between Privacy and the role step, then reopen it. You are on Welcome and no account was created. Start again.

### E. Accessibility and small screens
1. Set the device font size to largest (about 1.3×) and display size to default, on a 360 dp-wide phone if possible. Repeat A6 to A11 and C3 to C7, looking for clipped or overlapping text.
2. Turn on TalkBack. On Home, Payments, Properties and a payment form, every button and field should announce a name, and status chips should read as text.
3. Turn on "Remove animations". Cards should appear without fading.

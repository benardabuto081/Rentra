import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/screens/account_screen.dart';
import '../../features/account/screens/portfolio_form_screen.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/auth/providers/session_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/landlord/screens/add_units_screen.dart';
import '../../features/landlord/screens/building_detail_screen.dart';
import '../../features/landlord/screens/building_form_screen.dart';
import '../../features/landlord/screens/dashboard_screen.dart';
import '../../features/landlord/screens/invite_tenant_screen.dart';
import '../../features/landlord/screens/properties_screen.dart';
import '../../features/landlord/screens/tenancy_detail_screen.dart';
import '../../features/landlord/screens/tenants_screen.dart';
import '../../features/landlord/screens/unit_detail_screen.dart';
import '../../features/landlord/screens/unit_form_screen.dart';
import '../../features/maintenance/screens/issue_detail_screen.dart';
import '../../features/maintenance/screens/issues_screen.dart';
import '../../features/onboarding/screens/app_tour_screen.dart';
import '../../features/onboarding/screens/create_account_screen.dart';
import '../../features/onboarding/screens/owner_setup_screen.dart';
import '../../features/onboarding/screens/privacy_consent_screen.dart';
import '../../features/onboarding/screens/role_selection_screen.dart';
import '../../features/onboarding/screens/tenant_setup_screen.dart';
import '../../features/onboarding/screens/verify_email_screen.dart';
import '../../features/payments/screens/landlord_payments_screen.dart';
import '../../features/payments/screens/payment_detail_screen.dart';
import '../../features/payments/screens/record_payment_screen.dart';
import '../../features/tenant/screens/activity_screen.dart';
import '../../features/tenant/screens/edit_rental_screen.dart';
import '../../features/tenant/screens/household_screen.dart';
import '../../features/tenant/screens/tenant_home_screen.dart';
import '../../features/tenant/screens/tenant_payments_screen.dart';
import 'app_routes.dart';
import 'main_shell.dart';

typedef AuthState = ({AuthStatus status, UserRole? role});

final authStatusProvider = Provider<AuthState>((ref) {
  final session = ref.watch(sessionControllerProvider);
  final splash = ref.watch(splashGateProvider);
  if (splash.isLoading || (session.isLoading && !session.hasValue)) {
    return (status: AuthStatus.loading, role: null);
  }
  final user = session.value?.user;
  return (
    status: user == null ? AuthStatus.signedOut : AuthStatus.signedIn,
    role: user?.role,
  );
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AuthState>(ref.read(authStatusProvider));
  ref.listen(authStatusProvider, (_, next) => refresh.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      status: refresh.value.status,
      role: refresh.value.role,
    ),
    routes: [
      _page(AppRoutes.splash, (_) => const SplashScreen()),
      _page(AppRoutes.welcome, (_) => const WelcomeScreen()),
      _page(AppRoutes.login, (_) => const LoginScreen()),
      _page(AppRoutes.createAccount, (_) => const CreateAccountScreen()),
      _page(AppRoutes.verifyEmail, (_) => const VerifyEmailScreen()),
      _page(AppRoutes.privacy, (_) => const PrivacyConsentScreen()),
      _page(AppRoutes.role, (_) => const RoleSelectionScreen()),
      _page(AppRoutes.tenantSetup, (_) => const TenantSetupScreen()),
      _page(AppRoutes.ownerSetup, (_) => const OwnerSetupScreen()),
      _page(AppRoutes.tour, (_) => const AppTourScreen()),
      _page(
        AppRoutes.rentalSetup,
        (_) => const TenantSetupScreen(fromOnboarding: false),
      ),
      _page(AppRoutes.rentalEdit, (_) => const EditRentalScreen()),

      // Landlord forms, shown full screen above the tabs.
      _page(AppRoutes.newBuilding, (_) => const BuildingFormScreen()),
      _page(
        '/landlord/buildings/:buildingId/edit',
        (s) => BuildingFormScreen(buildingId: s.pathParameters['buildingId']),
      ),
      _page(
        '/landlord/buildings/:buildingId/units/new',
        (s) => AddUnitsScreen(
          buildingId: s.pathParameters['buildingId']!,
          afterNewBuilding: s.uri.queryParameters['next'] == 'building',
        ),
      ),
      _page(
        '/landlord/buildings/:buildingId/units/:unitId/edit',
        (s) => UnitFormScreen(
          buildingId: s.pathParameters['buildingId']!,
          unitId: s.pathParameters['unitId']!,
        ),
      ),
      _page(
        '/landlord/buildings/:buildingId/units/:unitId/invite',
        (s) => InviteTenantScreen(
          buildingId: s.pathParameters['buildingId']!,
          unitId: s.pathParameters['unitId']!,
        ),
      ),
      _page(
        '/landlord/record-payment',
        (s) => RecordPaymentScreen(tenancyId: s.uri.queryParameters['tenancy']),
      ),
      _page(AppRoutes.editPortfolio, (_) => const PortfolioFormScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) =>
            MainShell(navigationShell: shell, tabs: tenantTabs),
        branches: [
          _branch(AppRoutes.home, const TenantHomeScreen()),
          _branch(AppRoutes.payments, const TenantPaymentsScreen()),
          _branch(AppRoutes.household, const HouseholdScreen()),
          _branch(AppRoutes.activity, const ActivityScreen()),
          _branch(AppRoutes.account, const AccountScreen()),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) =>
            MainShell(navigationShell: shell, tabs: landlordTabs),
        branches: [
          _branch(AppRoutes.landlordDashboard, const DashboardScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.landlordProperties,
                builder: (_, __) => const PropertiesScreen(),
                routes: [
                  GoRoute(
                    path: 'tenants',
                    builder: (_, __) => const TenantsScreen(),
                    routes: [
                      GoRoute(
                        path: ':tenancyId',
                        builder: (_, s) => TenancyDetailScreen(
                          tenancyId: s.pathParameters['tenancyId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':buildingId',
                    builder: (_, s) => BuildingDetailScreen(
                      buildingId: s.pathParameters['buildingId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'units/:unitId',
                        builder: (_, s) => UnitDetailScreen(
                          buildingId: s.pathParameters['buildingId']!,
                          unitId: s.pathParameters['unitId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.landlordPayments,
                builder: (_, __) => const LandlordPaymentsScreen(),
                routes: [
                  GoRoute(
                    path: ':paymentId',
                    builder: (_, s) => PaymentDetailScreen(
                      paymentId: s.pathParameters['paymentId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.landlordOperations,
                builder: (_, __) => const IssuesScreen(),
                routes: [
                  GoRoute(
                    path: ':issueId',
                    builder: (_, s) => IssueDetailScreen(
                      issueId: s.pathParameters['issueId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _branch(AppRoutes.landlordAccount, const AccountScreen()),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

GoRoute _page(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(path: path, builder: (_, state) => build(state));

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (_, __) => screen)],
    );

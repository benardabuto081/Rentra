import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/screens/account_screen.dart';
import '../../features/auth/providers/session_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/onboarding/screens/app_tour_screen.dart';
import '../../features/onboarding/screens/create_account_screen.dart';
import '../../features/onboarding/screens/owner_setup_screen.dart';
import '../../features/onboarding/screens/privacy_consent_screen.dart';
import '../../features/onboarding/screens/role_selection_screen.dart';
import '../../features/onboarding/screens/tenant_setup_screen.dart';
import '../../features/onboarding/screens/verify_email_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/tenant/screens/activity_screen.dart';
import '../../features/tenant/screens/home_screen.dart';
import '../../features/tenant/screens/household_screen.dart';
import 'main_shell.dart';
import 'app_routes.dart';

final authStatusProvider = Provider<AuthStatus>((ref) {
  final session = ref.watch(sessionControllerProvider);
  final splash = ref.watch(splashGateProvider);
  if (splash.isLoading || (session.isLoading && !session.hasValue)) {
    return AuthStatus.loading;
  }
  return session.value == null ? AuthStatus.signedOut : AuthStatus.signedIn;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AuthStatus>(ref.read(authStatusProvider));
  ref.listen(authStatusProvider, (_, next) => refresh.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      status: refresh.value,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        builder: (_, __) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, __) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, __) => const PrivacyConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.role,
        builder: (_, __) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.tenantSetup,
        builder: (_, __) => const TenantSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.ownerSetup,
        builder: (_, __) => const OwnerSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.tour,
        builder: (_, __) => const AppTourScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          _branch(AppRoutes.home, const HomeScreen()),
          _branch(AppRoutes.payments, const PaymentsScreen()),
          _branch(AppRoutes.household, const HouseholdScreen()),
          _branch(AppRoutes.activity, const ActivityScreen()),
          _branch(AppRoutes.account, const AccountScreen()),
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

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (_, __) => screen)],
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/router/app_router.dart';
import 'package:rentra/core/router/app_routes.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/auth/providers/session_providers.dart';

import '../helpers/memory_fakes.dart';

const _tenant = Session(
  token: 't',
  user: AppUser(id: 'u', role: UserRole.tenant),
);

String? _signedIn(String location, UserRole role) => resolveRedirect(
      location: location,
      status: AuthStatus.signedIn,
      role: role,
    );

void main() {
  group('resolveRedirect', () {
    test('everything waits on the splash while loading', () {
      expect(
        resolveRedirect(location: AppRoutes.home, status: AuthStatus.loading),
        AppRoutes.splash,
      );
      expect(
        resolveRedirect(location: AppRoutes.splash, status: AuthStatus.loading),
        isNull,
      );
    });

    test('signed out people can use the sign-up and sign-in routes', () {
      for (final route in AppRoutes.signedOutRoutes) {
        expect(
          resolveRedirect(location: route, status: AuthStatus.signedOut),
          isNull,
          reason: route,
        );
      }
    });

    test('signed out people are sent to Welcome from anything else', () {
      for (final route in [
        AppRoutes.splash,
        AppRoutes.home,
        AppRoutes.account,
        AppRoutes.tenantSetup,
        AppRoutes.ownerSetup,
        AppRoutes.tour,
        AppRoutes.landlordDashboard,
        AppRoutes.newBuilding,
      ]) {
        expect(
          resolveRedirect(location: route, status: AuthStatus.signedOut),
          AppRoutes.welcome,
          reason: route,
        );
      }
    });

    test('signed in people skip the signed-out screens to their own home', () {
      for (final route in AppRoutes.signedOutOnly) {
        expect(_signedIn(route, UserRole.tenant), AppRoutes.home, reason: route);
        expect(
          _signedIn(route, UserRole.landlord),
          AppRoutes.landlordDashboard,
          reason: route,
        );
      }
    });

    test('everyone can finish onboarding', () {
      for (final role in UserRole.values) {
        for (final route in [
          AppRoutes.privacy,
          AppRoutes.role,
          AppRoutes.tenantSetup,
          AppRoutes.ownerSetup,
          AppRoutes.tour,
        ]) {
          expect(_signedIn(route, role), isNull, reason: '$role $route');
        }
      }
    });

    test('tenants stay in the tenant area', () {
      for (final route in [
        AppRoutes.home,
        AppRoutes.payments,
        AppRoutes.account,
        AppRoutes.rentalEdit,
      ]) {
        expect(_signedIn(route, UserRole.tenant), isNull, reason: route);
      }
      for (final route in [
        AppRoutes.landlordDashboard,
        AppRoutes.landlordPayments,
        AppRoutes.building('b1'),
        AppRoutes.newBuilding,
        AppRoutes.recordPayment(),
      ]) {
        expect(_signedIn(route, UserRole.tenant), AppRoutes.home, reason: route);
      }
    });

    test('landlords and caretakers stay in the landlord area', () {
      for (final role in [UserRole.landlord, UserRole.caretaker]) {
        for (final route in [
          AppRoutes.landlordDashboard,
          AppRoutes.unit('b1', 'u1'),
          AppRoutes.editPortfolio,
          AppRoutes.issue('i1'),
        ]) {
          expect(_signedIn(route, role), isNull, reason: route);
        }
        for (final route in [
          AppRoutes.home,
          AppRoutes.payments,
          AppRoutes.account,
          AppRoutes.rentalSetup,
        ]) {
          expect(
            _signedIn(route, role),
            AppRoutes.landlordDashboard,
            reason: route,
          );
        }
      }
    });
  });

  group('authStatusProvider', () {
    ProviderContainer container(MemorySessionStore store) {
      final c = ProviderContainer(
        overrides: [
          sessionStoreProvider.overrideWithValue(store),
          splashDurationProvider.overrideWithValue(Duration.zero),
        ],
        retry: (_, __) => null,
      );
      addTearDown(c.dispose);
      return c;
    }

    test('is loading until the session is restored', () async {
      final c = container(MemorySessionStore());
      expect(c.read(authStatusProvider).status, AuthStatus.loading);
      await c.read(sessionControllerProvider.future);
      await c.read(splashGateProvider.future);
      expect(c.read(authStatusProvider).status, AuthStatus.signedOut);
    });

    test('restores a saved session as signed in with its role', () async {
      final c = container(MemorySessionStore(_tenant));
      c.listen(authStatusProvider, (_, __) {});
      await c.read(sessionControllerProvider.future);
      await c.read(splashGateProvider.future);
      expect(
        c.read(authStatusProvider),
        (status: AuthStatus.signedIn, role: UserRole.tenant),
      );
    });

    test('expire signs out and leaves a notice for Welcome', () async {
      final store = MemorySessionStore(_tenant);
      final c = container(store);
      await c.read(sessionControllerProvider.future);
      await c.read(splashGateProvider.future);

      await c.read(sessionControllerProvider.notifier).expire();

      expect(c.read(authStatusProvider).status, AuthStatus.signedOut);
      expect(store.session, isNull);
      expect(
        c.read(sessionNoticeProvider),
        'Your session has ended. Please sign in again.',
      );
    });

    test('expire does nothing when already signed out', () async {
      final c = container(MemorySessionStore());
      await c.read(sessionControllerProvider.future);
      await c.read(sessionControllerProvider.notifier).expire();
      expect(c.read(sessionNoticeProvider), isNull);
    });
  });
}

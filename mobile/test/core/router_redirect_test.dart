import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/router/app_router.dart';
import 'package:rentra/core/router/app_routes.dart';
import 'package:rentra/features/auth/data/session_store.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/auth/providers/session_providers.dart';

class _MemoryStore implements SessionStore {
  _MemoryStore([this.session]);

  Session? session;

  @override
  Future<Session?> read() async => session;

  @override
  Future<void> save(Session s) async => session = s;

  @override
  Future<void> clear() async => session = null;
}

const _tenant = Session(
  token: 't',
  user: AppUser(id: 'u', role: UserRole.tenant),
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
        AppRoutes.role,
        AppRoutes.tenantSetup,
        AppRoutes.ownerSetup,
        AppRoutes.tour,
      ]) {
        expect(
          resolveRedirect(location: route, status: AuthStatus.signedOut),
          AppRoutes.welcome,
          reason: route,
        );
      }
    });

    test('signed in people skip the signed-out screens', () {
      for (final route in AppRoutes.signedOutOnly) {
        expect(
          resolveRedirect(location: route, status: AuthStatus.signedIn),
          AppRoutes.home,
          reason: route,
        );
      }
    });

    test('signed in people can finish onboarding and use the app', () {
      for (final route in [
        AppRoutes.privacy,
        AppRoutes.role,
        AppRoutes.tenantSetup,
        AppRoutes.ownerSetup,
        AppRoutes.tour,
        AppRoutes.home,
        AppRoutes.payments,
        AppRoutes.account,
      ]) {
        expect(
          resolveRedirect(location: route, status: AuthStatus.signedIn),
          isNull,
          reason: route,
        );
      }
    });
  });

  group('authStatusProvider', () {
    ProviderContainer container(SessionStore store) {
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
      final c = container(_MemoryStore());
      expect(c.read(authStatusProvider), AuthStatus.loading);
      await c.read(sessionControllerProvider.future);
      await c.read(splashGateProvider.future);
      expect(c.read(authStatusProvider), AuthStatus.signedOut);
    });

    test('restores a saved session as signed in', () async {
      final c = container(_MemoryStore(_tenant));
      c.listen(authStatusProvider, (_, __) {});
      await c.read(sessionControllerProvider.future);
      await c.read(splashGateProvider.future);
      expect(c.read(authStatusProvider), AuthStatus.signedIn);
    });

    test('expire signs out and leaves a notice for Welcome', () async {
      final store = _MemoryStore(_tenant);
      final c = container(store);
      await c.read(sessionControllerProvider.future);
      await c.read(splashGateProvider.future);

      await c.read(sessionControllerProvider.notifier).expire();

      expect(c.read(authStatusProvider), AuthStatus.signedOut);
      expect(store.session, isNull);
      expect(
        c.read(sessionNoticeProvider),
        'Your session has ended. Please sign in again.',
      );
    });

    test('expire does nothing when already signed out', () async {
      final c = container(_MemoryStore());
      await c.read(sessionControllerProvider.future);
      await c.read(sessionControllerProvider.notifier).expire();
      expect(c.read(sessionNoticeProvider), isNull);
    });
  });
}

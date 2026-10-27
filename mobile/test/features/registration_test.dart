import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentra/core/errors/app_exception.dart';
import 'package:rentra/features/auth/data/auth_repository.dart';
import 'package:rentra/features/auth/data/session_store.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/auth/providers/auth_providers.dart';
import 'package:rentra/features/auth/providers/session_providers.dart';
import 'package:rentra/features/landlord/models/organization.dart';
import 'package:rentra/features/onboarding/providers/onboarding_draft.dart';
import 'package:rentra/features/onboarding/providers/registration.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MemoryStore implements SessionStore {
  Session? session;

  @override
  Future<Session?> read() async => session;

  @override
  Future<void> save(Session s) async => session = s;

  @override
  Future<void> clear() async => session = null;
}

const _draft = OnboardingDraft(
  firstName: 'Achieng',
  lastName: 'Otieno',
  phone: '0712345678',
  email: 'achieng@example.com',
  password: 'secret1',
);

const _tenantSession = Session(
  token: 'tenant-jwt',
  user: AppUser(id: 'u1', role: UserRole.tenant),
);

const _landlordSession = Session(
  token: 'landlord-jwt',
  user: AppUser(id: 'u2', role: UserRole.landlord, organizationId: 'org1'),
  organization: Organization(id: 'org1', name: "Achieng's Organization", ownerId: 'u2'),
);

void main() {
  late _MockAuth auth;
  late _MemoryStore store;
  late ProviderContainer container;

  setUp(() async {
    auth = _MockAuth();
    store = _MemoryStore();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionStoreProvider.overrideWithValue(store),
      ],
      retry: (_, __) => null,
    );
    addTearDown(container.dispose);
    container.listen(onboardingDraftProvider, (_, __) {});
    await container.read(sessionControllerProvider.future);
    container.read(onboardingDraftProvider.notifier).set(_draft);
  });

  test('renter registers as a tenant with phone and email', () async {
    when(() => auth.registerTenant(
          firstName: 'Achieng',
          lastName: 'Otieno',
          phone: '0712345678',
          email: 'achieng@example.com',
          password: 'secret1',
        )).thenAnswer((_) async => _tenantSession);

    final session =
        await container.read(registrationProvider).register(OnboardingRole.renter);

    expect(session.user.role, UserRole.tenant);
    expect(store.session?.token, 'tenant-jwt');
    expect(container.read(sessionControllerProvider).value?.token, 'tenant-jwt');
    expect(container.read(onboardingDraftProvider), isNull);
    verifyNever(() => auth.registerLandlord(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ));
  });

  for (final role in [OnboardingRole.owner, OnboardingRole.manager]) {
    test('${role.name} registers as a landlord without a phone', () async {
      when(() => auth.registerLandlord(
            firstName: 'Achieng',
            lastName: 'Otieno',
            email: 'achieng@example.com',
            password: 'secret1',
          )).thenAnswer((_) async => _landlordSession);

      final session = await container.read(registrationProvider).register(role);

      expect(session.user.role, UserRole.landlord);
      expect(store.session?.organization?.id, 'org1');
      expect(container.read(onboardingDraftProvider), isNull);
      verifyNever(() => auth.registerTenant(
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            phone: any(named: 'phone'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });
  }

  test('already registered email keeps the draft and saves nothing', () async {
    when(() => auth.registerTenant(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const BadRequestException('Email already registered'));

    await expectLater(
      container.read(registrationProvider).register(OnboardingRole.renter),
      throwsA(isA<BadRequestException>()),
    );
    expect(store.session, isNull);
    expect(container.read(onboardingDraftProvider), isNotNull);
  });

  test('a second confirmation never registers again', () async {
    when(() => auth.registerTenant(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _tenantSession);

    final registration = container.read(registrationProvider);
    await registration.register(OnboardingRole.renter);
    final again = await registration.register(OnboardingRole.renter);

    expect(again.token, 'tenant-jwt');
    verify(() => auth.registerTenant(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).called(1);
  });

  test('signing out clears a draft', () async {
    store.session = _tenantSession;
    container.invalidate(sessionControllerProvider);
    await container.read(sessionControllerProvider.future);
    container.read(onboardingDraftProvider.notifier).set(_draft);

    await container.read(sessionControllerProvider.notifier).signOut();

    expect(container.read(onboardingDraftProvider), isNull);
  });

  group('describeRegistrationFailure', () {
    test('email already registered', () {
      final f = describeRegistrationFailure(
        const BadRequestException('Email already registered'),
      );
      expect(f.alreadyRegistered, isTrue);
      expect(f.message, 'That email is already registered. Try signing in instead.');
    });

    test('phone already registered', () {
      final f = describeRegistrationFailure(
        const BadRequestException('Phone number already registered'),
      );
      expect(f.alreadyRegistered, isTrue);
      expect(f.message, contains('phone number is already registered'));
    });

    test('other failures pass their message through', () {
      final f = describeRegistrationFailure(const NoConnectionException());
      expect(f.alreadyRegistered, isFalse);
      expect(f.message, const NoConnectionException().message);
    });
  });
}

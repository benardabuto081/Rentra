import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentra/app.dart';
import 'package:rentra/core/errors/app_exception.dart';
import 'package:rentra/features/auth/data/auth_repository.dart';
import 'package:rentra/features/auth/data/session_store.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/auth/providers/auth_providers.dart';
import 'package:rentra/features/auth/providers/session_providers.dart';
import 'package:rentra/features/landlord/data/landlord_repositories.dart';
import 'package:rentra/features/landlord/models/organization.dart';
import 'package:rentra/features/landlord/providers/landlord_providers.dart';
import 'package:rentra/features/onboarding/widgets/onboarding_widgets.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockOrganizations extends Mock implements OrganizationRepository {}

class _MemoryStore implements SessionStore {
  Session? session;

  @override
  Future<Session?> read() async => session;

  @override
  Future<void> save(Session s) async => session = s;

  @override
  Future<void> clear() async => session = null;
}

const _org = Organization(id: 'org1', name: "Baraka's Organization", ownerId: 'u2');

const _landlord = Session(
  token: 'landlord-jwt',
  user: AppUser(id: 'u2', role: UserRole.landlord, organizationId: 'org1'),
  organization: _org,
);

const _tenant = Session(
  token: 'tenant-jwt',
  user: AppUser(id: 'u1', role: UserRole.tenant, firstName: 'Baraka'),
);

void main() {
  late _MockAuth auth;
  late _MockOrganizations organizations;
  late _MemoryStore store;

  setUp(() {
    auth = _MockAuth();
    organizations = _MockOrganizations();
    store = _MemoryStore();
    when(() => auth.sendOtp(
          recipient: any(named: 'recipient'),
          channel: any(named: 'channel'),
        )).thenAnswer((_) async {});
    when(() => auth.verifyOtp(
          recipient: any(named: 'recipient'),
          channel: any(named: 'channel'),
          code: any(named: 'code'),
        )).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(OtpChannel.email));

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, Finder field, String text) async {
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pump();
  }

  Future<void> reachRoleScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          organizationRepositoryProvider.overrideWithValue(organizations),
          sessionStoreProvider.overrideWithValue(store),
          splashDurationProvider.overrideWithValue(Duration.zero),
        ],
        retry: (_, __) => null,
        child: const RentraApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tap(tester, find.text('Create Account'));
    final fields = find.byType(TextFormField);
    const values = [
      'Baraka',
      'Mwangi',
      '0712345678',
      'baraka@example.com',
      'secret1',
      'secret1',
    ];
    for (var i = 0; i < values.length; i++) {
      await type(tester, fields.at(i), values[i]);
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));

    expect(find.text('Verify your email'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(find.text('Your data belongs to you'), findsOneWidget);
    await tap(tester, find.byType(CheckboxListTile).first);
    await tap(tester, find.byType(CheckboxListTile).last);
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));

    expect(find.text('How do you use Rentra?'), findsOneWidget);
  }

  testWidgets('no account exists before the role is confirmed',
      (tester) async {
    await reachRoleScreen(tester);
    expect(store.session, isNull);
    verifyZeroInteractions(organizations);
    verifyNever(() => auth.registerTenant(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ));
  });

  testWidgets('renter is registered as a tenant and continues to setup',
      (tester) async {
    when(() => auth.registerTenant(
          firstName: 'Baraka',
          lastName: 'Mwangi',
          phone: '0712345678',
          email: 'baraka@example.com',
          password: 'secret1',
        )).thenAnswer((_) async => _tenant);

    await reachRoleScreen(tester);
    await tap(tester, find.text('I rent a property'));
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));

    expect(find.text('How is your rent set up?'), findsOneWidget);
    expect(store.session?.token, 'tenant-jwt');
  });

  testWidgets('manager is registered as a landlord and saves the portfolio',
      (tester) async {
    when(() => auth.registerLandlord(
          firstName: 'Baraka',
          lastName: 'Mwangi',
          email: 'baraka@example.com',
          password: 'secret1',
        )).thenAnswer((_) async => _landlord);
    when(() => organizations.update(
          'org1',
          name: 'Mwangi Homes',
          city: 'Nakuru',
          phone: '0722000111',
        )).thenAnswer((_) async => const Organization(
          id: 'org1',
          name: 'Mwangi Homes',
          ownerId: 'u2',
          city: 'Nakuru',
          phone: '0722000111',
        ));

    await reachRoleScreen(tester);
    await tap(tester, find.text('I manage properties'));
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));

    expect(find.text('Set up your property portfolio'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await type(tester, fields.at(0), 'Mwangi Homes');
    await type(tester, fields.at(1), 'Nakuru');
    await type(tester, fields.at(2), '0722000111');
    await tap(tester, find.widgetWithText(FilledButton, 'Complete Setup'));

    expect(find.text('Your portfolio is set up.'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(store.session?.organization?.name, 'Mwangi Homes');
  });

  testWidgets('a failed portfolio save does not block onboarding',
      (tester) async {
    when(() => auth.registerLandlord(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _landlord);
    when(() => organizations.update(
          any(),
          name: any(named: 'name'),
          city: any(named: 'city'),
          phone: any(named: 'phone'),
        )).thenThrow(const NoConnectionException());

    await reachRoleScreen(tester);
    await tap(tester, find.text('I own property'));
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await type(tester, find.byType(TextFormField).first, 'Mwangi Homes');
    await tap(tester, find.widgetWithText(FilledButton, 'Complete Setup'));

    expect(find.textContaining("couldn't save your business details"), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    expect(find.text('Next'), findsOneWidget);
    expect(store.session?.token, 'landlord-jwt');
  });

  testWidgets('an already registered email stays on the role screen',
      (tester) async {
    when(() => auth.registerLandlord(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const BadRequestException('Email already registered'));

    await reachRoleScreen(tester);
    await tap(tester, find.text('I own property'));
    await tap(tester, find.widgetWithText(FilledButton, 'Continue'));

    expect(
      find.text('That email is already registered. Try signing in instead.'),
      findsOneWidget,
    );
    expect(find.text('How do you use Rentra?'), findsOneWidget);
    final ownerCard = find.ancestor(
      of: find.text('I own property'),
      matching: find.byType(ChoiceCard),
    );
    expect(
      find.descendant(of: ownerCard, matching: find.byIcon(Icons.radio_button_checked)),
      findsOneWidget,
    );
    expect(store.session, isNull);

    await tap(tester, find.widgetWithText(OutlinedButton, 'Sign In'));
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('leaving Create Account forgets the details', (tester) async {
    await reachRoleScreen(tester);
    for (var i = 0; i < 4; i++) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(find.text('Sign In'), findsOneWidget);

    await tap(tester, find.text('Create Account'));
    final firstName = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(firstName.controller.text, isEmpty);
  });
}

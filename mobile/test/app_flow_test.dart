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
import 'package:rentra/features/tenant/providers/tenant_providers.dart';

import 'helpers/memory_fakes.dart';

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

const _tenant = Session(
  token: 't',
  user: AppUser(id: 'u1', role: UserRole.tenant, firstName: 'Amina'),
);

void main() {
  late _MockAuth auth;
  late _MemoryStore store;

  setUp(() {
    auth = _MockAuth();
    store = _MemoryStore();
  });

  Future<void> tapText(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sessionStoreProvider.overrideWithValue(store),
          shadowRentalRepositoryProvider.overrideWithValue(MemoryShadowRentals()),
          splashDurationProvider.overrideWithValue(Duration.zero),
        ],
        retry: (_, __) => null,
        child: const RentraApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed out start lands on Welcome', (tester) async {
    await pumpApp(tester);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('tenant signs in with a phone number, then signs out',
      (tester) async {
    when(() => auth.tenantLogin(phone: '0712345678', password: 'secret1'))
        .thenAnswer((_) async => _tenant);

    await pumpApp(tester);
    await tapText(tester, find.text('Sign In'));

    await tester.enterText(find.byType(TextFormField).first, '0712345678');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.pump();
    expect(find.text('Signing in as tenant'), findsOneWidget);

    await tapText(tester, find.widgetWithText(FilledButton, 'Sign In'));

    expect(find.textContaining('Amina'), findsOneWidget);
    expect(store.session?.token, 't');

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tapText(tester, find.widgetWithText(OutlinedButton, 'Sign Out'));
    await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(store.session, isNull);
  });

  testWidgets('a failed sign-in explains what happened', (tester) async {
    when(() => auth.login(email: 'a@b.co', password: 'wrong1'))
        .thenThrow(const UnauthorizedException(sessionEnded: false));

    await pumpApp(tester);
    await tapText(tester, find.text('Sign In'));
    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'wrong1');
    await tapText(tester, find.widgetWithText(FilledButton, 'Sign In'));

    expect(find.textContaining("couldn't sign you in"), findsOneWidget);
    expect(store.session, isNull);
  });

  testWidgets('a restored session opens straight into the app',
      (tester) async {
    store.session = _tenant;
    await pumpApp(tester);
    expect(find.textContaining('Amina'), findsOneWidget);
    expect(find.text('Create Account'), findsNothing);
  });
}

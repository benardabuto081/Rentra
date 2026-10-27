import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentra/app.dart';
import 'package:rentra/core/errors/app_exception.dart';
import 'package:rentra/core/theme/app_tokens.dart';
import 'package:rentra/features/auth/data/auth_repository.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/auth/providers/auth_providers.dart';
import 'package:rentra/features/auth/providers/session_providers.dart';
import 'package:rentra/features/tenant/models/shadow_rental.dart';
import 'package:rentra/features/tenant/providers/tenant_providers.dart';

import 'helpers/memory_fakes.dart';

class _MockAuth extends Mock implements AuthRepository {}

const _independent = Session(
  token: 't',
  user: AppUser(id: 'u1', role: UserRole.tenant, firstName: 'Wanjiku'),
);

const _managed = Session(
  token: 't',
  user: AppUser(
    id: 'u1',
    role: UserRole.tenant,
    firstName: 'Wanjiku',
    organizationId: 'org1',
  ),
);

void main() {
  late MemoryShadowRentals rentals;
  late MemorySessionStore store;
  late _MockAuth auth;
  String? clipboard;

  setUp(() {
    rentals = MemoryShadowRentals();
    store = MemorySessionStore(_independent);
    auth = _MockAuth();
    clipboard = null;
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sessionStoreProvider.overrideWithValue(store),
          shadowRentalRepositoryProvider.overrideWithValue(rentals),
          splashDurationProvider.overrideWithValue(Duration.zero),
        ],
        retry: (_, __) => null,
        child: const RentraApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> addExisting() => rentals.create(
        nickname: 'Bedsitter in Kasarani',
        address: 'Kasarani, Nairobi',
        rentAmount: 7000,
        billingCycle: BillingCycle.monthly,
        dueDayOfMonth: 5,
        destinationType: PaymentDestinationType.paybill,
        destinationNumber: '522522',
        referenceName: '0712345678',
      );

  testWidgets('independent tenant sets up a rental from Home', (tester) async {
    await pumpApp(tester);
    expect(find.text('Add your rental'), findsOneWidget);

    await tap(tester, find.text('Set up my rental'));
    expect(find.text('How is your rent set up?'), findsOneWidget);
    expect(find.text('Skip for now'), findsNothing);
    await tap(tester, find.text('My landlord isn’t on Rentra'));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Bedsitter in Kasarani');
    await tester.pump();
    await tester.enterText(fields.at(2), '7000');
    await tester.pump();
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), '522522');
    await tester.pump();
    await tap(tester, find.widgetWithText(FilledButton, 'Save My Rental'));

    expect(find.text('Your rental is set up.'), findsOneWidget);
    expect(find.text('Bedsitter in Kasarani'), findsOneWidget);
    expect(find.text('KES 7,000'), findsOneWidget);
    expect(find.textContaining('Next rent is due'), findsOneWidget);
    expect(rentals.rentals.single.billingCycle, BillingCycle.monthly);
    expect(rentals.rentals.single.dueDayOfMonth, inInclusiveRange(1, 28));
  });

  testWidgets('weekly rent hides the due day', (tester) async {
    await pumpApp(tester);
    await tap(tester, find.text('Set up my rental'));
    await tap(tester, find.text('My landlord isn’t on Rentra'));
    expect(find.text('Rent Due Day'), findsOneWidget);
    await tap(tester, find.text('Weekly'));
    expect(find.text('Rent Due Day'), findsNothing);
  });

  testWidgets('How to pay shows copyable details and the schedule',
      (tester) async {
    await addExisting();
    await pumpApp(tester);

    await tap(tester, find.widgetWithText(FilledButton, 'How to pay'));
    expect(find.text('M-Pesa Paybill'), findsOneWidget);
    expect(find.text('522522'), findsOneWidget);
    expect(find.text('0712345678'), findsOneWidget);
    expect(find.text('The 5th of every month'), findsOneWidget);
    expect(find.text("Payment tracking isn't available yet"), findsOneWidget);

    await tap(tester, find.byTooltip('Copy paybill number'));
    expect(clipboard, '522522');
    expect(find.text('Paybill Number copied.'), findsOneWidget);
  });

  testWidgets('a rental can be edited', (tester) async {
    await addExisting();
    await pumpApp(tester);

    await tap(tester, find.text('Edit rental details'));
    final rent = find.byType(TextFormField).at(2);
    await tester.enterText(rent, '8500');
    await tester.pump();
    await tap(tester, find.widgetWithText(FilledButton, 'Save changes'));

    expect(find.text('Rental details saved.'), findsOneWidget);
    expect(find.text('KES 8,500'), findsOneWidget);
    expect(rentals.rentals.single.rentAmount, 8500);
  });

  testWidgets('a rental can be ended after confirming', (tester) async {
    await addExisting();
    await pumpApp(tester);

    await tap(tester, find.text('Edit rental details'));
    final endButton = find.widgetWithText(OutlinedButton, 'End this rental');
    await tester.scrollUntilVisible(
      endButton,
      AppSpacing.xxxl,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, endButton);
    expect(find.text('End this rental?'), findsOneWidget);

    await tap(tester, find.widgetWithText(TextButton, 'Cancel'));
    expect(rentals.rentals.single.status, ShadowRentalStatus.unverified);

    await tap(tester, endButton);
    await tap(tester, find.widgetWithText(TextButton, 'End rental'));

    expect(find.text('Your rental has ended.'), findsOneWidget);
    expect(find.text('Add your rental'), findsOneWidget);
    expect(rentals.rentals.single.status, ShadowRentalStatus.ended);
  });

  testWidgets('a passkey that cannot be checked offers the other path',
      (tester) async {
    when(() => auth.previewPasskey('RTR-ABC123'))
        .thenThrow(const NotFoundException());
    await pumpApp(tester);

    await tap(tester, find.text('Set up my rental'));
    await tap(tester, find.text('My landlord gave me a passkey'));
    await tester.enterText(find.byType(TextFormField), 'rtr-abc123');
    await tap(tester, find.widgetWithText(FilledButton, 'Find My Unit'));

    expect(
      find.text(
        "We couldn't check this passkey right now. You can try again, or set up your rental yourself.",
      ),
      findsOneWidget,
    );
    verifyNever(() => auth.linkPasskey(
          passkeyCode: any(named: 'passkeyCode'),
          rentAmount: any(named: 'rentAmount'),
          moveInDate: any(named: 'moveInDate'),
        ));

    await tap(tester, find.text('Set up my rental myself'));
    expect(find.text('Tell us about your rental'), findsOneWidget);
  });

  testWidgets('managed tenant sees the connected state', (tester) async {
    store.session = _managed;
    await pumpApp(tester);

    expect(find.text("You're connected to your landlord's property."), findsOneWidget);
    expect(find.text('Your rent and request details are on their way.'), findsOneWidget);

    await tap(tester, find.text('Payments'));
    expect(find.text('Your rent details are on their way'), findsOneWidget);
  });

  testWidgets('Account is read-only with role and version', (tester) async {
    await pumpApp(tester);
    await tap(tester, find.text('Account'));

    expect(find.text('Tenant'), findsWidgets);
    expect(find.text('1.0.0 (build 1)'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Sign Out'), findsOneWidget);
  });

  testWidgets('Household and Activity have no buttons', (tester) async {
    await pumpApp(tester);
    for (final tab in ['Household', 'Activity']) {
      await tap(tester, find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(tab),
      ));
      final body = find.descendant(
        of: find.byType(Scaffold).last,
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(body, findsNothing, reason: tab);
    }
  });
}

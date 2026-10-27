import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/app.dart';
import 'package:rentra/core/network/network_providers.dart';
import 'package:rentra/core/theme/app_tokens.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/auth/providers/session_providers.dart';

import 'helpers/fake_backend.dart';
import 'helpers/memory_fakes.dart';

const _landlord = Session(
  token: 't',
  user: AppUser(
    id: 'u1',
    role: UserRole.landlord,
    firstName: 'Baraka',
    email: 'baraka@example.com',
    organizationId: 'org1',
  ),
);

void main() {
  late FakeBackend backend;
  late MemorySessionStore store;

  setUp(() {
    backend = FakeBackend();
    store = MemorySessionStore(_landlord);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = backend;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          sessionStoreProvider.overrideWithValue(store),
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

  Future<void> scrollTo(WidgetTester tester, Finder finder) => tester.scrollUntilVisible(
        finder,
        AppSpacing.xxxl,
        scrollable: find.byType(Scrollable).first,
      );

  Future<void> type(WidgetTester tester, Finder field, String text) async {
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pump();
  }

  Finder field(String label) => find.descendant(
        of: find.ancestor(of: find.text(label).last, matching: find.byType(Column)).first,
        matching: find.byType(TextFormField),
      );

  Finder tab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  testWidgets('new landlord adds a building, several units and invites a tenant',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Add your first building'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);

    await tap(tester, find.text('Add a building'));
    await type(tester, field('Building name'), 'Kamau Court');
    await tap(tester, find.widgetWithText(FilledButton, 'Add building'));

    expect(find.text('Now add the units in Kamau Court'), findsOneWidget);
    await tap(tester, find.text('Several units'));
    await type(tester, field('How many units'), '3');
    expect(find.text('We will add A1, A2, A3.'), findsOneWidget);
    await type(tester, field('Monthly rent for each unit'), '12000');
    await tap(tester, find.widgetWithText(FilledButton, 'Add 3 units'));

    expect(find.text('3 units added.'), findsOneWidget);
    expect(backend.rooms.map((r) => r['name']), ['A1', 'A2', 'A3']);
    expect(backend.rooms.every((r) => r['rentAmount'] == '12000.00'), isTrue);
    expect(find.text('0 of 3 units occupied'), findsOneWidget);

    await tap(tester, find.text('A1'));
    await tap(tester, find.widgetWithText(FilledButton, 'Invite a tenant'));
    expect(find.text('7 days'), findsOneWidget);
    await tap(tester, find.text('14 days'));
    await tap(tester, find.widgetWithText(FilledButton, 'Create passkey'));

    expect(find.text('RTR-7KQ2ZD'), findsOneWidget);
    expect(find.textContaining('Works until'), findsOneWidget);
    expect(backend.passkeys.single['generatedBy'], 'u1');
    final passkeyRequest = backend.requests.last;
    expect(passkeyRequest.data['expiresInDays'], 14);
    expect(passkeyRequest.data['unitId'], backend.rooms.first['id']);
  });

  testWidgets('one unit can be added, edited and the building deactivated',
      (tester) async {
    final b = backend.addBuilding('Kamau Court');
    final repair = backend.addRoom(b['id'], 'B1', 9000, status: 'maintenance');
    await pumpApp(tester);

    await tap(tester, tab('Properties'));
    await tap(tester, find.text('Kamau Court'));
    await tap(tester, find.text('Add units'));
    await type(tester, field('Unit name'), 'B2');
    await type(tester, field('Monthly rent'), '8500');
    await tap(tester, find.widgetWithText(FilledButton, 'Add unit'));
    expect(find.text('Unit B2 added.'), findsOneWidget);

    await tap(tester, find.text('B1'));
    expect(find.text('Under repair'), findsOneWidget);
    await tap(tester, find.widgetWithText(OutlinedButton, 'Mark as vacant'));
    await tap(tester, find.widgetWithText(TextButton, 'Mark vacant'));
    expect(find.text('B1 is now vacant.'), findsOneWidget);
    expect(repair['status'], 'vacant');

    await tap(tester, find.byTooltip('Edit unit'));
    await type(tester, field('Monthly rent'), '9500');
    await tap(tester, find.widgetWithText(FilledButton, 'Save changes'));
    expect(find.text('Unit details saved.'), findsOneWidget);
    expect(repair['rentAmount'], '9500.00');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('More actions'));
    await tap(tester, find.text('Deactivate building'));
    expect(find.text('Deactivate Kamau Court?'), findsOneWidget);
    await tap(tester, find.widgetWithText(TextButton, 'Deactivate'));
    expect(find.text('Kamau Court deactivated.'), findsOneWidget);
    expect(b['status'], 'inactive');
    expect(find.text('No buildings yet'), findsOneWidget);
  });

  testWidgets('records a payment with defaults and settles a partial one',
      (tester) async {
    final b = backend.addBuilding('Kamau Court');
    final room = backend.addRoom(b['id'], 'A1', 12000);
    backend.addTenant(room);
    await pumpApp(tester);

    await tap(tester, tab('Payments'));
    expect(find.text('No payments for this month'), findsOneWidget);
    await tap(tester, find.text('Record payment'));

    expect(find.text('A1 · Kamau Court'), findsOneWidget);
    final due = tester.widget<EditableText>(
      find.descendant(of: field('Amount due'), matching: find.byType(EditableText)),
    );
    expect(due.controller.text, '12000');
    expect(find.text('M-Pesa code (optional)'), findsOneWidget);

    await type(tester, field('M-Pesa code (optional)'), 'abc');
    await type(tester, field('Amount paid'), '5000');
    await tap(tester, find.widgetWithText(FilledButton, 'Record payment'));
    expect(find.textContaining('An M-Pesa code has 10 letters and numbers'), findsOneWidget);
    expect(backend.payments, isEmpty);

    await type(tester, field('M-Pesa code (optional)'), 'qjk3xy7zab');
    await tap(tester, find.widgetWithText(FilledButton, 'Record payment'));
    expect(find.text('Payment recorded as partly paid.'), findsOneWidget);
    final p = backend.payments.single;
    expect(p['type'], 'rent');
    expect(p['method'], 'mpesa');
    expect(p['mpesaCode'], 'QJK3XY7ZAB');
    expect(p['month'], DateTime.now().month);
    expect(p['year'], DateTime.now().year);
    expect(p['amount'], '12000.00');
    expect(p['status'], 'partial');

    await tap(tester, find.text('A1 · Kamau Court'));
    await tap(tester, find.widgetWithText(FilledButton, 'Update amount paid'));
    await tap(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(find.text('Payment updated. It is now fully paid.'), findsOneWidget);
    expect(p['status'], 'completed');
  });

  testWidgets('manages a tenant: rent, notice and move out', (tester) async {
    final b = backend.addBuilding('Kamau Court');
    final room = backend.addRoom(b['id'], 'A1', 12000);
    final tenant = backend.addTenant(room);
    await pumpApp(tester);

    await tap(tester, tab('Properties'));
    await tap(tester, find.text('Tenants'));
    await tap(tester, find.text('A1 · Kamau Court'));

    await tap(tester, find.widgetWithText(OutlinedButton, 'Update rent'));
    await type(tester, field('Monthly rent'), '13000');
    await tap(tester, find.widgetWithText(FilledButton, 'Save rent'));
    expect(find.text('Rent updated to KES 13,000.'), findsOneWidget);
    expect(tenant['rentAmount'], '13000.00');

    await tap(tester, find.widgetWithText(OutlinedButton, 'Record notice'));
    await tap(tester, find.widgetWithText(FilledButton, 'Record notice'));
    expect(find.text('Notice recorded.'), findsOneWidget);
    expect(tenant['status'], 'notice');

    await tap(tester, find.widgetWithText(OutlinedButton, 'Move out'));
    expect(find.text('Move this tenant out?'), findsOneWidget);
    await tap(tester, find.widgetWithText(OutlinedButton, 'Move out').last);
    expect(find.text('Tenant moved out. A1 · Kamau Court is now vacant.'), findsOneWidget);
    expect(tenant['status'], 'vacated');
    expect(room['status'], 'vacant');
  });

  testWidgets('handles issues: assign, priority, resolve and cancel',
      (tester) async {
    final b = backend.addBuilding('Kamau Court');
    final tenant = backend.addTenant(backend.addRoom(b['id'], 'A1', 12000));
    final leak = backend.addIssue(tenant, 'Leaking tap');
    final bulb = backend.addIssue(tenant, 'Broken bulb');
    await pumpApp(tester);

    expect(find.text('2 issues waiting for you'), findsOneWidget);
    await tap(tester, find.text('2 issues waiting for you'));
    expect(find.text('Leaking tap'), findsOneWidget);

    await tap(tester, find.text('Leaking tap'));
    await tap(tester, find.widgetWithText(OutlinedButton, 'Assign someone'));
    await type(tester, field('Name'), 'Juma');
    await tap(tester, find.widgetWithText(FilledButton, 'Assign'));
    expect(find.text('Assigned to Juma.'), findsOneWidget);
    expect(leak['status'], 'in_progress');

    await tap(tester, find.widgetWithText(OutlinedButton, 'Change priority'));
    await tap(tester, find.text('Urgent'));
    await tap(tester, find.widgetWithText(FilledButton, 'Save priority'));
    expect(find.text('Priority updated.'), findsOneWidget);
    expect(leak['priority'], 'urgent');

    await tap(tester, find.widgetWithText(FilledButton, 'Mark resolved'));
    await tap(tester, find.widgetWithText(FilledButton, 'Mark resolved').last);
    expect(find.text('Please describe what was done.'), findsOneWidget);
    await type(tester, field('What was done'), 'Replaced the washer');
    await type(tester, field('Cost (optional)'), '800');
    await tap(tester, find.widgetWithText(FilledButton, 'Mark resolved').last);
    expect(find.text('Issue resolved.'), findsOneWidget);
    expect(leak['status'], 'resolved');
    expect(leak['cost'], '800.00');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Broken bulb'));
    await scrollTo(tester, find.widgetWithText(OutlinedButton, 'Cancel issue'));
    await tap(tester, find.widgetWithText(OutlinedButton, 'Cancel issue'));
    await tap(tester, find.widgetWithText(TextButton, 'Keep it'));
    expect(bulb['status'], 'pending');
    await tap(tester, find.widgetWithText(OutlinedButton, 'Cancel issue'));
    await tap(tester, find.widgetWithText(TextButton, 'Cancel issue'));
    expect(find.text('Issue cancelled.'), findsOneWidget);
    expect(bulb['status'], 'cancelled');
  });

  testWidgets('edits portfolio details from Account', (tester) async {
    await pumpApp(tester);
    await tap(tester, tab('Account'));
    expect(find.text("Baraka's Organization"), findsOneWidget);
    expect(find.text('Landlord'), findsWidgets);

    await tap(tester, find.widgetWithText(OutlinedButton, 'Edit details'));
    await type(tester, field('Business or Portfolio Name'), 'Mwangi Homes');
    await type(tester, field('City (optional)'), 'Nakuru');
    await tap(tester, find.widgetWithText(FilledButton, 'Save changes'));

    expect(find.text('Portfolio details saved.'), findsOneWidget);
    expect(find.text('Mwangi Homes'), findsOneWidget);
    expect(backend.organization['city'], 'Nakuru');
    expect(store.session?.organization?.name, 'Mwangi Homes');
  });

  testWidgets('nothing needing attention is said calmly', (tester) async {
    final b = backend.addBuilding('Kamau Court');
    backend.addTenant(backend.addRoom(b['id'], 'A1', 12000));
    await pumpApp(tester);
    expect(
      find.text('Nothing needs your attention today. Everything is up to date.'),
      findsOneWidget,
    );
  });
}

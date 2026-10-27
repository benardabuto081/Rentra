import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/app.dart';
import 'package:rentra/core/network/network_providers.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/auth/providers/session_providers.dart';

import 'helpers/fake_http_adapter.dart';
import 'helpers/memory_fakes.dart';

const _rental = {
  'id': 's1',
  'tenantUserId': 'u1',
  'propertyNickname': 'Bedsitter in Kasarani',
  'address': null,
  'rentAmount': '7000.00',
  'billingCycle': 'monthly',
  'dueDayOfMonth': 5,
  'paymentDestinationType': 'paybill',
  'paymentDestinationNumber': '522522',
  'paymentReferenceName': null,
  'status': 'unverified',
  'createdAt': '2026-10-01T08:00:00.000Z',
};

/// Visits every tenant screen against the real repositories and records each
/// HTTP request, so a landlord endpoint anywhere in the tenant UI fails here.
void main() {
  Future<FakeHttpAdapter> visitEverything(
    WidgetTester tester, {
    required String? organizationId,
  }) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final adapter = FakeHttpAdapter({
      'GET /shadow-relationships': const FakeReply(200, [_rental]),
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    final session = Session(
      token: 't',
      user: AppUser(
        id: 'u1',
        role: UserRole.tenant,
        firstName: 'Wanjiku',
        organizationId: organizationId,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          sessionStoreProvider.overrideWithValue(MemorySessionStore(session)),
          splashDurationProvider.overrideWithValue(Duration.zero),
        ],
        retry: (_, __) => null,
        child: const RentraApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (final tab in ['Payments', 'Household', 'Activity', 'Account', 'Home']) {
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(tab),
      ));
      await tester.pumpAndSettle();
    }
    if (organizationId == null) {
      await tester.ensureVisible(find.text('Edit rental details'));
      await tester.tap(find.text('Edit rental details'));
      await tester.pumpAndSettle();
    }
    return adapter;
  }

  void expectNoLandlordCalls(FakeHttpAdapter adapter) {
    for (final request in adapter.requests) {
      expect(request.path, isNot(startsWith('/organizations')));
      expect(request.path, isNot('/auth/generate-passkey'));
    }
  }

  testWidgets('independent tenant only uses their own rental', (tester) async {
    final adapter = await visitEverything(tester, organizationId: null);
    expect(adapter.requests, isNotEmpty);
    expect(
      adapter.requests.map((r) => r.path).toSet(),
      {'/shadow-relationships'},
    );
    expectNoLandlordCalls(adapter);
  });

  testWidgets('managed tenant makes no landlord calls', (tester) async {
    final adapter = await visitEverything(tester, organizationId: 'org1');
    expectNoLandlordCalls(adapter);
    expect(adapter.requests, isEmpty);
  });
}

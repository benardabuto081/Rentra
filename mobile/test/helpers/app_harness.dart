import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/app.dart';
import 'package:rentra/core/network/network_providers.dart';
import 'package:rentra/core/router/app_router.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/auth/providers/session_providers.dart';

import 'fake_backend.dart';
import 'memory_fakes.dart';

const landlordSession = Session(
  token: 't',
  user: AppUser(
    id: 'u1',
    role: UserRole.landlord,
    firstName: 'Baraka',
    lastName: 'Mwangi',
    email: 'baraka.mwangi.properties@example.com',
    organizationId: 'org1',
  ),
);

const tenantSession = Session(
  token: 't',
  user: AppUser(
    id: 'u1',
    role: UserRole.tenant,
    firstName: 'Wanjiku',
    lastName: 'Kamau',
    phone: '0712345678',
    email: 'wanjiku.kamau@example.com',
  ),
);

/// Pumps the whole app against [backend] on a phone-sized screen.
/// Returns the container so tests can drive the router directly.
Future<ProviderContainer> pumpRentra(
  WidgetTester tester, {
  required FakeBackend backend,
  Session? session,
  Size logicalSize = const Size(360, 640),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = logicalSize * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (_) async => null,
  );

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = backend;
  final container = ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
      sessionStoreProvider.overrideWithValue(MemorySessionStore(session)),
      splashDurationProvider.overrideWithValue(Duration.zero),
    ],
    retry: (_, __) => null,
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const RentraApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> goTo(WidgetTester tester, ProviderContainer container, String route) async {
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
}

/// A landlord portfolio with something in every state.
({String building, String vacant, String occupied, String tenancy, String payment, String issue})
    seedPortfolio(FakeBackend backend) {
  final b = backend.addBuilding('Kamau Court Apartments, Kasarani');
  final vacant = backend.addRoom(b['id'], 'A1', 12000);
  final occupied = backend.addRoom(b['id'], 'A2', 12500.5);
  backend.addRoom(b['id'], 'A3', 9000, status: 'maintenance');
  final tenancy = backend.addTenant(occupied);
  final payment = (backend.payments..add({
    'id': 'p-seed',
    'organizationId': 'org1',
    'tenantId': tenancy['id'],
    'roomId': occupied['id'],
    'buildingId': b['id'],
    'type': 'rent',
    'status': 'partial',
    'method': 'mpesa',
    'amount': '1250000.00',
    'amountPaid': '500000.50',
    'month': DateTime.now().month,
    'year': DateTime.now().year,
    'mpesaCode': 'QJK3XY7ZAB',
    'receiptNumber': 'RNT-123456-001',
    'notes': 'Paid part in cash at the gate and the rest promised next week.',
    'dueDate': null,
    'daysLate': 0,
    'paidAt': '2026-10-05T08:00:00.000Z',
    'createdAt': '2026-10-05T08:00:00.000Z',
  })).last;
  final issue = backend.addIssue(tenancy, 'Kitchen sink is leaking under the cabinet');
  return (
    building: b['id'] as String,
    vacant: vacant['id'] as String,
    occupied: occupied['id'] as String,
    tenancy: tenancy['id'] as String,
    payment: payment['id'] as String,
    issue: issue['id'] as String,
  );
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/errors/app_exception.dart';
import 'package:rentra/core/network/api_client.dart';
import 'package:rentra/core/network/auth_interceptor.dart';
import 'package:rentra/features/auth/data/auth_repository.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/landlord/data/landlord_repositories.dart';
import 'package:rentra/features/landlord/models/tenancy.dart';
import 'package:rentra/features/landlord/models/unit.dart';
import 'package:rentra/features/maintenance/data/maintenance_repository.dart';
import 'package:rentra/features/maintenance/models/maintenance_request.dart';
import 'package:rentra/features/payments/data/payment_repository.dart';
import 'package:rentra/features/payments/models/payment.dart';
import 'package:rentra/features/tenant/data/shadow_rental_repository.dart';
import 'package:rentra/features/tenant/models/shadow_rental.dart';

import '../helpers/fake_http_adapter.dart';

const _user = {
  'id': 'u1',
  'firstName': 'Otieno',
  'lastName': 'Odhiambo',
  'email': 'o@example.com',
  'phone': null,
  'role': 'landlord',
  'status': 'pending',
  'organizationId': 'org1',
  'nationalId': null,
  'createdAt': '2026-10-01T08:00:00.000Z',
  'updatedAt': '2026-10-01T08:00:00.000Z',
};

const _unit = {
  'id': 'r1',
  'name': 'A1',
  'buildingId': 'b1',
  'organizationId': 'org1',
  'floor': 0,
  'type': 'one_bedroom',
  'status': 'vacant',
  'rentAmount': '12500.00',
  'storageAmount': '0.00',
  'description': null,
  'currentTenantId': null,
  'createdAt': '2026-10-01T08:00:00.000Z',
};

const _payment = {
  'id': 'p1',
  'organizationId': 'org1',
  'tenantId': 't1',
  'roomId': 'r1',
  'buildingId': 'b1',
  'type': 'rent',
  'status': 'partial',
  'method': 'mpesa',
  'amount': '12500.00',
  'amountPaid': '5000.50',
  'month': 10,
  'year': 2026,
  'mpesaCode': 'QWE123RTY4',
  'receiptNumber': 'RNT-123456-001',
  'notes': null,
  'dueDate': null,
  'daysLate': 0,
  'paidAt': '2026-10-05T08:00:00.000Z',
  'createdAt': '2026-10-05T08:00:00.000Z',
};

class _Harness {
  _Harness(Map<String, FakeReply> replies, {this.token}) {
    adapter = FakeHttpAdapter(replies);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(
          readToken: () => token,
          onSessionExpired: () => expiredCount++,
        ),
      );
    api = ApiClient(dio);
  }

  late final FakeHttpAdapter adapter;
  late final ApiClient api;

  RequestOptions get last => adapter.last;
  String? token;
  int expiredCount = 0;
}

void main() {
  group('AuthRepository', () {
    test('register parses user, portfolio and token', () async {
      final h = _Harness({
        'POST /auth/register': const FakeReply(201, {
          'user': _user,
          'organization': {
            'id': 'org1',
            'name': "Otieno's Organization",
            'ownerId': 'u1',
            'email': 'o@example.com',
            'status': 'active',
            'createdAt': '2026-10-01T08:00:00.000Z',
          },
          'token': 'jwt-abc',
        }),
      });
      final session = await ApiAuthRepository(h.api).registerLandlord(
        firstName: 'Otieno',
        lastName: 'Odhiambo',
        email: 'o@example.com',
        password: 'secret1',
      );
      expect(session.token, 'jwt-abc');
      expect(session.user.role, UserRole.landlord);
      expect(session.organization!.id, 'org1');
      expect(h.last.headers['Authorization'], isNull);
    });

    test('tenant login sends the phone exactly as typed', () async {
      final h = _Harness({
        'POST /auth/tenant-login': FakeReply(201, {
          'user': Map.of(_user)
            ..['role'] = 'tenant'
            ..['organizationId'] = null,
          'token': 'jwt',
        }),
      });
      final session = await ApiAuthRepository(h.api)
          .tenantLogin(phone: '0712345678', password: 'pw1234');
      expect(h.last.data, {'phone': '0712345678', 'password': 'pw1234'});
      expect(session.user.role, UserRole.tenant);
      expect(session.organization, isNull);
    });

    test('wrong password is a sign-in error, not a session end', () async {
      final h = _Harness({
        'POST /auth/login': const FakeReply(401, {
          'message': 'Invalid credentials',
          'error': 'Unauthorized',
          'statusCode': 401,
        }),
      }, token: 'stale');
      await expectLater(
        ApiAuthRepository(h.api).login(email: 'a@b.co', password: 'x'),
        throwsA(isA<UnauthorizedException>()
            .having((e) => e.sessionEnded, 'sessionEnded', false)),
      );
      expect(h.expiredCount, 0);
    });

    test('verifyOtp passes on verified true', () async {
      final h = _Harness({
        'POST /auth/otp/verify': const FakeReply(201, {'verified': true}),
      });
      await ApiAuthRepository(h.api).verifyOtp(
        recipient: 'a@b.co',
        channel: OtpChannel.email,
        code: '123456',
      );
      expect(h.last.data, {'recipient': 'a@b.co', 'type': 'email', 'code': '123456'});
    });

    test('missing passkey preview endpoint surfaces as NotFound', () async {
      final h = _Harness({}, token: 't');
      await expectLater(
        ApiAuthRepository(h.api).previewPasskey('RTR-ABC123'),
        throwsA(isA<NotFoundException>()),
      );
      expect(h.expiredCount, 0);
    });

    test('a malformed user is a parse error', () async {
      final h = _Harness({
        'POST /auth/login': FakeReply(201, {
          'user': Map.of(_user)..['role'] = 'superuser',
          'token': 'jwt',
        }),
      });
      await expectLater(
        ApiAuthRepository(h.api).login(email: 'a@b.co', password: 'x'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('authenticated requests', () {
    test('carry the bearer token', () async {
      final h = _Harness({
        'GET /organizations/org1/buildings': const FakeReply(200, []),
      }, token: 'jwt-1');
      await ApiBuildingRepository(h.api).list('org1');
      expect(h.last.headers['Authorization'], 'Bearer jwt-1');
    });

    test('a 401 ends the session', () async {
      final h = _Harness({
        'GET /organizations/org1/buildings': const FakeReply(401, {
          'message': 'Unauthorized',
          'statusCode': 401,
        }),
      }, token: 'expired');
      await expectLater(
        ApiBuildingRepository(h.api).list('org1'),
        throwsA(isA<UnauthorizedException>()
            .having((e) => e.sessionEnded, 'sessionEnded', true)),
      );
      expect(h.expiredCount, 1);
    });

    test('offline becomes NoConnectionException', () async {
      final h = _Harness({
        'GET /shadow-relationships': const FakeReply.offline(),
      }, token: 't');
      await expectLater(
        ApiShadowRentalRepository(h.api).list(),
        throwsA(isA<NoConnectionException>()),
      );
    });

    test('a non-JSON body is a parse error', () async {
      final h = _Harness({
        'GET /organizations/org1/payments': const FakeReply(200, '<html></html>', raw: true),
      }, token: 't');
      await expectLater(
        ApiPaymentRepository(h.api).list('org1'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('response parsing', () {
    test('units parse decimal strings and backend types', () async {
      final h = _Harness({
        'GET /organizations/org1/buildings/b1/rooms': const FakeReply(200, [_unit]),
      }, token: 't');
      final units = await ApiUnitRepository(h.api).list('org1', 'b1');
      expect(units.single.rentAmount, 12500);
      expect(units.single.type, UnitType.oneBedroom);
      expect(units.single.isVacant, isTrue);
    });

    test('unit create sends the backend type value', () async {
      final h = _Harness({
        'POST /organizations/org1/buildings/b1/rooms': const FakeReply(201, _unit),
      }, token: 't');
      await ApiUnitRepository(h.api).create(
        'org1',
        'b1',
        name: 'A1',
        rentAmount: 12500,
        type: UnitType.oneBedroom,
      );
      expect(h.last.data, {'name': 'A1', 'rentAmount': 12500.0, 'type': 'one_bedroom'});
    });

    test('payments parse money and enums', () async {
      final h = _Harness({
        'GET /organizations/org1/payments/arrears': const FakeReply(200, [_payment]),
      }, token: 't');
      final p = (await ApiPaymentRepository(h.api).arrears('org1')).single;
      expect(p.amount, 12500);
      expect(p.amountPaid, 5000.5);
      expect(p.status, PaymentStatus.partial);
      expect(p.method, PaymentMethod.mpesa);
      expect(p.unitId, 'r1');
    });

    test('payment stats pass month and year as query', () async {
      final h = _Harness({
        'GET /organizations/org1/payments/stats': const FakeReply(200, {
          'totalExpected': 25000,
          'totalCollected': 12500,
          'totalArrears': 12500,
          'paymentCount': 2,
        }),
      }, token: 't');
      final stats =
          await ApiPaymentRepository(h.api).stats('org1', month: 10, year: 2026);
      expect(h.last.queryParameters, {'month': 10, 'year': 2026});
      expect(stats.collected, 12500);
      expect(stats.count, 2);
    });

    test('tenancies map roomId to unitId and parse dates', () async {
      final h = _Harness({
        'GET /organizations/org1/tenants/active': const FakeReply(200, [
          {
            'id': 't1',
            'userId': 'u2',
            'roomId': 'r1',
            'buildingId': 'b1',
            'organizationId': 'org1',
            'rentAmount': '12500.00',
            'storageAmount': '0.00',
            'depositAmount': '12500.00',
            'status': 'active',
            'moveInDate': '2026-10-01',
            'moveOutDate': null,
            'noticeDate': null,
            'notes': null,
            'createdAt': '2026-10-01T08:00:00.000Z',
          },
        ]),
      }, token: 't');
      final t = (await ApiTenancyRepository(h.api).active('org1')).single;
      expect(t.unitId, 'r1');
      expect(t.status, TenancyStatus.active);
      expect(t.moveInDate, DateTime(2026, 10, 1));
      expect(t.depositAmount, 12500);
    });

    test('maintenance maps in_progress', () async {
      final h = _Harness({
        'GET /organizations/org1/maintenance': const FakeReply(200, [
          {
            'id': 'm1',
            'organizationId': 'org1',
            'buildingId': 'b1',
            'roomId': 'r1',
            'tenantId': 't1',
            'assignedTo': 'Juma',
            'title': 'Leaking tap',
            'description': 'Kitchen tap drips',
            'category': 'plumbing',
            'priority': 'high',
            'status': 'in_progress',
            'resolutionNotes': null,
            'cost': null,
            'resolvedAt': null,
            'createdAt': '2026-10-01T08:00:00.000Z',
          },
        ]),
      }, token: 't');
      final m = (await ApiMaintenanceRepository(h.api).list('org1')).single;
      expect(m.status, IssueStatus.inProgress);
      expect(m.category, IssueCategory.plumbing);
      expect(m.priority, IssuePriority.high);
      expect(m.cost, isNull);
    });

    test('dashboard financial summary', () async {
      final h = _Harness({
        'GET /organizations/org1/dashboard/financial': const FakeReply(200, {
          'month': '10',
          'year': '2026',
          'totalExpected': 25000,
          'totalCollected': 20000,
          'collectionRate': 80,
          'totalOutstandingArrears': 5000,
          'totalArrearsCount': 1,
        }),
      }, token: 't');
      final f = await ApiDashboardRepository(h.api)
          .financial('org1', month: 10, year: 2026);
      expect(f.month, 10);
      expect(f.collectionRate, 80);
      expect(f.outstanding, 5000);
    });

    test('shadow rental create omits empty optionals', () async {
      final h = _Harness({
        'POST /shadow-relationships': const FakeReply(201, {
          'id': 's1',
          'tenantUserId': 'u1',
          'propertyNickname': 'My bedsitter',
          'address': null,
          'rentAmount': '7000.00',
          'billingCycle': 'monthly',
          'dueDayOfMonth': 5,
          'paymentDestinationType': 'paybill',
          'paymentDestinationNumber': '522522',
          'paymentReferenceName': null,
          'status': 'unverified',
          'createdAt': '2026-10-01T08:00:00.000Z',
        }),
      }, token: 't');
      final rental = await ApiShadowRentalRepository(h.api).create(
        nickname: 'My bedsitter',
        rentAmount: 7000,
        billingCycle: BillingCycle.monthly,
        dueDayOfMonth: 5,
        destinationType: PaymentDestinationType.paybill,
        destinationNumber: '522522',
      );
      expect(h.last.data, {
        'propertyNickname': 'My bedsitter',
        'rentAmount': 7000.0,
        'billingCycle': 'monthly',
        'dueDayOfMonth': 5,
        'paymentDestinationType': 'paybill',
        'paymentDestinationNumber': '522522',
      });
      expect(rental.rentAmount, 7000);
      expect(rental.status, ShadowRentalStatus.unverified);
      expect(rental.isActive, isTrue);
    });

    test('passkey generation sends who generated it', () async {
      final h = _Harness({
        'POST /auth/generate-passkey': const FakeReply(201, {
          'id': 'pk1',
          'code': 'RTR-7KQ2ZD',
          'unitId': 'r1',
          'organizationId': 'org1',
          'generatedBy': 'u1',
          'status': 'active',
          'expiresAt': '2026-11-03T08:00:00.000Z',
        }),
      }, token: 't');
      final passkey = await ApiPasskeyRepository(h.api).generate(
        unitId: 'r1',
        organizationId: 'org1',
        generatedBy: 'u1',
        expiresInDays: 7,
      );
      expect(h.last.headers['Authorization'], 'Bearer t');
      expect(h.last.data['generatedBy'], 'u1');
      expect(passkey.code, 'RTR-7KQ2ZD');
      expect(passkey.expiresAt, isNotNull);
    });
  });
}

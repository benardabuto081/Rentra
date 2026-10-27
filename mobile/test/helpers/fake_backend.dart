import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A small in-memory imitation of the landlord endpoints, with the same paths
/// and JSON shapes as backend/src. Money comes back as decimal strings, as
/// TypeORM sends it.
class FakeBackend implements HttpClientAdapter {
  FakeBackend({this.orgId = 'org1'});

  final String orgId;
  final List<RequestOptions> requests = [];

  final Map<String, dynamic> organization = {
    'id': 'org1',
    'name': "Baraka's Organization",
    'ownerId': 'u1',
    'phone': null,
    'email': 'baraka@example.com',
    'address': null,
    'city': null,
    'status': 'active',
    'createdAt': '2026-10-01T08:00:00.000Z',
  };
  final List<Map<String, dynamic>> buildings = [];
  final List<Map<String, dynamic>> rooms = [];
  final List<Map<String, dynamic>> tenants = [];
  final List<Map<String, dynamic>> payments = [];
  final List<Map<String, dynamic>> issues = [];
  final List<Map<String, dynamic>> passkeys = [];
  int _id = 1;

  String _next(String prefix) => '$prefix${_id++}';

  static String money(num v) => v.toStringAsFixed(2);

  Map<String, dynamic> addBuilding(String name) {
    final b = <String, dynamic>{
      'id': _next('b'),
      'name': name,
      'organizationId': orgId,
      'address': null,
      'city': 'Nairobi',
      'county': null,
      'totalFloors': null,
      'description': null,
      'propertyType': null,
      'status': 'active',
      'createdAt': '2026-10-01T08:00:00.000Z',
    };
    buildings.add(b);
    return b;
  }

  Map<String, dynamic> addRoom(String buildingId, String name, num rent,
      {String status = 'vacant'}) {
    final r = <String, dynamic>{
      'id': _next('r'),
      'name': name,
      'buildingId': buildingId,
      'organizationId': orgId,
      'floor': null,
      'type': 'bedsitter',
      'status': status,
      'rentAmount': money(rent),
      'storageAmount': money(0),
      'description': null,
      'currentTenantId': null,
      'createdAt': '2026-10-01T08:00:00.000Z',
    };
    rooms.add(r);
    return r;
  }

  Map<String, dynamic> addTenant(Map<String, dynamic> room) {
    final t = <String, dynamic>{
      'id': _next('t'),
      'userId': _next('u'),
      'roomId': room['id'],
      'buildingId': room['buildingId'],
      'organizationId': orgId,
      'rentAmount': room['rentAmount'],
      'storageAmount': money(0),
      'depositAmount': money(0),
      'status': 'active',
      'moveInDate': '2026-09-01',
      'moveOutDate': null,
      'noticeDate': null,
      'notes': null,
      'createdAt': '2026-09-01T08:00:00.000Z',
    };
    tenants.add(t);
    room['status'] = 'occupied';
    room['currentTenantId'] = t['id'];
    return t;
  }

  Map<String, dynamic> addIssue(Map<String, dynamic> tenant, String title) {
    final i = <String, dynamic>{
      'id': _next('m'),
      'organizationId': orgId,
      'buildingId': tenant['buildingId'],
      'roomId': tenant['roomId'],
      'tenantId': tenant['id'],
      'assignedTo': null,
      'title': title,
      'description': '$title, reported by the tenant.',
      'category': 'plumbing',
      'priority': 'medium',
      'status': 'pending',
      'resolutionNotes': null,
      'cost': null,
      'resolvedAt': null,
      'createdAt': '2026-10-20T08:00:00.000Z',
    };
    issues.add(i);
    return i;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = options.data is Map
        ? (options.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final (status, json) = _handle(
      options.method,
      options.path,
      options.queryParameters,
      body,
    );
    return ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  (int, Object?) _notFound(String what) =>
      (404, {'message': '$what not found', 'statusCode': 404});

  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, String id) {
    for (final item in list) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  String _status(num amount, num paid) =>
      paid <= 0 ? 'pending' : (paid >= amount ? 'completed' : 'partial');

  (int, Object?) _handle(
    String method,
    String path,
    Map<String, dynamic> query,
    Map<String, dynamic> body,
  ) {
    final org = '/organizations/$orgId';
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    String seg(int i) => i < segments.length ? segments[i] : '';
    final route = '$method $path';

    if (route == 'POST /auth/generate-passkey') {
      final p = <String, dynamic>{
        'id': _next('pk'),
        'code': 'RTR-7KQ2ZD',
        'unitId': body['unitId'],
        'organizationId': body['organizationId'],
        'generatedBy': body['generatedBy'],
        'status': 'active',
        'expiresAt': DateTime.now()
            .add(Duration(days: body['expiresInDays'] as int))
            .toUtc()
            .toIso8601String(),
      };
      passkeys.add(p);
      return (201, p);
    }
    if (!path.startsWith(org)) return _notFound('Route');

    if (path == org) {
      if (method == 'PATCH') organization.addAll(body);
      return (200, organization);
    }

    final area = seg(2);
    if (area == 'dashboard') {
      final active = buildings.where((b) => b['status'] == 'active').toList();
      switch (seg(3)) {
        case 'overview':
          return (200, {
            'totalBuildings': active.length,
            'totalActiveTenants': tenants.where((t) => t['status'] == 'active').length,
            'totalNoticeTenants': tenants.where((t) => t['status'] == 'notice').length,
            'totalPendingMaintenance': issues.where((i) => i['status'] == 'pending').length,
          });
        case 'financial':
          final month = int.parse('${query['month']}');
          final year = int.parse('${query['year']}');
          final inMonth = payments.where((p) => p['month'] == month && p['year'] == year);
          final expected = inMonth.fold<num>(0, (s, p) => s + num.parse(p['amount']));
          final collected = inMonth.fold<num>(0, (s, p) => s + num.parse(p['amountPaid']));
          final arrears = payments.where((p) => p['status'] != 'completed');
          return (200, {
            'month': '$month',
            'year': '$year',
            'totalExpected': expected,
            'totalCollected': collected,
            'collectionRate': expected > 0 ? (collected / expected * 100).round() : 0,
            'totalOutstandingArrears': arrears.fold<num>(
              0,
              (s, p) => s + num.parse(p['amount']) - num.parse(p['amountPaid']),
            ),
            'totalArrearsCount': arrears.length,
          });
        case 'buildings':
          return (200, [
            for (final b in active)
              {
                'buildingId': b['id'],
                'buildingName': b['name'],
                'totalRooms': rooms.where((r) => r['buildingId'] == b['id']).length,
                'occupiedRooms': rooms
                    .where((r) => r['buildingId'] == b['id'] && r['status'] == 'occupied')
                    .length,
                'vacantRooms': rooms
                    .where((r) => r['buildingId'] == b['id'] && r['status'] == 'vacant')
                    .length,
                'occupancyRate': '0%',
              },
          ]);
      }
    }

    if (area == 'buildings') {
      final buildingId = seg(3);
      if (seg(4) == 'rooms') {
        final roomId = seg(5);
        if (roomId.isEmpty) {
          if (method == 'POST') {
            final r = addRoom(buildingId, body['name'], body['rentAmount'] as num);
            if (body['type'] != null) r['type'] = body['type'];
            return (201, r);
          }
          return (200, rooms.where((r) => r['buildingId'] == buildingId).toList());
        }
        final room = _find(rooms, roomId);
        if (room == null) return _notFound('Room');
        if (seg(6) == 'vacate') {
          room['status'] = 'vacant';
          room['currentTenantId'] = null;
        } else if (method == 'PATCH') {
          for (final e in body.entries) {
            room[e.key] = e.value is num && e.key.endsWith('Amount')
                ? money(e.value as num)
                : e.value;
          }
        }
        return (200, room);
      }
      if (buildingId.isEmpty) {
        if (method == 'POST') {
          final b = addBuilding(body['name']);
          b.addAll(body);
          return (201, b);
        }
        return (200, buildings.where((b) => b['status'] == 'active').toList());
      }
      final building = _find(buildings, buildingId);
      if (building == null) return _notFound('Building');
      if (method == 'PATCH') building.addAll(body);
      if (method == 'DELETE') building['status'] = 'inactive';
      return (200, building);
    }

    if (area == 'tenants') {
      final id = seg(3);
      if (id.isEmpty) return (200, tenants);
      if (id == 'active') {
        return (200, tenants.where((t) => t['status'] == 'active').toList());
      }
      final t = _find(tenants, id);
      if (t == null) return _notFound('Tenant');
      switch (seg(4)) {
        case 'notice':
          t['status'] = 'notice';
          t['noticeDate'] = body['noticeDate'];
        case 'vacate':
          t['status'] = 'vacated';
          t['moveOutDate'] = body['moveOutDate'];
          final room = _find(rooms, t['roomId']);
          room?['status'] = 'vacant';
          room?['currentTenantId'] = null;
        default:
          if (method == 'PATCH' && body['rentAmount'] != null) {
            t['rentAmount'] = money(body['rentAmount'] as num);
          }
      }
      return (200, t);
    }

    if (area == 'payments') {
      final id = seg(3);
      if (id.isEmpty) {
        if (method == 'POST') {
          final amount = body['amount'] as num;
          final paid = body['amountPaid'] as num;
          final p = <String, dynamic>{
            'id': _next('p'),
            'organizationId': orgId,
            'tenantId': body['tenantId'],
            'roomId': body['roomId'],
            'buildingId': body['buildingId'],
            'type': body['type'],
            'status': _status(amount, paid),
            'method': body['method'],
            'amount': money(amount),
            'amountPaid': money(paid),
            'month': body['month'],
            'year': body['year'],
            'mpesaCode': body['mpesaCode'],
            'receiptNumber': 'RNT-000001-001',
            'notes': body['notes'],
            'dueDate': null,
            'daysLate': 0,
            'paidAt': paid > 0 ? '2026-10-27T08:00:00.000Z' : null,
            'createdAt': '2026-10-27T08:00:00.000Z',
          };
          payments.add(p);
          return (201, p);
        }
        return (200, payments);
      }
      if (id == 'arrears') {
        return (200, payments.where((p) => p['status'] != 'completed').toList());
      }
      if (id == 'month' || id == 'stats') {
        final month = int.parse('${query['month']}');
        final year = int.parse('${query['year']}');
        final list = payments.where((p) => p['month'] == month && p['year'] == year).toList();
        if (id == 'month') return (200, list);
        final expected = list.fold<num>(0, (s, p) => s + num.parse(p['amount']));
        final collected = list.fold<num>(0, (s, p) => s + num.parse(p['amountPaid']));
        return (200, {
          'totalExpected': expected,
          'totalCollected': collected,
          'totalArrears': expected - collected,
          'paymentCount': list.length,
        });
      }
      if (id == 'tenant') {
        return (200, payments.where((p) => p['tenantId'] == seg(4)).toList());
      }
      final p = _find(payments, id);
      if (p == null) return _notFound('Payment');
      if (method == 'PATCH' && body['amountPaid'] != null) {
        final paid = body['amountPaid'] as num;
        p['amountPaid'] = money(paid);
        p['status'] = _status(num.parse(p['amount']), paid);
      }
      return (200, p);
    }

    if (area == 'maintenance') {
      final id = seg(3);
      if (id.isEmpty) return (200, issues);
      final i = _find(issues, id);
      if (i == null) return _notFound('Maintenance request');
      switch (seg(4)) {
        case 'assign':
          i['assignedTo'] = body['assignedTo'];
          i['status'] = 'in_progress';
        case 'resolve':
          i['status'] = 'resolved';
          i['resolutionNotes'] = body['resolutionNotes'];
          i['cost'] = body['cost'] == null ? null : money(body['cost'] as num);
          i['resolvedAt'] = '2026-10-27T08:00:00.000Z';
        case 'cancel':
          i['status'] = 'cancelled';
        case 'priority':
          i['priority'] = body['priority'];
      }
      return (200, i);
    }

    return _notFound('Route');
  }

  @override
  void close({bool force = false}) {}
}

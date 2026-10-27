import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../models/payment.dart';

abstract class PaymentRepository {
  Future<List<Payment>> list(String orgId);
  Future<List<Payment>> forMonth(String orgId, {required int month, required int year});
  Future<List<Payment>> arrears(String orgId);
  Future<PaymentStats> stats(String orgId, {required int month, required int year});
  Future<List<Payment>> forTenant(String orgId, String tenantId);
  Future<Payment> get(String orgId, String paymentId);

  Future<Payment> record(
    String orgId, {
    required String tenantId,
    required String unitId,
    required String buildingId,
    required PaymentType type,
    required PaymentMethod method,
    required double amount,
    required double amountPaid,
    required int month,
    required int year,
    String? mpesaCode,
    String? notes,
  });

  Future<Payment> update(
    String orgId,
    String paymentId, {
    double? amountPaid,
    PaymentMethod? method,
    String? mpesaCode,
    String? notes,
  });
}

class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Payment>> list(String orgId) async =>
      parseList(await _api.get(Endpoints.payments(orgId)), Payment.fromJson);

  @override
  Future<List<Payment>> forMonth(
    String orgId, {
    required int month,
    required int year,
  }) async =>
      parseList(
        await _api.get(
          Endpoints.paymentsByMonth(orgId),
          query: {'month': month, 'year': year},
        ),
        Payment.fromJson,
      );

  @override
  Future<List<Payment>> arrears(String orgId) async =>
      parseList(await _api.get(Endpoints.paymentArrears(orgId)), Payment.fromJson);

  @override
  Future<PaymentStats> stats(
    String orgId, {
    required int month,
    required int year,
  }) async =>
      parseObject(
        await _api.get(
          Endpoints.paymentStats(orgId),
          query: {'month': month, 'year': year},
        ),
        PaymentStats.fromJson,
      );

  @override
  Future<List<Payment>> forTenant(String orgId, String tenantId) async =>
      parseList(
        await _api.get(Endpoints.paymentsByTenant(orgId, tenantId)),
        Payment.fromJson,
      );

  @override
  Future<Payment> get(String orgId, String paymentId) async => parseObject(
        await _api.get(Endpoints.payment(orgId, paymentId)),
        Payment.fromJson,
      );

  @override
  Future<Payment> record(
    String orgId, {
    required String tenantId,
    required String unitId,
    required String buildingId,
    required PaymentType type,
    required PaymentMethod method,
    required double amount,
    required double amountPaid,
    required int month,
    required int year,
    String? mpesaCode,
    String? notes,
  }) async {
    final data = await _api.post(
      Endpoints.payments(orgId),
      body: withoutNulls({
        'tenantId': tenantId,
        'roomId': unitId,
        'buildingId': buildingId,
        'type': type.name,
        'method': method.name,
        'amount': amount,
        'amountPaid': amountPaid,
        'month': month,
        'year': year,
        'mpesaCode': mpesaCode,
        'notes': notes,
      }),
    );
    return parseObject(data, Payment.fromJson);
  }

  @override
  Future<Payment> update(
    String orgId,
    String paymentId, {
    double? amountPaid,
    PaymentMethod? method,
    String? mpesaCode,
    String? notes,
  }) async {
    final data = await _api.patch(
      Endpoints.payment(orgId, paymentId),
      body: withoutNulls({
        'amountPaid': amountPaid,
        'method': method?.name,
        'mpesaCode': mpesaCode,
        'notes': notes,
      }),
    );
    return parseObject(data, Payment.fromJson);
  }
}

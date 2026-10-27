import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../models/shadow_rental.dart';

abstract class ShadowRentalRepository {
  Future<List<ShadowRental>> list();
  Future<ShadowRental> get(String id);

  Future<ShadowRental> create({
    String? nickname,
    String? address,
    required double rentAmount,
    BillingCycle? billingCycle,
    int? dueDayOfMonth,
    required PaymentDestinationType destinationType,
    required String destinationNumber,
    String? referenceName,
  });

  Future<ShadowRental> update(
    String id, {
    String? nickname,
    String? address,
    double? rentAmount,
    BillingCycle? billingCycle,
    int? dueDayOfMonth,
    PaymentDestinationType? destinationType,
    String? destinationNumber,
    String? referenceName,
  });

  Future<ShadowRental> end(String id);
}

class ApiShadowRentalRepository implements ShadowRentalRepository {
  ApiShadowRentalRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ShadowRental>> list() async =>
      parseList(await _api.get(Endpoints.shadowRentals), ShadowRental.fromJson);

  @override
  Future<ShadowRental> get(String id) async => parseObject(
        await _api.get(Endpoints.shadowRental(id)),
        ShadowRental.fromJson,
      );

  @override
  Future<ShadowRental> create({
    String? nickname,
    String? address,
    required double rentAmount,
    BillingCycle? billingCycle,
    int? dueDayOfMonth,
    required PaymentDestinationType destinationType,
    required String destinationNumber,
    String? referenceName,
  }) async {
    final data = await _api.post(
      Endpoints.shadowRentals,
      body: withoutNulls({
        'propertyNickname': nickname,
        'address': address,
        'rentAmount': rentAmount,
        'billingCycle': billingCycle?.name,
        'dueDayOfMonth': dueDayOfMonth,
        'paymentDestinationType': destinationType.name,
        'paymentDestinationNumber': destinationNumber,
        'paymentReferenceName': referenceName,
      }),
    );
    return parseObject(data, ShadowRental.fromJson);
  }

  @override
  Future<ShadowRental> update(
    String id, {
    String? nickname,
    String? address,
    double? rentAmount,
    BillingCycle? billingCycle,
    int? dueDayOfMonth,
    PaymentDestinationType? destinationType,
    String? destinationNumber,
    String? referenceName,
  }) async {
    final data = await _api.patch(
      Endpoints.shadowRental(id),
      body: withoutNulls({
        'propertyNickname': nickname,
        'address': address,
        'rentAmount': rentAmount,
        'billingCycle': billingCycle?.name,
        'dueDayOfMonth': dueDayOfMonth,
        'paymentDestinationType': destinationType?.name,
        'paymentDestinationNumber': destinationNumber,
        'paymentReferenceName': referenceName,
      }),
    );
    return parseObject(data, ShadowRental.fromJson);
  }

  @override
  Future<ShadowRental> end(String id) async => parseObject(
        await _api.patch(Endpoints.endShadowRental(id)),
        ShadowRental.fromJson,
      );
}

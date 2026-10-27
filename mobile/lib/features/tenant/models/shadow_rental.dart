import '../../../core/utils/json.dart';

enum BillingCycle {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  const BillingCycle(this.label);

  final String label;

  static BillingCycle fromJson(Object? raw) =>
      parseEnum(BillingCycle.values, (c) => c.name, raw);
}

enum PaymentDestinationType {
  paybill('Paybill'),
  till('Till'),
  bank('Bank');

  const PaymentDestinationType(this.label);

  final String label;

  static PaymentDestinationType fromJson(Object? raw) =>
      parseEnum(PaymentDestinationType.values, (t) => t.name, raw);
}

enum ShadowRentalStatus {
  unverified,
  converted,
  ended;

  static ShadowRentalStatus fromJson(Object? raw) =>
      parseEnum(ShadowRentalStatus.values, (s) => s.name, raw);
}

/// A rental the tenant records themselves because their landlord is not on
/// Rentra. The backend calls this a shadow relationship.
class ShadowRental {
  const ShadowRental({
    required this.id,
    required this.rentAmount,
    required this.billingCycle,
    required this.destinationType,
    required this.destinationNumber,
    required this.status,
    this.nickname,
    this.address,
    this.dueDayOfMonth,
    this.referenceName,
    this.createdAt,
  });

  final String id;
  final double rentAmount;
  final BillingCycle billingCycle;
  final PaymentDestinationType destinationType;
  final String destinationNumber;
  final ShadowRentalStatus status;
  final String? nickname;
  final String? address;
  final int? dueDayOfMonth;
  final String? referenceName;
  final DateTime? createdAt;

  factory ShadowRental.fromJson(Map<String, dynamic> json) => ShadowRental(
        id: requireString(json, 'id'),
        rentAmount: requireMoney(json, 'rentAmount'),
        billingCycle: json['billingCycle'] == null
            ? BillingCycle.monthly
            : BillingCycle.fromJson(json['billingCycle']),
        destinationType:
            PaymentDestinationType.fromJson(json['paymentDestinationType']),
        destinationNumber: requireString(json, 'paymentDestinationNumber'),
        status: ShadowRentalStatus.fromJson(json['status']),
        nickname: optionalString(json, 'propertyNickname'),
        address: optionalString(json, 'address'),
        dueDayOfMonth: optionalInt(json, 'dueDayOfMonth'),
        referenceName: optionalString(json, 'paymentReferenceName'),
        createdAt: optionalDate(json, 'createdAt'),
      );

  bool get isActive => status != ShadowRentalStatus.ended;
}

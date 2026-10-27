import '../../../core/utils/json.dart';

enum PaymentType {
  rent('Rent'),
  storage('Storage'),
  deposit('Deposit'),
  utility('Utility'),
  penalty('Penalty'),
  other('Other');

  const PaymentType(this.label);

  final String label;

  static PaymentType fromJson(Object? raw) =>
      parseEnum(PaymentType.values, (t) => t.name, raw);
}

enum PaymentMethod {
  mpesa('M-Pesa'),
  cash('Cash'),
  bank('Bank'),
  other('Other');

  const PaymentMethod(this.label);

  final String label;

  static PaymentMethod fromJson(Object? raw) =>
      parseEnum(PaymentMethod.values, (m) => m.name, raw);
}

enum PaymentStatus {
  pending('Not paid'),
  completed('Paid'),
  failed('Failed'),
  partial('Partly paid');

  const PaymentStatus(this.label);

  final String label;

  static PaymentStatus fromJson(Object? raw) =>
      parseEnum(PaymentStatus.values, (s) => s.name, raw);
}

class Payment {
  const Payment({
    required this.id,
    required this.organizationId,
    required this.tenantId,
    required this.unitId,
    required this.buildingId,
    required this.type,
    required this.status,
    required this.method,
    required this.amount,
    required this.amountPaid,
    required this.month,
    required this.year,
    this.mpesaCode,
    this.receiptNumber,
    this.notes,
    this.daysLate = 0,
    this.dueDate,
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final String organizationId;
  final String tenantId;
  final String unitId;
  final String buildingId;
  final PaymentType type;
  final PaymentStatus status;
  final PaymentMethod method;
  final double amount;
  final double amountPaid;
  final int month;
  final int year;
  final String? mpesaCode;
  final String? receiptNumber;
  final String? notes;
  final int daysLate;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime? createdAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: requireString(json, 'id'),
        organizationId: requireString(json, 'organizationId'),
        tenantId: requireString(json, 'tenantId'),
        unitId: requireString(json, 'roomId'),
        buildingId: requireString(json, 'buildingId'),
        type: PaymentType.fromJson(json['type']),
        status: PaymentStatus.fromJson(json['status']),
        method: PaymentMethod.fromJson(json['method']),
        amount: requireMoney(json, 'amount'),
        amountPaid: moneyOrZero(json, 'amountPaid'),
        month: requireInt(json, 'month'),
        year: requireInt(json, 'year'),
        mpesaCode: optionalString(json, 'mpesaCode'),
        receiptNumber: optionalString(json, 'receiptNumber'),
        notes: optionalString(json, 'notes'),
        daysLate: optionalInt(json, 'daysLate') ?? 0,
        dueDate: optionalDate(json, 'dueDate'),
        paidAt: optionalDate(json, 'paidAt'),
        createdAt: optionalDate(json, 'createdAt'),
      );
}

class PaymentStats {
  const PaymentStats({
    required this.expected,
    required this.collected,
    required this.outstanding,
    required this.count,
  });

  final double expected;
  final double collected;
  final double outstanding;
  final int count;

  factory PaymentStats.fromJson(Map<String, dynamic> json) => PaymentStats(
        expected: moneyOrZero(json, 'totalExpected'),
        collected: moneyOrZero(json, 'totalCollected'),
        outstanding: moneyOrZero(json, 'totalArrears'),
        count: optionalInt(json, 'paymentCount') ?? 0,
      );
}

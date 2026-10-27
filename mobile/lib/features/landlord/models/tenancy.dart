import '../../../core/utils/json.dart';

enum TenancyStatus {
  active,
  notice,
  vacated;

  static TenancyStatus fromJson(Object? raw) =>
      parseEnum(TenancyStatus.values, (s) => s.name, raw);
}

/// A tenant's occupancy of a unit. The backend calls this a tenant.
class Tenancy {
  const Tenancy({
    required this.id,
    required this.userId,
    required this.unitId,
    required this.buildingId,
    required this.organizationId,
    required this.rentAmount,
    required this.storageAmount,
    required this.depositAmount,
    required this.status,
    required this.moveInDate,
    this.moveOutDate,
    this.noticeDate,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String unitId;
  final String buildingId;
  final String organizationId;
  final double rentAmount;
  final double storageAmount;
  final double depositAmount;
  final TenancyStatus status;
  final DateTime moveInDate;
  final DateTime? moveOutDate;
  final DateTime? noticeDate;
  final String? notes;
  final DateTime? createdAt;

  factory Tenancy.fromJson(Map<String, dynamic> json) => Tenancy(
        id: requireString(json, 'id'),
        userId: requireString(json, 'userId'),
        unitId: requireString(json, 'roomId'),
        buildingId: requireString(json, 'buildingId'),
        organizationId: requireString(json, 'organizationId'),
        rentAmount: requireMoney(json, 'rentAmount'),
        storageAmount: moneyOrZero(json, 'storageAmount'),
        depositAmount: moneyOrZero(json, 'depositAmount'),
        status: TenancyStatus.fromJson(json['status']),
        moveInDate: requireDate(json, 'moveInDate'),
        moveOutDate: optionalDate(json, 'moveOutDate'),
        noticeDate: optionalDate(json, 'noticeDate'),
        notes: optionalString(json, 'notes'),
        createdAt: optionalDate(json, 'createdAt'),
      );
}

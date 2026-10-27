import '../../../core/utils/json.dart';

enum UnitStatus {
  vacant,
  occupied,
  maintenance,
  inactive;

  static UnitStatus fromJson(Object? raw) =>
      parseEnum(UnitStatus.values, (s) => s.name, raw);
}

enum UnitType {
  bedsitter('bedsitter', 'Bedsitter'),
  oneBedroom('one_bedroom', '1 Bedroom'),
  twoBedroom('two_bedroom', '2 Bedroom'),
  threeBedroom('three_bedroom', '3 Bedroom'),
  singleRoom('single_room', 'Single Room'),
  shop('shop', 'Shop'),
  office('office', 'Office'),
  studio('studio', 'Studio');

  const UnitType(this.wire, this.label);

  final String wire;
  final String label;

  static UnitType fromJson(Object? raw) =>
      parseEnum(UnitType.values, (t) => t.wire, raw);
}

/// A rentable space. The backend calls this a room.
class Unit {
  const Unit({
    required this.id,
    required this.name,
    required this.buildingId,
    required this.organizationId,
    required this.type,
    required this.status,
    required this.rentAmount,
    required this.storageAmount,
    this.floor,
    this.description,
    this.currentTenantId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String buildingId;
  final String organizationId;
  final UnitType type;
  final UnitStatus status;
  final double rentAmount;
  final double storageAmount;
  final int? floor;
  final String? description;
  final String? currentTenantId;
  final DateTime? createdAt;

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        id: requireString(json, 'id'),
        name: requireString(json, 'name'),
        buildingId: requireString(json, 'buildingId'),
        organizationId: requireString(json, 'organizationId'),
        type: UnitType.fromJson(json['type']),
        status: UnitStatus.fromJson(json['status']),
        rentAmount: requireMoney(json, 'rentAmount'),
        storageAmount: moneyOrZero(json, 'storageAmount'),
        floor: optionalInt(json, 'floor'),
        description: optionalString(json, 'description'),
        currentTenantId: optionalString(json, 'currentTenantId'),
        createdAt: optionalDate(json, 'createdAt'),
      );

  bool get isVacant => status == UnitStatus.vacant;
}

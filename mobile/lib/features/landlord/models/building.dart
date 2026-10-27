import '../../../core/utils/json.dart';

class Building {
  const Building({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.isActive,
    this.address,
    this.city,
    this.county,
    this.totalFloors,
    this.description,
    this.createdAt,
  });

  final String id;
  final String name;
  final String organizationId;
  final bool isActive;
  final String? address;
  final String? city;
  final String? county;
  final int? totalFloors;
  final String? description;
  final DateTime? createdAt;

  factory Building.fromJson(Map<String, dynamic> json) => Building(
        id: requireString(json, 'id'),
        name: requireString(json, 'name'),
        organizationId: requireString(json, 'organizationId'),
        isActive: optionalString(json, 'status') != 'inactive',
        address: optionalString(json, 'address'),
        city: optionalString(json, 'city'),
        county: optionalString(json, 'county'),
        totalFloors: optionalInt(json, 'totalFloors'),
        description: optionalString(json, 'description'),
        createdAt: optionalDate(json, 'createdAt'),
      );
}

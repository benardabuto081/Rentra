import '../../../core/utils/json.dart';

/// A landlord's portfolio. Shown to people as "My Properties".
class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.ownerId,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.status,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? status;
  final DateTime? createdAt;

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: requireString(json, 'id'),
        name: requireString(json, 'name'),
        ownerId: requireString(json, 'ownerId'),
        phone: optionalString(json, 'phone'),
        email: optionalString(json, 'email'),
        address: optionalString(json, 'address'),
        city: optionalString(json, 'city'),
        status: optionalString(json, 'status'),
        createdAt: optionalDate(json, 'createdAt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerId': ownerId,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
      };
}

import '../../../core/utils/json.dart';

enum UserRole {
  landlord,
  caretaker,
  tenant;

  static UserRole fromJson(Object? raw) =>
      parseEnum(UserRole.values, (r) => r.name, raw);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.status,
    this.organizationId,
    this.createdAt,
  });

  final String id;
  final UserRole role;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? status;
  final String? organizationId;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: requireString(json, 'id'),
        role: UserRole.fromJson(json['role']),
        firstName: optionalString(json, 'firstName'),
        lastName: optionalString(json, 'lastName'),
        email: optionalString(json, 'email'),
        phone: optionalString(json, 'phone'),
        status: optionalString(json, 'status'),
        organizationId: optionalString(json, 'organizationId'),
        createdAt: optionalDate(json, 'createdAt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'status': status,
        'organizationId': organizationId,
        'createdAt': createdAt?.toIso8601String(),
      };

  String get fullName =>
      [firstName, lastName].whereType<String>().join(' ').trim();

  String get initial {
    final name = firstName?.trim() ?? '';
    return name.isEmpty ? 'R' : name.substring(0, 1).toUpperCase();
  }

  bool get hasOrganization =>
      organizationId != null && organizationId!.isNotEmpty;
}

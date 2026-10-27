import '../../../core/utils/json.dart';

class Passkey {
  const Passkey({
    required this.id,
    required this.code,
    required this.unitId,
    required this.status,
    this.expiresAt,
  });

  final String id;
  final String code;
  final String unitId;
  final String status;
  final DateTime? expiresAt;

  factory Passkey.fromJson(Map<String, dynamic> json) => Passkey(
        id: requireString(json, 'id'),
        code: requireString(json, 'code'),
        unitId: requireString(json, 'unitId'),
        status: requireString(json, 'status'),
        expiresAt: optionalDate(json, 'expiresAt'),
      );
}

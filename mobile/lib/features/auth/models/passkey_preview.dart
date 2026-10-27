import '../../../core/utils/json.dart';

/// Shape assumed from the existing tenant setup screen. The backend has no
/// preview endpoint yet; see docs/open-questions.md.
class PasskeyPreview {
  const PasskeyPreview({
    required this.code,
    this.propertyName,
    this.unitName,
    this.rentAmount,
  });

  final String code;
  final String? propertyName;
  final String? unitName;
  final double? rentAmount;

  factory PasskeyPreview.fromJson(String code, Map<String, dynamic> json) =>
      PasskeyPreview(
        code: code,
        propertyName: optionalString(json, 'propertyName'),
        unitName: optionalString(json, 'roomName'),
        rentAmount: optionalMoney(json, 'rentAmount'),
      );
}

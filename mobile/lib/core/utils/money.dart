import 'package:intl/intl.dart';

final _whole = NumberFormat('#,##0', 'en_US');
final _fraction = NumberFormat('#,##0.00', 'en_US');

/// Parses an amount that may arrive as a JSON number or a decimal string.
double parseMoney(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim().replaceAll(',', ''));
    if (parsed != null && parsed.isFinite) return parsed;
  }
  throw FormatException('Invalid amount: $value');
}

/// Formats as `KES 12,500`, or `KES 12,500.50` when there are cents.
String formatMoney(num amount) {
  final rounded = (amount * 100).round() / 100;
  final hasCents = rounded != rounded.truncateToDouble();
  final formatted =
      hasCents ? _fraction.format(rounded) : _whole.format(rounded);
  return 'KES $formatted';
}

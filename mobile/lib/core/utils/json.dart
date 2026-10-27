import 'money.dart';

String requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Missing or invalid "$key"');
}

String? optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Invalid "$key"');
}

int requireInt(Map<String, dynamic> json, String key) {
  final value = optionalInt(json, key);
  if (value == null) throw FormatException('Missing "$key"');
  return value;
}

int? optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed != null) return parsed.toInt();
  }
  throw FormatException('Invalid "$key"');
}

double requireMoney(Map<String, dynamic> json, String key) {
  if (json[key] == null) throw FormatException('Missing "$key"');
  return parseMoney(json[key]);
}

double moneyOrZero(Map<String, dynamic> json, String key) =>
    json[key] == null ? 0 : parseMoney(json[key]);

double? optionalMoney(Map<String, dynamic> json, String key) =>
    json[key] == null ? null : parseMoney(json[key]);

DateTime requireDate(Map<String, dynamic> json, String key) {
  final value = optionalDate(json, key);
  if (value == null) throw FormatException('Missing "$key"');
  return value;
}

DateTime? optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return DateTime.parse(value);
  throw FormatException('Invalid "$key"');
}

T parseEnum<T extends Enum>(
  Iterable<T> values,
  String Function(T value) wire,
  Object? raw,
) {
  for (final value in values) {
    if (wire(value) == raw) return value;
  }
  throw FormatException('Unknown value "$raw"');
}

/// Drops null entries so PATCH bodies only carry fields that were set.
Map<String, dynamic> withoutNulls(Map<String, dynamic> map) =>
    Map.fromEntries(map.entries.where((e) => e.value != null));

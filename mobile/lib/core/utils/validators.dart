class Validators {
  const Validators._();

  static String? Function(String?) required(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email address.';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : 'Enter an email address like name@example.com.';
  }

  /// Accepts 07XXXXXXXX, 01XXXXXXXX, +2547XXXXXXXX or 2547XXXXXXXX as typed.
  static String? kenyanPhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your phone number.';
    final valid = RegExp(r'^(?:0|\+?254)[17]\d{8}$').hasMatch(text);
    return valid
        ? null
        : 'Enter a Kenyan phone number, for example 0712345678.';
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Create a password.';
    if (text.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? amount(String? value) {
    final text = value?.trim().replaceAll(',', '') ?? '';
    if (text.isEmpty) return 'Enter an amount.';
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) {
      return 'Enter an amount greater than 0.';
    }
    return null;
  }
}

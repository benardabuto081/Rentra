class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://rentra-backend-z36t.onrender.com',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration slowRequestThreshold = Duration(seconds: 5);
  static const Duration splashMinimum = Duration(seconds: 2);
}

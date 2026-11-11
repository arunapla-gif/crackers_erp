class AppConfig {
  const AppConfig._();

  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://crackers-erp-api-production.up.railway.app/api',
  );

  static const Duration requestTimeout = Duration(seconds: 20);
}


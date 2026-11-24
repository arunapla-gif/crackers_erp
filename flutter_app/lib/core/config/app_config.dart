class AppConfig {
  const AppConfig._();

  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://crackers-erp-api-production.up.railway.app/api',
  );

  /// Embedded app version compiled into the binary/JS bundle.
  /// Keep in sync with pubspec.yaml (or override via --dart-define).
  static const String appVersionName = String.fromEnvironment(
    'APP_VERSION_NAME',
    defaultValue: '1.0.28',
  );

  static const int appVersionCode = int.fromEnvironment(
    'APP_VERSION_CODE',
    defaultValue: 29,
  );

  static const Duration requestTimeout = Duration(seconds: 35);
}


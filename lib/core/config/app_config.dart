class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'OWND_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  const AppConfig._();
}

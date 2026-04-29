class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'https://chronora-java-master.onrender.com',
    defaultValue: 'http://localhost:8085',
  );
}

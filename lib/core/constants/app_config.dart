class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'https://chronora-java-master.onrender.com',
    defaultValue: 'http://localhost:8085',
  );

  static const String mpPublicKey = String.fromEnvironment(
    'MP_PUBLIC_KEY',
    defaultValue: 'TEST-4109e8df-e883-4d68-a130-0fadc859100b',
  );
}

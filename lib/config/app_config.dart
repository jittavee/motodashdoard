class AppConfig {
  // App Info
  static const String appName = 'ECU Gauge';
  static const String appVersion = '1.0.0';

  // Bluetooth Config
  static const int bluetoothScanTimeout = 15; // seconds
  static const int bluetoothConnectTimeout = 15; // seconds

  // Performance Test Config
  static const double speedThreshold = 100.0; // km/h for 0-100 test
  static const double quarterMileDistance = 402.336; // meters

  // Database Config
  static const String databaseName = 'ecu_gauge.db';
  static const int databaseVersion = 1;

  // API Config (if needed in the future)
  static const String apiBaseUrl = '';
  static const int apiTimeout = 30; // seconds

  // Cache Config
  static const int maxCacheSize = 100; // items
  static const int cacheExpiration = 3600; // seconds (1 hour)

  // UI Config
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const int animationDuration = 300; // milliseconds
}

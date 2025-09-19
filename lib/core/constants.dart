class AppConstants {
  static const String appTitle = 'ApiTech Dashboard';
  
  static const String serviceUUID = "2916f51f-3d75-4868-9214-396d9ebb82f1";
  static const String characteristicUUID = "09e6f548-20c3-48cf-8b5c-897a2f683cc3";
  
  static const int scanTimeoutSeconds = 4;
  static const double animationDurationMs = 500;
  
  static const double speedGaugeMinimum = 0.0;
  static const double speedGaugeMaximum = 260.0;
  static const double speedGaugeInterval = 20.0;
  
  static const double gaugeAxisLineThickness = 0.1;
  static const double gaugeMajorTickLength = 0.1;
  static const double gaugeMinorTickLength = 0.05;
  static const double gaugeNeedleLength = 0.7;
  static const double gaugeKnobRadius = 0.08;
  
  static const double gridChildAspectRatio = 2.3;
  static const double gridSpacing = 10.0;
  static const double cardBorderRadius = 10.0;
  static const double defaultPadding = 16.0;
  static const double cardPadding = 8.0;
  
  static const int primaryColorHex = 0xFF1a1a1a;
  static const int cardColorHex = 0xFF212121;
}

class SensorKeys {
  static const String techo = 'TECHO';
  static const String speed = 'SPEED';
  static const String water = 'WATER';
  static const String airTemp = 'AIR.T';
  static const String map = 'MAP';
  static const String tps = 'TPS';
  static const String battery = 'BATT';
  static const String ignition = 'IGNITI';
  static const String injection = 'INJECT';
  static const String afr = 'AFR';
  static const String sTrim = 'S.TRIM';
  static const String lTrim = 'L.TRIM';
  static const String iacv = 'IACV';
}

class AppStrings {
  static const String connectButtonText = 'CONNECT';
  static const String findDevicesTitle = 'Find Dashboard Device';
  static const String connectionLostTitle = 'Connection Lost';
  static const String disconnectTooltip = 'Disconnect';
  static const String okButtonText = 'OK';
  
  static const String speedUnit = 'km/h';
  static const String voltageUnit = 'V';
  static const String temperatureUnit = '°C';
  static const String percentageUnit = '%';
  
  static const String rpmLabel = 'RPM';
  static const String batteryLabel = 'Battery';
  static const String waterTempLabel = 'Water Temp';
  static const String afrLabel = 'AFR';
  static const String tpsLabel = 'TPS';
  static const String mapLabel = 'MAP';
  static const String airTempLabel = 'Air Temp';
  static const String injectionLabel = 'Injection';
}
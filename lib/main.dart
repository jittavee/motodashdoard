
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'controllers/theme_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/ecu_data_controller.dart';
import 'controllers/bluetooth_controller.dart';
import 'controllers/language_controller.dart';
import 'controllers/performance_test_controller.dart';
import 'controllers/gps_speed_controller.dart';

import 'services/permission_service.dart';

import 'constants/app_themes.dart';
import 'translations/app_translations.dart';

import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // บังคับให้แอปใช้แนวนอนเท่านั้น (ทั้งซ้ายและขวา)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize services and controllers - Dependency Injection
  await _initializeDependencies();

  runApp(const MyApp());
}

Future<void> _initializeDependencies() async {
  // Initialize services first (순서 중요)
  await Get.putAsync(() async => PermissionService());

  // Initialize controllers (can use services)
  Get.put(ThemeController(), permanent: true);
  Get.put(LanguageController(), permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(ECUDataController(), permanent: true);
  Get.put(BluetoothController(), permanent: true);
  Get.put(PerformanceTestController(), permanent: true);
  Get.put(GpsSpeedController(), permanent: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Find controllers (already initialized in main)
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    return Obx(
      () => GetMaterialApp(
        title: 'ECU Gauge',
        debugShowCheckedModeBanner: false,

        // Translations
        translations: AppTranslations(),
        locale: languageController.currentLocale.value,
        fallbackLocale: const Locale('th', 'TH'),

        theme: AppThemes.getTheme(themeController.currentTheme.value),
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      ),
    );
  }
}

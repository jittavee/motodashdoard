import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controllers/theme_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/ecu_data_controller.dart';
import 'controllers/bluetooth_controller.dart';
import 'controllers/language_controller.dart';
import 'constants/app_themes.dart';
import 'translations/app_translations.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/dashboard_screen.dart';
import 'views/screens/bluetooth_screen.dart';
import 'views/screens/settings_screen.dart';
import 'views/screens/alert_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // กำหนดให้แอปรองรับทั้ง portrait และ landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    final themeController = Get.put(ThemeController());
    final languageController = Get.put(LanguageController());
    Get.put(SettingsController());
    Get.put(ECUDataController());
    Get.put(BluetoothController());

    return Obx(
      () => GetMaterialApp(
        title: 'ECU Gauge',
        debugShowCheckedModeBanner: false,

        // Translations
        translations: AppTranslations(),
        locale: languageController.currentLocale.value,
        fallbackLocale: const Locale('th', 'TH'),

        theme: AppThemes.getTheme(themeController.currentTheme.value),
        initialRoute: '/splash',
        getPages: [
          GetPage(name: '/splash', page: () => const SplashScreen()),
          GetPage(name: '/', page: () => const DashboardScreen()),
          GetPage(name: '/bluetooth', page: () => const BluetoothScreen()),
          GetPage(name: '/settings', page: () => const SettingsScreen()),
          GetPage(name: '/alert-settings', page: () => const AlertSettingsScreen()),
        ],
      ),
    );
  }
}

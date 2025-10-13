
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

import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // บังคับให้แอปใช้แนวนอนเท่านั้น (ทั้งซ้ายและขวา)
  await SystemChrome.setPreferredOrientations([
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
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      ),
    );
  }
}

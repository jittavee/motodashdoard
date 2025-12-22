import 'package:get/get.dart';
import '../views/screens/splash_screen.dart';
import '../views/screens/bluetooth_screen.dart';
import '../views/screens/settings_screen.dart';
import '../views/screens/alert_settings_screen.dart';
import '../views/screens/data_log_screen.dart';
import '../views/screens/performance_test_screen.dart';
import '../views/screens/dashboard/dashboard_1.dart';
import '../views/screens/dashboard/dashboard_2.dart';
import '../views/screens/dashboard/dashboard_3.dart';
import '../views/screens/dashboard/dashboard_4.dart';
import '../views/screens/dashboard/dashboard_5.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.bluetooth,
      page: () => const BluetoothScreen(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.alertSettings,
      page: () => const AlertSettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.dataLog,
      page: () => const DataLogScreen(),
    ),
    GetPage(
      name: AppRoutes.performanceTest,
      page: () => const PerformanceTestScreen(),
    ),
    GetPage(
      name: AppRoutes.template1,
      page: () => const TemplateOneScreen(),
    ),
    GetPage(
      name: AppRoutes.template2,
      page: () => const TemplateTwoScreen(),
    ),
    GetPage(
      name: AppRoutes.template3,
      page: () => const TemplateThreeScreen(),
    ),
    GetPage(
      name: AppRoutes.template4,
      page: () => const TemplateFourScreen(),
    ),
    GetPage(
      name: AppRoutes.template5,
      page: () => const TemplateFiveScreen(),
    ),
  ];
}

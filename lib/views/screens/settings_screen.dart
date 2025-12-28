import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/ecu_data_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // บังคับให้หน้า Settings เป็นแนวตั้งเท่านั้น
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // คืนค่าให้รองรับทุกแนว
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final languageController = Get.find<LanguageController>();
    final ecuController = Get.find<ECUDataController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        children: [
          // Speed Unit
          const ListTile(
            leading: Icon(Icons.speed),
            title: Text(
              'Speed Unit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Obx(() => Column(
                children: [
                  RadioListTile<SpeedUnit>(
                    title: const Text('km/h'),
                    value: SpeedUnit.kmh,
                    groupValue: settingsController.speedUnit.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setSpeedUnit(value);
                      }
                    },
                  ),
                  RadioListTile<SpeedUnit>(
                    title: const Text('mph'),
                    value: SpeedUnit.mph,
                    groupValue: settingsController.speedUnit.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setSpeedUnit(value);
                      }
                    },
                  ),
                ],
              )),
          const Divider(),

          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              'language'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Obx(() => Column(
                children: [
                  RadioListTile<Locale>(
                    title: Text('thai'.tr),
                    value: const Locale('th', 'TH'),
                    groupValue: languageController.currentLocale.value,
                    onChanged: (value) {
                      if (value != null) {
                        languageController.changeLanguage(value);
                      }
                    },
                  ),
                  RadioListTile<Locale>(
                    title: Text('english'.tr),
                    value: const Locale('en', 'US'),
                    groupValue: languageController.currentLocale.value,
                    onChanged: (value) {
                      if (value != null) {
                        languageController.changeLanguage(value);
                      }
                    },
                  ),
                ],
              )),
          const Divider(),

          // Dashboard Template
          const ListTile(
            leading: Icon(Icons.dashboard),
            title: Text(
              'Dashboard Template',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Obx(() => Column(
                children: [
                  RadioListTile<DashboardTemplate>(
                    title: const Text('Template 1 - Default'),
                    value: DashboardTemplate.template1,
                    groupValue: settingsController.dashboardTemplate.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setDashboardTemplate(value);
                        Get.offAllNamed(settingsController.getDashboardRoute());
                      }
                    },
                  ),
                  RadioListTile<DashboardTemplate>(
                    title: const Text('Template 2'),
                    value: DashboardTemplate.template2,
                    groupValue: settingsController.dashboardTemplate.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setDashboardTemplate(value);
                        Get.offAllNamed(settingsController.getDashboardRoute());
                      }
                    },
                  ),
                  RadioListTile<DashboardTemplate>(
                    title: const Text('Template 3'),
                    value: DashboardTemplate.template3,
                    groupValue: settingsController.dashboardTemplate.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setDashboardTemplate(value);
                        Get.offAllNamed(settingsController.getDashboardRoute());
                      }
                    },
                  ),
                  RadioListTile<DashboardTemplate>(
                    title: const Text('Template 4'),
                    value: DashboardTemplate.template4,
                    groupValue: settingsController.dashboardTemplate.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setDashboardTemplate(value);
                        Get.offAllNamed(settingsController.getDashboardRoute());
                      }
                    },
                  ),
                  RadioListTile<DashboardTemplate>(
                    title: const Text('Template 5'),
                    value: DashboardTemplate.template5,
                    groupValue: settingsController.dashboardTemplate.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setDashboardTemplate(value);
                        Get.offAllNamed(settingsController.getDashboardRoute());
                      }
                    },
                  ),
                ],
              )),
          const Divider(),


          // Other Options
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Alert Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed('/alert-settings');
            },
          ),
          // Data Logging Toggle
          Obx(() => ListTile(
                leading: const Icon(Icons.data_usage),
                title: const Text('Data Logging'),
                subtitle: Text(
                  ecuController.isLogging.value
                      ? 'Recording ECU data to database'
                      : 'Not recording',
                  style: TextStyle(
                    fontSize: 12,
                    color: ecuController.isLogging.value
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                trailing: Switch(
                  value: ecuController.isLogging.value,
                  onChanged: (value) {
                    if (value) {
                      ecuController.startLogging();
                      Get.snackbar(
                        'Data Logging',
                        'Started recording ECU data',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    } else {
                      ecuController.stopLogging();
                      Get.snackbar(
                        'Data Logging',
                        'Stopped recording ECU data',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
              )),
          // View Log History
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('View Log History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed('/data-log');
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Performance Test'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed('/performance-test');
            },
          ),

          const Divider(),

          // About
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('ECU Gauge v1.0.0'),
          ),
        ],
      ),
    );
  }
}

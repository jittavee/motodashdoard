import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/language_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final languageController = Get.find<LanguageController>();

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

         
          // Other Options
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Alert Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to alert settings
              Get.snackbar('Info', 'Alert settings coming soon');
            },
          ),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('Data Logging'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to data logging
              Get.snackbar('Info', 'Data logging screen coming soon');
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Performance Test'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to performance test
              Get.snackbar('Info', 'Performance test screen coming soon');
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

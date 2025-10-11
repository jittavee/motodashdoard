import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../constants/app_themes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final settingsController = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Selection
          const ListTile(
            leading: Icon(Icons.palette),
            title: Text(
              'Theme',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Obx(() => Column(
                children: ThemeType.values.map((theme) {
                  return RadioListTile<ThemeType>(
                    title: Text(themeController.getThemeName(theme)),
                    value: theme,
                    groupValue: themeController.currentTheme.value,
                    onChanged: (value) {
                      if (value != null) {
                        themeController.changeTheme(value);
                      }
                    },
                  );
                }).toList(),
              )),
          const Divider(),

          // Temperature Unit
          const ListTile(
            leading: Icon(Icons.thermostat),
            title: Text(
              'Temperature Unit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Obx(() => Column(
                children: [
                  RadioListTile<TemperatureUnit>(
                    title: const Text('Celsius (°C)'),
                    value: TemperatureUnit.celsius,
                    groupValue: settingsController.temperatureUnit.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setTemperatureUnit(value);
                      }
                    },
                  ),
                  RadioListTile<TemperatureUnit>(
                    title: const Text('Fahrenheit (°F)'),
                    value: TemperatureUnit.fahrenheit,
                    groupValue: settingsController.temperatureUnit.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setTemperatureUnit(value);
                      }
                    },
                  ),
                ],
              )),
          const Divider(),

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
          const ListTile(
            leading: Icon(Icons.language),
            title: Text(
              'Language',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Obx(() => Column(
                children: [
                  RadioListTile<Language>(
                    title: const Text('ไทย'),
                    value: Language.thai,
                    groupValue: settingsController.language.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setLanguage(value);
                      }
                    },
                  ),
                  RadioListTile<Language>(
                    title: const Text('English'),
                    value: Language.english,
                    groupValue: settingsController.language.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.setLanguage(value);
                      }
                    },
                  ),
                ],
              )),
          const Divider(),

          // Auto Day/Night Mode
          Obx(() => SwitchListTile(
                title: const Text('Auto Day/Night Mode'),
                subtitle: const Text('เปลี่ยนธีมอัตโนมัติตามเวลา'),
                value: settingsController.autoDayNightMode.value,
                onChanged: (value) {
                  settingsController.setAutoDayNightMode(value);
                },
                secondary: const Icon(Icons.brightness_auto),
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

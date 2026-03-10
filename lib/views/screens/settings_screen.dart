import 'package:api_tech_moto/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/ecu_data_controller.dart';
import '../../controllers/bluetooth_controller.dart';

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
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        children: [
          // ECU Model Selection
          ListTile(
            leading: const Icon(Icons.memory),
            title: Text(
              'ecu_model'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Obx(() => Text(
                  btController.isEcuModelSynced.value
                      ? 'synced_with_dongle'.tr
                      : 'not_synced'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: btController.isEcuModelSynced.value
                        ? Colors.green
                        : Colors.orange,
                  ),
                )),
          ),
          Obx(() => Stack(
                children: [
                  Column(
                    children: EcuModel.values.map((model) {
                      return RadioListTile<EcuModel>(
                        title: Text(model.description),
                        value: model,
                        groupValue: btController.currentEcuModel.value,
                        onChanged: btController.isSettingEcuModel.value
                            ? null // ปิด interaction ขณะรอ response
                            : (value) {
                                if (value != null) {
                                  btController.setEcuModel(value);
                                }
                              },
                      );
                    }).toList(),
                  ),
                  // Loading overlay
                  if (btController.isSettingEcuModel.value)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text(
                                'กำลังรอ ECU ตอบกลับ...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
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
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: Text(
              'dashboard_template'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Obx(() => Column(
                children: [
                  RadioListTile<DashboardTemplate>(
                    title: Text('template_default'.tr),
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
                    title: Text('template_2'.tr),
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
                    title: Text('template_3'.tr),
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
                    title: Text('template_4'.tr),
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
                    title: Text('template_5'.tr),
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
            title: Text('alert_settings'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed(AppRoutes.alertSettings);
            },
          ),
          // Data Logging Toggle
          Obx(() => ListTile(
                leading: const Icon(Icons.data_usage),
                title: Text('data_logging'.tr),
                subtitle: Text(
                  ecuController.isLogging.value
                      ? 'recording_ecu_data'.tr
                      : 'not_recording'.tr,
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
                        'data_logging'.tr,
                        'started_recording'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    } else {
                      ecuController.stopLogging();
                      Get.snackbar(
                        'data_logging'.tr,
                        'stopped_recording'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
              )),
          // View Log History
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: Text('view_log_history'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed(AppRoutes.dataLogChart);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text('performance_test'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed(AppRoutes.performanceTest);
            },
          ),

          const Divider(),

          // Bluetooth
          Obx(() {
            final isConnected = btController.connectionStatus.value ==
                BluetoothConnectionStatus.connected;
            return ListTile(
              leading: Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: isConnected ? Colors.blue : null,
              ),
              title: Text('bluetooth'.tr),
              subtitle: Text(
                isConnected
                    ? btController.connectedDevice.value?.platformName ?? 'connected'.tr
                    : 'not_connected'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Get.toNamed(AppRoutes.bluetooth);
              },
            );
          }),

          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('about'.tr),
            subtitle: Text('app_version'.tr),
          ),
        ],
      ),
    );
  }
}

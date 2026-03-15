import 'package:api_tech_moto/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/ecu_data_controller.dart';
import '../../controllers/bluetooth_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setLandscape();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // เมื่อ app กลับมา foreground (หลังเลื่อนแถบแจ้งเตือน) ให้บังคับแนวนอนใหม่
    if (state == AppLifecycleState.resumed) {
      _setLandscape();
    }
  }

  void _setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _showLanguageDialog(BuildContext context, LanguageController languageController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('language'.tr),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<Locale>(
                  title: Text('thai'.tr),
                  value: const Locale('th', 'TH'),
                  groupValue: languageController.currentLocale.value,
                  onChanged: (value) {
                    if (value != null) {
                      languageController.changeLanguage(value);
                      Navigator.pop(context);
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
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final ecuController = Get.find<ECUDataController>();
    final btController = Get.find<BluetoothController>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _setLandscape();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('settings'.tr),
        ),
      body: ListView(
        children: [
          // 1. Bluetooth - ต้องเชื่อมต่อก่อนถึงจะเริ่มทำงานได้
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

          // 2. ECU Model - เลือกโปรไฟล์ให้ตรงกับรถ
          Obx(() => ListTile(
                leading: const Icon(Icons.memory),
                title: Text('ecu_model'.tr),
                subtitle: Text(
                  btController.isEcuModelSynced.value
                      ? 'synced_with_dongle'.tr
                      : 'not_synced'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: btController.isEcuModelSynced.value
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.toNamed(AppRoutes.ecuModel);
                },
              )),

          // 3. Dashboard Template - ตั้งค่าหน้าตาแอปให้พร้อมใช้งาน
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: Text('dashboard_template'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed(AppRoutes.dashboardTemplate);
            },
          ),

          // 4. Data Logging - เปิดใช้งานก่อนออกตัว
          // Obx(() => ListTile(
          //       leading: const Icon(Icons.data_usage),
          //       title: Text('data_logging'.tr),
          //       subtitle: Text(
          //         ecuController.isLogging.value
          //             ? 'recording_ecu_data'.tr
          //             : 'not_recording'.tr,
          //         style: TextStyle(
          //           fontSize: 12,
          //           color: ecuController.isLogging.value
          //               ? Colors.green
          //               : Colors.grey,
          //         ),
          //       ),
          //       trailing: Switch(
          //         value: ecuController.isLogging.value,
          //         onChanged: (value) {
          //           if (value) {
          //             ecuController.startLogging();
          //             Get.snackbar(
          //               'data_logging'.tr,
          //               'started_recording'.tr,
          //               snackPosition: SnackPosition.BOTTOM,
          //               duration: const Duration(seconds: 2),
          //             );
          //           } else {
          //             ecuController.stopLogging();
          //             Get.snackbar(
          //               'data_logging'.tr,
          //               'stopped_recording'.tr,
          //               snackPosition: SnackPosition.BOTTOM,
          //               duration: const Duration(seconds: 2),
          //             );
          //           }
          //         },
          //       ),
          //     )),

          // 5. View History / Performance Test - ส่วนของการสรุปผล
          // ListTile(
          //   leading: const Icon(Icons.show_chart),
          //   title: Text('view_log_history'.tr),
          //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          //   onTap: () {
          //     Get.toNamed(AppRoutes.dataLogChart);
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text('performance_test'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed(AppRoutes.performanceTest);
            },
          ),

          // 6. Alert Settings / Language / About - ส่วนเสริมและข้อมูลระบบ
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text('alert_settings'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed(AppRoutes.alertSettings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context, languageController),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('about'.tr),
            subtitle: Text('app_version'.tr),
          ),
        ],
      ),
    ),
    );
  }
}

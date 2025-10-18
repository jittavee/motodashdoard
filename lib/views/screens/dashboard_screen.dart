import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ecu_data_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/bluetooth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../constants/app_themes.dart';
import '../widgets/rpm_gauge.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/info_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.put(ECUDataController());
    final themeController = Get.put(ThemeController());
    final btController = Get.put(BluetoothController());
    final settingsController = Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('ECU Gauge'),
        actions: [
          // สถานะ Bluetooth
          Obx(() => IconButton(
                icon: Icon(
                  btController.connectionStatus.value ==
                          BluetoothConnectionStatus.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: btController.connectionStatus.value ==
                          BluetoothConnectionStatus.connected
                      ? Colors.green
                      : Colors.red,
                ),
                onPressed: () => Get.toNamed('/bluetooth'),
              )),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Obx(() {
            final data = ecuController.currentData.value;
            final theme = themeController.currentTheme.value;

            if (data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_searching,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'กำลังรอข้อมูลจาก ECU...',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        // สร้างข้อมูล dummy สำหรับ testing
                        ecuController.startGeneratingData();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('สร้างข้อมูลทดสอบ'),
                    ),
                  ],
                ),
              );
            }

            if (orientation == Orientation.landscape) {
              return _buildLandscapeLayout(
                  context, data, theme, settingsController);
            } else {
              return _buildPortraitLayout(
                  context, data, theme, settingsController);
            }
          });
        },
      ),
      floatingActionButton: Obx(() {
        if (ecuController.isAlertActive.value) {
          return FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.red,
            child: const Icon(Icons.warning),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, dynamic data,
      ThemeType theme, SettingsController settings) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left side - Main gauges
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: RpmGauge(value: data.rpm, theme: theme),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: SpeedGauge(
                      value: settings.convertSpeed(data.speed),
                      theme: theme,
                      unit: settings.getSpeedUnit(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side - Info cards
            Expanded(
              flex: 1,
              child: _buildInfoGrid(data, settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, dynamic data,
      ThemeType theme, SettingsController settings) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // RPM Gauge
            SizedBox(
              height: 250,
              child: RpmGauge(value: data.rpm, theme: theme),
            ),
            const SizedBox(height: 16),
            // Speed Gauge
            SizedBox(
              height: 200,
              child: SpeedGauge(
                value: settings.convertSpeed(data.speed),
                theme: theme,
                unit: settings.getSpeedUnit(),
              ),
            ),
            const SizedBox(height: 16),
            // Info Grid
            _buildInfoGrid(data, settings),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(dynamic data, SettingsController settings) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        InfoCard(
          label: 'Water Temp',
          value: settings.convertTemperature(data.waterTemp).toStringAsFixed(1),
          unit: settings.getTemperatureUnit(),
          icon: Icons.thermostat,
          color: data.waterTemp > 100 ? Colors.red : Colors.blue,
        ),
        InfoCard(
          label: 'Air Temp',
          value: settings.convertTemperature(data.airTemp).toStringAsFixed(1),
          unit: settings.getTemperatureUnit(),
          icon: Icons.air,
        ),
        InfoCard(
          label: 'TPS',
          value: data.tps.toStringAsFixed(1),
          unit: '%',
          icon: Icons.speed,
        ),
        InfoCard(
          label: 'AFR',
          value: data.afr.toStringAsFixed(1),
          unit: '',
          icon: Icons.local_gas_station,
        ),
        InfoCard(
          label: 'Battery',
          value: data.battery.toStringAsFixed(1),
          unit: 'V',
          icon: Icons.battery_full,
          color: data.battery < 12 ? Colors.red : Colors.green,
        ),
        InfoCard(
          label: 'MAP',
          value: data.map.toStringAsFixed(0),
          unit: 'kPa',
          icon: Icons.compress,
        ),
        InfoCard(
          label: 'Ignition',
          value: data.ignition.toStringAsFixed(1),
          unit: '°',
          icon: Icons.flash_on,
        ),
        InfoCard(
          label: 'Inject',
          value: data.inject.toStringAsFixed(1),
          unit: 'ms',
          icon: Icons.water_drop,
        ),
      ],
    );
  }
}

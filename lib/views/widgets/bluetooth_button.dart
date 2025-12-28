import 'package:api_tech_moto/utils/debug_data_generator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bluetooth_controller.dart';
import '../../controllers/ecu_data_controller.dart';

/// Reusable Bluetooth Button Widget with Test Data Generator
///
/// Features:
/// - Tap: Navigate to Bluetooth settings
/// - Long Press: Show test data generator menu (commented out by default)
class BluetoothButton extends StatelessWidget {
  const BluetoothButton({super.key});

  @override
  Widget build(BuildContext context) {
    final btController = Get.find<BluetoothController>();
    final ecuController = Get.find<ECUDataController>();

    return Obx(() {
      final isConnected = btController.connectionStatus.value ==
          BluetoothConnectionStatus.connected;

      return Container(
        decoration: BoxDecoration(
          color: isConnected ? Colors.green : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70, width: 2),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.bluetooth,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {
            Get.toNamed('/bluetooth');
          },
          // Long press for test data menu (Commented out - Uncomment to enable)
          onLongPress: () {
            Get.dialog(
              AlertDialog(
                title: const Text('Generate Test Data'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.all_inclusive),
                        title: const Text('Continuous Data'),
                        subtitle: const Text('Cycling pattern (1000-7000 RPM)'),
                        onTap: () {
                          ecuController.startContinuousData();
                          Get.back();
                          Get.snackbar(
                            'Test Data',
                            'Starting continuous data generation',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.hourglass_empty),
                        title: const Text('Idle Engine'),
                        subtitle: const Text('Low RPM (800-880)'),
                        onTap: () {
                          ecuController.startIdleData();
                          Get.back();
                          Get.snackbar(
                            'Test Data',
                            'Starting idle engine simulation',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.speed),
                        title: const Text('Racing Mode'),
                        subtitle: const Text('High performance (5000-8000 RPM)'),
                        onTap: () {
                          ecuController.startRacingData();
                          Get.back();
                          Get.snackbar(
                            'Test Data',
                            'Starting racing simulation',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.timeline),
                        title: const Text('Realistic Data'),
                        subtitle: const Text('Auto-stop after 60 cycles'),
                        onTap: () {
                          ecuController.startRealisticDebugData();
                          Get.back();
                          Get.snackbar(
                            'Test Data',
                            'Starting realistic test data',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.stop, color: Colors.red),
                        title: const Text('Stop Generation'),
                        onTap: () {
                          ecuController.stopDebugData();
                          Get.back();
                          Get.snackbar(
                            'Test Data',
                            'Stopped data generation',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

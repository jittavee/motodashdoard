import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/bluetooth_controller.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  @override
  void initState() {
    super.initState();

    // บังคับให้หน้า Bluetooth เป็นแนวตั้งเท่านั้น
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final btController = Get.find<BluetoothController>();
    btController.startScan();
  }

  @override
  void dispose() {
    // คืนค่ากลับเป็นแนวนอนตามการตั้งค่าของแอพ
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('scan_devices'.tr),
        actions: [
          Obx(
            () => Row(
              children: [
                TextButton(
                  onPressed: btController.isScanning.value
                      ? null
                      : btController.startScan,
                  child: Text('add_devices'.tr),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: btController.isScanning.value
                      ? null
                      : btController.startScan,
                  tooltip: 'add_devices'.tr,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            // Error Message
            if (btController.errorMessage.value.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        btController.errorMessage.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Device List with Pull to Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await btController.startScan();
                },
                child: btController.scanResults.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      btController.isScanning.value
                                          ? Icons.bluetooth_searching
                                          : Icons.bluetooth_disabled,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      btController.isScanning.value
                                          ? 'searching_devices'.tr
                                          : 'no_devices_found'.tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'pull_to_scan'.tr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: btController.scanResults.length,
                        itemBuilder: (context, index) {
                          final result = btController.scanResults[index];
                          final device = result.device;
                          final isConnected =
                              btController.connectedDevice.value != null &&
                              btController.connectedDevice.value!.remoteId ==
                                  device.remoteId;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth),
                              title: Text(
                                device.platformName.isEmpty
                                    ? 'unknown_device'.tr
                                    : device.platformName,
                              ),
                              subtitle: Text(device.remoteId.toString()),
                              trailing: isConnected
                                  ? ElevatedButton(
                                      onPressed: btController.disconnect,
                                      child: Text('disconnect'.tr,
                                      style: TextStyle(color: Colors.red),),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        btController.connectToDevice(device);
                                      },
                                      child: Text('connect'.tr),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

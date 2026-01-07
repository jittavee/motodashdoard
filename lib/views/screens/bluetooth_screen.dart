import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
                child: btController.scanResults.isEmpty && btController.connectedDevice.value == null
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
                        itemCount: _getDeviceCount(btController),
                        itemBuilder: (context, index) {
                          // แสดงอุปกรณ์ที่เชื่อมต่ออยู่ที่ด้านบนสุด
                          if (index == 0 && btController.connectedDevice.value != null) {
                            final device = btController.connectedDevice.value!;
                            // ตรวจสอบว่าอุปกรณ์ที่เชื่อมต่ออยู่ในรายการ scan results หรือไม่
                            final isInScanResults = btController.scanResults.any(
                              (result) => result.device.remoteId == device.remoteId,
                            );

                            // ถ้าอยู่ใน scan results แล้ว ข้ามไป (จะแสดงในรายการปกติ)
                            if (isInScanResults && btController.scanResults.isNotEmpty) {
                              // แสดงอุปกรณ์จาก scan results
                              final result = btController.scanResults[0];
                              return _buildDeviceCard(result.device, btController);
                            }

                            // ถ้าไม่อยู่ใน scan results แสดงแยก
                            return _buildDeviceCard(device, btController);
                          }

                          // แสดงอุปกรณ์จาก scan results
                          final adjustedIndex = btController.connectedDevice.value != null &&
                                  !btController.scanResults.any(
                                    (result) => result.device.remoteId == btController.connectedDevice.value!.remoteId,
                                  )
                              ? index - 1
                              : index;

                          if (adjustedIndex >= 0 && adjustedIndex < btController.scanResults.length) {
                            final result = btController.scanResults[adjustedIndex];
                            final device = result.device;
                            return _buildDeviceCard(device, btController);
                          }

                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  int _getDeviceCount(BluetoothController btController) {
    // ถ้ามีอุปกรณ์เชื่อมต่ออยู่และไม่อยู่ใน scan results ให้เพิ่ม 1
    if (btController.connectedDevice.value != null) {
      final isInScanResults = btController.scanResults.any(
        (result) => result.device.remoteId == btController.connectedDevice.value!.remoteId,
      );
      return isInScanResults ? btController.scanResults.length : btController.scanResults.length + 1;
    }
    return btController.scanResults.length;
  }

  Widget _buildDeviceCard(BluetoothDevice device, BluetoothController btController) {
    final isConnected = btController.connectedDevice.value != null &&
        btController.connectedDevice.value!.remoteId == device.remoteId;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: isConnected ? Colors.blue.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: Icon(
          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          color: isConnected ? Colors.blue : null,
        ),
        title: Text(
          device.platformName.isEmpty ? 'unknown_device'.tr : device.platformName,
          style: TextStyle(
            fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.remoteId.toString()),
            if (isConnected)
              Text(
                'connected'.tr,
                style: const TextStyle(color: Colors.blue, fontSize: 12),
              ),
          ],
        ),
        trailing: isConnected
            ? ElevatedButton(
                onPressed: btController.disconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'disconnect'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : ElevatedButton(
                onPressed: () {
                  btController.connectToDevice(device);
                },
                child: Text('connect'.tr),
              ),
      ),
    );
  }
}

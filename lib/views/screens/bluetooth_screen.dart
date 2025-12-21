import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/bluetooth_controller.dart';
import '../../controllers/ecu_data_controller.dart';
import '../../utils/debug_data_generator.dart';

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
    // คืนค่าให้รองรับทุกแนว
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
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
          Obx(() => Row(
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
          )),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            // Connected Device
            if (btController.connectedDevice.value != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.green,
                child: Row(
                  children: [
                    const Icon(
                      Icons.bluetooth_connected,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เชื่อมต่ออยู่',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            btController.connectedDevice.value!.platformName.isEmpty
                                ? 'Unknown Device'
                                : btController.connectedDevice.value!.platformName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            btController.connectedDevice.value!.remoteId.toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: btController.disconnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ตัดการเชื่อมต่อ'),
                    ),
                  ],
                ),
              ),

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
                                          ? 'กำลังค้นหาอุปกรณ์...'
                                          : 'ไม่พบอุปกรณ์',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ลากลงเพื่อค้นหาอุปกรณ์',
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
                                    ? 'Unknown Device'
                                    : device.platformName,
                              ),
                              subtitle: Text(device.remoteId.toString()),
                              trailing: isConnected
                                  ? ElevatedButton(
                                      onPressed: btController.disconnect,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('ตัดการเชื่อมต่อ'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        btController.connectToDevice(device);
                                      },
                                      child: const Text('เชื่อมต่อ'),
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

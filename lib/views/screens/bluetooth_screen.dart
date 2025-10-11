import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bluetooth_controller.dart';

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Connection'),
      ),
      body: Column(
        children: [
          // Connection Status
          Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: _getStatusColor(btController.connectionStatus.value),
                child: Column(
                  children: [
                    Icon(
                      _getStatusIcon(btController.connectionStatus.value),
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusText(btController.connectionStatus.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (btController.connectedDevice != null)
                      Text(
                        btController.connectedDevice!.platformName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              )),

          // Scan Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => ElevatedButton.icon(
                  onPressed: btController.isScanning.value
                      ? btController.stopScan
                      : btController.startScan,
                  icon: Icon(
                    btController.isScanning.value
                        ? Icons.stop
                        : Icons.bluetooth_searching,
                  ),
                  label: Text(
                    btController.isScanning.value
                        ? 'หยุดสแกน'
                        : 'สแกนอุปกรณ์',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                )),
          ),

          // Error Message
          Obx(() {
            if (btController.errorMessage.value.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
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
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 16),

          // Device List
          Expanded(
            child: Obx(() {
              if (btController.scanResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่พบอุปกรณ์',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'กดปุ่มสแกนเพื่อค้นหาอุปกรณ์',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: btController.scanResults.length,
                itemBuilder: (context, index) {
                  final result = btController.scanResults[index];
                  final device = result.device;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(
                        device.platformName.isEmpty
                            ? 'Unknown Device'
                            : device.platformName,
                      ),
                      subtitle: Text(device.remoteId.toString()),
                      trailing: Obx(() {
                        final isConnected = btController.connectedDevice != null &&
                            btController.connectedDevice!.remoteId ==
                                device.remoteId;

                        if (isConnected) {
                          return ElevatedButton(
                            onPressed: btController.disconnect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('ตัดการเชื่อมต่อ'),
                          );
                        }

                        return ElevatedButton(
                          onPressed: () {
                            btController.connectToDevice(device);
                          },
                          child: const Text('เชื่อมต่อ'),
                        );
                      }),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BluetoothConnectionStatus status) {
    switch (status) {
      case BluetoothConnectionStatus.connected:
        return Colors.green;
      case BluetoothConnectionStatus.connecting:
        return Colors.orange;
      case BluetoothConnectionStatus.disconnected:
        return Colors.grey;
      case BluetoothConnectionStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BluetoothConnectionStatus status) {
    switch (status) {
      case BluetoothConnectionStatus.connected:
        return Icons.bluetooth_connected;
      case BluetoothConnectionStatus.connecting:
        return Icons.bluetooth_searching;
      case BluetoothConnectionStatus.disconnected:
        return Icons.bluetooth_disabled;
      case BluetoothConnectionStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(BluetoothConnectionStatus status) {
    switch (status) {
      case BluetoothConnectionStatus.connected:
        return 'เชื่อมต่อแล้ว';
      case BluetoothConnectionStatus.connecting:
        return 'กำลังเชื่อมต่อ...';
      case BluetoothConnectionStatus.disconnected:
        return 'ไม่ได้เชื่อมต่อ';
      case BluetoothConnectionStatus.error:
        return 'เกิดข้อผิดพลาด';
    }
  }
}

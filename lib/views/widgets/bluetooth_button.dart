import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bluetooth_controller.dart';

class BluetoothButton extends StatelessWidget {
  const BluetoothButton({super.key});

  @override
  Widget build(BuildContext context) {
    final btController = Get.find<BluetoothController>();

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
        ),
      );
    });
  }
}

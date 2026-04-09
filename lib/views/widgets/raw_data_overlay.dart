import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bluetooth_controller.dart';

/// แสดง raw data string ที่รับจาก Bluetooth ที่มุมขวาบนของจอ
class RawDataOverlay extends StatelessWidget {
  const RawDataOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final btController = Get.find<BluetoothController>();

    return Obx(() {
      final raw = btController.lastReceivedData.value;
      if (raw.isEmpty) return const SizedBox.shrink();

      return Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Text(
          raw,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    });
  }
}

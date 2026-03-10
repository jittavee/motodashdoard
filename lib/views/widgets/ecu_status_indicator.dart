import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bluetooth_controller.dart';

/// ECU Status Indicator Widget
///
/// แสดงสถานะการเชื่อมต่อระหว่าง Dongle กับ ECU รถ
class EcuStatusIndicator extends StatelessWidget {
  const EcuStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final btController = Get.find<BluetoothController>();

    return Obx(() {
      // ไม่แสดงถ้ายังไม่ได้เชื่อมต่อ Bluetooth
      if (btController.connectionStatus.value != BluetoothConnectionStatus.connected) {
        return const SizedBox.shrink();
      }

      final ecuStatus = btController.ecuConnectionStatus.value;

      Color statusColor;
      IconData statusIcon;

      switch (ecuStatus) {
        case EcuConnectionStatus.connected:
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
        case EcuConnectionStatus.connecting:
          statusColor = Colors.orange;
          statusIcon = Icons.sync;
          break;
        case EcuConnectionStatus.noResponse:
          statusColor = Colors.red;
          statusIcon = Icons.error;
          break;
      }

      // แสดงเป็นจุดกลมเล็กๆ
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      );

      // แบบเก่า - แสดง text
      // return Container(
      //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      //   decoration: BoxDecoration(
      //     color: statusColor.withValues(alpha: 0.8),
      //     borderRadius: BorderRadius.circular(20),
      //     boxShadow: [
      //       BoxShadow(
      //         color: statusColor.withValues(alpha: 0.5),
      //         blurRadius: 8,
      //         spreadRadius: 2,
      //       ),
      //     ],
      //   ),
      //   child: Row(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Icon(
      //         statusIcon,
      //         color: Colors.white,
      //         size: 14,
      //       ),
      //       const SizedBox(width: 6),
      //       Text(
      //         'ECU: ${_getStatusText(ecuStatus)}',
      //         style: const TextStyle(
      //           color: Colors.white,
      //           fontSize: 11,
      //           fontWeight: FontWeight.bold,
      //         ),
      //       ),
      //     ],
      //   ),
      // );
    });
  }

  String _getStatusText(EcuConnectionStatus status) {
    switch (status) {
      case EcuConnectionStatus.connected:
        return 'ecu_connected'.tr;
      case EcuConnectionStatus.connecting:
        return 'ecu_connecting'.tr;
      case EcuConnectionStatus.noResponse:
        return 'ecu_no_response'.tr;
    }
  }
}

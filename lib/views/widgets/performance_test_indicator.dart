import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/performance_test_controller.dart';

/// Widget แสดงสถานะการทดสอบสมรรถนะบน Dashboard
/// แสดงเฉพาะเมื่อ isTestRunning = true
class PerformanceTestIndicator extends StatelessWidget {
  const PerformanceTestIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final perfController = Get.find<PerformanceTestController>();

    return Obx(() {
      // ไม่แสดงอะไรถ้าไม่ได้ทำการทดสอบ
      if (!perfController.isTestRunning.value) {
        return const SizedBox.shrink();
      }

      final testType = perfController.currentTestType.value;
      final time = perfController.currentTime.value;
      final distance = perfController.currentDistance.value;
      final targetDistance = _getTargetDistance(testType);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Test Type + Stop Button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  testType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => perfController.stopTest(saveResult: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'stop_test'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Row 2: Time + Distance
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${time.toStringAsFixed(2)}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.straighten,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${distance.toStringAsFixed(0)}m / ${targetDistance.toInt()}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  double _getTargetDistance(String testType) {
    switch (testType) {
      case '0-100m':
        return 100.0;
      case '0-201m':
      case '201m':
        return 201.0;
      case '0-402m':
      case '402m':
        return 402.0;
      case '0-1000m':
      case '1000m':
        return 1000.0;
      default:
        return 100.0;
    }
  }
}

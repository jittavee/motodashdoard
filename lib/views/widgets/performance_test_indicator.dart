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
          ],
        ),
      );
    });
  }
}

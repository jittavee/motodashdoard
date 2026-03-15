import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/performance_test_controller.dart';
import '../../controllers/ecu_data_controller.dart';
import '../../models/performance_test.dart';

class HistoryButton extends StatelessWidget {
  const HistoryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPerformanceTestHistory(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 2),
          ),
          child: const Icon(Icons.history, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Future<void> _showPerformanceTestHistory(BuildContext context) async {
    final controller = Get.find<PerformanceTestController>();
    await controller.loadTestHistory();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'test_history'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.testHistory.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_test_history'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.testHistory.length,
                      itemBuilder: (context, index) {
                        final test = controller.testHistory[index];
                        return _buildHistoryCard(context, test);
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, PerformanceTest test) {
    final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(test.timestamp);
    final hasEcuSession = test.ecuSessionStart != null && test.ecuSessionEnd != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: hasEcuSession
            ? () {
                // Load ECU timeline for this test
                final ecuController = Get.find<ECUDataController>();
                final start = DateTime.fromMillisecondsSinceEpoch(test.ecuSessionStart!);
                final end = DateTime.fromMillisecondsSinceEpoch(test.ecuSessionEnd!);
                Navigator.pop(context);
                ecuController.loadPlaybackSession(start, end);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    test.testType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('time'.tr, '${test.time.toStringAsFixed(2)} s'),
                _buildMetric('max_speed'.tr, '${test.maxSpeed.toStringAsFixed(0)} km/h'),
                _buildMetric('avg_speed'.tr, '${test.avgSpeed.toStringAsFixed(0)} km/h'),
              ],
            ),
            if (test.maxRpm != null) ...[
              const Divider(height: 24),
              Text(
                'ecu_data'.tr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('max_rpm'.tr, '${test.maxRpm?.toStringAsFixed(0) ?? '-'}'),
                  _buildMetric('max_water_temp'.tr, '${test.maxWaterTemp?.toStringAsFixed(0) ?? '-'}°C'),
                  _buildMetric('max_tps'.tr, '${test.maxTps?.toStringAsFixed(0) ?? '-'}%'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('avg_rpm'.tr, '${test.avgRpm?.toStringAsFixed(0) ?? '-'}'),
                  _buildMetric('avg_afr'.tr, '${test.avgAfr?.toStringAsFixed(1) ?? '-'}'),
                  _buildMetric('min_battery'.tr, '${test.minBattery?.toStringAsFixed(1) ?? '-'}V'),
                ],
              ),
            ],
            if (test.note != null && test.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${'note'.tr}: ${test.note}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

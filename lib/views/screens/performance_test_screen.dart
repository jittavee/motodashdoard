import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/performance_test_controller.dart';
import '../../controllers/ecu_data_controller.dart';
import '../../models/performance_test.dart';

class PerformanceTestScreen extends StatefulWidget {
  const PerformanceTestScreen({super.key});

  @override
  State<PerformanceTestScreen> createState() => _PerformanceTestScreenState();
}

class _PerformanceTestScreenState extends State<PerformanceTestScreen> {
  @override
  void initState() {
    super.initState();
    // บังคับให้หน้านี้เป็นแนวตั้งเท่านั้น
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // คืนค่าให้รองรับทุกแนว
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfController = Get.find<PerformanceTestController>();
    final ecuController = Get.find<ECUDataController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Test History',
            onPressed: () => _showTestHistory(context, perfController),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current Speed Display
            Obx(() {
              final currentSpeed = ecuController.currentData.value?.speed ?? 0;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CURRENT SPEED',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentSpeed.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              );
            }),

            // Test Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Test Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => Column(
                      children: [
                        _buildTestCard(
                          context,
                          perfController,
                          '0-100 m',
                          '0-100m',
                          Icons.speed,
                          'Quarter Kilometer Sprint',
                        ),
                        _buildTestCard(
                          context,
                          perfController,
                          '0-201 m',
                          '0-201m',
                          Icons.directions_run,
                          'Eighth Mile',
                        ),
                        _buildTestCard(
                          context,
                          perfController,
                          '0-402 m',
                          '0-402m',
                          Icons.local_fire_department,
                          'Quarter Mile',
                        ),
                        _buildTestCard(
                          context,
                          perfController,
                          '0-1000 m',
                          '0-1000m',
                          Icons.rocket_launch,
                          'Kilometer Sprint',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Active Test Display
            Obx(() {
              if (perfController.isTestActive.value) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perfController.currentTestType.value
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const Text(
                                'Test in Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop_circle, size: 48),
                            color: Colors.red,
                            onPressed: () => perfController.stopTest(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTestMetric(
                            'TIME',
                            '${perfController.currentTime.value.toStringAsFixed(2)} s',
                            Icons.timer,
                          ),
                          _buildTestMetric(
                            'MAX SPEED',
                            '${perfController.maxSpeed.value.toStringAsFixed(0)} km/h',
                            Icons.speed,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context,
    PerformanceTestController controller,
    String title,
    String testType,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = controller.selectedTestType.value == testType;
    final isActive = controller.isTestActive.value;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          size: 32,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? ElevatedButton.icon(
                onPressed: isActive
                    ? null
                    : () => controller.startTest(testType),
                icon: const Icon(Icons.play_arrow),
                label: const Text('START'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              )
            : null,
        onTap: isActive ? null : () => controller.selectTestType(testType),
      ),
    );
  }

  Widget _buildTestMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.orange),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showTestHistory(
    BuildContext context,
    PerformanceTestController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
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
                    const Icon(Icons.history, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Test History',
                      style: TextStyle(
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
                            'No test history yet',
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
                      return _buildHistoryCard(test);
                    },
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(PerformanceTest test) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy HH:mm',
    ).format(test.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                _buildHistoryMetric(
                  'Time',
                  '${test.time.toStringAsFixed(2)} s',
                ),
                _buildHistoryMetric(
                  'Max Speed',
                  '${test.maxSpeed.toStringAsFixed(0)} km/h',
                ),
                _buildHistoryMetric(
                  'Avg Speed',
                  '${test.avgSpeed.toStringAsFixed(0)} km/h',
                ),
              ],
            ),
            if (test.note != null && test.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Note: ${test.note}',
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
    );
  }

  Widget _buildHistoryMetric(String label, String value) {
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

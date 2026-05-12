import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/performance_test_controller.dart';
import '../../models/performance_test.dart';

class PerformanceTestScreenV2 extends StatefulWidget {
  const PerformanceTestScreenV2({super.key});

  @override
  State<PerformanceTestScreenV2> createState() => _PerformanceTestScreenV2State();
}

class _PerformanceTestScreenV2State extends State<PerformanceTestScreenV2> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PerformanceTestController>();
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('performance_test'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'test_history'.tr,
            onPressed: () => _showTestHistory(context, ctrl),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimer(ctrl, primary),
                      const SizedBox(height: 16),
                      _buildStatusBadge(ctrl, primary),
                      const SizedBox(height: 24),
                      _buildDistanceTabs(ctrl, primary),
                      const SizedBox(height: 24),
                      _buildBestRecords(ctrl, primary),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _buildStartButton(ctrl, primary),
            ],
          ),
          _buildCountdownOverlay(ctrl),
        ],
      ),
    );
  }

  Widget _buildTimer(PerformanceTestController ctrl, Color primary) {
    return Obx(() {
      final t = ctrl.currentTime.value;
      final mm = (t ~/ 60).toString().padLeft(2, '0');
      final ss = (t % 60).toInt().toString().padLeft(2, '0');
      final cs = ((t * 100) % 100).toInt().toString().padLeft(2, '0');

      return Center(
        child: Column(
          children: [
            Text(
              'TELEMETRY_SESSION_ACTIVE',
              style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              '$mm:$ss.$cs',
              style: TextStyle(
                color: primary,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'Ethnocentric',
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusBadge(PerformanceTestController ctrl, Color primary) {
    return Obx(() {
      final running = ctrl.isTestRunning.value;
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: running
                ? Colors.orange.withValues(alpha: 0.15)
                : primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: running ? Colors.orange : primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                running ? Icons.fiber_manual_record : Icons.check_circle_outline,
                size: 12,
                color: running ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                running ? 'test_in_progress'.tr.toUpperCase() : 'READY FOR LAUNCH',
                style: TextStyle(
                  color: running ? Colors.orange : primary,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDistanceTabs(PerformanceTestController ctrl, Color primary) {
    const types = [
      ('0-100M', '0-100m'),
      ('201M', '0-201m'),
      ('402M', '0-402m'),
      ('1000M', '0-1000m'),
    ];

    return Obx(() {
      final selected = ctrl.selectedTestType.value;
      final running = ctrl.isTestRunning.value;
      return Row(
        children: types.map((entry) {
          final isSelected = selected == entry.$2;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: running ? null : () => ctrl.selectTestType(entry.$2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? primary : Colors.grey.shade700,
                    ),
                  ),
                  child: Text(
                    entry.$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildBestRecords(PerformanceTestController ctrl, Color primary) {
    return Obx(() {
      final selected = ctrl.selectedTestType.value;
      final filtered = ctrl.testHistory
          .where((t) => selected.isEmpty || t.testType == selected)
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));
      final best = filtered.take(3).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'สถิติที่ดีที่สุด',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: primary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          if (best.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.timer_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('no_test_history'.tr, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...best.asMap().entries.map((e) => _buildRecordRow(e.key, e.value, primary)),
        ],
      );
    });
  }

  Widget _buildRecordRow(int index, PerformanceTest test, Color primary) {
    final date = DateFormat('dd MMM yyyy | HH:mm').format(test.timestamp);
    final label = 'DRAG_RECORD_${(index + 1).toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(date, style: TextStyle(color: Colors.grey, fontSize: 11)),
        subtitle: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        trailing: Text(
          '${test.time.toStringAsFixed(2)}s',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Ethnocentric',
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay(PerformanceTestController ctrl) {
    return Obx(() {
      if (!ctrl.isCountingDown.value) return const SizedBox.shrink();
      final count = ctrl.countdownValue.value;
      return Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ethnocentric',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'GET READY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStartButton(PerformanceTestController ctrl, Color primary) {
    return Obx(() {
      final running = ctrl.isTestRunning.value;
      final counting = ctrl.isCountingDown.value;
      final selected = ctrl.selectedTestType.value;
      final canStart = selected.isNotEmpty && !running && !counting;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: running
                ? () => ctrl.stopTest()
                : counting
                    ? () => ctrl.stopTest()
                    : (canStart ? () => ctrl.startTest(selected) : null),
            icon: Icon(running || counting ? Icons.stop : Icons.flag_outlined),
            label: Text(
              running ? 'STOP RACE' : counting ? 'CANCEL' : 'START RACE',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: running || counting ? Colors.red : primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    });
  }

  Future<void> _showTestHistory(BuildContext context, PerformanceTestController ctrl) async {
    await ctrl.loadTestHistory();
    if (!context.mounted) return;

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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'test_history'.tr,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Obx(() {
                      if (ctrl.testHistory.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.white),
                          tooltip: 'delete_all'.tr,
                          onPressed: () => _confirmDeleteAll(context, ctrl),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (ctrl.testHistory.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('no_test_history'.tr, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: ctrl.testHistory.length,
                    itemBuilder: (context, index) =>
                        _buildHistoryCard(context, ctrl.testHistory[index], ctrl),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, PerformanceTest test, PerformanceTestController ctrl) {
    final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(test.timestamp);
    final primary = Theme.of(context).primaryColor;

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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    test.testType.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
                  ),
                ),
                const Spacer(),
                Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _confirmDeleteOne(context, test, ctrl),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 20, color: Colors.red[300]),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _historyMetric('time'.tr, '${test.time.toStringAsFixed(2)} s'),
                _historyMetric('max_speed'.tr, '${test.maxSpeed.toStringAsFixed(0)} km/h'),
                _historyMetric('avg_speed'.tr, '${test.avgSpeed.toStringAsFixed(0)} km/h'),
              ],
            ),
            if (test.maxRpm != null) ...[
              const Divider(height: 24),
              Text('ecu_data'.tr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _historyMetric('max_rpm'.tr, test.maxRpm?.toStringAsFixed(0) ?? '-'),
                  _historyMetric('max_water_temp'.tr, '${test.maxWaterTemp?.toStringAsFixed(0) ?? '-'}°C'),
                  _historyMetric('max_tps'.tr, '${test.maxTps?.toStringAsFixed(0) ?? '-'}%'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _historyMetric('avg_rpm'.tr, test.avgRpm?.toStringAsFixed(0) ?? '-'),
                  _historyMetric('avg_afr'.tr, test.avgAfr?.toStringAsFixed(1) ?? '-'),
                  _historyMetric('min_battery'.tr, '${test.minBattery?.toStringAsFixed(1) ?? '-'}V'),
                ],
              ),
            ],
            if (test.note != null && test.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${'note'.tr}: ${test.note}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOne(BuildContext context, PerformanceTest test, PerformanceTestController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_record'.tr),
        content: Text('${'confirm_delete'.tr} ${test.testType.toUpperCase()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true && test.id != null) {
      await ctrl.deleteTest(test.id!);
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, PerformanceTestController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_all'.tr),
        content: Text('confirm_delete_all'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete_all'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final test in List.from(ctrl.testHistory)) {
        if (test.id != null) await ctrl.deleteTest(test.id!);
      }
    }
  }

  Widget _historyMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';
import '../../models/ecu_data.dart';

class DataLogChartScreen extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const DataLogChartScreen({
    super.key,
    this.startDate,
    this.endDate,
  });

  @override
  State<DataLogChartScreen> createState() => _DataLogChartScreenState();
}

class _DataLogChartScreenState extends State<DataLogChartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ECUData> _logs = [];
  bool _isLoading = true;
  String _selectedParameter = 'rpm';
  DateTime? _startDate;
  DateTime? _endDate;

  Map<String, Map<String, dynamic>> get _parameters => {
    'rpm': {
      'name': 'rpm_label'.tr,
      'unit': 'RPM',
      'color': Colors.red,
      'getValue': (ECUData data) => data.rpm,
    },
    'speed': {
      'name': 'speed_label'.tr,
      'unit': 'km/h',
      'color': Colors.blue,
      'getValue': (ECUData data) => data.speed,
    },
    'waterTemp': {
      'name': 'water_temp_label'.tr,
      'unit': '°C',
      'color': Colors.orange,
      'getValue': (ECUData data) => data.waterTemp,
    },
    'airTemp': {
      'name': 'air_temp_label'.tr,
      'unit': '°C',
      'color': Colors.cyan,
      'getValue': (ECUData data) => data.airTemp,
    },
    'battery': {
      'name': 'battery_label'.tr,
      'unit': 'V',
      'color': Colors.green,
      'getValue': (ECUData data) => data.battery,
    },
    'tps': {
      'name': 'tps_label'.tr,
      'unit': '%',
      'color': Colors.purple,
      'getValue': (ECUData data) => data.tps,
    },
    'afr': {
      'name': 'afr_label'.tr,
      'unit': '',
      'color': Colors.pink,
      'getValue': (ECUData data) => data.afr,
    },
    'map': {
      'name': 'map_label'.tr,
      'unit': 'kPa',
      'color': Colors.teal,
      'getValue': (ECUData data) => data.map,
    },
  };

  @override
  void initState() {
    super.initState();
    // บังคับให้หน้านี้เป็นแนวนอน
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Initialize dates from widget parameters
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _loadLogs();
  }

  @override
  void dispose() {
    // คืนค่าให้รองรับทุกแนว
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _dbHelper.getECULogs(
        limit: 500, // ดึงข้อมูล 500 จุดสุดท้าย
        startDate: _startDate,
        endDate: _endDate,
      );

      // เรียงข้อมูลจากเก่าไปใหม่ (ASC) เพื่อให้กราฟแสดงถูกต้อง
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load data: $e');
    }
  }

  List<FlSpot> _getChartData() {
    if (_logs.isEmpty) return [];

    final getValue = _parameters[_selectedParameter]!['getValue'] as double Function(ECUData);

    // สร้างจุดข้อมูลสำหรับกราฟ
    final spots = <FlSpot>[];
    for (int i = 0; i < _logs.length; i++) {
      final value = getValue(_logs[i]);
      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  double _getMaxY() {
    if (_logs.isEmpty) return 100;

    final getValue = _parameters[_selectedParameter]!['getValue'] as double Function(ECUData);
    double maxValue = 0;

    for (var log in _logs) {
      final value = getValue(log);
      if (value > maxValue) maxValue = value;
    }

    // เพิ่ม 10% สำหรับ padding
    return maxValue * 1.1;
  }

  double _getMinY() {
    if (_logs.isEmpty) return 0;

    final getValue = _parameters[_selectedParameter]!['getValue'] as double Function(ECUData);
    double minValue = double.infinity;

    for (var log in _logs) {
      final value = getValue(log);
      if (value < minValue) minValue = value;
    }

    // ลด 10% สำหรับ padding
    return minValue * 0.9;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: Colors.blue.shade700,
              headerForegroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Set start of day to end of day for the selected date
        _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
      _loadLogs();
    }
  }

  Future<void> _clearDateFilter() async {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final param = _parameters[_selectedParameter];
    if (param == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Log Chart')),
        body: const Center(child: Text('Invalid parameter selected')),
      );
    }

    final paramColor = param['color'] as Color;
    final paramUnit = param['unit'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('data_log_chart'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'select_date'.tr,
            onPressed: _selectDate,
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'clear_filter'.tr,
              onPressed: _clearDateFilter,
            ),
          PopupMenuButton<String>(
            initialValue: _selectedParameter,
            onSelected: (value) {
              setState(() {
                _selectedParameter = value;
              });
            },
            itemBuilder: (context) => _parameters.entries.map((entry) {
              return PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: entry.value['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value['name']),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'no_data_for_chart'.tr,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Date range indicator
                    if (_startDate != null && _endDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.blue.withValues(alpha: 0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    // Chart
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: (_getMaxY() - _getMinY()) / 5,
                              verticalInterval: _logs.length / 10,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey[300]!,
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Colors.grey[300]!,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: _logs.length / 5,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= _logs.length) return const SizedBox();
                                    final log = _logs[value.toInt()];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('HH:mm').format(log.timestamp),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: (_getMaxY() - _getMinY()) / 5,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toStringAsFixed(0)} $paramUnit',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            minX: 0,
                            maxX: (_logs.length - 1).toDouble(),
                            minY: _getMinY(),
                            maxY: _getMaxY(),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getChartData(),
                                isCurved: true,
                                color: paramColor,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: _logs.length < 50, // แสดงจุดถ้าข้อมูลน้อยกว่า 50 จุด
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: paramColor.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final index = spot.x.toInt();
                                    if (index >= _logs.length) return null;

                                    final log = _logs[index];
                                    final time = DateFormat('HH:mm:ss').format(log.timestamp);
                                    final value = spot.y.toStringAsFixed(1);

                                    return LineTooltipItem(
                                      '$time\n$value $paramUnit',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Stats summary
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'min_value'.tr,
                            _getMinY().toStringAsFixed(1),
                            paramUnit,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'max_value'.tr,
                            _getMaxY().toStringAsFixed(1),
                            paramUnit,
                            Colors.red,
                          ),
                          _buildStatCard(
                            'avg_value'.tr,
                            _getAverage().toStringAsFixed(1),
                            paramUnit,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$value $unit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getAverage() {
    if (_logs.isEmpty) return 0;

    final getValue = _parameters[_selectedParameter]!['getValue'] as double Function(ECUData);
    double sum = 0;

    for (var log in _logs) {
      sum += getValue(log);
    }

    return sum / _logs.length;
  }
}

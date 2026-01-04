import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/database_helper.dart';
import '../../models/ecu_data.dart';
import 'data_log_chart_screen.dart';

class DataLogScreen extends StatefulWidget {
  const DataLogScreen({super.key});

  @override
  State<DataLogScreen> createState() => _DataLogScreenState();
}

class _DataLogScreenState extends State<DataLogScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ECUData> _logs = [];
  bool _isLoading = true;
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 50;

  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> _sessions = [];
  bool _showSessions = false;

  @override
  void initState() {
    super.initState();
    // บังคับให้หน้านี้เป็นแนวตั้งเท่านั้น
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadLogs();
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

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final logs = await _dbHelper.getECULogs(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        startDate: _startDate,
        endDate: _endDate,
      );

      final count = await _dbHelper.getECULogsCount(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _logs = logs;
        _totalCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load logs: $e');
    }
  }

  Future<void> _detectSessions() async {
    setState(() => _isLoading = true);

    try {
      // โหลดข้อมูลทั้งหมดในช่วงเวลาที่เลือก
      final allLogs = await _dbHelper.getECULogs(
        limit: 10000,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (allLogs.isEmpty) {
        setState(() {
          _sessions = [];
          _isLoading = false;
          _showSessions = true;
        });
        Get.snackbar('Info', 'no_data_in_range'.tr);
        return;
      }

      // แบ่ง session โดยดูจากช่วงเวลาที่ห่างกันเกิน 1 นาที
      final sessions = <Map<String, dynamic>>[];
      List<ECUData> currentSession = [allLogs[0]];

      for (int i = 1; i < allLogs.length; i++) {
        final prevTime = allLogs[i - 1].timestamp;
        final currentTime = allLogs[i].timestamp;
        final difference = currentTime.difference(prevTime);

        if (difference.inSeconds > 60) {
          // ห่างกันเกิน 1 นาที = session ใหม่
          sessions.add(_calculateSessionStats(currentSession));
          currentSession = [allLogs[i]];
        } else {
          currentSession.add(allLogs[i]);
        }
      }

      // เพิ่ม session สุดท้าย
      if (currentSession.isNotEmpty) {
        sessions.add(_calculateSessionStats(currentSession));
      }

      setState(() {
        _sessions = sessions;
        _isLoading = false;
        _showSessions = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to detect sessions: $e');
    }
  }

  Map<String, dynamic> _calculateSessionStats(List<ECUData> sessionData) {
    double maxSpeed = 0;
    double maxRpm = 0;
    double maxWaterTemp = 0;
    double avgSpeed = 0;
    double avgRpm = 0;

    for (var data in sessionData) {
      if (data.speed > maxSpeed) maxSpeed = data.speed;
      if (data.rpm > maxRpm) maxRpm = data.rpm;
      if (data.waterTemp > maxWaterTemp) maxWaterTemp = data.waterTemp;
      avgSpeed += data.speed;
      avgRpm += data.rpm;
    }

    avgSpeed /= sessionData.length;
    avgRpm /= sessionData.length;

    return {
      'start': sessionData.first.timestamp,
      'end': sessionData.last.timestamp,
      'count': sessionData.length,
      'maxSpeed': maxSpeed,
      'maxRpm': maxRpm,
      'maxWaterTemp': maxWaterTemp,
      'avgSpeed': avgSpeed,
      'avgRpm': avgRpm,
    };
  }

  
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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
        _startDate = picked.start;
        _endDate = picked.end;
        _currentPage = 0;
      });
      _loadLogs();
    }
  }

  Future<void> _selectMonthQuickPick() async {
    final now = DateTime.now();
    final options = [
      {'label': 'today'.tr, 'start': DateTime(now.year, now.month, now.day), 'end': now},
      {'label': 'this_week'.tr, 'start': now.subtract(Duration(days: now.weekday - 1)), 'end': now},
      {'label': 'this_month'.tr, 'start': DateTime(now.year, now.month, 1), 'end': now},
      {'label': '7_days_ago'.tr, 'start': now.subtract(const Duration(days: 7)), 'end': now},
      {'label': '30_days_ago'.tr, 'start': now.subtract(const Duration(days: 30)), 'end': now},
      {'label': 'last_month'.tr, 'start': DateTime(now.year, now.month - 1, 1), 'end': DateTime(now.year, now.month, 0)},
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('select_time_period'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return ListTile(
                title: Text(option['label'] as String),
                onTap: () {
                  setState(() {
                    _startDate = option['start'] as DateTime;
                    _endDate = option['end'] as DateTime;
                    _currentPage = 0;
                  });
                  Navigator.pop(context);
                  _loadLogs();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _selectDateRange();
              },
              child: Text('select_custom_date'.tr),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearDateFilter() async {
    setState(() {
      _startDate = null;
      _endDate = null;
      _currentPage = 0;
    });
    _loadLogs();
  }

  Future<void> _deleteAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Logs'),
        content: const Text('Are you sure you want to delete all ECU logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteAllECULogs();
        Get.snackbar('Success', 'All logs deleted');
        _loadLogs();
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete logs: $e');
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
  }

  Future<void> _exportToCSV() async {
    try {
      // Load all logs (without pagination)
      final allLogs = await _dbHelper.getECULogs(
        limit: 10000, // Max limit
        startDate: _startDate,
        endDate: _endDate,
      );

      if (allLogs.isEmpty) {
        Get.snackbar('Info', 'No data to export');
        return;
      }

      // Create CSV content
      final StringBuffer csvBuffer = StringBuffer();

      // Header
      csvBuffer.writeln('Timestamp,RPM,Speed (km/h),Water Temp (°C),Air Temp (°C),MAP (kPa),TPS (%),Battery (V),Ignition (°),Inject (ms),AFR,Short Trim (%),Long Trim (%),IACV');

      // Data rows
      for (var log in allLogs) {
        final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp);
        csvBuffer.writeln(
          '$formattedTime,${log.rpm},${log.speed},${log.waterTemp},${log.airTemp},${log.map},${log.tps},${log.battery},${log.ignition},${log.inject},${log.afr},${log.shortTrim},${log.longTrim},${log.iacv}',
        );
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/ecu_logs_$timestamp.csv');
      await file.writeAsString(csvBuffer.toString());

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ECU Data Logs (CSV)',
        text: 'Exported ${allLogs.length} ECU data records',
      );

      Get.snackbar(
        'Success',
        'Exported ${allLogs.length} records to CSV',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to export CSV: $e');
    }
  }

  Future<void> _exportToJSON() async {
    try {
      // Load all logs (without pagination)
      final allLogs = await _dbHelper.getECULogs(
        limit: 10000, // Max limit
        startDate: _startDate,
        endDate: _endDate,
      );

      if (allLogs.isEmpty) {
        Get.snackbar('Info', 'No data to export');
        return;
      }

      // Create JSON content
      final jsonData = {
        'exportDate': DateTime.now().toIso8601String(),
        'totalRecords': allLogs.length,
        'dateRange': {
          'start': _startDate?.toIso8601String(),
          'end': _endDate?.toIso8601String(),
        },
        'data': allLogs.map((log) => {
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp),
          'timestampMillis': log.timestamp.millisecondsSinceEpoch,
          'rpm': log.rpm,
          'speed': log.speed,
          'waterTemp': log.waterTemp,
          'airTemp': log.airTemp,
          'map': log.map,
          'tps': log.tps,
          'battery': log.battery,
          'ignition': log.ignition,
          'inject': log.inject,
          'afr': log.afr,
          'shortTrim': log.shortTrim,
          'longTrim': log.longTrim,
          'iacv': log.iacv,
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/ecu_logs_$timestamp.json');
      await file.writeAsString(jsonString);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ECU Data Logs (JSON)',
        text: 'Exported ${allLogs.length} ECU data records',
      );

      Get.snackbar(
        'Success',
        'Exported ${allLogs.length} records to JSON',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to export JSON: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Log History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'View Chart',
            onPressed: () {
              Get.to(() => DataLogChartScreen(
                    startDate: _startDate,
                    endDate: _endDate,
                  ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.drive_eta),
            tooltip: 'Select driving session',
            onPressed: _detectSessions,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Quick date filter',
            onPressed: _selectMonthQuickPick,
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear filter',
              onPressed: _clearDateFilter,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_all') {
                _deleteAllLogs();
              } else if (value == 'export_csv') {
                _exportToCSV();
              } else if (value == 'export_json') {
                _exportToJSON();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_json',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 8),
                    Text('Export JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Records: $_totalCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_startDate != null && _endDate != null)
                        Text(
                          '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Page ${_currentPage + 1} of ${(_totalCount / _pageSize).ceil()}'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0
                                ? () {
                                    setState(() => _currentPage--);
                                    _loadLogs();
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: (_currentPage + 1) * _pageSize < _totalCount
                                ? () {
                                    setState(() => _currentPage++);
                                    _loadLogs();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Log List or Session List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showSessions
                    ? _sessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'no_driving_sessions_found'.tr,
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                elevation: 3,
                                child: InkWell(
                                  onTap: () {
                                    // Navigate to chart view for this session
                                    Get.to(() => DataLogChartScreen(
                                      startDate: session['start'] as DateTime,
                                      endDate: session['end'] as DateTime,
                                    ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Session header
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    DateFormat('dd MMM yyyy, HH:mm')
                                                        .format(session['start'] as DateTime),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                 
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        // Statistics grid
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSessionStatCard(
                                                'max_speed'.tr,
                                                '${session['maxSpeed'].toStringAsFixed(0)}',
                                                'km/h',
                                                Icons.speed,
                                                Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildSessionStatCard(
                                                'max_rpm'.tr,
                                                '${session['maxRpm'].toStringAsFixed(0)}',
                                                'RPM',
                                                Icons.av_timer,
                                                Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSessionStatCard(
                                                'max_water_temp'.tr,
                                                '${session['maxWaterTemp'].toStringAsFixed(1)}',
                                                '°C',
                                                Icons.thermostat,
                                                Colors.deepOrange,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildSessionStatCard(
                                                'avg_speed'.tr,
                                                '${session['avgSpeed'].toStringAsFixed(0)}',
                                                'km/h',
                                                Icons.trending_up,
                                                Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSessionStatCard(
                                                'avg_rpm'.tr,
                                                '${session['avgRpm'].toStringAsFixed(0)}',
                                                'RPM',
                                                Icons.show_chart,
                                                Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildSessionStatCard(
                                                'record_count'.tr,
                                                '${session['count']}',
                                                'records'.tr,
                                                Icons.data_usage,
                                                Colors.purple,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                    : _logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No logs found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Enable Data Logging in Settings to start recording',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ExpansionTile(
                                  title: Text(
                                    _formatTimestamp(log.timestamp),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'RPM: ${log.rpm.toStringAsFixed(0)} | Speed: ${log.speed.toStringAsFixed(0)} km/h',
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          _buildDataRow('RPM', log.rpm.toStringAsFixed(0)),
                                          _buildDataRow('Speed', '${log.speed.toStringAsFixed(0)} km/h'),
                                          _buildDataRow('Water Temp', '${log.waterTemp.toStringAsFixed(1)}°C'),
                                          _buildDataRow('Air Temp', '${log.airTemp.toStringAsFixed(1)}°C'),
                                          _buildDataRow('MAP', '${log.map.toStringAsFixed(1)} kPa'),
                                          _buildDataRow('TPS', '${log.tps.toStringAsFixed(1)}%'),
                                          _buildDataRow('Battery', '${log.battery.toStringAsFixed(1)}V'),
                                          _buildDataRow('Ignition', '${log.ignition.toStringAsFixed(1)}°'),
                                          _buildDataRow('Inject', '${log.inject.toStringAsFixed(2)} ms'),
                                          _buildDataRow('AFR', log.afr.toStringAsFixed(2)),
                                          _buildDataRow('Short Trim', '${log.shortTrim.toStringAsFixed(1)}%'),
                                          _buildDataRow('Long Trim', '${log.longTrim.toStringAsFixed(1)}%'),
                                          _buildDataRow('IACV', '${log.iacv.toStringAsFixed(0)}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSessionStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:api_tech_moto/utils/logger.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ecu_data.dart';
import '../models/alert_threshold.dart';
import '../services/database_helper.dart';

class ECUDataController extends GetxController {
  final Rx<ECUData?> currentData = Rx<ECUData?>(null);
  final RxList<ECUData> dataHistory = <ECUData>[].obs;
  final RxBool isLogging = false.obs;

  // Alert system
  final RxList<AlertThreshold> alertThresholds = <AlertThreshold>[].obs;
  final RxBool isAlertActive = false.obs;
  final RxString activeAlertMessage = ''.obs;

  // Playback system
  final RxBool isPlaybackMode = false.obs;
  final RxBool isPlaying = false.obs;
  final RxList<ECUData> playbackLogs = <ECUData>[].obs;
  final RxInt playbackIndex = 0.obs;
  final RxDouble playbackSpeed = 1.0.obs;
  Timer? _playbackTimer;

  // Getter สำหรับข้อมูลที่แสดง (ใช้ playback data ถ้าอยู่ใน playback mode)
  ECUData? get displayData => isPlaybackMode.value
      ? (playbackLogs.isNotEmpty ? playbackLogs[playbackIndex.value] : null)
      : currentData.value;

  Timer? _loggingTimer;
  final Map<String, double> _dataBuffer = {}; // Buffer สำหรับเก็บข้อมูลที่รับมาทีละตัว
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Valid ECU parameter keys
  static const Set<String> _validKeys = {
    'TECHO', 'SPEED', 'WATER', 'AIR.T', 'MAP', 'TPS',
    'BATT', 'IGNITI', 'INJECT', 'AFR', 'S.TRIM', 'L.TRIM', 'IACV'
  };

  @override
  void onInit() {
    super.onInit();
    _loadAlertThresholds();
  }

  @override
  void onClose() {
    _loggingTimer?.cancel();
    _playbackTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadAlertThresholds() async {
    alertThresholds.value = await _dbHelper.getAllAlertThresholds();
  }

  // รับข้อมูลจาก Bluetooth (มาทีละตัว เช่น "TECHO=290")
  void updateDataFromBluetooth(String rawData) {
    try {
      // Validate input
      if (rawData.isEmpty) {
        logger.w('Empty data received');
        return;
      }

      // แยก key=value
      List<String> keyValue = rawData.trim().split('=');
      if (keyValue.length != 2) {
        logger.w('Invalid data format: $rawData');
        return;
      }

      String key = keyValue[0].trim().toUpperCase();

      // Validate key
      if (!_validKeys.contains(key)) {
        logger.w('Unknown ECU parameter: $key');
        return;
      }

      // Parse value
      double? value = double.tryParse(keyValue[1].trim());
      if (value == null) {
        logger.w('Invalid numeric value for $key: ${keyValue[1]}');
        return;
      }

      // Validate value bounds
      if (!_isValueInValidRange(key, value)) {
        logger.w('Value out of range for $key: $value');
        return;
      }

      // เก็บค่าลง buffer
      _dataBuffer[key] = value;

      // อัพเดท UI ทันทีแบบ real-time (ไม่รอ averaging timer)
      _updateUI();
    } catch (e) {
      logger.e('Error parsing ECU data: $e');
    }
  }

  // Validate ECU parameter values are within realistic ranges
  bool _isValueInValidRange(String key, double value) {
    switch (key) {
      case 'TECHO': // RPM
        return value >= 0 && value <= 20000;
      case 'SPEED': // km/h
        return value >= 0 && value <= 400;
      case 'WATER': // Water temp (°C)
        return value >= -40 && value <= 200;
      case 'AIR.T': // Air temp (°C)
        return value >= -40 && value <= 150;
      case 'MAP': // kPa
        return value >= 0 && value <= 300;
      case 'TPS': // %
        return value >= 0 && value <= 100;
      case 'BATT': // Volts
        return value >= 0 && value <= 20;
      case 'IGNITI': // Degrees
        return value >= -30 && value <= 60;
      case 'INJECT': // ms
        return value >= 0 && value <= 50;
      case 'AFR': // Air-Fuel Ratio
        return value >= 5 && value <= 25;
      case 'S.TRIM': // %
        return value >= 0 && value <= 200;
      case 'L.TRIM': // %
        return value >= 0 && value <= 200;
      case 'IACV': // %
        return value >= 0 && value <= 100;
      default:
        return true;
    }
  }

  // อัพเดท UI ทันทีทุกครั้งที่รับข้อมูล (real-time, no averaging timer)
  void _updateUI() {
    try {
      // สร้าง ECU Data object จาก buffer
      final newData = ECUData.fromJson(_dataBuffer);

      // อัพเดทค่าใหม่ - Rxn จะ trigger Obx โดยอัตโนมัติ
      currentData.value = newData;
      currentData.refresh(); // บังคับ refresh เพื่อให้แน่ใจว่า Obx จะ rebuild

      // Debug: ยืนยันว่า currentData อัพเดทแล้ว
      logger.d('ECU UI Updated - RPM: ${newData.rpm}, Speed: ${newData.speed}, Water: ${newData.waterTemp}');

      // เพิ่มลงใน history (จำกัด 100 รายการ)
      if (dataHistory.length >= 100) {
        dataHistory.removeAt(0);
      }
      dataHistory.add(newData);

      // ตรวจสอบ alerts
      _checkAlerts(newData);

      // บันทึกลง database ถ้าเปิด logging (async without blocking)
      if (isLogging.value) {
        _dbHelper.insertECUData(newData).catchError((error) {
          logger.e('Error saving to database: $error');
          return -1; // Return error indicator
        });
      }

      // ไม่ล้าง buffer เพื่อให้ค่าเก่ายังคงอยู่ (จะถูก overwrite ด้วยค่าใหม่)
    } catch (e) {
      logger.e('Error updating UI: $e');
    }
  }

  // ตรวจสอบ alerts
  void _checkAlerts(ECUData data) {
    isAlertActive.value = false;
    activeAlertMessage.value = '';

    for (var threshold in alertThresholds) {
      if (!threshold.enabled) continue;

      double? value;
      String paramName = '';

      switch (threshold.parameter) {
        case 'rpm':
          value = data.rpm;
          paramName = 'RPM';
          break;
        case 'waterTemp':
          value = data.waterTemp;
          paramName = 'Water Temp';
          break;
        case 'battery':
          value = data.battery;
          paramName = 'Battery';
          break;
        case 'tps':
          value = data.tps;
          paramName = 'TPS';
          break;
        case 'afr':
          value = data.afr;
          paramName = 'AFR';
          break;
      }

      if (value != null) {
        if (value < threshold.minValue || value > threshold.maxValue) {
          isAlertActive.value = true;
          activeAlertMessage.value =
              '$paramName: ${value.toStringAsFixed(1)} (${threshold.minValue}-${threshold.maxValue})';

          // เล่นเสียงแจ้งเตือน
          if (threshold.soundAlert) {
            _playAlertSound();
          }

          // แสดง popup
          if (threshold.popupAlert) {
            _showAlertPopup(paramName, value, threshold);
          }

          break;
        }
      }
    }
  }

  void _playAlertSound() {
    // เล่นเสียงแจ้งเตือน
    SystemSound.play(SystemSoundType.alert);
  }

  void _showAlertPopup(String paramName, double value, AlertThreshold threshold) {
    Get.snackbar(
      '⚠️ แจ้งเตือน',
      '$paramName: ${value.toStringAsFixed(1)} (ควรอยู่ระหว่าง ${threshold.minValue}-${threshold.maxValue})',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      shouldIconPulse: true,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
    );
  }


  // จัดการ Alert Thresholds
  Future<void> addAlertThreshold(AlertThreshold threshold) async {
    await _dbHelper.insertAlertThreshold(threshold);
    await _loadAlertThresholds();
  }

  Future<void> updateAlertThreshold(AlertThreshold threshold) async {
    await _dbHelper.updateAlertThreshold(threshold);
    await _loadAlertThresholds();
  }

  Future<void> deleteAlertThreshold(int id) async {
    await _dbHelper.deleteAlertThreshold(id);
    await _loadAlertThresholds();
  }

  // Data Logging
  void startLogging() {
    isLogging.value = true;
    // บันทึกทุก 1 วินาที
    _loggingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentData.value != null) {
        _dbHelper.insertECUData(currentData.value!).catchError((error) {
          logger.e('Error in periodic logging: $error');
          return -1;
        });
      }
    });
  }

  void stopLogging() {
    isLogging.value = false;
    _loggingTimer?.cancel();
    _loggingTimer = null;
  }

  // ดึงข้อมูล logs จาก database
  Future<List<ECUData>> getLogs({DateTime? startDate, DateTime? endDate}) async {
    return await _dbHelper.getECULogs(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ลบ logs
  Future<void> deleteLogsBefore(DateTime date) async {
    await _dbHelper.deleteECULogsBefore(date);
  }

  Future<void> deleteAllLogs() async {
    await _dbHelper.deleteAllECULogs();
  }

  // Export data เป็น CSV
  Future<String> exportToCsv({DateTime? startDate, DateTime? endDate}) async {
    List<ECUData> logs = await getLogs(startDate: startDate, endDate: endDate);

    StringBuffer csv = StringBuffer();

    // Header
    csv.writeln('Timestamp,RPM,Speed,Water Temp,Air Temp,MAP,TPS,Battery,Ignition,Inject,AFR,Short Trim,Long Trim,IACV');

    // Data rows
    for (var data in logs) {
      csv.writeln(
        '${data.timestamp.toIso8601String()},'
        '${data.rpm},'
        '${data.speed},'
        '${data.waterTemp},'
        '${data.airTemp},'
        '${data.map},'
        '${data.tps},'
        '${data.battery},'
        '${data.ignition},'
        '${data.inject},'
        '${data.afr},'
        '${data.shortTrim},'
        '${data.longTrim},'
        '${data.iacv}'
      );
    }

    return csv.toString();
  }

  // Export data เป็น JSON
  Future<String> exportToJson({DateTime? startDate, DateTime? endDate}) async {
    List<ECUData> logs = await getLogs(startDate: startDate, endDate: endDate);

    List<Map<String, dynamic>> jsonList = logs.map((data) => data.toJson()).toList();

    return jsonEncode(jsonList);
  }

  // Reset data
  void resetData() {
    currentData.value = null;
    dataHistory.clear();
    _dataBuffer.clear();
  }

  // ========== Playback System ==========

  // โหลด session สำหรับ playback
  Future<void> loadPlaybackSession(DateTime start, DateTime end) async {
    try {
      final logs = await _dbHelper.getECULogs(
        limit: 10000,
        startDate: start,
        endDate: end,
      );

      if (logs.isEmpty) {
        Get.snackbar(
          'ไม่พบข้อมูล',
          'ไม่มีข้อมูลในช่วงเวลาที่เลือก',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // เรียงตาม timestamp จากเก่าไปใหม่ (สำหรับ playback)
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      playbackLogs.value = logs;
      playbackIndex.value = 0;
      isPlaybackMode.value = true;
      isPlaying.value = false;

      logger.d('Loaded ${logs.length} records for playback');
    } catch (e) {
      logger.e('Error loading playback session: $e');
      Get.snackbar(
        'Error',
        'Failed to load session: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // เล่น playback
  void playPlayback() {
    if (playbackLogs.isEmpty) return;

    isPlaying.value = true;

    // คำนวณ interval ตาม playback speed
    final intervalMs = (200 / playbackSpeed.value).round();

    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (playbackIndex.value < playbackLogs.length - 1) {
        playbackIndex.value++;
      } else {
        // จบ playback
        pausePlayback();
      }
    });
  }

  // หยุด playback
  void pausePlayback() {
    isPlaying.value = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  // เลื่อนไปยังตำแหน่งที่ต้องการ
  void seekPlayback(int index) {
    if (index >= 0 && index < playbackLogs.length) {
      playbackIndex.value = index;
    }
  }

  // ปรับความเร็ว playback
  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;

    // ถ้ากำลังเล่นอยู่ ให้ restart ด้วย speed ใหม่
    if (isPlaying.value) {
      pausePlayback();
      playPlayback();
    }
  }

  // ออกจาก playback mode
  void exitPlayback() {
    pausePlayback();
    isPlaybackMode.value = false;
    playbackLogs.clear();
    playbackIndex.value = 0;
    playbackSpeed.value = 1.0;
  }

  // ดึงรายการ sessions จาก database
  Future<List<Map<String, dynamic>>> getPlaybackSessions() async {
    try {
      final allLogs = await _dbHelper.getECULogs(limit: 10000);

      if (allLogs.isEmpty) return [];

      // เรียงตาม timestamp
      allLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

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

      // เรียงจากใหม่ไปเก่า
      sessions.sort((a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));

      return sessions;
    } catch (e) {
      logger.e('Error getting playback sessions: $e');
      return [];
    }
  }

  Map<String, dynamic> _calculateSessionStats(List<ECUData> sessionData) {
    double maxSpeed = 0;
    double maxRpm = 0;
    double maxWaterTemp = 0;

    for (var data in sessionData) {
      if (data.speed > maxSpeed) maxSpeed = data.speed;
      if (data.rpm > maxRpm) maxRpm = data.rpm;
      if (data.waterTemp > maxWaterTemp) maxWaterTemp = data.waterTemp;
    }

    final duration = sessionData.last.timestamp.difference(sessionData.first.timestamp);

    return {
      'start': sessionData.first.timestamp,
      'end': sessionData.last.timestamp,
      'count': sessionData.length,
      'maxSpeed': maxSpeed,
      'maxRpm': maxRpm,
      'maxWaterTemp': maxWaterTemp,
      'duration': duration,
    };
  }
}
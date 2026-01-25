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

  Timer? _loggingTimer;
  final Map<String, double> _dataBuffer = {}; // Buffer สำหรับเก็บข้อมูลที่รับมาทีละตัว
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Averaging system
  final Map<String, List<double>> _averagingBuffer = {};
  Timer? _averagingTimer;
  final Duration _averagingInterval = const Duration(seconds: 1); // คำนวณค่าเฉลี่ยทุก 1 วินาที

  // Lerp smoothing system
  final Map<String, double> _smoothedValues = {};
  final double _alpha = 0.1; // ค่าความสมูท (0.05 = นุ่มมาก, 0.2 = ตอบสนองไว)

  // Valid ECU parameter keys
  static const Set<String> _validKeys = {
    'TECHO', 'SPEED', 'WATER', 'AIR.T', 'MAP', 'TPS',
    'BATT', 'IGNITI', 'INJECT', 'AFR', 'S.TRIM', 'L.TRIM', 'IACV'
  };

  @override
  void onInit() {
    super.onInit();
    _loadAlertThresholds();
    _startAveragingTimer();
  }

  @override
  void onClose() {
    _loggingTimer?.cancel();
    _stopAveragingTimer();
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

      // เก็บค่าลง buffer (ไว้ใช้คำนวณค่าเฉลี่ย)
      _dataBuffer[key] = value;

      // เพิ่มค่าลง averaging buffer
      if (!_averagingBuffer.containsKey(key)) {
        _averagingBuffer[key] = [];
      }
      _averagingBuffer[key]!.add(value);

      // **ไม่เรียก _updateUI() ทันที** - จะอัพเดทผ่าน Timer แทน
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

  // อัพเดท UI ทันทีทุกครั้งที่รับข้อมูล
  // void _updateUI() {
  //   try {
  //     // สร้าง ECU Data object จาม buffer
  //     ECUData newData = ECUData.fromJson(_dataBuffer);
  //     currentData.value = newData;
  //     currentData.refresh(); // บังคับให้ GetX update listeners ทั้งหมด

  //     // เพิ่มลงใน history
  //     dataHistory.add(newData);

  //     // จำกัดขนาด history (เก็บแค่ 1000 รายการล่าสุด)
  //     if (dataHistory.length > 1000) {
  //       dataHistory.removeAt(0);
  //     }

  //     // ตรวจสอบ alerts
  //     _checkAlerts(newData);

  //     // บันทึกลง database ถ้าเปิด logging (async without blocking)
  //     if (isLogging.value) {
  //       _dbHelper.insertECUData(newData).catchError((error) {
  //         logger.e('Error saving to database: $error');
  //         return -1; // Return error indicator
  //       });
  //     }

  //     // ไม่ล้าง buffer เพื่อให้ค่าเก่ายังคงอยู่ (จะถูก overwrite ด้วยค่าใหม่)
  //   } catch (e) {
  //     logger.e('Error updating UI: $e');
  //   }
  // }

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

  // Averaging & Lerp Smoothing System
  void _calculateAndUpdateAveragedData() {
    try {
      if (_averagingBuffer.isEmpty) {
        logger.d('No data to average');
        return;
      }

      Map<String, double> smoothedValues = {};

      // คำนวณค่าเฉลี่ย + Lerp smoothing ของแต่ละ parameter
      _averagingBuffer.forEach((key, values) {
        if (values.isNotEmpty) {
          // Step 1: คำนวณค่าเฉลี่ย (Averaging)
          double sum = values.reduce((a, b) => a + b);
          double averagedValue = sum / values.length;

          // Step 2: Apply Lerp smoothing
          // สูตร: displayValue = displayValue + (alpha * (targetValue - displayValue))
          double currentSmoothed = _smoothedValues[key] ?? averagedValue; // ค่าปัจจุบัน
          double newSmoothed = currentSmoothed + (_alpha * (averagedValue - currentSmoothed));

          // เก็บค่า smoothed ไว้ใช้ในรอบถัดไป
          _smoothedValues[key] = newSmoothed;
          smoothedValues[key] = newSmoothed;

          logger.d('$key: ${values.length} samples → avg: ${averagedValue.toStringAsFixed(2)} → smoothed: ${newSmoothed.toStringAsFixed(2)}');
        }
      });

      // อัพเดท currentData ด้วยค่าที่ผ่าน Lerp แล้ว
      if (smoothedValues.isNotEmpty) {
        ECUData smoothedData = ECUData.fromJson(smoothedValues);
        currentData.value = smoothedData;  // อัพเดท currentData
        currentData.refresh();

        // เพิ่มลง history
        dataHistory.add(smoothedData);
        if (dataHistory.length > 100) {
          dataHistory.removeAt(0);
        }

        // ตรวจสอบ alerts
        _checkAlerts(smoothedData);

        // บันทึกลง database ถ้าเปิด logging
        if (isLogging.value) {
          _dbHelper.insertECUData(smoothedData);
        }

        logger.i('Smoothed data updated: ${smoothedValues.length} parameters');
      }

      // ล้าง averaging buffer (แต่ไม่ล้าง _smoothedValues)
      _averagingBuffer.clear();

    } catch (e) {
      logger.e('Error calculating smoothed data', error: e);
    }
  }

  void _startAveragingTimer() {
    _averagingTimer?.cancel();

    _averagingTimer = Timer.periodic(_averagingInterval, (timer) {
      _calculateAndUpdateAveragedData();
    });

    logger.i('Averaging timer started (interval: ${_averagingInterval.inSeconds}s)');
  }

  void _stopAveragingTimer() {
    _averagingTimer?.cancel();
    _averagingTimer = null;
    _averagingBuffer.clear();

    logger.i('Averaging timer stopped');
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
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:api_tech_moto/utils/logger.dart';
import 'package:get/get.dart';
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
  Timer? _debounceTimer;
  final Map<String, double> _dataBuffer = {}; // Buffer สำหรับเก็บข้อมูลที่รับมาทีละตัว
  bool _isProcessing = false; // Thread-safety flag
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // จำนวนฟิลด์ทั้งหมดที่ต้องรับครบ
  static const int _expectedFieldCount = 13;

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
    _debounceTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadAlertThresholds() async {
    alertThresholds.value = await _dbHelper.getAllAlertThresholds();
  }

  // รับข้อมูลจาก Bluetooth (มาทีละตัว เช่น "TECHO=290")
  void updateDataFromBluetooth(String rawData) {
    // Prevent concurrent access
    if (_isProcessing) {
      logger.w('Skipping data update - already processing');
      return;
    }

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

      // ถ้าครบ 13 ค่าแล้ว -> อัพเดท UI
      if (_dataBuffer.length >= _expectedFieldCount) {
        _updateUI();
      } else {
        // ยังไม่ครบ -> ตั้ง timeout กันข้อมูลค้าง
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 200), () {
          // ถ้าเกิน 200ms ยังไม่มีข้อมูลใหม่ -> อัพเดทแม้ยังไม่ครบ
          if (_dataBuffer.isNotEmpty) {
            _updateUI();
          }
        });
      }
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

  // อัพเดท UI เมื่อรับข้อมูลครบแล้ว
  void _updateUI() {
    _isProcessing = true;
    try {
      // สร้าง ECU Data object จาก buffer
      ECUData newData = ECUData.fromJson(_dataBuffer);
      currentData.value = newData;

      // เพิ่มลงใน history
      dataHistory.add(newData);

      // จำกัดขนาด history (เก็บแค่ 1000 รายการล่าสุด)
      if (dataHistory.length > 1000) {
        dataHistory.removeAt(0);
      }

      // ตรวจสอบ alerts
      _checkAlerts(newData);

      // บันทึกลง database ถ้าเปิด logging (async without blocking)
      if (isLogging.value) {
        _dbHelper.insertECUData(newData).catchError((error) {
          logger.e('Error saving to database: $error');
          return -1; // Return error indicator
        });
      }

      // ล้าง buffer เพื่อรอรับชุดใหม่
      _dataBuffer.clear();
      _debounceTimer?.cancel();
    } catch (e) {
      logger.e('Error updating UI: $e');
    } finally {
      _isProcessing = false;
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
            // _showAlertPopup(paramName, value, threshold);
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

  // void _showAlertPopup(String paramName, double value, AlertThreshold threshold) {
  //   Get.snackbar(
  //     '⚠️ แจ้งเตือน',
  //     '$paramName: ${value.toStringAsFixed(1)} (ควรอยู่ระหว่าง ${threshold.minValue}-${threshold.maxValue})',
  //     snackPosition: SnackPosition.TOP,
  //     duration: const Duration(seconds: 3),
  //     backgroundColor: Get.theme.colorScheme.error.withValues(alpha: .9),
  //     colorText: Get.theme.colorScheme.onError,
  //   );
  // }

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
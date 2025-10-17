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

  Timer? loggingTimer;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void onInit() {
    super.onInit();
    _loadAlertThresholds();
  }

  @override
  void onClose() {
    loggingTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadAlertThresholds() async {
    alertThresholds.value = await _dbHelper.getAllAlertThresholds();
  }

  // รับข้อมูลจาก Bluetooth
  void updateDataFromBluetooth(String rawData) {
    try {
      // แปลงข้อมูลจาก String เป็น Map
      // รูปแบบตัวอย่าง: "TECHO=15000,SPEED=255,WATER=150,..."
      Map<String, dynamic> dataMap = {};

      List<String> pairs = rawData.split(',');
      for (var pair in pairs) {
        List<String> keyValue = pair.split('=');
        if (keyValue.length == 2) {
          String key = keyValue[0].trim();
          double value = double.tryParse(keyValue[1].trim()) ?? 0.0;
          dataMap[key] = value;
        }
      }

      // สร้าง ECU Data object
      ECUData newData = ECUData.fromJson(dataMap);
      currentData.value = newData;

      // เพิ่มลงใน history
      dataHistory.add(newData);

      // จำกัดขนาด history (เก็บแค่ 1000 รายการล่าสุด)
      if (dataHistory.length > 1000) {
        dataHistory.removeAt(0);
      }

      // ตรวจสอบ alerts
      _checkAlerts(newData);

      // บันทึกลง database ถ้าเปิด logging
      if (isLogging.value) {
        _dbHelper.insertECUData(newData);
      }
    } catch (e) {
      logger.e('Error parsing ECU data: $e');
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

  void _showAlertPopup(String paramName, double value, AlertThreshold threshold) {
    Get.snackbar(
      '⚠️ แจ้งเตือน',
      '$paramName: ${value.toStringAsFixed(1)} (ควรอยู่ระหว่าง ${threshold.minValue}-${threshold.maxValue})',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Get.theme.colorScheme.error.withValues(alpha: .9),
      colorText: Get.theme.colorScheme.onError,
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
    loggingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentData.value != null) {
        _dbHelper.insertECUData(currentData.value!);
      }
    });
  }

  void stopLogging() {
    isLogging.value = false;
    loggingTimer?.cancel();
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

  // สร้างข้อมูล dummy สำหรับ testing (สามารถลบได้)
  void generateDummyData() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick > 30) {
        timer.cancel();
        return;
      }

      // RPM เพิ่มทีละ 500 (0, 500, 1000, 1500, ...)
      int rpm = timer.tick * 500;

      // สร้างข้อมูลแบบเรียงลำดับ
      String dummyData =
        'TECHO=$rpm,'
        'SPEED=${(timer.tick * 5).toString()},'
        'WATER=${(80 + timer.tick).toString()},'
        'AIR.T=${(30 + timer.tick).toString()},'
        'MAP=${(100 + timer.tick).toString()},'
        'TPS=${(timer.tick * 2).toString()},'
        'BATT=13.5,'
        'IGNITI=${(15 + timer.tick * 0.5).toString()},'
        'INJECT=${(5 + timer.tick * 0.2).toString()},'
        'AFR=14.7,'
        'S.TRIM=100,'
        'L.TRIM=100,'
        'IACV=50';

      updateDataFromBluetooth(dummyData);
    });
  }

  // Reset data
  void resetData() {
    currentData.value = null;
    dataHistory.clear();
  }
}
import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/performance_test.dart';
import '../services/database_helper.dart';
import '../services/permission_service.dart';
import 'ecu_data_controller.dart';
import 'settings_controller.dart';

class PerformanceTestController extends GetxController {
  final RxBool isTestRunning = false.obs;
  final RxString currentTestType = ''.obs;
  final RxString selectedTestType = ''.obs;
  final RxDouble currentDistance = 0.0.obs;
  final RxDouble currentTime = 0.0.obs;
  final RxDouble currentSpeed = 0.0.obs;
  final RxDouble maxSpeed = 0.0.obs;

  // Alias for compatibility
  RxBool get isTestActive => isTestRunning;

  Position? _startPosition;
  DateTime? _startTime;
  Timer? _testTimer;
  StreamSubscription<Position>? _positionSubscription;

  // ECU tracking variables
  int? _ecuSessionStart;
  double _maxRpm = 0.0;
  double _sumRpm = 0.0;
  double _maxWaterTemp = 0.0;
  double _sumWaterTemp = 0.0;
  double _maxTps = 0.0;
  double _sumTps = 0.0;
  double _maxAfr = 0.0;
  double _sumAfr = 0.0;
  double _minBattery = double.infinity;
  double _sumBattery = 0.0;
  int _ecuSampleCount = 0;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final RxList<PerformanceTest> testHistory = <PerformanceTest>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadTestHistory();
  }

  @override
  void onClose() {
    stopTest();
    super.onClose();
  }

  Future<void> _loadTestHistory() async {
    final tests = await _dbHelper.getAllPerformanceTests();
    print('DEBUG _loadTestHistory: Loaded ${tests.length} tests from DB');
    for (var t in tests) {
      print('  - ${t.testType}: ${t.time}s, ${t.distance}m');
    }
    testHistory.value = tests;
    testHistory.refresh(); // บังคับ refresh reactive list
  }

  /// Public method สำหรับ reload history จากภายนอก
  Future<void> loadTestHistory() async {
    await _loadTestHistory();
  }

  void selectTestType(String testType) {
    selectedTestType.value = testType;
  }

  void _resetEcuTracking() {
    _ecuSessionStart = null;
    _maxRpm = 0.0;
    _sumRpm = 0.0;
    _maxWaterTemp = 0.0;
    _sumWaterTemp = 0.0;
    _maxTps = 0.0;
    _sumTps = 0.0;
    _maxAfr = 0.0;
    _sumAfr = 0.0;
    _minBattery = double.infinity;
    _sumBattery = 0.0;
    _ecuSampleCount = 0;
  }

  void _trackEcuData() {
    final ecuController = Get.find<ECUDataController>();
    final data = ecuController.currentData.value;
    if (data == null) return;

    _ecuSampleCount++;

    // RPM
    if (data.rpm > _maxRpm) _maxRpm = data.rpm;
    _sumRpm += data.rpm;

    // Water Temp
    if (data.waterTemp > _maxWaterTemp) _maxWaterTemp = data.waterTemp;
    _sumWaterTemp += data.waterTemp;

    // TPS
    if (data.tps > _maxTps) _maxTps = data.tps;
    _sumTps += data.tps;

    // AFR
    if (data.afr > _maxAfr) _maxAfr = data.afr;
    _sumAfr += data.afr;

    // Battery (min)
    if (data.battery < _minBattery) _minBattery = data.battery;
    _sumBattery += data.battery;
  }

  Map<String, double?> _getEcuSummary() {
    if (_ecuSampleCount == 0) {
      return {
        'maxRpm': null,
        'avgRpm': null,
        'maxWaterTemp': null,
        'avgWaterTemp': null,
        'maxTps': null,
        'avgTps': null,
        'maxAfr': null,
        'avgAfr': null,
        'minBattery': null,
        'avgBattery': null,
      };
    }

    return {
      'maxRpm': _maxRpm,
      'avgRpm': _sumRpm / _ecuSampleCount,
      'maxWaterTemp': _maxWaterTemp,
      'avgWaterTemp': _sumWaterTemp / _ecuSampleCount,
      'maxTps': _maxTps,
      'avgTps': _sumTps / _ecuSampleCount,
      'maxAfr': _maxAfr,
      'avgAfr': _sumAfr / _ecuSampleCount,
      'minBattery': _minBattery == double.infinity ? null : _minBattery,
      'avgBattery': _sumBattery / _ecuSampleCount,
    };
  }

  // ใช้ GPS สำหรับการทดสอบ (ขอ permission ตอนกด START)
  Future<void> startTest(String testType) async {
    if (isTestRunning.value) return;

    // ขอ permission location
    final permissionService = PermissionService.instance;
    final hasPermission = await permissionService.requestLocationPermissions();

    if (!hasPermission) {
      Get.snackbar(
        'permission_required'.tr,
        'location_permission_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // ตั้งค่า state ทันที
    isTestRunning.value = true;
    currentTestType.value = testType;
    selectedTestType.value = testType;
    currentDistance.value = 0.0;
    currentTime.value = 0.0;
    currentSpeed.value = 0.0;
    maxSpeed.value = 0.0;

    // Reset ECU tracking
    _resetEcuTracking();
    _ecuSessionStart = DateTime.now().millisecondsSinceEpoch;

    // เริ่ม ECU logging อัตโนมัติ
    final ecuController = Get.find<ECUDataController>();
    if (!ecuController.isLogging.value) {
      ecuController.startLogging();
    }

    // Navigate ไป Dashboard ทันที (ไม่ต้องรอ GPS)
    final settingsController = Get.find<SettingsController>();
    Get.offAllNamed(settingsController.getDashboardRoute());

    // ดึงตำแหน่ง GPS แบบ background (ใช้ medium accuracy เพื่อให้เร็วขึ้น)
    try {
      _startPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'cannot_get_gps'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      isTestRunning.value = false;
      return;
    }

    _startTime = DateTime.now();

    // เริ่มจับเวลา
    _testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_startTime != null) {
        currentTime.value =
            DateTime.now().difference(_startTime!).inMilliseconds / 1000;
        // Track ECU data every 100ms
        _trackEcuData();
      }
    });

    // ติดตามตำแหน่ง GPS
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position position) {
    if (_startPosition == null) return;

    // คำนวณระยะทาง
    double distance = Geolocator.distanceBetween(
      _startPosition!.latitude,
      _startPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    currentDistance.value = distance;
    currentSpeed.value = position.speed * 3.6; // แปลง m/s เป็น km/h

    // บันทึกความเร็วสูงสุด
    if (currentSpeed.value > maxSpeed.value) {
      maxSpeed.value = currentSpeed.value;
    }

    // ตรวจสอบว่าถึงเป้าหมายหรือยัง
    double targetDistance = _getTargetDistance(currentTestType.value);
    if (distance >= targetDistance) {
      _completeTest();
    }
  }

  double _getTargetDistance(String testType) {
    switch (testType) {
      case '0-100m':
        return 100.0;
      case '0-201m':
        return 201.0;
      case '0-402m':
        return 402.0;
      case '0-1000m':
        return 1000.0;
      default:
        return 100.0;
    }
  }

  Future<void> _completeTest() async {
    if (!isTestRunning.value) return;

    // เก็บค่า ECU ก่อน stopTest
    final ecuSummary = _getEcuSummary();
    final sessionStart = _ecuSessionStart;
    final sessionEnd = DateTime.now().millisecondsSinceEpoch;

    // เก็บค่าอื่นๆ
    final testType = currentTestType.value;
    final distance = currentDistance.value;
    final time = currentTime.value;
    final speed = maxSpeed.value;

    stopTest();

    // คำนวณความเร็วเฉลี่ย (ป้องกัน division by zero)
    double avgSpeed = 0.0;
    if (time > 0) {
      avgSpeed = (distance / time) * 3.6;
    }

    // สร้าง PerformanceTest object พร้อม ECU data
    PerformanceTest test = PerformanceTest(
      testType: testType,
      distance: distance,
      time: time,
      maxSpeed: speed,
      avgSpeed: avgSpeed,
      timestamp: DateTime.now(),
      ecuSessionStart: sessionStart,
      ecuSessionEnd: sessionEnd,
      maxRpm: ecuSummary['maxRpm'],
      avgRpm: ecuSummary['avgRpm'],
      maxWaterTemp: ecuSummary['maxWaterTemp'],
      avgWaterTemp: ecuSummary['avgWaterTemp'],
      maxTps: ecuSummary['maxTps'],
      avgTps: ecuSummary['avgTps'],
      maxAfr: ecuSummary['maxAfr'],
      avgAfr: ecuSummary['avgAfr'],
      minBattery: ecuSummary['minBattery'],
      avgBattery: ecuSummary['avgBattery'],
    );

    // บันทึกลง database
    await _dbHelper.insertPerformanceTest(test);
    await _loadTestHistory();

    // แสดงผลลัพธ์
    Get.snackbar(
      'completed'.tr,
      '${'distance'.tr}: ${distance.toStringAsFixed(2)} ${'m'.tr}\n'
      '${'time'.tr}: ${time.toStringAsFixed(2)} ${'seconds'.tr}\n'
      '${'max_speed'.tr}: ${speed.toStringAsFixed(2)} km/h',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> stopTest({bool saveResult = false}) async {
    // เก็บค่าไว้ก่อน reset (สำหรับบันทึก)
    final testType = currentTestType.value;
    final distance = currentDistance.value;
    final time = currentTime.value;
    final speed = maxSpeed.value;
    final wasRunning = isTestRunning.value;

    // เก็บค่า ECU ก่อน reset
    final ecuSummary = _getEcuSummary();
    final sessionStart = _ecuSessionStart;
    final sessionEnd = DateTime.now().millisecondsSinceEpoch;

    // หยุดการทดสอบ
    isTestRunning.value = false;
    _testTimer?.cancel();
    _positionSubscription?.cancel();

    // หยุด ECU logging ด้วย
    final ecuController = Get.find<ECUDataController>();
    if (ecuController.isLogging.value) {
      ecuController.stopLogging();
    }

    _testTimer = null;
    _positionSubscription = null;
    _startPosition = null;
    _startTime = null;

    // บันทึกผลลัพธ์ (ใช้ค่าที่เก็บไว้)
    if (saveResult && wasRunning && time > 0) {
      await _saveTestResult(
        testType: testType,
        distance: distance,
        time: time,
        maxSpeed: speed,
        ecuSummary: ecuSummary,
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
      );
    }
  }

  Future<void> _saveTestResult({
    required String testType,
    required double distance,
    required double time,
    required double maxSpeed,
    Map<String, double?>? ecuSummary,
    int? sessionStart,
    int? sessionEnd,
  }) async {
    // คำนวณความเร็วเฉลี่ย (ป้องกัน division by zero)
    double avgSpeed = 0.0;
    if (time > 0) {
      avgSpeed = (distance / time) * 3.6;
    }

    // สร้าง PerformanceTest object พร้อม ECU data
    PerformanceTest test = PerformanceTest(
      testType: testType,
      distance: distance,
      time: time,
      maxSpeed: maxSpeed,
      avgSpeed: avgSpeed,
      timestamp: DateTime.now(),
      note: 'cancelled'.tr,
      ecuSessionStart: sessionStart,
      ecuSessionEnd: sessionEnd,
      maxRpm: ecuSummary?['maxRpm'],
      avgRpm: ecuSummary?['avgRpm'],
      maxWaterTemp: ecuSummary?['maxWaterTemp'],
      avgWaterTemp: ecuSummary?['avgWaterTemp'],
      maxTps: ecuSummary?['maxTps'],
      avgTps: ecuSummary?['avgTps'],
      maxAfr: ecuSummary?['maxAfr'],
      avgAfr: ecuSummary?['avgAfr'],
      minBattery: ecuSummary?['minBattery'],
      avgBattery: ecuSummary?['avgBattery'],
    );

    // บันทึกลง database
    await _dbHelper.insertPerformanceTest(test);
    await _loadTestHistory();

    // แสดงผลลัพธ์
    Get.snackbar(
      'test_stopped'.tr,
      '${'distance'.tr}: ${distance.toStringAsFixed(2)} ${'m'.tr}\n'
      '${'time'.tr}: ${time.toStringAsFixed(2)} ${'seconds'.tr}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> deleteTest(int id) async {
    await _dbHelper.deletePerformanceTest(id);
    await _loadTestHistory();
  }

  List<PerformanceTest> getTestsByType(String testType) {
    return testHistory.where((test) => test.testType == testType).toList();
  }

  // ใช้ความเร็วจาก ECU แทน GPS (ถ้ามี)
  void startTestWithECUSpeed(String testType) {
    if (isTestRunning.value) return;

    isTestRunning.value = true;
    currentTestType.value = testType;
    currentDistance.value = 0.0;
    currentTime.value = 0.0;
    currentSpeed.value = 0.0;
    maxSpeed.value = 0.0;

    _startTime = DateTime.now();

    // เริ่มจับเวลา
    _testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_startTime != null) {
        currentTime.value =
            DateTime.now().difference(_startTime!).inMilliseconds / 1000;

        // ดึงความเร็วจาก ECUDataController
        final ecuController = Get.find<ECUDataController>();
        if (ecuController.currentData.value != null) {
          currentSpeed.value = ecuController.currentData.value!.speed;

          // คำนวณระยะทางจากความเร็ว (ใช้สูตร v = s/t)
          // s = v * t (แปลง km/h เป็น m/s แล้วคูณด้วยเวลา)
          double speedInMps = currentSpeed.value / 3.6;
          currentDistance.value += speedInMps * 0.1; // เพิ่มทุก 0.1 วินาที

          // บันทึกความเร็วสูงสุด
          if (currentSpeed.value > maxSpeed.value) {
            maxSpeed.value = currentSpeed.value;
          }

          // ตรวจสอบว่าถึงเป้าหมายหรือยัง
          double targetDistance = _getTargetDistance(currentTestType.value);
          if (currentDistance.value >= targetDistance) {
            _completeTest();
          }
        }
      }
    });
  }
}
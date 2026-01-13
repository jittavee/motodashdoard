import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/performance_test.dart';
import '../services/database_helper.dart';
import '../services/permission_service.dart';
import 'ecu_data_controller.dart';

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
    testHistory.value = await _dbHelper.getAllPerformanceTests();
  }

  void selectTestType(String testType) {
    selectedTestType.value = testType;
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

    isTestRunning.value = true;
    currentTestType.value = testType;
    selectedTestType.value = testType;
    currentDistance.value = 0.0;
    currentTime.value = 0.0;
    currentSpeed.value = 0.0;
    maxSpeed.value = 0.0;

    // บันทึกตำแหน่งเริ่มต้น
    try {
      _startPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
      case '201m':
        return 201.0;
      case '402m':
        return 402.0;
      case '1000m':
        return 1000.0;
      default:
        return 100.0;
    }
  }

  Future<void> _completeTest() async {
    if (!isTestRunning.value) return;

    stopTest();

    // คำนวณความเร็วเฉลี่ย (ป้องกัน division by zero)
    double avgSpeed = 0.0;
    if (currentTime.value > 0) {
      avgSpeed = (currentDistance.value / currentTime.value) * 3.6;
    }

    // สร้าง PerformanceTest object
    PerformanceTest test = PerformanceTest(
      testType: currentTestType.value,
      distance: currentDistance.value,
      time: currentTime.value,
      maxSpeed: maxSpeed.value,
      avgSpeed: avgSpeed,
      timestamp: DateTime.now(),
    );

    // บันทึกลง database
    await _dbHelper.insertPerformanceTest(test);
    await _loadTestHistory();

    // แสดงผลลัพธ์
    Get.snackbar(
      'completed'.tr,
      '${'distance'.tr}: ${currentDistance.value.toStringAsFixed(2)} ${'m'.tr}\n'
      '${'time'.tr}: ${currentTime.value.toStringAsFixed(2)} ${'seconds'.tr}\n'
      '${'max_speed'.tr}: ${maxSpeed.value.toStringAsFixed(2)} km/h',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  void stopTest() {
    isTestRunning.value = false;
    _testTimer?.cancel();
    _positionSubscription?.cancel();

    _testTimer = null;
    _positionSubscription = null;
    _startPosition = null;
    _startTime = null;
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
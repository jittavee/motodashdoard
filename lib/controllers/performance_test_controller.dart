import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/performance_test.dart';
import '../services/database_helper.dart';
import 'ecu_data_controller.dart';

class PerformanceTestController extends GetxController {
  final RxBool isTestRunning = false.obs;
  final RxString currentTestType = ''.obs;
  final RxDouble currentDistance = 0.0.obs;
  final RxDouble currentTime = 0.0.obs;
  final RxDouble currentSpeed = 0.0.obs;
  final RxDouble maxSpeed = 0.0.obs;

  Position? startPosition;
  DateTime? startTime;
  Timer? testTimer;
  StreamSubscription<Position>? positionSubscription;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final RxList<PerformanceTest> testHistory = <PerformanceTest>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadTestHistory();
    _checkLocationPermission();
  }

  @override
  void onClose() {
    stopTest();
    super.onClose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Location', 'กรุณาเปิด Location Service');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Permission', 'ไม่มีสิทธิ์เข้าถึง Location');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Permission', 'กรุณาอนุญาตการเข้าถึง Location ในการตั้งค่า');
      return;
    }
  }

  Future<void> _loadTestHistory() async {
    testHistory.value = await _dbHelper.getAllPerformanceTests();
  }

  Future<void> startTest(String testType) async {
    if (isTestRunning.value) return;

    // ตรวจสอบ permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _checkLocationPermission();
      return;
    }

    isTestRunning.value = true;
    currentTestType.value = testType;
    currentDistance.value = 0.0;
    currentTime.value = 0.0;
    currentSpeed.value = 0.0;
    maxSpeed.value = 0.0;

    // บันทึกตำแหน่งเริ่มต้น
    startPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    startTime = DateTime.now();

    // เริ่มจับเวลา
    testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (startTime != null) {
        currentTime.value =
            DateTime.now().difference(startTime!).inMilliseconds / 1000;
      }
    });

    // ติดตามตำแหน่ง
    positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position position) {
    if (startPosition == null) return;

    // คำนวณระยะทาง
    double distance = Geolocator.distanceBetween(
      startPosition!.latitude,
      startPosition!.longitude,
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

    // คำนวณความเร็วเฉลี่ย
    double avgSpeed = (currentDistance.value / currentTime.value) * 3.6;

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
      'เสร็จสิ้น!',
      'ระยะทาง: ${currentDistance.value.toStringAsFixed(2)} ม.\n'
      'เวลา: ${currentTime.value.toStringAsFixed(2)} วินาที\n'
      'ความเร็วสูงสุด: ${maxSpeed.value.toStringAsFixed(2)} km/h',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  void stopTest() {
    isTestRunning.value = false;
    testTimer?.cancel();
    positionSubscription?.cancel();

    startPosition = null;
    startTime = null;
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

    startTime = DateTime.now();

    // เริ่มจับเวลา
    testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (startTime != null) {
        currentTime.value =
            DateTime.now().difference(startTime!).inMilliseconds / 1000;

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
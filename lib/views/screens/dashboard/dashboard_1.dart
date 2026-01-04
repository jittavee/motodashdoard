import 'dart:math';
import 'package:api_tech_moto/models/ecu_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../widgets/bluetooth_button.dart';
import '../../widgets/settings_button.dart';

class TemplateOneScreen extends StatefulWidget {
  const TemplateOneScreen({super.key});

  @override
  State<TemplateOneScreen> createState() => _TemplateOneScreenState();
}

class _TemplateOneScreenState extends State<TemplateOneScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setLandscape();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setLandscape();
    }
  }

  void _setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.find<ECUDataController>();

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            return Stack(
              children: [

                // TPS Progress Bar (below image)
                Positioned(
                  bottom: screenHeight * 0.2 - 5, // ต่ำกว่ารูปเล็กน้อย
                  right: screenWidth * 0.2 - 21,
                  child: Obx(() {
                    final tps = ecuController.currentData.value?.tps ?? 0;
                    return Container(
                      width: screenWidth * .140, // ความกว้าง
                      height: 15, // ความสูง (เรียวกว่าเดิม)
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                      child: _buildTPSProgressBar(tps),
                    );
                  }),
                ),
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/ui-1/background.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // Main Gauge (RPM) - ใช้สัดส่วนจากขนาดจอ
                Positioned(
                  top: screenHeight * 0.53, // 53% จากด้านบน
                  left:
                      screenWidth * 0.5 - 35, // ดึงจากตรงกลางแนวนอนไปทางซ้าย 35
                  child: Obx(() {
                    final rpm = ecuController.currentData.value?.rpm ?? 0;
                    return _buildRotatingNeedleGauge(
                      value: rpm, // ค่าปัจจุบันของ RPM
                      maxValue: 15000,
                      size: 85,
                      offsetAngle: 140.0,
                      rotationRange: 240.0,
                    );
                  }),
                ),
                Positioned(
                  bottom: screenHeight * 0.24,
                  right: screenWidth * 0.2-10, // ตรงกลางแนวนอนไปทางขวา 150
                  child: Obx(() {
                    final rpm = ecuController.currentData.value?.rpm ?? 0;
                    return _buildNumberRPM(rpm: rpm);
                  }),
                ),

                // Speed Gauge
                Positioned(
                  top: screenHeight * 0.53 + 1, // 53% จากด้านบน
                  left: screenWidth * 0.5 - 196,
                  child: Obx(() {
                    final speed = ecuController.currentData.value?.speed ?? 0;
                    return _buildRotatingNeedleGauge(
                      value: speed, // ค่าปัจจุบันของความเร็ว
                      maxValue: 250, // ความเร็วสูงสุด (km/h)
                      size: 50, // ขนาด gauge (pixels)
                      offsetAngle:
                          100.0, // มุมเริ่มต้น (องศา) - ปรับตำแหน่งเข็มที่ 0 km/h
                      rotationRange:
                          247.0, // ช่วงการหมุน (องศา) - จาก 0 ถึง 250 km/h
                    );
                  }),
                ),
                Positioned(
                  top: screenHeight * 0.43,
                  right: screenWidth * 0.5 + 270,
                  child: Obx(() {
                    final speed = ecuController.currentData.value?.speed ?? 0;
                    return _buildSpeedometer(speed);
                  }),
                ),

                // Data Display (Left Side)
                Positioned(
                  top: screenHeight * 0.5, // 53% จากด้านบน
                  left:
                      screenWidth * 0.1 + 50, // ดึงจากตรงกลางแนวนอนไปทางซ้าย 35
                  child: Container(
                    height: 105,
                    padding: const EdgeInsets.all(12),
                    child: Obx(() {
                      final data = ecuController.currentData.value;
                      return _buildLedtDataPanel(data);
                    }),
                  ),
                ),

                // Data Display (Right Side)
                Positioned(
                  bottom: screenHeight * 0.5 -10, // 53% จากด้านบน
                  right:
                      screenWidth * 0.1 +
                      120, // ดึงจากตรงกลางแนวนอนไปทางซ้าย 35
                  child: SizedBox(
                    height: 100,
                    child: Obx(() {
                      final data = ecuController.currentData.value;
                      return _buildSecondaryDataPanel(data);
                    }),
                  ),
                ),

                

                // Settings Button (Top Left)
                const Positioned(
                  top: 10,
                  left: 10,
                  child: SettingsButton(),
                ),

                // Bluetooth Button
                const Positioned(
                  top: 10,
                  right: 10,
                  child: BluetoothButton(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Left Data Panel
  Column _buildLedtDataPanel(ECUData? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDataRow(data?.map.toStringAsFixed(0) ?? '0'),
        _buildDataRow(data?.battery.toStringAsFixed(1) ?? '0'),
        _buildDataRow(data?.airTemp.toStringAsFixed(0) ?? '0'),
        _buildDataRow(data?.waterTemp.toStringAsFixed(0) ?? '0'),
      ],
    );
  }

  /// RPM Number Display
  Widget _buildNumberRPM({required double rpm}) {
    return Container(
      width: 120,
      height: 30,
      alignment: Alignment.center,
      child: Text(
        " ${rpm.toInt()}",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Main RPM Gauge with rotating needle
  ///
  /// [value] ค่าปัจจุบัน (RPM)
  /// [maxValue] ค่าสูงสุด
  /// [size] ขนาดของ gauge
  /// [offsetAngle] มุม offset เฉพาะของ gauge นี้
  /// [rotationRange] ช่วงการหมุนเฉพาะของ gauge นี้
  Widget _buildRotatingNeedleGauge({
    required double value, // ค่าปัจจุบัน (RPM, Speed, etc.)
    required double maxValue, // ค่าสูงสุด
    required double size,
    required double offsetAngle, // ค่า offset เฉพาะของ gauge นี้
    required double rotationRange, // ช่วงการหมุนเฉพาะของ gauge นี้
  }) {
    // คำนวณมุม
    final angle = _rpmToAngle(value, maxValue, offsetAngle, rotationRange);

    return Stack(
      children: [
        // Rotating Needle with smooth animation
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: angle),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * (pi / 180),
                alignment: Alignment(0, -1), // หมุนรอบจุดฐานของเข็ม
                child: child,
              );
            },
            child: Image.asset('assets/ui-1/needle.png', fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  /// Convert RPM to angle in degrees
  double _rpmToAngle(
    double rpm,
    double maxRpm,
    double offsetAngle,
    double rotationRange,
  ) {
    // RPM 0 → เลข 1 บน gauge, RPM max → เลข 15 บน gauge
    final normalizedRpm = rpm.clamp(0, maxRpm);
    return (normalizedRpm / maxRpm) * rotationRange - 135 + offsetAngle;
  }

  /// Speedometer Display
  Widget _buildSpeedometer(double speed) {
    return Container(
      width: 70,
      height: 40,
      alignment: Alignment.center,
      child: Text(
        speed.toInt().toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Right Data Panel
  Widget _buildSecondaryDataPanel(dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDataRow(data?.ignition.toStringAsFixed(1) ?? '0'),
        _buildDataRow(data?.inject.toStringAsFixed(1) ?? '0'),
        _buildDataRow(data?.tps.toStringAsFixed(0) ?? '0'),
        _buildDataRow(data?.afr.toStringAsFixed(1) ?? '0'),
      ],
    );
  }

  /// Data Row Widget
  Widget _buildDataRow(String value) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// TPS Progress Bar (Linear Gauge) - รูปแบบตามรูป
  Widget _buildTPSProgressBar(double tps) {
    return Stack(
      children: [
        // Progress Fill (หลอดที่เต็ม)
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: (tps / 100).clamp(0.0, 1.0), // TPS 0-100%
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00BFFF), // Cyan สว่าง
                    Color(0xFF1E90FF), // น้ำเงินสด
                  ],
                ),
                borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(300.0),
                        ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

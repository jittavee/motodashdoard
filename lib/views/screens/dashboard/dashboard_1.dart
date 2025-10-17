import 'dart:math';
import 'package:api_tech_moto/models/ecu_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';

class TemplateOneScreen extends StatelessWidget {
  const TemplateOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.find<ECUDataController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Dashboard Template 1'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ecuController.generateDummyData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            return Stack(
              children: [
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
                      value: rpm,
                      maxValue: 15000,
                      size: 85,
                      offsetAngle: 150.0,
                      rotationRange: 240.0,
                    );
                  }),
                ),
                Positioned(
                  top: screenHeight * 0.7, // 40% จากด้านบน
                  left: screenWidth * 0.5 + 150, // ตรงกลางแนวนอนไปทางขวา 150
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
                  top: screenHeight * 0.09, // 53% จากด้านบน
                  right:
                      screenWidth * 0.1 +
                      100, // ดึงจากตรงกลางแนวนอนไปทางซ้าย 35
                  child: Container(
                    height: screenHeight * 0.5 + 5,
                    padding: const EdgeInsets.all(12),
                    child: Obx(() {
                      final data = ecuController.currentData.value;
                      return _buildSecondaryDataPanel(data);
                    }),
                  ),
                ),

                // TPS Progress Bar
                Positioned(
                  bottom: screenHeight * 0.11, // 11% จากด้านล่าง
                  right:
                      screenWidth * 0.2 -
                      21,
                  child: Obx(() {
                    final tps = ecuController.currentData.value?.tps ?? 0;
                    return Container(
                      width: screenWidth * .140, // ความกว้าง
                      height: screenHeight * .054, // ความสูง (เรียวกว่าเดิม)
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(300.0),
                          bottomRight: Radius.circular(300.0),
                        ),
                      ),
                      child: _buildTPSProgressBar(tps),
                    );
                  }),
                ),

                // Debug Button (Top Left)
                // Positioned(
                //   top: 20,
                //   left: 20,
                //   child: IconButton(
                //     icon: const Icon(Icons.bug_report, color: Colors.white),
                //     onPressed: () {
                //       ecuController.generateDummyData();
                //     },
                //   ),
                // ),
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
        _buildDataRow(data?.map.toStringAsFixed(0) ?? 'XXX'),
        _buildDataRow(data?.battery.toStringAsFixed(1) ?? 'XX'),
        _buildDataRow(data?.airTemp.toStringAsFixed(0) ?? 'XX'),
        _buildDataRow(data?.waterTemp.toStringAsFixed(0) ?? 'XX'),
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
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDataRow(data?.ignition.toStringAsFixed(1) ?? 'XXX'),
          _buildDataRow(data?.inject.toStringAsFixed(1) ?? 'XXX'),
          _buildDataRow(data?.tps.toStringAsFixed(0) ?? 'XX'),
          _buildDataRow(data?.afr.toStringAsFixed(1) ?? 'XX'),
        ],
      ),
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

  /// Bottom Information Bar
  Widget _buildBottomInfo(dynamic data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomInfoItem('AFR', (data?.afr ?? 0).toStringAsFixed(1)),
          Container(width: 1, height: 30, color: Colors.white30),
          _buildBottomInfoItem('TPS', '${(data?.tps ?? 0).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildBottomInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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

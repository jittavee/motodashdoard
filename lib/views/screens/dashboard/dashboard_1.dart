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
                // Positioned(
                //   left: 20,
                //   top: 100,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildDataPanel(data);
                //   }),
                // ),

                // Data Display (Right Side)
                // Positioned(
                //   right: 20,
                //   top: 100,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildSecondaryDataPanel(data);
                //   }),
                // ),

                // Bottom Info
                // Positioned(
                //   bottom: 20,
                //   left: 0,
                //   right: 0,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildBottomInfo(data);
                //   }),
                // ),

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
        _buildDataRow(
          'M4P',
          data?.map.toStringAsFixed(0) ?? 'XXX',
          'kPa.',
          Colors.white,
        ),
        _buildDataRow(
          'BATTERY',
          data?.battery.toStringAsFixed(1) ?? 'XX',
          'V.',
          Colors.white,
        ),
        _buildDataRow(
          'IAT',
          data?.airTemp.toStringAsFixed(0) ?? 'XX',
          'C.',
          Colors.white,
        ),
        _buildDataRow(
          'ECT',
          data?.waterTemp.toStringAsFixed(0) ?? 'XX',
          'C.',
          Colors.white,
        ),
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
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataRow(
            'IGN',
            data?.ignition.toStringAsFixed(1) ?? 'XXX',
            'Deg.',
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildDataRow(
            'INJ',
            data?.inject.toStringAsFixed(1) ?? 'XXX',
            'Pw.(ms.)',
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildDataRow(
            'TPS',
            data?.tps.toStringAsFixed(0) ?? 'XX',
            '%',
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildDataRow(
            'AFR',
            data?.afr.toStringAsFixed(1) ?? 'XX',
            '',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  /// Data Row Widget
  Widget _buildDataRow(String label, String value, String unit, Color color) {
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
          Container(width: 1, height: 30, color: Colors.white30),
          _buildBottomInfoItem('IACV', (data?.iacv ?? 0).toStringAsFixed(0)),
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
}

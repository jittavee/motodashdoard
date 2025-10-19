import 'dart:math';
import 'package:api_tech_moto/models/ecu_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../controllers/bluetooth_controller.dart';

class TemplateFiveScreen extends StatelessWidget {
  const TemplateFiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.find<ECUDataController>();
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      backgroundColor: Colors.black,
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
                    'assets/ui-5/Component 1.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Positioned(
                  top: screenHeight * 0.28, // 53% จากด้านบน
                  right: screenWidth * 0.21, // ดึงจากตรงกลางแนวนอนไปทางซ้าย 35
                  child: Obx(() {
                    final speed = ecuController.currentData.value?.speed ?? 0;
                    return
                    _buildRotatingNeedleGauge(
                      value: speed,
                      maxValue: 270,
                      size: 85,
                      offsetAngle: -15,
                      rotationRange: 270,
                    );
                  }),
                ),
                // RPM Needle (Left)
                // Positioned(
                //   top: screenHeight * 0.2,
                //   left: screenWidth * 0.05,
                //   child: Obx(() {
                //     final rpm = ecuController.currentData.value?.rpm ?? 0;
                //     return SizedBox(
                //       width: screenWidth * 0.35,
                //       height: screenWidth * 0.35,
                //       child: _buildRotatingNeedle(
                //         value: rpm,
                //         maxValue: 15000,
                //         offsetAngle: -45.0, // Start at 7 o'clock
                //         rotationRange: 270.0, // Rotate to 5 o'clock
                //       ),
                //     );
                //   }),
                // ),

                // // Speed Needle (Right)
                // Positioned(
                //   top: screenHeight * 0.2,
                //   right: screenWidth * 0.05,
                //   child: Obx(() {
                //     final speed = ecuController.currentData.value?.speed ?? 0;
                //     return SizedBox(
                //       width: screenWidth * 0.35,
                //       height: screenWidth * 0.35,
                //       child: _buildRotatingNeedle(
                //         value: speed,
                //         maxValue: 280,
                //         offsetAngle: -45.0,
                //         rotationRange: 270.0,
                //       ),
                //     );
                //   }),
                // ),

                // // RPM Number Display (Center of left gauge)
                // Positioned(
                //   top: screenHeight * 0.4,
                //   left: screenWidth * 0.225 - 40,
                //   child: Obx(() {
                //     final rpm = ecuController.currentData.value?.rpm ?? 0;
                //     return _buildCenterDisplay(
                //       value: (rpm / 1000).toStringAsFixed(1),
                //       label: 'RPM x 1000',
                //     );
                //   }),
                // ),

                // // Speed Number Display (Center of right gauge)
                // Positioned(
                //   top: screenHeight * 0.4,
                //   right: screenWidth * 0.225 - 40,
                //   child: Obx(() {
                //     final speed = ecuController.currentData.value?.speed ?? 0;
                //     return _buildCenterDisplay(
                //       value: speed.toInt().toString(),
                //       label: 'KM/H',
                //     );
                //   }),
                // ),

                // // Center Data Panel
                // Positioned(
                //   top: screenHeight * 0.25,
                //   left: screenWidth * 0.5 - 60,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildCenterDataPanel(data);
                //   }),
                // ),

                // Bluetooth Button (Bottom Right)
                Positioned(
                  bottom: screenHeight * 0.15,
                  right: screenWidth * 0.05,
                  child: Obx(() {
                    final isConnected =
                        btController.connectionStatus.value ==
                        BluetoothConnectionStatus.connected;
                    return Container(
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.bluetooth,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          print(" Bluetooth Button Pressed");
                          ecuController.startGeneratingData();
                        },
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Rotating Needle Widget
  Widget _buildRotatingNeedle({
    required double value,
    required double maxValue,
    required double offsetAngle,
    required double rotationRange,
  }) {
    final angle = _valueToAngle(value, maxValue, offsetAngle, rotationRange);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: angle),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * (pi / 180),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: CustomPaint(painter: NeedlePainter()),
    );
  }

  /// Convert value to angle
  double _valueToAngle(
    double value,
    double maxValue,
    double offsetAngle,
    double rotationRange,
  ) {
    final normalizedValue = value.clamp(0, maxValue);
    return (normalizedValue / maxValue) * rotationRange + offsetAngle;
  }

  /// Center Display Widget
  Widget _buildCenterDisplay({required String value, required String label}) {
    return Container(
      width: 80,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Center Data Panel
  Widget _buildCenterDataPanel(ECUData? data) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top section
          _buildDataRow('MAP', data?.map.toStringAsFixed(0) ?? 'XX', 'kPa'),
          const SizedBox(height: 8),
          _buildDataRow('IAT', data?.airTemp.toStringAsFixed(0) ?? 'XX', '°C'),
          const SizedBox(height: 8),
          _buildDataRow(
            'ECT',
            data?.waterTemp.toStringAsFixed(0) ?? 'XX',
            '°C',
          ),
          const SizedBox(height: 8),
          _buildDataRow(
            'BATTERY',
            data?.battery.toStringAsFixed(1) ?? 'XX',
            'V',
          ),
          const SizedBox(height: 20),

          // Bottom section
          _buildDataRow(
            'IGN',
            data?.ignition.toStringAsFixed(1) ?? 'XX',
            'Deg',
          ),
          const SizedBox(height: 8),
          _buildDataRow(
            'IGN',
            data?.ignition.toStringAsFixed(1) ?? 'XX',
            'Pw.(ms.)',
          ),
          const SizedBox(height: 8),
          _buildDataRow('INJ', data?.inject.toStringAsFixed(1) ?? 'XX', 'Deg'),
          const SizedBox(height: 8),
          _buildDataRow('INJ', data?.inject.toStringAsFixed(1) ?? 'XX', 'Pw.'),
          const SizedBox(height: 20),

          // AFR and TPS
          _buildDataRow('AFR', data?.afr.toStringAsFixed(1) ?? 'XX', ''),
          const SizedBox(height: 8),
          _buildDataRow('TPS', data?.tps.toStringAsFixed(0) ?? 'XX', ''),
        ],
      ),
    );
  }

  /// Data Row Widget
  Widget _buildDataRow(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Text(
              unit,
              style: const TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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
    print(value);
    // คำนวณมุม
    final angle = _rpmToAngle(value, maxValue, offsetAngle, rotationRange);
    print(angle);
    return Stack(
      children: [
        // Rotating Needle with smooth animation
        Container(
          color: Colors.green.withValues(alpha: .3),
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: angle),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * (pi / 180),
                alignment: Alignment.bottomLeft, // หมุนรอบจุดซ้ายล่าง
                child: child,
              );
            },
            child: Image.asset(
              'assets/ui-5/Component 2.png',
              fit: BoxFit.contain,
            ),
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
}

/// Custom Needle Painter
class NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.width / 2.5;

    canvas.drawLine(center, Offset(center.dx, center.dy - needleLength), paint);

    // Draw center circle
    final circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

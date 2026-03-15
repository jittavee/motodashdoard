import 'dart:math';
import 'package:api_tech_moto/models/ecu_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../controllers/gps_speed_controller.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/animated_gauge_needle.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/ecu_status_indicator.dart';
import '../../widgets/history_button.dart';
import '../../widgets/playback_timeline.dart';
import '../../widgets/performance_test_indicator.dart';

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
    final gpsSpeedController = Get.find<GpsSpeedController>();

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Stack(
          children: [
            // Background with AspectRatio - widgets scale with image
            Center(
              child: AspectRatio(
                aspectRatio: 1920 / 1080, // ใส่ตาม aspect ratio ของ background.png
                child: LayoutBuilder(
                  builder: (context, imageConstraints) {
                    final imageWidth = imageConstraints.maxWidth;
                    final imageHeight = imageConstraints.maxHeight;

                    // Helper functions for positioning
                    double pxW(double percent) => imageWidth * percent;
                    double pxH(double percent) => imageHeight * percent;

                    // ขนาดเข็ม RPM และ Speed (เป็น % ของความสูงภาพ)
                    final rpmNeedleSize = pxH(0.22);  // ~85px ที่ 1080p
                    final speedNeedleSize = pxH(0.13); // ~50px ที่ 1080p

                    return Stack(
                      children: [
                        // TPS Progress Bar (below image)
                        Positioned(
                          bottom: pxH(0.19),
                          right: pxW(0.19),
                          child: Obx(() {
                            final tps = ecuController.displayData?.tps ?? 0;
                            return Container(
                              width: pxW(0.140),
                              height: pxH(0.04),
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
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Main Gauge (RPM)
                        Positioned(
                          top: pxH(0.51),
                          left: pxW(0.47),
                          child: Obx(() {
                            final rpm = ecuController.displayData?.rpm ?? 0;
                            return AnimatedGaugeNeedle(
                              targetValue: rpm,
                              maxValue: 15000,
                              size: rpmNeedleSize,
                              offsetAngle: 140.0 - 135,
                              rotationRange: 240.0,
                              animationDuration: const Duration(milliseconds: 300),
                              animationCurve: Curves.easeInOut,
                              builder: (angle, currentValue) {
                                return SizedBox(
                                  width: rpmNeedleSize,
                                  height: rpmNeedleSize,
                                  child: Transform.rotate(
                                    angle: angle * (pi / 180),
                                    alignment: Alignment(0, -1),
                                    child: Image.asset(
                                      'assets/ui-1/needle.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),

                        Positioned(
                          bottom: pxH(0.3),
                          right: pxW(0.12),
                          child: Obx(() {
                            final rpm = ecuController.displayData?.rpm ?? 0;
                            return _buildNumberRPM(rpm: rpm, imageHeight: imageHeight);
                          }),
                        ),

                        // Speed Gauge
                        Positioned(
                          top: pxH(0.52),
                          left: pxW(0.26),
                          child: Obx(() {
                            final speed = gpsSpeedController.gpsSpeed.value;
                            return AnimatedGaugeNeedle(
                              targetValue: speed,
                              maxValue: 250,
                              size: speedNeedleSize,
                              offsetAngle: 100.0 - 135,
                              rotationRange: 247.0,
                              animationDuration: const Duration(milliseconds: 300),
                              animationCurve: Curves.easeInOut,
                              builder: (angle, currentValue) {
                                return SizedBox(
                                  width: speedNeedleSize,
                                  height: speedNeedleSize,
                                  child: Transform.rotate(
                                    angle: angle * (pi / 180),
                                    alignment: Alignment(0, -1),
                                    child: Image.asset(
                                      'assets/ui-1/needle.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),

                        // Top Speed Number Display
                        Positioned(
                          top: pxH(0.44),
                          left: pxW(0.05),
                          child: Obx(() {
                            final speed = gpsSpeedController.gpsSpeed.value;
                            return _buildSpeedometer(speed, imageHeight: imageHeight);
                          }),
                        ),

                        // Data Display (Left Side)
                        Positioned(
                          top: pxH(0.5),
                          left: pxW(0.13),
                          child: Container(
                            height: pxH(0.26),
                            padding: EdgeInsets.all(pxH(0.03)),
                            child: Obx(() {
                              final data = ecuController.displayData;
                              return _buildLedtDataPanel(data, imageHeight: imageHeight);
                            }),
                          ),
                        ),

                        // Data Display (Right Side)
                        Positioned(
                          bottom: pxH(0.48),
                          right: pxW(0.18),
                          child: SizedBox(
                            height: pxH(0.23),
                            child: Obx(() {
                              final data = ecuController.displayData;
                              return _buildSecondaryDataPanel(data, imageHeight: imageHeight);
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // History Button (Top Right - before Settings)
            const Positioned(
              top: 10,
              left: 60,
              child: HistoryButton(),
            ),

            // Settings Button (Top Right) - outside AspectRatio
            const Positioned(
              top: 10,
              right: 10,
              child: SettingsButton(),
            ),

            // Recording Indicator (Top Center)
            const Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(child: RecordingIndicator()),
            ),

            // ECU Status Indicator (Bottom Left)
            const Positioned(
              bottom: 10,
              left: 10,
              child: EcuStatusIndicator(),
            ),

            // Performance Test Indicator (Bottom Right)
            const Positioned(
              bottom: 10,
              right: 10,
              child: PerformanceTestIndicator(),
            ),

            // Playback Timeline (Bottom)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: PlaybackTimeline(),
            ),
          ],
        ),
      ),
    );
  }

  /// Left Data Panel
  Column _buildLedtDataPanel(ECUData? data, {required double imageHeight}) {
    final fontSize = imageHeight * 0.034;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDataRow(data?.map.toStringAsFixed(0) ?? '0', fontSize: fontSize),
        _buildDataRow(data?.battery.toStringAsFixed(1) ?? '0', fontSize: fontSize),
        _buildDataRow(data?.airTemp.toStringAsFixed(0) ?? '0', fontSize: fontSize),
        _buildDataRow(data?.waterTemp.toStringAsFixed(0) ?? '0', fontSize: fontSize),
      ],
    );
  }

  /// RPM Number Display
  Widget _buildNumberRPM({required double rpm, required double imageHeight}) {
    final fontSize = imageHeight * 0.05;
    return Container(
      width: imageHeight * 0.3,
      height: imageHeight * 0.08,
      alignment: Alignment.center,
      child: Text(
        " ${rpm.toInt()}",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Speedometer Display
  Widget _buildSpeedometer(double speed, {required double imageHeight}) {
    final fontSize = imageHeight * 0.06;
    return Container(
      width: imageHeight * 0.18,
      height: imageHeight * 0.1,
      alignment: Alignment.centerRight,
      child: Text(
        speed.toInt().toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Right Data Panel
  Widget _buildSecondaryDataPanel(dynamic data, {required double imageHeight}) {
    final fontSize = imageHeight * 0.035;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDataRow(data?.ignition.toStringAsFixed(1) ?? '0', fontSize: fontSize),
        _buildDataRow(data?.inject.toStringAsFixed(1) ?? '0', fontSize: fontSize),
        _buildDataRow(data?.tps.toStringAsFixed(0) ?? '0', fontSize: fontSize),
        _buildDataRow(data?.afr.toStringAsFixed(1) ?? '0', fontSize: fontSize),
      ],
    );
  }

  /// Data Row Widget
  Widget _buildDataRow(String value, {required double fontSize}) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
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

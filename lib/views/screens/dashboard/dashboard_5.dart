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

class TemplateFiveScreen extends StatefulWidget {
  const TemplateFiveScreen({super.key});

  @override
  State<TemplateFiveScreen> createState() => _TemplateFiveScreenState();
}

class _TemplateFiveScreenState extends State<TemplateFiveScreen> with WidgetsBindingObserver {
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
      backgroundColor: const Color(0xFF19171e),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, screenConstraints) {
            // คำนวณขนาดภาพจริงที่จะแสดงโดยใช้ BoxFit.contain logic
            const imageAspectRatio = 11773 / 5256;
            final screenAspectRatio = screenConstraints.maxWidth / screenConstraints.maxHeight;

            double imageWidth, imageHeight;
            if (screenAspectRatio > imageAspectRatio) {
              // จอกว้างกว่าภาพ -> ใช้ความสูงเต็ม
              imageHeight = screenConstraints.maxHeight;
              imageWidth = imageHeight * imageAspectRatio;
            } else {
              // จอแคบกว่าภาพ -> ใช้ความกว้างเต็ม
              imageWidth = screenConstraints.maxWidth;
              imageHeight = imageWidth / imageAspectRatio;
            }

            // Helper functions for positioning
            double pxW(double percent) => imageWidth * percent;
            double pxH(double percent) => imageHeight * percent;

            // ขนาดเข็ม (เป็น % ของความสูงภาพ)
            final speedNeedleSize = pxH(0.22);
            final rpmNeedleSize = pxH(0.26);

            return Stack(
              children: [
                // Background Image - centered
                Center(
                  child: SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Stack(
                      children: [
                        // Background
                        Positioned.fill(
                          child: Image.asset(
                            'assets/ui-5/Component 1.png',
                            fit: BoxFit.fill,
                          ),
                        ),

                        // Speed Gauge (Right)
                        Positioned(
                          top: pxH(0.28),
                          right: pxW(0.16),
                          child: Obx(() {
                            final speed = gpsSpeedController.gpsSpeed.value;
                            return AnimatedGaugeNeedle(
                              targetValue: speed,
                              maxValue: 270,
                              size: speedNeedleSize,
                              offsetAngle: -15 - 135,
                              rotationRange: 270,
                              animationDuration: const Duration(milliseconds: 300),
                              animationCurve: Curves.easeInOut,
                              builder: (angle, currentValue) {
                                return SizedBox(
                                  height: speedNeedleSize,
                                  child: Transform.rotate(
                                    angle: angle * (pi / 180),
                                    alignment: Alignment.bottomLeft,
                                    child: Image.asset(
                                      'assets/ui-5/Component 2.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),

                        // RPM Gauge (Left)
                        Positioned(
                          top: pxH(0.28),
                          left: pxW(0.22),
                          child: Obx(() {
                            final rpm = ecuController.displayData?.rpm ?? 0;
                            return AnimatedGaugeNeedle(
                              targetValue: rpm,
                              maxValue: 15000,
                              size: rpmNeedleSize,
                              offsetAngle: -65 - 135,
                              rotationRange: 320,
                              animationDuration: const Duration(milliseconds: 300),
                              animationCurve: Curves.easeInOut,
                              builder: (angle, currentValue) {
                                return SizedBox(
                                  height: rpmNeedleSize,
                                  child: Transform.rotate(
                                    angle: angle * (pi / 180),
                                    alignment: Alignment.bottomLeft,
                                    child: Image.asset(
                                      'assets/ui-5/Component 3.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),

                        // Speed Number Display (Center of right gauge)
                        Positioned(
                          top: pxH(0.4),
                          right: pxW(0.16),
                          child: Obx(() {
                            final speed = gpsSpeedController.gpsSpeed.value;
                            return _buildCenterDisplay(
                              value: speed.toInt().toString(),
                              label: 'KM/H',
                              imageHeight: imageHeight,
                            );
                          }),
                        ),

                        // MAP, BATTERY, IAT, ECT Data Panel (Center)
                        Positioned(
                          top: pxH(0.19),
                          left: pxW(0.48),
                          child: Obx(() {
                            final data = ecuController.displayData;
                            return _buildTopRightDataPanel(data, imageHeight: imageHeight, imageWidth: imageWidth);
                          }),
                        ),

                        // IGN & INJ Data Panel (Center Bottom)
                        Positioned(
                          bottom: pxH(0.22),
                          left: pxW(0.55),
                          child: Obx(() {
                            final data = ecuController.displayData;
                            return Container(
                              child: _buildCenterDataPanel(data, imageHeight: imageHeight));
                          }),
                        ),

                        // AFR and TPS Display (Bottom Center)
                        Positioned(
                          bottom: pxH(0.11),
                          left: pxW(0.47),
                          child: Obx(() {
                            final data = ecuController.displayData;
                            final afr = data?.afr ?? 0;
                            final tps = data?.tps ?? 0;
                            return _buildBottomDataPanel(afr, tps, imageHeight: imageHeight, imageWidth: imageWidth);
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                // History Button (Top Right - before Settings)
                const Positioned(
                  top: 10,
                  right: 60,
                  child: HistoryButton(),
                ),

                // Settings Button (Top Right) - outside image area
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

                // Playback Timeline (Bottom)
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: PlaybackTimeline(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomDataPanel(double afr, double tps, {required double imageHeight, required double imageWidth}) {
    return Row(
      children: [
        _buildDataLabel('AFR', afr.toStringAsFixed(1), imageHeight: imageHeight),
        SizedBox(width: imageWidth * 0.098),
        _buildDataLabel('TPS', tps.toInt().toString(), imageHeight: imageHeight),
      ],
    );
  }

  /// Center Display Widget
  Widget _buildCenterDisplay({required String value, required String label, required double imageHeight}) {
    return Container(
      width: imageHeight * 0.2,
      alignment: Alignment.center,
      child: Text(
        value,
        style: TextStyle(
          color: Colors.white,
          fontSize: imageHeight * 0.07,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Data Label Widget (for AFR, TPS display)
  Widget _buildDataLabel(String label, String value, {required double imageHeight}) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: imageHeight * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Center Data Panel (IGN, INJ display)
  Widget _buildCenterDataPanel(ECUData? data, {required double imageHeight}) {
    final spacing = imageHeight * 0.028;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDataLabel('IGN', data?.ignition.toStringAsFixed(0) ?? '0', imageHeight: imageHeight),
        SizedBox(height: spacing),
        _buildDataLabel('IGN', data?.ignition.toStringAsFixed(0) ?? '0', imageHeight: imageHeight),
        SizedBox(height: spacing),
        _buildDataLabel('INJ', data?.inject.toStringAsFixed(1) ?? '0', imageHeight: imageHeight),
        SizedBox(height: spacing),
        _buildDataLabel('INJ', data?.inject.toStringAsFixed(0) ?? '0', imageHeight: imageHeight),
      ],
    );
  }

  /// Top Right Data Panel (MAP, BATTERY, IAT, ECT display)
  Widget _buildTopRightDataPanel(ECUData? data, {required double imageHeight, required double imageWidth}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildTopRightDataItem('MAP', data?.map.toInt().toString() ?? '0', imageHeight: imageHeight),
            SizedBox(width: imageWidth * 0.11),
            _buildTopRightDataItem('BATTERY', data?.battery.toStringAsFixed(1) ?? '0', imageHeight: imageHeight),
          ],
        ),
        SizedBox(height: imageHeight * 0.045),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: imageWidth * 0.012),
            _buildTopRightDataItem('IAT', data?.airTemp.toInt().toString() ?? '0', imageHeight: imageHeight),
            SizedBox(width: imageWidth * 0.1),
            _buildTopRightDataItem('ECT', data?.waterTemp.toInt().toString() ?? '0', imageHeight: imageHeight),
          ],
        ),
      ],
    );
  }

  /// Top Right Data Item
  Widget _buildTopRightDataItem(String label, String value, {required double imageHeight}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: imageHeight * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../controllers/gps_speed_controller.dart';
import '../../../models/ecu_data.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/animated_gauge_needle.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/ecu_status_indicator.dart';
import '../../widgets/history_button.dart';
import '../../widgets/playback_timeline.dart';
import '../../widgets/performance_test_indicator.dart';
import '../../widgets/raw_data_overlay.dart';

class TemplateThreeScreen extends StatefulWidget {
  const TemplateThreeScreen({super.key});

  @override
  State<TemplateThreeScreen> createState() => _TemplateThreeScreenState();
}

class _TemplateThreeScreenState extends State<TemplateThreeScreen> with WidgetsBindingObserver {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscape();
    });

    // Aspect ratio ของพื้นหลัง (ปรับตามขนาดจริงของ mile.png)
    const double bgAspectRatio = 16 / 9;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
            aspectRatio: bgAspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bgWidth = constraints.maxWidth;
                final bgHeight = constraints.maxHeight;

                return Stack(
                  children: [
                    Row(
                      children: [
                        // ส่วนซ้าย - แสดงข้อมูล ETC, MAP, IAT, AFR
                        Expanded(
                          child: Obx(() {
                            final data = ecuController.displayData;
                            return _buildDataContainer(
                              data: data,
                              alignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              titleFactor: 0.05,
                              unitFactor: 0.03,
                              valueFactor: 0.05,
                              items: [
                                {
                                  'title': 'ECT',
                                  'unit': 'C',
                                  'getValue': (ECUData? d) =>
                                      (d?.waterTemp ?? 0).toStringAsFixed(0),
                                },
                                {
                                  'title': 'MAP',
                                  'unit': 'kPa',
                                  'getValue': (ECUData? d) =>
                                      (d?.map ?? 0).toStringAsFixed(0),
                                },
                                {
                                  'title': 'IAT',
                                  'unit': 'C',
                                  'getValue': (ECUData? d) =>
                                      (d?.airTemp ?? 0).toStringAsFixed(0),
                                },
                                {
                                  'title': 'AFR',
                                  'unit': ' ',
                                  'getValue': (ECUData? d) =>
                                      (d?.afr ?? 0).toStringAsFixed(1),
                                },
                              ],
                            );
                          }),
                        ),
                        // ส่วนกลาง - speedometer with needle (ยึดเป็นขนาดหลัก)
                        Center(
                          child: LayoutBuilder(
                            builder: (context, speedometerConstraints) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background speedometer
                                  Image.asset(
                                    'assets/ui-3/mile.png',
                                    height: bgHeight,
                                    fit: BoxFit.fitHeight,
                                  ),
                                  // Needle with rotation based on rpm
                                  Obx(() {
                                    final rpm = ecuController.displayData?.rpm ?? 0;
                                    final needleSize = bgHeight * 0.25;
                                    return AnimatedGaugeNeedle(
                                      targetValue: rpm,
                                      maxValue: 20000,
                                      size: needleSize,
                                      offsetAngle: 0,
                                      rotationRange: 300,
                                      animationDuration: const Duration(milliseconds: 300),
                                      animationCurve: Curves.easeInOut,
                                      builder: (angle, currentValue) {
                                        return Transform.translate(
                                          offset: Offset(0, needleSize * 0.5),
                                          child: SizedBox(
                                            width: needleSize,
                                            height: needleSize,
                                            child: Transform.rotate(
                                              angle: angle * (pi / 180),
                                              alignment: Alignment(0, -1),
                                              child: Image.asset(
                                                'assets/ui-3/needle.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  // Speed value display
                                  Obx(() {
                                    final speed = gpsSpeedController.gpsSpeed.value;
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          speed.toInt().toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: bgHeight * 0.15,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Ethnocentric',
                                          ),
                                        ),
                                        Text(
                                          'km/h',
                                          style: TextStyle(
                                            color: Color(0xFFFF6522),
                                            fontSize: bgHeight * 0.05,
                                            fontFamily: 'Ethnocentric',
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                        // ส่วนขวา - แสดงข้อมูล TPS, BAT, IGN, INJ
                        Expanded(
                          child: Obx(() {
                            final data = ecuController.displayData;
                            return _buildDataContainer(
                              data: data,
                              alignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              titleFactor: 0.05,
                              unitFactor: 0.03,
                              valueFactor: 0.05,
                              items: [
                                {
                                  'title': 'TPS',
                                  'unit': '%',
                                  'getValue': (ECUData? d) =>
                                      (d?.tps ?? 0).toStringAsFixed(0),
                                },
                                {
                                  'title': 'BATT',
                                  'unit': 'V',
                                  'getValue': (ECUData? d) =>
                                      (d?.battery ?? 0).toStringAsFixed(1),
                                },
                                {
                                  'title': 'IGN',
                                  'unit': 'deg',
                                  'getValue': (ECUData? d) =>
                                      (d?.ignition ?? 0).toStringAsFixed(1),
                                },
                                {
                                  'title': 'INJ',
                                  'unit': 'ms',
                                  'getValue': (ECUData? d) =>
                                      (d?.inject ?? 0).toStringAsFixed(1),
                                },
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                    // Recording Indicator (Top Center)
                    Positioned(
                      top: bgHeight * 0.02,
                      left: 0,
                      right: 0,
                      child: const Center(child: RecordingIndicator()),
                    ),
                    // ECU Status Indicator (Bottom Left)
                    Positioned(
                      bottom: bgHeight * 0.02,
                      left: bgWidth * 0.02,
                      child: const EcuStatusIndicator(),
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
          right: 60,
          child: HistoryButton(),
        ),
        // Settings Button (Top Right) - ยึดมุมขวาบนของจอ
        const Positioned(
          top: 10,
          right: 10,
          child: SettingsButton(),
        ),
        // Raw Data Overlay (Bottom Right)
        const Positioned(
          bottom: 40,
          right: 10,
          child: RawDataOverlay(),
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


  /// Helper: Build data row with title, unit on top and value below
  Widget _buildDataRow({
    required String title,
    required String unit,
    required String value,
    required double sizeTitle,
    required double sizeUnit,
    required double sizeValue,
    bool useExpanded = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title และ Unit อยู่บรรทัดเดียวกัน
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: sizeTitle,
                fontFamily: 'Ethnocentric',
              ),
            ),
            if (unit.isNotEmpty) ...[
              SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: Color(0xFFFF6522),
                  fontSize: sizeUnit,
                  fontFamily: 'Ethnocentric',
                ),
              ),
            ],
          ],
        ),
        // Value อยู่ข้างล่างชิดซ้าย
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: sizeValue,
            fontWeight: FontWeight.bold,
            fontFamily: 'Ethnocentric',
          ),
        ),
      ],
    );
  }

  /// Helper: Build data container with multiple rows
  Widget _buildDataContainer({
    required ECUData? data,
    Color color = Colors.transparent,
    required List<Map<String, dynamic>> items,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double titleFactor = 0.05,
    double valueFactor = 0.08,
    double unitFactor = 0.04,
    bool useExpanded = true,
  }) {
    return Container(
      color: color,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sizeTitle = constraints.maxHeight * titleFactor;
          final sizeValue = constraints.maxHeight * valueFactor;
          final sizeUnit = constraints.maxHeight * unitFactor;

          return Column(
            mainAxisAlignment: alignment,
            crossAxisAlignment: crossAxisAlignment,
            children: items.map((item) {
              return _buildDataRow(
                title: item['title'] as String,
                unit: item['unit'] as String,
                value: item['getValue'](data),
                sizeTitle: sizeTitle,
                sizeUnit: sizeUnit,
                sizeValue: sizeValue,
                useExpanded: useExpanded,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
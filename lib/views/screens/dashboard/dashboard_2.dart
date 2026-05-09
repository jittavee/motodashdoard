import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../controllers/gps_speed_controller.dart';
import '../../../models/ecu_data.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/ecu_status_indicator.dart';
import '../../widgets/history_button.dart';
import '../../widgets/playback_timeline.dart';
import '../../widgets/performance_test_indicator.dart';
import '../../widgets/raw_data_overlay.dart';

class TemplateTwoScreen extends StatefulWidget {
  const TemplateTwoScreen({super.key});

  @override
  State<TemplateTwoScreen> createState() => _TemplateTwoScreenState();
}

class _TemplateTwoScreenState extends State<TemplateTwoScreen>
    with WidgetsBindingObserver {
  TextStyle _mia(
    double fontSize, {
    Color color = const Color.fromARGB(255, 145, 145, 145),
    FontWeight fontWeight = FontWeight.normal,
  }) => TextStyle(
    fontFamily: 'Miamagon',
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
  );

  double _topSpeed = 0;

  Widget _buildTopSpeed(double speed, double height) {
    if (speed > _topSpeed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _topSpeed = speed);
      });
    }
    final fontSize = height * 0.08;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _topSpeed.toInt().toString(),
          style: _mia(fontSize, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

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

    // Aspect ratio ของรูปพื้นหลัง (ปรับตามขนาดจริงของ bg.png)
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
                        // RPM Bar
                        Obx(() {
                          final rpm = ecuController.displayData?.rpm ?? 0;
                          final rpmPercent = (rpm / 16000).clamp(0.0, 1.0);
                          return Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: bgWidth * rpmPercent,
                            child: Container(
                              color: Color(0xFF93dae0).withValues(alpha: 0.7),
                            ),
                          );
                        }),
                        // Background Image
                        Positioned.fill(
                          child: Image.asset(
                            'assets/ui-2/bg.png',
                            fit: BoxFit.fill,
                          ),
                        ),

                        // Top Speed
                        Positioned(
                          top: bgHeight * 0.15,
                          left: 100,
                          right: 0,
                          child: Center(
                            child: Obx(() {
                              final speed = gpsSpeedController.gpsSpeed.value;
                              return _buildTopSpeed(speed, bgHeight);
                            }),
                          ),
                        ),

                        // Data Overlay
                        Positioned(
                          left: 0,
                          top: bgHeight * 0.2,
                          bottom: bgHeight * 0.2,
                          right: 0,
                          child: Column(
                            children: [
                              Expanded(
                                flex: 70,
                                child: Row(
                                  children: [
                                    // Left Data Column
                                    Expanded(
                                      child: Obx(() {
                                        final data = ecuController.displayData;
                                        return _buildDataContainer(
                                          alignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          titleFactor: 0.13,
                                          unitFactor: 0.08,
                                          valueFactor: 0.13,
                                          data: data,
                                          items: [
                                            {
                                              'title': 'MAP',
                                              'unit': 'kPa',
                                              'getValue': (ECUData? d) =>
                                                  (d?.map ?? 0).toStringAsFixed(
                                                    0,
                                                  ),
                                            },
                                            {
                                              'title': 'BATTERY',
                                              'unit': 'V',
                                              'getValue': (ECUData? d) =>
                                                  (d?.battery ?? 0)
                                                      .toStringAsFixed(1),
                                            },
                                            {
                                              'title': 'IAT',
                                              'unit': 'C',
                                              'getValue': (ECUData? d) =>
                                                  (d?.airTemp ?? 0)
                                                      .toStringAsFixed(0),
                                            },
                                            {
                                              'title': 'ECT',
                                              'unit': 'C',
                                              'getValue': (ECUData? d) =>
                                                  (d?.waterTemp ?? 0)
                                                      .toStringAsFixed(0),
                                            },
                                          ],
                                        );
                                      }),
                                    ),
                                    // Speed Display
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final sizeValue =
                                            constraints.maxHeight * 0.5;
                                        return Center(
                                          child: Obx(() {
                                            final speed = gpsSpeedController
                                                .gpsSpeed
                                                .value;
                                            return Text(
                                              speed.toInt().toString(),
                                              style: _mia(
                                                sizeValue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                    // Right Data Column
                                    Expanded(
                                      child: Obx(() {
                                        final data = ecuController.displayData;
                                        return _buildAfrTps(data);
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              // Bottom Row - 2 Data Containers
                              Expanded(
                                flex: 30,
                                child: Obx(() {
                                  final data = ecuController.displayData;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildDataContainer(
                                          data: data,
                                          alignment: MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          titleFactor: 0.3,
                                          unitFactor: 0.2,
                                          valueFactor: 0.3,
                                          items: [
                                            {
                                              'title': 'IGN',
                                              'unit': 'Deg',
                                              'getValue': (ECUData? d) =>
                                                  (d?.ignition ?? 0)
                                                      .toStringAsFixed(1),
                                            },
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildDataContainer(
                                          data: data,
                                          alignment: MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          titleFactor: 0.3,
                                          unitFactor: 0.2,
                                          valueFactor: 0.3,
                                          items: [
                                            {
                                              'title': 'INJ',
                                              'unit': 'ms',
                                              'getValue': (ECUData? d) =>
                                                  (d?.inject ?? 0)
                                                      .toStringAsFixed(1),
                                            },
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        // History Button (Top Right - before Settings)
                        // Positioned(
                        //   top: bgHeight * 0.02,
                        //   left: bgWidth * 0.02,
                        //   child: const HistoryButton(),
                        // ),
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
                        // Raw Data Overlay (Bottom Right)
                        Positioned(
                          bottom: bgHeight * 0.12,
                          right: bgWidth * 0.02,
                          child: const RawDataOverlay(),
                        ),

                        // Performance Test Indicator (Bottom Right)
                        Positioned(
                          bottom: bgHeight * 0.02,
                          right: bgWidth * 0.02,
                          child: const PerformanceTestIndicator(),
                        ),
                        // Playback Timeline (Bottom)
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: PlaybackTimeline(),
                        ),
                      ], // Stack children
                    ); // Stack
                  },
                ), // LayoutBuilder
              ), // AspectRatio
            ), // Center
            // Settings Button outside AspectRatio
            const Positioned(top: 10, right: 10, child: SettingsButton()),
          ], // Stack(outer) children
        ), // Stack(outer)
      ), // SafeArea
    ); // Scaffold
  }

  Widget _buildAfrTps(ECUData? data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeTitle = constraints.maxHeight * 0.13;
        final sizeUnit = constraints.maxHeight * 0.08;
        final sizeValue = constraints.maxHeight * 0.13;
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AFR', style: _mia(sizeTitle)),
                SizedBox(width: 20),
                Text(
                  (data?.afr ?? 0).toStringAsFixed(1),
                  style: _mia(sizeValue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TPS', style: _mia(sizeTitle)),
                SizedBox(width: 2),
                Text(
                  '%',
                  style: _mia(sizeUnit, color: const Color(0xFFFF6522)),
                ),
                SizedBox(width: 20),
                Text(
                  (data?.tps ?? 0).toStringAsFixed(0),
                  style: _mia(sizeValue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Helper: Build data row with title, unit, value
  Widget _buildDataRow({
    required String title,
    required String unit,
    required String value,
    required double sizeTitle,
    required double sizeUnit,
    required double sizeValue,
    bool useExpanded = true,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(title, style: _mia(sizeTitle)),
        if (unit.isNotEmpty) ...[
          SizedBox(width: 2),
          Text(unit, style: _mia(sizeUnit, color: const Color(0xFFFF6522))),
        ],
        SizedBox(width: 20),
        Text(value, style: _mia(sizeValue, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Helper: Build data container with multiple rows
  Widget _buildDataContainer({
    required ECUData? data,
    required List<Map<String, dynamic>> items,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double titleFactor = 0.05,
    double valueFactor = 0.08,
    double unitFactor = 0.04,
    bool useExpanded = false,
  }) {
    return Container(
      color: Colors.transparent,
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

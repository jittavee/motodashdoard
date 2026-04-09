import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../controllers/gps_speed_controller.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/ecu_status_indicator.dart';
import '../../widgets/history_button.dart';
import '../../widgets/playback_timeline.dart';
import '../../widgets/performance_test_indicator.dart';
import '../../widgets/raw_data_overlay.dart';

class TemplateFourScreen extends StatefulWidget {
  const TemplateFourScreen({super.key});

  @override
  State<TemplateFourScreen> createState() => _TemplateFourScreenState();
}

class _TemplateFourScreenState extends State<TemplateFourScreen>
    with WidgetsBindingObserver {
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

    // Aspect ratio ของพื้นหลัง
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left margin
                            SizedBox(width: bgWidth * 0.05),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // แถวที่ 1
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Obx(() {
                                            final data =
                                                ecuController.displayData;
                                            return _buildCircleGauge(
                                              value: (data?.airTemp ?? 0)
                                                  .toStringAsFixed(0),
                                              unit: 'C',
                                              label: 'IAT',
                                            );
                                          }),
                                        ),
                                        Expanded(
                                          child: Obx(() {
                                            final data =
                                                ecuController.displayData;
                                            return _buildCircleGauge(
                                              value: (data?.waterTemp ?? 0)
                                                  .toStringAsFixed(0),
                                              unit: 'C',
                                              label: 'ECT',
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // แถวที่ 2
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Obx(() {
                                            final data =
                                                ecuController.displayData;
                                            return _buildCircleGauge(
                                              value: (data?.map ?? 0)
                                                  .toStringAsFixed(0),
                                              unit: 'kPa',
                                              label: 'MAP',
                                            );
                                          }),
                                        ),
                                        Expanded(
                                          child: Obx(() {
                                            final data =
                                                ecuController.displayData;
                                            return _buildCircleGauge(
                                              value: (data?.battery ?? 0)
                                                  .toStringAsFixed(1),
                                              unit: 'V',
                                              label: 'BATT',
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // แถวที่ 3 (1 คอลัมน์)
                                  Expanded(
                                    child: Obx(() {
                                      final data =
                                          ecuController.displayData;
                                      return _buildCircleGauge(
                                        value: ((data?.rpm ?? 0) / 1000)
                                            .toStringAsFixed(1),
                                        unit: 'x1000',
                                        label: 'RPM',
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            // Center speedometer
                            Container(
                              width: bgWidth * 0.4,
                              height: bgHeight,
                              color: Colors.black,
                              child: LayoutBuilder(
                                builder: (context, speedConstraints) {
                                  final speedSize = speedConstraints.maxHeight;
                                  return Stack(
                                    children: [
                                      // Speed image
                                      Center(
                                        child: Image.asset(
                                          'assets/ui-4/speed.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      // Speed value overlay
                                      Center(
                                        child: Obx(() {
                                          final speed =
                                              gpsSpeedController.gpsSpeed.value;
                                          return Text(
                                            speed.toInt().toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: speedSize * 0.22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // แถวที่ 1
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Obx(() {
                                            final data =
                                                ecuController.displayData;
                                            return _buildCircleGauge(
                                              value: (data?.ignition ?? 0)
                                                  .toStringAsFixed(1),
                                              unit: 'deg',
                                              label: 'IGN',
                                            );
                                          }),
                                        ),
                                        Expanded(
                                          child: Obx(() {
                                            final data =
                                                ecuController.displayData;
                                            return _buildCircleGauge(
                                              value: (data?.ignition ?? 0)
                                                  .toStringAsFixed(1),
                                              unit: 'ms',
                                              label: 'IGN',
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // แถวที่ 2
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Obx(() {
                                            final data =
                                                ecuController.displayData;
                                            return _buildCircleGauge(
                                              value: (data?.inject ?? 0)
                                                  .toStringAsFixed(1),
                                              unit: 'ms',
                                              label: 'INJ',
                                            );
                                          }),
                                        ),
                                        Expanded(
                                          child: Obx(() {
                                            final data =
                                                ecuController.displayData;
                                            return _buildCircleGauge(
                                              value: (data?.inject ?? 0)
                                                  .toStringAsFixed(1),
                                              unit: 'ms',
                                              label: 'INJ',
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // แถวที่ 3 (1 คอลัมน์)
                                  Expanded(
                                    child: Obx(() {
                                      final data =
                                          ecuController.displayData;
                                      return _buildCircleGauge(
                                        value:
                                            (data?.tps ?? 0).toStringAsFixed(0),
                                        unit: '%',
                                        label: 'TPS',
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            // Right margin
                            SizedBox(width: bgWidth * 0.05),
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

  /// Circle Gauge Widget with value, unit, and label
  Widget _buildCircleGauge({
    required String value,
    required String unit,
    required String label,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/ui-4/circle.png',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
              // Value in center
              Center(
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Unit and Label at bottom
              Positioned(
                bottom: size * 0.05,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unit,
                      style: TextStyle(
                        color: Color(0xFFFF6522),
                        fontSize: size * 0.08,
                        fontFamily: 'Ethnocentric',
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.10,
                        fontFamily: 'Ethnocentric',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../controllers/gps_speed_controller.dart';
import '../../widgets/arc_gauge.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/ecu_status_indicator.dart';
import '../../widgets/playback_timeline.dart';
import '../../widgets/performance_test_indicator.dart';
import '../../widgets/raw_data_overlay.dart';
import '../../widgets/speed_arc_gauge.dart';
import '../../widgets/afr_bar_gauge.dart';

class TemplateFourOneScreen extends StatefulWidget {
  const TemplateFourOneScreen({super.key});

  @override
  State<TemplateFourOneScreen> createState() => _TemplateFourOneScreenState();
}

class _TemplateFourOneScreenState extends State<TemplateFourOneScreen>
    with WidgetsBindingObserver {
  static const double _canvasW = 14851;
  static const double _canvasH = 8397;

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
    if (state == AppLifecycleState.resumed) _setLandscape();
  }

  void _setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ecu = Get.find<ECUDataController>();
    final gps = Get.find<GpsSpeedController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _canvasW,
                  height: _canvasH,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final h = c.maxHeight;
                      double pW(double p) => w * p;
                      double pH(double p) => h * p;

                      final speedSize = pW(0.30);
                      final smallSize = pW(0.115);
                      final rightSize = pW(0.130);

                      return Stack(
                        children: [
                          
                          // ── Logo — บนกึ่งกลาง speed gauge
                          Positioned(
                            top: pH(0.02),
                            left: pW(0.5) - speedSize * 0.28,
                            child: Image.asset(
                              'assets/ui-4/Component 2 logo.png',
                              width: speedSize * 0.56,
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Speed — กลาง
                          Positioned(
                            top: pH(0.5) - speedSize / 2,
                            left: pW(0.5) - speedSize / 2,
                            child: Obx(() => SpeedArcGauge(
                                  value: gps.gpsSpeed.value,
                                  maxValue: 180,
                                  size: speedSize,
                                )),
                          ),

                          // ── ซ้าย row 1: IAT | ECT
                          Positioned(
                            top: pH(0.04),
                            left: pW(0.01),
                            child: Obx(() => ArcGauge(
                                  value: ecu.displayData?.airTemp ?? 0,
                                  maxValue: 80,
                                  label: 'IAT',
                                  unit: 'c.',
                                  size: smallSize,
                                )),
                          ),
                          Positioned(
                            top: pH(0.04),
                            left: pW(0.135),
                            child: Obx(() => ArcGauge(
                                  value: ecu.displayData?.waterTemp ?? 0,
                                  maxValue: 120,
                                  label: 'ECT',
                                  unit: 'c.',
                                  size: smallSize,
                                )),
                          ),

                          // ── ซ้าย row 2: MAP | BATT
                          Positioned(
                            top: pH(0.37),
                            left: pW(0.01),
                            child: Obx(() => ArcGauge(
                                  value: ecu.displayData?.map ?? 0,
                                  maxValue: 200,
                                  label: 'MAP',
                                  unit: 'kPa.',
                                  size: smallSize,
                                )),
                          ),
                          Positioned(
                            top: pH(0.37),
                            left: pW(0.135),
                            child: Obx(() => ArcGauge(
                                  value: ecu.displayData?.battery ?? 0,
                                  maxValue: 16,
                                  label: 'BATT',
                                  unit: 'V.',
                                  size: smallSize,
                                )),
                          ),

                          // ── ซ้าย row 3: IGN | INJ
                          Positioned(
                            top: pH(0.68),
                            left: pW(0.01),
                            child: Obx(() => ArcGauge(
                                  value: ecu.displayData?.ignition ?? 0,
                                  maxValue: 60,
                                  label: 'IGN',
                                  unit: 'Deg.',
                                  size: smallSize,
                                )),
                          ),
                          Positioned(
                            top: pH(0.68),
                            left: pW(0.135),
                            child: Obx(() => ArcGauge(
                                  value: ecu.displayData?.inject ?? 0,
                                  maxValue: 20,
                                  label: 'INJ',
                                  unit: 'ms',
                                  size: smallSize,
                                )),
                          ),

                          // ── AFR bar — กึ่งกลางใต้ speed gauge
                          Positioned(
                            top: pH(0.5) + speedSize / 2 - pH(0.04),
                            left: pW(0.5) - speedSize * 0.45,
                            child: Obx(() => AfrBarGauge(
                                  value: ecu.displayData?.afr ?? 14.7,
                                  minValue: 10,
                                  maxValue: 18,
                                  label: 'AFR',
                                  width: speedSize * 0.9,
                                  height: pH(0.06),
                                )),
                          ),

                          // ── ขวา: RPM | TPS
                          Positioned(
                            top: pH(0.04),
                            right: pW(0.01),
                            child: Obx(() => ArcGauge(
                                  value: (ecu.displayData?.rpm ?? 0) / 1000,
                                  maxValue: 15,
                                  label: 'RPM',
                                  unit: 'x1000R/M',
                                  size: rightSize,
                                )),
                          ),
                          Positioned(
                            top: pH(0.55),
                            right: pW(0.01),
                            child: Obx(() => ArcGauge(
                                  value: ecu.displayData?.tps ?? 0,
                                  maxValue: 100,
                                  label: 'TPS',
                                  unit: '%',
                                  activeColor: const Color(0xFF00BFFF),
                                  size: rightSize,
                                )),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const Positioned(top: 10, right: 10, child: SettingsButton()),
            const Positioned(
              top: 10, left: 0, right: 0,
              child: Center(child: RecordingIndicator()),
            ),
            const Positioned(bottom: 10, left: 10, child: EcuStatusIndicator()),
            const Positioned(bottom: 40, right: 10, child: RawDataOverlay()),
            const Positioned(bottom: 10, right: 10, child: PerformanceTestIndicator()),
            const Positioned(
              bottom: 0, left: 0, right: 0,
              child: PlaybackTimeline(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/gps_speed_controller.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/ecu_status_indicator.dart';
import '../../widgets/playback_timeline.dart';
import '../../widgets/performance_test_indicator.dart';
import '../../widgets/raw_data_overlay.dart';
import '../../widgets/speed_arc_gauge.dart';

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

                      final gaugeSize = pW(0.30);

                      return Stack(
                        children: [
                          // Positioned.fill(
                          //   child: Image.asset(
                          //     'assets/ui-4/00401.png',
                          //     fit: BoxFit.fill,
                          //   ),
                          // ),
                          Positioned(
                            top: pH(0.5) - gaugeSize / 2,
                            left: pW(0.5) - gaugeSize / 2,
                            child: Obx(() => SpeedArcGauge(
                                  value: gps.gpsSpeed.value,
                                  maxValue: 180,
                                  size: gaugeSize,
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

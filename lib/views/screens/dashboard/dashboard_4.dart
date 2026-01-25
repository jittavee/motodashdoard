import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../widgets/bluetooth_button.dart';
import '../../widgets/settings_button.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscape();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            return Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left margin for settings button
                    SizedBox(width: 60),
                    Expanded(
                      child: Column(
                        children: [
                          // แถวที่ 1
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Obx(() {
                                    final data =
                                        ecuController.currentData.value;
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
                                        ecuController.currentData.value;
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
                              children: [
                                Expanded(
                                  child: Obx(() {
                                    final data =
                                        ecuController.currentData.value;
                                    return _buildCircleGauge(
                                      value: (data?.map ?? 0).toStringAsFixed(
                                        0,
                                      ),
                                      unit: 'kPa',
                                      label: 'MAP',
                                    );
                                  }),
                                ),
                                Expanded(
                                  child: Obx(() {
                                    final data =
                                        ecuController.currentData.value;
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
                              final data = ecuController.currentData.value;
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
                    Center(
                      child: Container(
                        width: screenWidth * 0.4,
                        height: screenHeight,
                        color: Colors.black,
                        child: Stack(
                          children: [
                            // Speed image
                            Image.asset(
                              'assets/ui-4/speed.png',
                              fit: BoxFit.contain,
                            ),
                            // Speed value overlay
                            Center(
                              child: Obx(() {
                                final speed = ecuController.currentData.value?.speed ?? 0;
                                return Text(
                                  speed.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenHeight * 0.22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          // แถวที่ 1
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Obx(() {
                                    final data =
                                        ecuController.currentData.value;
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
                                        ecuController.currentData.value;
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
                              children: [
                                Expanded(
                                  child: Obx(() {
                                    final data =
                                        ecuController.currentData.value;
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
                                        ecuController.currentData.value;
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
                              final data = ecuController.currentData.value;
                              return _buildCircleGauge(
                                value: (data?.tps ?? 0).toStringAsFixed(0),
                                unit: '%',
                                label: 'TPS',
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    // Right margin for bluetooth button
                    SizedBox(width: 60),
                  ],
                ),
                // Settings Button (Top Left)
                const Positioned(top: 10, left: 10, child: SettingsButton()),
                // Bluetooth Button (Top Right)
                const Positioned(top: 10, right: 10, child: BluetoothButton()),
              ],
            );
          },
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
    return Stack(
      children: [
        Container(
          alignment: Alignment.center,
          child: Image.asset('assets/ui-4/circle.png', fit: BoxFit.contain),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Value in center
                  Center(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.20,
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
        ),
      ],
    );
  }
}

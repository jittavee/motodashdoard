import 'dart:math';
import 'package:api_tech_moto/models/ecu_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../widgets/bluetooth_button.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/animated_gauge_needle.dart';

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
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/ui-5/Component 1.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Positioned(
                  top: screenHeight * 0.28,
                  right: screenWidth * 0.21,
                  child: Obx(() {
                    final speed = ecuController.currentData.value?.speed ?? 0;
                    return AnimatedGaugeNeedle(
                      targetValue: speed,
                      maxValue: 270,
                      size: 85,
                      offsetAngle: -15 - 135, // ปรับ offset
                      rotationRange: 270,
                      animationDuration: const Duration(milliseconds: 300),
                      animationCurve: Curves.easeInOut,
                      builder: (angle, currentValue) {
                        return SizedBox(
                          height: 85,
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
                Positioned(
                  top: screenHeight * 0.3 - 10,
                  left: screenWidth * 0.3 - 35,
                  child: Obx(() {
                    final rpm = ecuController.currentData.value?.rpm ?? 0;
                    return AnimatedGaugeNeedle(
                      targetValue: rpm,
                      maxValue: 15000,
                      size: 100,
                      offsetAngle: -65 - 135, // ปรับ offset
                      rotationRange: 320,
                      animationDuration: const Duration(milliseconds: 300),
                      animationCurve: Curves.easeInOut,
                      builder: (angle, currentValue) {
                        return SizedBox(
                          height: 100,
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
                  top: screenHeight * 0.5,
                  right: screenWidth * 0.25 - 45,
                  child: Obx(() {
                    final speed = ecuController.currentData.value?.speed ?? 0;
                    return _buildCenterDisplay(
                      value: speed.toInt().toString(),
                      label: 'KM/H',
                    );
                  }),
                ),

                // Center Data Panel
                // Positioned(
                //   top: screenHeight * 0.25,
                //   left: screenWidth * 0.5 - 60,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildCenterDataPanel(data);
                //   }),
                // ),

                // Settings Button (Top Left)
                Positioned(
                  top: screenHeight * 0.05,
                  left: screenWidth * 0.05,
                  child: const SettingsButton(),
                ),

                // MAP, BATTERY, IAT, ECT Data Panel (Top Right)
                Positioned(
                  top: screenHeight * 0.2 + 10,
                  left: screenWidth * 0.5 - 30,
                  child: Obx(() {
                    final data = ecuController.currentData.value;
                    return Container(
                      child: _buildTopRightDataPanel(data));
                  }),
                ),

                // IGN & INJ Data Panel (Left Side)
                Positioned(
                  bottom: screenHeight * 0.25 - 5,
                  left: screenWidth * 0.55,
                  child: Obx(() {
                    final data = ecuController.currentData.value;
                    return _buildCenterDataPanel(data);
                  }),
                ),

                // AFR and TPS Display (Bottom Center)
                Positioned(
                  bottom: screenHeight * 0.1 + 10,
                  left: screenWidth * 0.45 + 20,
                  child: Obx(() {
                    final data = ecuController.currentData.value;
                    final afr = data?.afr ?? 0;
                    final tps = data?.tps ?? 0;
                    return _buildBottomDataPanel(afr, tps);
                  }),
                ),

                // Bluetooth Button (Bottom Right)
                Positioned(
                  bottom: screenHeight * 0.15,
                  right: screenWidth * 0.05,
                  child: const BluetoothButton(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Row _buildBottomDataPanel(double afr, double tps) {
    return Row(
      children: [
        _buildDataLabel('AFR', afr.toStringAsFixed(1)),
        SizedBox(width: 50),
        _buildDataLabel('TPS', tps.toInt().toString()),
      ],
    );
  }

  /// Center Display Widget
  Widget _buildCenterDisplay({required String value, required String label}) {
    return Container(
      width: 80,
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Data Row Widget
  /// Data Label Widget (for AFR, TPS display)
  Widget _buildDataLabel(String label, String value) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Top Left Data Panel (IGN, INJ display)
  Widget _buildCenterDataPanel(ECUData? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataLabel('IGN', data?.ignition.toStringAsFixed(0) ?? '0'),
        const SizedBox(height: 4),
        _buildDataLabel('IGN', data?.ignition.toStringAsFixed(0) ?? '0'),
        const SizedBox(height: 4),
        _buildDataLabel('INJ', data?.inject.toStringAsFixed(1) ?? '0'),
        const SizedBox(height: 4),
        _buildDataLabel('INJ', data?.inject.toStringAsFixed(0) ?? '0'),
      ],
    );
  }

  /// Top Right Data Panel (MAP, BATTERY, IAT, ECT display)
  Widget _buildTopRightDataPanel(ECUData? data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildTopRightDataItem('MAP', data?.map.toInt().toString() ?? '0'),
            SizedBox(width: 80),
            _buildTopRightDataItem(
              'BATTERY',
              data?.battery.toStringAsFixed(1) ?? '0',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            _buildTopRightDataItem(
              'IAT',
              data?.airTemp.toInt().toString() ?? '0',
            ),
            const SizedBox(width: 70),
            _buildTopRightDataItem(
              'ECT',
              data?.waterTemp.toInt().toString() ?? '0',
            ),
          ],
        ),
      ],
    );
  }

  /// Top Right Data Item
  Widget _buildTopRightDataItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

}

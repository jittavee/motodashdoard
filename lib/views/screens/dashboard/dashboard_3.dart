import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../models/ecu_data.dart';
import '../../widgets/bluetooth_button.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/animated_gauge_needle.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscape();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            return Stack(
              children: [
                Row(
                  children: [
                    // ส่วนซ้าย - แสดงข้อมูล ETC, MAP, IAT, AFR
                    Expanded(
                      child: Obx(() {
                        final data = ecuController.currentData.value;
                        return _buildDataContainer(
                          data: data,
                          alignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          titleFactor: 0.065,
                          unitFactor: 0.03,
                          valueFactor: 0.065,
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
                              'unit': '',
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
                          // ใช้ความสูงของหน้าจอเป็นตัวกำหนดขนาด speedometer
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background speedometer
                              Image.asset(
                                'assets/ui-3/mile.png',
                                fit: BoxFit.fitHeight,
                              ),
                              // Needle with rotation based on rpm
                              Obx(() {
                                final rpm = ecuController.currentData.value?.rpm ?? 0;
                                return AnimatedGaugeNeedle(
                                  targetValue: rpm,
                                  maxValue: 20000,
                                  size: screenHeight * 0.25,
                                  offsetAngle: 0,
                                  rotationRange: 300,
                                  animationDuration: const Duration(milliseconds: 300),
                                  animationCurve: Curves.easeInOut,
                                  builder: (angle, currentValue) {
                                    return Transform.translate(
                                      offset: Offset(0, screenHeight * 0.25 * 0.5),
                                      child: SizedBox(
                                        width: screenHeight * 0.25,
                                        height: screenHeight * 0.25,
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
                                final speed = ecuController.currentData.value?.speed ?? 0;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      speed.toInt().toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenHeight * 0.15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Ethnocentric',
                                      ),
                                    ),
                                    Text(
                                      'km/h',
                                      style: TextStyle(
                                        color: Color(0xFFFF6522),
                                        fontSize: screenHeight * 0.05,
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
                        final data = ecuController.currentData.value;
                        return _buildDataContainer(
                          data: data,
                          alignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          titleFactor: 0.065,
                          unitFactor: 0.03,
                          valueFactor: 0.065,
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
                // Settings Button (Top Left)
                 Positioned(top: 10, left: screenWidth * 0.3, child: SettingsButton()),
                // Bluetooth Button (Top Right)
                Positioned(top: 10, right: screenWidth * 0.3, child: const BluetoothButton()),
              ],
            );
          },
        ),
      ),
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
    final labelRow = Row(
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
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (useExpanded)
          Expanded(child: labelRow)
        else
          labelRow,
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: sizeValue,
            fontWeight: FontWeight.bold,
            fontFamily: 'Ethnocentric',
          ),
        ),
        SizedBox(width: 10),
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
      color: color.withValues(alpha: 0.2),
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
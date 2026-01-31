import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../controllers/gps_speed_controller.dart';
import '../../../models/ecu_data.dart';
import '../../widgets/bluetooth_button.dart';
import '../../widgets/settings_button.dart';

class TemplateTwoScreen extends StatefulWidget {
  const TemplateTwoScreen({super.key});

  @override
  State<TemplateTwoScreen> createState() => _TemplateTwoScreenState();
}

class _TemplateTwoScreenState extends State<TemplateTwoScreen>
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            return Stack(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Obx(() {
                        final rpm = ecuController.currentData.value?.rpm ?? 0;
                        // คำนวณความกว้างตาม RPM (0-16000 -> 0%-100%)
                        final rpmPercent = (rpm / 16000).clamp(0.0, 1.0);
                        return Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: (screenWidth * 0.78) * rpmPercent,
                          child: Container(
                            color: Color(0xFF93dae0).withValues(alpha: 0.7),
                          ),
                        );
                      }),
                      Image.asset('assets/ui-2/bg.png', fit: BoxFit.fitHeight),

                      Positioned(
                        left: 0,
                        top: screenHeight * 0.2,
                        bottom: screenHeight * 0.2,
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
                                  final data = ecuController.currentData.value;
                                  return _buildDataContainer(
                                    alignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    titleFactor: 0.15,
                                    unitFactor: 0.08,
                                    valueFactor: 0.15,
                                    data: data,
                                    items: [
                                      {
                                        'title': 'MAP',
                                        'unit': 'kPa',
                                        'getValue': (ECUData? d) =>
                                            (d?.map ?? 0).toStringAsFixed(0),
                                      },
                                      {
                                        'title': 'BATTERY',
                                        'unit': 'V',
                                        'getValue': (ECUData? d) =>
                                            (d?.battery ?? 0).toStringAsFixed(
                                              1,
                                            ),
                                      },
                                      {
                                        'title': 'IAT',
                                        'unit': 'C',
                                        'getValue': (ECUData? d) =>
                                            (d?.airTemp ?? 0).toStringAsFixed(
                                              0,
                                            ),
                                      },
                                      {
                                        'title': 'ECT',
                                        'unit': 'C',
                                        'getValue': (ECUData? d) =>
                                            (d?.waterTemp ?? 0).toStringAsFixed(
                                              0,
                                            ),
                                      },
                                    ],
                                  );
                                }),
                              ),
    // Speed Display
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final sizeValue =
                                        constraints.maxHeight * 0.3;
                                    return Center(
                                      child: Obx(() {
                                        final speed =
                                            gpsSpeedController.gpsSpeed.value;
                                        return Text(
                                          speed.toInt().toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sizeValue,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Ethnocentric',
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ),
                              // Right Data Column
                              Expanded(
                                child: Obx(() {
                                  final data = ecuController.currentData.value;
                                  return _buildDataContainer(
                                    alignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    titleFactor: 0.15,
                                    unitFactor: 0.08,
                                    valueFactor: 0.15,
                                    data: data,
                                    items: [
                                      {
                                        'title': 'AFR',
                                        'unit': '',
                                        'getValue': (ECUData? d) =>
                                            (d?.afr ?? 0).toStringAsFixed(1),
                                      },
                                      {
                                        'title': 'TPS',
                                        'unit': '%',
                                        'getValue': (ECUData? d) =>
                                            (d?.tps ?? 0).toStringAsFixed(0),
                                      },
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        // Bottom Row - 4 Data Containers
                        Expanded(
                          flex: 30,
                          child: Obx(() {
                            final data = ecuController.currentData.value;
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildDataContainer(
                                    data: data,
                                    alignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    titleFactor: 0.3,
                                    unitFactor: 0.2,
                                    valueFactor: 0.3,
                                    useExpanded: true,
                                    items: [
                                      {
                                        'title': 'IGN',
                                        'unit': 'Deg',
                                        'getValue': (ECUData? d) =>
                                            (d?.ignition ?? 0).toStringAsFixed(
                                              1,
                                            ),
                                      },
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _buildDataContainer(
                                    data: data,
                                   alignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    titleFactor: 0.3,
                                    unitFactor: 0.2,
                                    valueFactor: 0.3,
                                    useExpanded: true,
                                    items: [
                                      {
                                        'title': 'IGN',
                                        'unit': 'ms',
                                        'getValue': (ECUData? d) =>
                                            (d?.ignition ?? 0).toStringAsFixed(
                                              1,
                                            ),
                                      },
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _buildDataContainer(
                                    data: data,
                                    alignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    titleFactor: 0.3,
                                    unitFactor: 0.2,
                                    valueFactor: 0.3,
                                    useExpanded: true,
                                    items: [
                                      {
                                        'title': 'INJ',
                                        'unit': 'Deg',
                                        'getValue': (ECUData? d) =>
                                            (d?.inject ?? 0).toStringAsFixed(1),
                                      },
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _buildDataContainer(
                                    data: data,
                                    alignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    titleFactor: 0.3,
                                    unitFactor: 0.2,
                                    valueFactor: 0.3,
                                    useExpanded: true,
                                    items: [
                                      {
                                        'title': 'INJ',
                                        'unit': 'ms',
                                        'getValue': (ECUData? d) =>
                                            (d?.inject ?? 0).toStringAsFixed(1),
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
                    ],
                  ),
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

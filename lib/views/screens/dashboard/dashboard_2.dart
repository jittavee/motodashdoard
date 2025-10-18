import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/bluetooth_controller.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../models/ecu_data.dart';

class TemplateTwoScreen extends StatelessWidget {
  const TemplateTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.find<ECUDataController>();
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            return Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/ui-2/template2.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // Bluetooth Button
                Positioned(
                  top: screenHeight * 0.06,
                  right: screenWidth * 0.084,
                  child: Obx(
                    () {
                    final isConnected = btController.connectionStatus.value == BluetoothConnectionStatus.connected;
                      
                      return Container(
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.bluetooth,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          ecuController.startGeneratingData();

                          // Get.toNamed('/bluetooth');
                        },
                      ),
                    );}
                  ),
                ),

                // Left Panel Data
                Positioned(
                  top: screenHeight * .2+ 9,
                  left: screenWidth * 0.25,
                  child: SizedBox(
                    height: screenHeight * 0.3 - 18,
                    child: Obx(() {
                      final data = ecuController.currentData.value;
                      return _buildLeftPanel(data);
                    }),
                  ),
                ),

                // Speed Display (km/h)
                Positioned(
                  top: screenHeight * 0.25,
                  left: screenWidth * 0.5 - 80,
                  child: Obx(() {
                    final speed = ecuController.currentData.value?.speed ?? 0;
                    return _buildSpeedDisplay(speed);
                  }),
                ),

                // RPM Linear Gauge
                // Positioned(
                //   bottom: screenHeight * 0.15,
                //   left: screenWidth * 0.1,
                //   right: screenWidth * 0.1,
                //   child: Obx(() {
                //     final rpm = ecuController.currentData.value?.rpm ?? 0;
                //     return _buildRPMGauge(rpm);
                //   }),
                // ),

                // Center Bottom Data
                // Positioned(
                //   bottom: screenHeight * 0.25,
                //   left: screenWidth * 0.25,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildCenterBottomData(data);
                //   }),
                // ),

                // Right Panel Data
                // Positioned(
                //   top: screenHeight * 0.25,
                //   right: screenWidth * 0.05,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildRightPanel(data);
                //   }),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Left Panel: MAP, BATTERY, IAT, ECT, IGN
  Widget _buildLeftPanel(ECUData? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDataItem(data?.map.toStringAsFixed(0) ?? '--'),
        _buildDataItem(data?.battery.toStringAsFixed(1) ?? '--'),
        _buildDataItem(data?.airTemp.toStringAsFixed(0) ?? '--'),
        _buildDataItem(data?.waterTemp.toStringAsFixed(0) ?? '--'),
      ],
    );
  }

  /// Right Panel: AFR, TPS, INJ Pw.
  Widget _buildRightPanel(ECUData? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDataItem(
          data?.afr.toStringAsFixed(1) ?? '--',
          isRightAlign: true,
        ),
        const SizedBox(height: 20),
        _buildDataItem(
          data?.tps.toStringAsFixed(0) ?? '--',
          isRightAlign: true,
        ),
        const SizedBox(height: 20),
        _buildDataItem(
          data?.inject.toStringAsFixed(1) ?? '--',
          isRightAlign: true,
        ),
      ],
    );
  }

  /// Center Bottom Data: IGN Pw., INJ Deg.
  Widget _buildCenterBottomData(ECUData? data) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDataItem(data?.ignition.toStringAsFixed(1) ?? '--'),
        const SizedBox(width: 40),
        _buildDataItem(data?.inject.toStringAsFixed(0) ?? '--'),
      ],
    );
  }

  /// Data Item Widget
  Widget _buildDataItem(String value, {bool isRightAlign = false}) {
    return Column(
      crossAxisAlignment: isRightAlign
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Speed Display (km/h)
  Widget _buildSpeedDisplay(double speed) {
    return Text(
      speed.toInt().toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 50,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// RPM Linear Gauge
  Widget _buildRPMGauge(double rpm) {
    final normalizedRpm = (rpm / 16000).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // RPM Bar
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              // Filled portion
              FractionallySizedBox(
                widthFactor: normalizedRpm,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          normalizedRpm >
                              0.875 // 14000/16000 = 0.875
                          ? [const Color(0xFF00E5FF), Colors.red]
                          : [const Color(0xFF00E5FF), const Color(0xFF00E5FF)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // RPM Value
        Text(
          'x1000r/min',
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      ],
    );
  }
}

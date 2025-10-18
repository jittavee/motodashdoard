import 'package:api_tech_moto/models/ecu_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';
import '../../../controllers/bluetooth_controller.dart';

class TemplateFourScreen extends StatelessWidget {
  const TemplateFourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.find<ECUDataController>();
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            return Stack(
              children: [
                // Main dashboard component in center
                Center(
                  child: Image.asset(
                    'assets/ui-4/Component 1.png',
                    fit: BoxFit.contain,
                  ),
                ),

                // Speed Display (Center top)
                Positioned(
                  top: screenHeight * 0.3,
                  left: screenWidth * 0.5 - 60,
                  child: Obx(() {
                    final speed = ecuController.currentData.value?.speed ?? 0;
                    return _buildSpeedDisplay(speed);
                  }),
                ),

                // Left Panel Container (IAT, ECT, MAP, BATTERY, RPM)
                Positioned(
                  left: screenWidth * 0.2 - 10,
                  top: screenHeight * 0.1  - 10,
                  child: Obx(() {
                    final data = ecuController.currentData.value;
                    return SizedBox(
                      height: screenHeight * 0.75,
                      width: screenWidth * 0.15 ,
                      child: _buildLeftPanelContainer(data));
                  }),
                ),
                // // RPM Display (Bottom left gauge)
                // Positioned(
                //   bottom: screenHeight * 0.15,
                //   left: screenWidth * 0.15+30,
                //   child: Obx(() {
                //     final rpm = ecuController.currentData.value?.rpm ?? 0;
                //     return _buildRPMDisplay(rpm);
                //   }),
                // ),

                // // TPS Display (Bottom right gauge)
                // Positioned(
                //   bottom: screenHeight * 0.15,
                //   right: screenWidth * 0.15,
                //   child: Obx(() {
                //     final tps = ecuController.currentData.value?.tps ?? 0;
                //     return _buildTPSDisplay(tps);
                //   }),
                // ),

                // // Left side data panel
                // Positioned(
                //   top: screenHeight * 0.3,
                //   left: screenWidth * 0.05,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildLeftDataPanel(data);
                //   }),
                // ),

                // // Right side data panel
                // Positioned(
                //   top: screenHeight * 0.3,
                //   right: screenWidth * 0.05,
                //   child: Obx(() {
                //     final data = ecuController.currentData.value;
                //     return _buildRightDataPanel(data);
                //   }),
                // ),

                // // AFR Progress Bar (Bottom)
                // Positioned(
                //   bottom: screenHeight * 0.05,
                //   left: screenWidth * 0.25,
                //   right: screenWidth * 0.25,
                //   child: Obx(() {
                //     final afr = ecuController.currentData.value?.afr ?? 0;
                //     return _buildAFRProgressBar(afr);
                //   }),
                // ),

                // Bluetooth Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: Obx(() {
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
                        },
                      ),
                    );
                  }),
                ),

                // Settings Button
                Positioned(
                  top: 10,
                  right: 60,
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      // TODO: Implement settings functionality
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Left Panel Container with all gauges (IAT, ECT, MAP, BATTERY, RPM)
  Widget _buildLeftPanelContainer(ECUData? data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top row: IAT and ECT
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataValue(
              data?.airTemp.toStringAsFixed(0) ?? 'XX',
            ),
            _buildDataValue(
              data?.waterTemp.toStringAsFixed(0) ?? 'XX',
            ),
          ],
        ),
    
        // Middle row: MAP and BATTERY
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataValue(
              data?.map.toStringAsFixed(0) ?? 'XX',
            ),
            _buildDataValue(
              data?.battery.toStringAsFixed(1) ?? 'XX',
            ),
          ],
        ),
    
        // Bottom: RPM value
        Container(
          width: double.infinity,
          height: 60,
          alignment: Alignment.center,
          child: _buildDataValue(
            ((data?.rpm ?? 0) / 1000).toStringAsFixed(0),
            fontSize: 32,
          ),
        ),
      ],
    );
  }

  /// Data Value Widget
  Widget _buildDataValue(String value, {double fontSize = 24}) {
    return Text(
      value,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Speed Display
  Widget _buildSpeedDisplay(double speed) {
    return Container(
      width: 120,
      height: 80,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            speed.toInt().toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// RPM Display
  Widget _buildRPMDisplay(double rpm) {
    return Container(
      width: 100,
      height: 60,
      alignment: Alignment.center,
      child: Text(
        (rpm / 1000).toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.red,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// TPS Display
  Widget _buildTPSDisplay(double tps) {
    return Container(
      width: 100,
      height: 60,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tps.toInt().toString(),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Left Data Panel
  Widget _buildLeftDataPanel(ECUData? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDataItem('IAT', data?.airTemp.toStringAsFixed(0) ?? 'XX', Colors.orange),
        const SizedBox(height: 15),
        _buildDataItem('ECT', data?.waterTemp.toStringAsFixed(0) ?? 'XX', Colors.orange),
        const SizedBox(height: 15),
        _buildDataItem('MAP', data?.map.toStringAsFixed(0) ?? 'XX', Colors.orange),
        const SizedBox(height: 15),
        _buildDataItem('BATTERY', data?.battery.toStringAsFixed(1) ?? 'XX', Colors.orange),
      ],
    );
  }

  /// Right Data Panel
  Widget _buildRightDataPanel(ECUData? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDataItem('IGN', data?.ignition.toStringAsFixed(1) ?? 'XX', Color(0xFF00FFFF)),
        const SizedBox(height: 15),
        _buildDataItem('IGN', data?.ignition.toStringAsFixed(1) ?? 'XX', Color(0xFF00FFFF)),
        const SizedBox(height: 15),
        _buildDataItem('INJ', data?.inject.toStringAsFixed(1) ?? 'XX', Color(0xFF00FFFF)),
        const SizedBox(height: 15),
        _buildDataItem('INJ', data?.inject.toStringAsFixed(1) ?? 'XX', Color(0xFF00FFFF)),
      ],
    );
  }

  /// Data Item Widget
  Widget _buildDataItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// AFR Progress Bar
  Widget _buildAFRProgressBar(double afr) {
    // AFR usually ranges from 10-20, normalize to 0-1
    final normalizedAFR = ((afr - 10) / 10).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          'AFR',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: normalizedAFR,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00FF00), // Green
                        Color(0xFFFFFF00), // Yellow
                        Color(0xFFFF0000), // Red
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          afr.toStringAsFixed(1),
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

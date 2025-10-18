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

                // Right Panel Container (IGN, IGN, INJ, INJ, TPS, AFR)
                Positioned(
                  right: screenWidth * 0.2 - 10,
                  top: screenHeight * 0.1 - 10,
                  child: Obx(() {
                    final data = ecuController.currentData.value;
                    return SizedBox(
                      height: screenHeight * 0.75,
                      width: screenWidth * 0.15,
                      child: _buildRightPanelContainer(data));
                  }),
                ),

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

  /// Right Panel Container with all gauges (IGN, IGN, INJ, INJ, TPS, AFR)
  Widget _buildRightPanelContainer(ECUData? data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top row: IGN (Deg) and IGN (Fly ms)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataValue(
              data?.ignition.toStringAsFixed(1) ?? 'XX',
            ),
            _buildDataValue(
              data?.ignition.toStringAsFixed(1) ?? 'XX',
            ),
          ],
        ),

        // Middle row: INJ (Pri) and INJ (Pri)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataValue(
              data?.inject.toStringAsFixed(1) ?? 'XX',
            ),
            _buildDataValue(
              data?.inject.toStringAsFixed(1) ?? 'XX',
            ),
          ],
        ),
        // Bottom: TPS value
        Container(
          width: double.infinity,
          height: 60,
          alignment: Alignment.center,
          child: _buildDataValue(
            (data?.tps ?? 0).toStringAsFixed(0),
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
}

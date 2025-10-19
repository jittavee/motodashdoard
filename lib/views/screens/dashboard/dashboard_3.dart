import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/bluetooth_controller.dart';
import '../../../controllers/ecu_data_controller.dart';

class TemplateThreeScreen extends StatelessWidget {
  const TemplateThreeScreen({super.key});

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
                // Black Background (no image)
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                  ),
                ),
                // Background - comp-1 full screen
                Positioned.fill(
                  child: Image.asset(
                    'assets/ui-3/comp-1.png',
                    fit: BoxFit.contain,
                  ),
                ),
                // Logo - comp-3 top left corner
                Positioned(
                  top: 20,
                  left: 20,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      'assets/ui-3/comp-3.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // Settings Button (Top Left)
                Positioned(
                  top: screenHeight * 0.06,
                  left: screenWidth * 0.084,
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed('/settings');
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Bluetooth Button
                Positioned(
                  top: screenHeight * 0.06,
                  right: screenWidth * 0.084,
                  child: Obx(() {
                    final isConnected =
                        btController.connectionStatus.value ==
                        BluetoothConnectionStatus.connected;

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
                          Get.toNamed('/bluetooth');
                        },
                      ),
                    );
                  }),
                ),

              ],
            );
          },
        ),
      ),
    );
  }
}
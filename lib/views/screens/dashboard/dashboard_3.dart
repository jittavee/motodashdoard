import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../widgets/bluetooth_button.dart';
import '../../widgets/settings_button.dart';

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
    _resetOrientation();
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

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const SettingsButton(),
                ),

                // Bluetooth Button
                Positioned(
                  top: screenHeight * 0.06,
                  right: screenWidth * 0.084,
                  child: const BluetoothButton(),
                ),

              ],
            );
          },
        ),
      ),
    );
  }
}
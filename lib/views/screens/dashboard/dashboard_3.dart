import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/ecu_data_controller.dart';

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
                // background speedometer with needle
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
                            final angle = _speedToAngle(rpm, 20000, 0, 300);
                            return _buildRotatingNeedle(
                              angle: angle,
                              size: screenHeight * 0.25, // ขนาดเข็มตามความสูงของ speedometer
                            );
                          }),
                        ],
                      );
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

  // คำนวณมุมจากค่า speed
  double _speedToAngle(
    double value,
    double maxValue,
    double offsetAngle,
    double rotationRange,
  ) {
    final normalized = (value / maxValue).clamp(0.0, 1.0);
    return offsetAngle + (normalized * rotationRange);
  }

  // สร้างเข็มที่หมุนได้พร้อม animation
  Widget _buildRotatingNeedle({
    required double angle,
    required double size,
  }) {
    return Transform.translate(
      offset: Offset(0, size * 0.5), // เลื่อนเข็มลง 50% ของขนาด
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: angle),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * (pi / 180),
              alignment: Alignment.topCenter, // หมุนรอบจุดด้านบน
              child: child,
            );
          },
          child: Image.asset(
            height: size,
            'assets/ui-3/needle.png',
            fit: BoxFit.fitHeight,
          ),
        ),
      ),
    );
  }
}
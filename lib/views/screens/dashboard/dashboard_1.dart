import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../../controllers/ecu_data_controller.dart';

class TemplateOneScreen extends StatefulWidget {
  const TemplateOneScreen({super.key});

  @override
  State<TemplateOneScreen> createState() => _TemplateOneScreenState();
}

class _TemplateOneScreenState extends State<TemplateOneScreen> {
  @override
  void initState() {
    super.initState();
    // Hide status bar and navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when leaving screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.find<ECUDataController>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Dashboard Image (Full Width)
          Positioned.fill(
            child: Image.asset(
              'assets/ui-1/background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

        ],
      ),
    );
  }

  // Map value to angle range
  double _mapSpeedToAngle(
      double value, double minValue, double maxValue, double minAngle, double maxAngle) {
    // Clamp value to range
    value = value.clamp(minValue, maxValue);

    // Map to angle
    final ratio = (value - minValue) / (maxValue - minValue);
    return minAngle + (ratio * (maxAngle - minAngle));
  }

  // Build data row widget
  Widget _buildDataRow(String label, String unit, String value, Color color, double fontSize) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        Text(
          unit,
          style: TextStyle(
            color: color,
            fontSize: fontSize - 2,
          ),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
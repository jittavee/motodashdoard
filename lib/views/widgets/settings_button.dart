import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reusable Settings Button Widget
///
/// A circular button with settings icon that navigates to settings screen
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

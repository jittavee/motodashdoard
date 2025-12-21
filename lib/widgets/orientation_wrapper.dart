import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget wrapper สำหรับควบคุม orientation ของแต่ละหน้า
class OrientationWrapper extends StatefulWidget {
  final Widget child;
  final List<DeviceOrientation> allowedOrientations;

  const OrientationWrapper({
    super.key,
    required this.child,
    this.allowedOrientations = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  });

  @override
  State<OrientationWrapper> createState() => _OrientationWrapperState();
}

class _OrientationWrapperState extends State<OrientationWrapper> {
  @override
  void initState() {
    super.initState();
    _setOrientation();
  }

  @override
  void dispose() {
    // คืนค่า orientation ให้รองรับทุกแนว
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations(widget.allowedOrientations);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

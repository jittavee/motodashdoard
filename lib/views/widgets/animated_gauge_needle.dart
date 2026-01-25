import 'package:flutter/material.dart';

/// Animated Gauge Needle Widget with Smooth Lerp Interpolation
///
/// ใช้สำหรับแสดงเข็มไมล์แบบ analog ที่เคลื่อนที่แบบ smooth sweep
/// แทนที่จะกระโดดแบบ digital step
///
/// Features:
/// - Frame-by-frame Linear Interpolation (Lerp)
/// - Configurable animation duration and curve
/// - Works with any gauge type (RPM, Speed, Temperature, etc.)
class AnimatedGaugeNeedle extends StatefulWidget {
  /// ค่าเป้าหมาย (target value) ที่เข็มจะค่อยๆ เคลื่อนที่ไป
  final double targetValue;

  /// ค่าสูงสุดของ gauge (สำหรับคำนวณ percentage)
  final double maxValue;

  /// ขนาดของเข็ม (pixels)
  final double size;

  /// มุมเริ่มต้น offset (degrees) - ขึ้นอยู่กับรูปแบบ gauge
  final double offsetAngle;

  /// ช่วงการหมุนของเข็ม (degrees) - เช่น 240, 270, 320
  final double rotationRange;

  /// ระยะเวลาของ animation (default: 300ms)
  final Duration animationDuration;

  /// Curve ของ animation (default: easeInOut)
  final Curve animationCurve;

  /// Widget builder สำหรับ render เข็มตามมุมที่คำนวณแล้ว
  /// [angle] = มุมปัจจุบันที่เข็มควรชี้ (degrees)
  /// [currentValue] = ค่าปัจจุบันที่แสดง (interpolated value)
  final Widget Function(double angle, double currentValue) builder;

  const AnimatedGaugeNeedle({
    super.key,
    required this.targetValue,
    required this.maxValue,
    required this.size,
    required this.offsetAngle,
    required this.rotationRange,
    required this.builder,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AnimatedGaugeNeedle> createState() => _AnimatedGaugeNeedleState();
}

class _AnimatedGaugeNeedleState extends State<AnimatedGaugeNeedle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.targetValue;

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(
      begin: _currentValue,
      end: widget.targetValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ))
      ..addListener(() {
        setState(() {
          _currentValue = _animation.value;
        });
      });

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedGaugeNeedle oldWidget) {
    super.didUpdateWidget(oldWidget);

    // เมื่อ targetValue เปลี่ยน ให้ animate ไปยังค่าใหม่
    if (oldWidget.targetValue != widget.targetValue) {
      // อัพเดท animation duration และ curve ถ้ามีการเปลี่ยนแปลง
      if (oldWidget.animationDuration != widget.animationDuration) {
        _controller.duration = widget.animationDuration;
      }

      _animation = Tween<double>(
        begin: _currentValue,
        end: widget.targetValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ))
        ..addListener(() {
          setState(() {
            _currentValue = _animation.value;
          });
        });

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // คำนวณเปอร์เซ็นต์ของค่าปัจจุบัน (0.0 - 1.0)
    final percentage = (_currentValue / widget.maxValue).clamp(0.0, 1.0);

    // คำนวณมุมของเข็ม (degrees)
    final angle = widget.offsetAngle + (percentage * widget.rotationRange);

    // เรียก builder function เพื่อ render เข็มตามมุมที่คำนวณแล้ว
    return widget.builder(angle, _currentValue);
  }
}

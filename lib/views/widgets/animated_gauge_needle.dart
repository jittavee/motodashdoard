import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedGaugeNeedle extends StatefulWidget {
  final double targetValue;
  final double maxValue;
  final double size;
  final double offsetAngle;
  final double rotationRange;
  final double lerpSpeed;
  final Duration animationDuration;
  final Curve animationCurve;

  /// เมื่อ true — เข็มจะแสดงเป็นสีแดง (alert mode)
  final bool isAlert;

  final Widget Function(double angle, double currentValue) builder;

  const AnimatedGaugeNeedle({
    super.key,
    required this.targetValue,
    required this.maxValue,
    required this.size,
    required this.offsetAngle,
    required this.rotationRange,
    required this.builder,
    this.lerpSpeed = 0.02,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.isAlert = false,
  });

  @override
  State<AnimatedGaugeNeedle> createState() => _AnimatedGaugeNeedleState();
}

class _AnimatedGaugeNeedleState extends State<AnimatedGaugeNeedle>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.targetValue;

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final target = widget.targetValue;
    if ((_currentValue - target).abs() < 0.5) {
      // ถึงเป้าแล้ว ไม่ต้อง setState
      if (_currentValue != target) {
        setState(() => _currentValue = target);
      }
      return;
    }
    setState(() {
      _currentValue = _lerpValue(_currentValue, target, widget.lerpSpeed);
    });
  }

  /// Lerp ที่ปรับเร็วตามระยะห่าง — ยิ่งห่างยิ่งไวขึ้น แต่ใกล้เป้าจะนุ่มนวล
  double _lerpValue(double current, double target, double t) {
    return current + (target - current) * t;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_currentValue / widget.maxValue).clamp(0.0, 1.0);
    final angle = widget.offsetAngle + (percentage * widget.rotationRange);
    final child = widget.builder(angle, _currentValue);

    if (!widget.isAlert) return child;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        1, 0, 0, 0, 180, // R: boost red channel
        0, 0, 0, 0, 0,   // G: zero green
        0, 0, 0, 0, 0,   // B: zero blue
        0, 0, 0, 1, 0,   // A: keep alpha
      ]),
      child: child,
    );
  }
}

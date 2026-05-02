import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animated Gauge Needle Widget with Smooth Lerp Interpolation
///
/// ใช้สำหรับแสดงเข็มไมล์แบบ analog ที่เคลื่อนที่แบบ smooth sweep
/// แทนที่จะกระโดดแบบ digital step
///
/// Features:
/// - Frame-by-frame Linear Interpolation (Lerp) via Ticker — ไม่ reset ทุกครั้งที่ค่าเปลี่ยน
/// - lerpSpeed: ความเร็วในการไล่ตาม target (0.0–1.0 ต่อ frame, default 0.12)
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

  /// ความเร็ว lerp ต่อ frame (0.0–1.0) — ค่าน้อย = สมูทกว่า, ค่ามาก = ตามเร็วกว่า
  /// 0.12 ≈ ถึงเป้าใน ~150ms ที่ 60fps
  final double lerpSpeed;

  // ยังคง parameter เดิมไว้เพื่อ backward-compat (ไม่ได้ใช้งานใน lerp mode)
  final Duration animationDuration;
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
    this.lerpSpeed = 0.02,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
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
    // คำนวณเปอร์เซ็นต์ของค่าปัจจุบัน (0.0 - 1.0)
    final percentage = (_currentValue / widget.maxValue).clamp(0.0, 1.0);

    // คำนวณมุมของเข็ม (degrees)
    final angle = widget.offsetAngle + (percentage * widget.rotationRange);

    // เรียก builder function เพื่อ render เข็มตามมุมที่คำนวณแล้ว
    return widget.builder(angle, _currentValue);
  }
}

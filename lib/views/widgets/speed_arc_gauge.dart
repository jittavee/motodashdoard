import 'dart:math';
import 'package:flutter/material.dart';

/// Arc gauge สำหรับ Speed โดยเฉพาะ
/// - segmented arc style เหมือนใน 00401.png
/// - animate smooth เมื่อค่าเปลี่ยน
class SpeedArcGauge extends StatefulWidget {
  final double value;
  final double maxValue;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const SpeedArcGauge({
    super.key,
    required this.value,
    this.maxValue = 250,
    required this.size,
    this.activeColor = const Color(0xFFD4A847),
    this.inactiveColor = const Color(0xFF2A2A2A),
  });

  @override
  State<SpeedArcGauge> createState() => _SpeedArcGaugeState();
}

class _SpeedArcGaugeState extends State<SpeedArcGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _prev = widget.value;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(SpeedArcGauge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: _prev, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      );
      _prev = widget.value;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          return CustomPaint(
            painter: _SpeedArcPainter(
              value: _anim.value,
              maxValue: widget.maxValue,
              activeColor: widget.activeColor,
              inactiveColor: widget.inactiveColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _anim.value.toInt().toString(),
                    style: TextStyle(
                      fontFamily: 'Digital7',
                      fontSize: s * 0.28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      fontFamily: 'Ethnocentric',
                      fontSize: s * 0.07,
                      color: const Color(0xFFFF6522),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpeedArcPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color activeColor;
  final Color inactiveColor;

  static const int _segments = 36;
  static const double _startAngleDeg = 405;
  static const double _sweepAngleDeg = 270;
  static const double _gapFraction = 0.15;

  const _SpeedArcPainter({
    required this.value,
    required this.maxValue,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    final strokeW = size.width * 0.065;

    final filledSegments =
        ((value / maxValue).clamp(0.0, 1.0) * _segments).round();

    final totalRad = _sweepAngleDeg * pi / 180;
    final segRad = totalRad / _segments;
    final gapRad = segRad * _gapFraction;
    final drawRad = segRad - gapRad;
    final startRad = _startAngleDeg * pi / 180;

    // white outer layer — same segment shape, larger radius
    final outerRadius = radius + strokeW * 1.05;
    final outerStrokeW = strokeW * 0.55;
    for (int i = 0; i < _segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startRad + i * segRad,
        drawRad,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = outerStrokeW
          ..strokeCap = StrokeCap.butt,
      );
    }

    for (int i = 0; i < _segments; i++) {
      final color = i < filledSegments
          ? _segmentColor(i, _segments)
          : inactiveColor;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRad + i * segRad,
        drawRad,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
    }

    // outer ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + strokeW * 0.65),
      startRad,
      totalRad,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.007,
    );

    // inner ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeW * 0.65),
      startRad,
      totalRad,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.005,
    );
  }

  Color _segmentColor(int index, int total) {
    final t = index / total;
    if (t < 0.5) return activeColor;
    if (t < 0.75) return Color.lerp(activeColor, const Color(0xFFFF8C00), (t - 0.5) / 0.25)!;
    return Color.lerp(const Color(0xFFFF8C00), const Color(0xFFFF2020), (t - 0.75) / 0.25)!;
  }

  @override
  bool shouldRepaint(_SpeedArcPainter old) => old.value != value;
}

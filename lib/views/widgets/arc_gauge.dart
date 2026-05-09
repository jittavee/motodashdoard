import 'dart:math';
import 'package:flutter/material.dart';

/// Segmented arc gauge — style matches 00401.png UI.
///
/// Parameters
/// ----------
/// value      : current value (0..maxValue)
/// maxValue   : upper bound
/// label      : bottom label (e.g. "RPM")
/// unit       : small unit text above label (e.g. "x1000R/M")
/// startAngle : arc start in degrees (0 = right, clockwise). Default 135.
/// sweepAngle : total arc sweep in degrees. Default 270.
/// segments   : number of tick segments drawn. Default 30.
/// activeColor: filled segment color
/// inactiveColor: unfilled segment color
/// size       : diameter of the widget
class ArcGauge extends StatefulWidget {
  final double value;
  final double maxValue;
  final String label;
  final String unit;
  final double startAngle;
  final double sweepAngle;
  final int segments;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const ArcGauge({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    this.unit = '',
    this.startAngle = 135,
    this.sweepAngle = 270,
    this.segments = 30,
    this.activeColor = const Color(0xFFD4A847),
    this.inactiveColor = const Color(0xFF3A3A3A),
    required this.size,
  });

  @override
  State<ArcGauge> createState() => _ArcGaugeState();
}

class _ArcGaugeState extends State<ArcGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _prevValue = widget.value;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(ArcGauge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: _prevValue, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      );
      _prevValue = widget.value;
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
            painter: _ArcPainter(
              value: _anim.value,
              maxValue: widget.maxValue,
              startAngleDeg: widget.startAngle,
              sweepAngleDeg: widget.sweepAngle,
              segments: widget.segments,
              activeColor: widget.activeColor,
              inactiveColor: widget.inactiveColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _anim.value.toStringAsFixed(
                      widget.value < 100 && widget.maxValue <= 100 ? 1 : 0,
                    ),
                    style: TextStyle(
                      fontFamily: 'Digital7',
                      fontSize: s * 0.22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.unit.isNotEmpty)
                    Text(
                      widget.unit,
                      style: TextStyle(
                        fontFamily: 'Ethnocentric',
                        fontSize: s * 0.065,
                        color: const Color(0xFFFF6522),
                      ),
                    ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Ethnocentric',
                      fontSize: s * 0.08,
                      color: Colors.white,
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

class _ArcPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final double startAngleDeg;
  final double sweepAngleDeg;
  final int segments;
  final Color activeColor;
  final Color inactiveColor;

  const _ArcPainter({
    required this.value,
    required this.maxValue,
    required this.startAngleDeg,
    required this.sweepAngleDeg,
    required this.segments,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final strokeW = size.width * 0.07;
    final gapFraction = 0.18;

    final filledFraction = (value / maxValue).clamp(0.0, 1.0);
    final filledSegments = (filledFraction * segments).round();

    final totalArcRad = sweepAngleDeg * pi / 180;
    final segArc = totalArcRad / segments;
    final drawArc = segArc * (1 - gapFraction);
    final startRad = startAngleDeg * pi / 180;

    // เส้นรอบนอกสุด — ตามช่วง arc เดียวกับ segment
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + strokeW * 1.1),
      startRad,
      totalArcRad,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.012,
    );

    // white segment layer — ระหว่างเส้นรอบนอกกับ active arc
    final outerRadius = radius + strokeW * 0.6;
    final outerStrokeW = strokeW * 0.45;
    for (int i = 0; i < segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startRad + i * segArc,
        drawArc,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = outerStrokeW
          ..strokeCap = StrokeCap.butt,
      );
    }

    // segments
    for (int i = 0; i < segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRad + i * segArc,
        drawArc,
        false,
        Paint()
          ..color = i < filledSegments ? activeColor : inactiveColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.filledFraction != filledFraction;

  double get filledFraction => (value / maxValue).clamp(0.0, 1.0);
}

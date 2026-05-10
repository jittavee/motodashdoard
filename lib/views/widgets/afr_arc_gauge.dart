import 'dart:math';
import 'package:flutter/material.dart';

class AfrArcGauge extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double width;
  final double height;

  const AfrArcGauge({
    super.key,
    required this.value,
    this.minValue = 10,
    this.maxValue = 18,
    required this.width,
    required this.height,
  });

  @override
  State<AfrArcGauge> createState() => _AfrArcGaugeState();
}

class _AfrArcGaugeState extends State<AfrArcGauge>
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
    _anim = Tween<double>(begin: widget.minValue, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _prevValue = widget.value;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AfrArcGauge old) {
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _AfrArcPainter(
          animValue: _anim.value,
          minValue: widget.minValue,
          maxValue: widget.maxValue,
        ),
      ),
    );
  }
}

class _AfrArcPainter extends CustomPainter {
  final double animValue;
  final double minValue;
  final double maxValue;

  const _AfrArcPainter({
    required this.animValue,
    required this.minValue,
    required this.maxValue,
  });

  // Arc spans from top-right area sweeping down-right
  // Origin of the arc circle is to the left of the widget (off-screen left)
  // The arc is the right side of a large circle

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // The arc's circle center is off to the left
    // Radius chosen so the arc edge touches right side of widget
    final double radius = w * 2.2;
    final Offset center = Offset(-radius + w * 0.55, h * 0.5);

    // Angular range: arc runs from top to bottom of widget
    // top angle: where arc exits at top of widget
    // bottom angle: where arc exits at bottom of widget
    // We compute angles from center to top-right and bottom-right corners
    final double angleTop = _angleToPoint(center, Offset(w, h * 0.02));
    final double angleBottom = _angleToPoint(center, Offset(w, h * 0.98));

    final double totalAngle = angleBottom - angleTop;

    // Draw arc track (inactive / dim)
    final Paint trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, angleTop, totalAngle, false, trackPaint);

    // Draw active portion up to current value
    final double fraction =
        ((animValue - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    // Active goes from bottom (minValue) up to current value
    final double activeStart = angleBottom - totalAngle * fraction;
    final double activeSweep = totalAngle * fraction;

    if (activeSweep > 0) {
      final Paint activePaint = Paint()
        ..color = const Color(0xFFFF6522)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, activeStart, activeSweep, false, activePaint);
    }

    // Draw tick marks and labels for each integer value
    final int steps = (maxValue - minValue).round();
    final double labelFontSize = w * 0.13;
    final double majorTickLen = w * 0.10;

    for (int i = 0; i <= steps; i++) {
      final double frac = i / steps;
      // angle at this value (bottom = min, top = max)
      final double angle = angleBottom - totalAngle * frac;

      // Point on arc
      final Offset arcPt = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      // Direction toward center (inward)
      final double dirX = (center.dx - arcPt.dx) / radius;
      final double dirY = (center.dy - arcPt.dy) / radius;

      final double tickLen = majorTickLen;
      final Offset tickEnd = Offset(
        arcPt.dx + dirX * tickLen,
        arcPt.dy + dirY * tickLen,
      );

      final int labelVal = (minValue + i).round();
      final bool isActive = animValue >= labelVal - 0.01;

      final Paint tickPaint = Paint()
        ..color = isActive
            ? const Color(0xFFFF6522)
            : Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = isActive ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(arcPt, tickEnd, tickPaint);

      // Label to the left of tick
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: labelVal.toString(),
          style: TextStyle(
            fontFamily: 'Ethnocentric',
            fontSize: labelFontSize,
            color: isActive
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.30),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Place label inward from tick end
      final Offset labelPt = Offset(
        tickEnd.dx + dirX * (tp.width * 0.6) - tp.width / 2,
        tickEnd.dy + dirY * (tp.height * 0.3) - tp.height / 2,
      );
      tp.paint(canvas, labelPt);
    }

    // Needle indicator line on arc at current value
    final double needleAngle = angleBottom - totalAngle * fraction;
    final Offset needlePt = Offset(
      center.dx + radius * cos(needleAngle),
      center.dy + radius * sin(needleAngle),
    );
    final double ndirX = (center.dx - needlePt.dx) / radius;
    final double ndirY = (center.dy - needlePt.dy) / radius;
    final Offset needleEnd = Offset(
      needlePt.dx + ndirX * majorTickLen * 2.0,
      needlePt.dy + ndirY * majorTickLen * 2.0,
    );
    canvas.drawLine(
      needlePt,
      needleEnd,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // "AFR" label at bottom
    final TextPainter afrTp = TextPainter(
      text: TextSpan(
        text: 'AFR',
        style: TextStyle(
          fontFamily: 'Ethnocentric',
          fontSize: w * 0.20,
          color: const Color(0xFFFF6522),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    afrTp.paint(
      canvas,
      Offset(w - afrTp.width - 2, h - afrTp.height - 2),
    );
  }

  double _angleToPoint(Offset center, Offset point) {
    return atan2(point.dy - center.dy, point.dx - center.dx);
  }

  @override
  bool shouldRepaint(_AfrArcPainter old) =>
      old.animValue != animValue ||
      old.minValue != minValue ||
      old.maxValue != maxValue;
}

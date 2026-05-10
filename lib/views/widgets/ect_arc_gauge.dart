import 'dart:math';
import 'package:flutter/material.dart';

class EctArcGauge extends StatefulWidget {
  final double ectValue;
  final double width;
  final double height;

  const EctArcGauge({
    super.key,
    required this.ectValue,
    required this.width,
    required this.height,
  });

  @override
  State<EctArcGauge> createState() => _EctArcGaugeState();
}

class _EctArcGaugeState extends State<EctArcGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prev = 40;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _anim = Tween<double>(begin: 40, end: widget.ectValue).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _prev = widget.ectValue;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(EctArcGauge old) {
    super.didUpdateWidget(old);
    if (old.ectValue != widget.ectValue) {
      _anim = Tween<double>(begin: _prev, end: widget.ectValue).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      );
      _prev = widget.ectValue;
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
        painter: _EctArcPainter(animValue: _anim.value),
      ),
    );
  }
}

class _EctArcPainter extends CustomPainter {
  final double animValue;

  const _EctArcPainter({required this.animValue});

  static const double _minVal = 40;
  static const double _maxVal = 130;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double topLabelH = h * 0.12;
    final double bottomLabelH = h * 0.12;
    final double arcAreaH = h - topLabelH - bottomLabelH;
    final double arcAreaTop = topLabelH;

    final double radius = w * 2.2;
    final Offset center = Offset(-radius + w * 0.55, arcAreaTop + arcAreaH * 0.5);

    final double angleTop = _angleToPoint(center, Offset(w, arcAreaTop + arcAreaH * 0.02));
    final double angleBottom = _angleToPoint(center, Offset(w, arcAreaTop + arcAreaH * 0.98));
    final double totalAngle = angleBottom - angleTop;

    // Track (inactive)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angleTop,
      totalAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Active fill (bottom = minVal, top = maxVal)
    final double fraction = ((animValue - _minVal) / (_maxVal - _minVal)).clamp(0.0, 1.0);
    final double activeStart = angleBottom - totalAngle * fraction;
    final double activeSweep = totalAngle * fraction;

    if (activeSweep > 0) {
      final bool isOverheat = animValue >= 110;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        activeStart,
        activeSweep,
        false,
        Paint()
          ..color = isOverheat ? Colors.red : const Color(0xFFFF6522)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tick marks: 40, 70, 100, 130
    const List<int> ticks = [40, 70, 100, 130];
    final double majorTickLen = w * 0.10;
    final double labelFontSize = w * 0.13;

    for (final int tickVal in ticks) {
      final double frac = (tickVal - _minVal) / (_maxVal - _minVal);
      final double angle = angleBottom - totalAngle * frac;

      final Offset arcPt = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final double dirX = (center.dx - arcPt.dx) / radius;
      final double dirY = (center.dy - arcPt.dy) / radius;

      final Offset tickEnd = Offset(
        arcPt.dx + dirX * majorTickLen,
        arcPt.dy + dirY * majorTickLen,
      );

      final bool isActive = animValue >= tickVal - 0.5;
      final bool isHot = tickVal >= 110;

      canvas.drawLine(
        arcPt,
        tickEnd,
        Paint()
          ..color = isActive
              ? (isHot ? Colors.red : const Color(0xFFFF6522))
              : Colors.white.withValues(alpha: 0.45)
          ..strokeWidth = isActive ? 2.5 : 1.5
          ..strokeCap = StrokeCap.round,
      );

      // Label for all ticks, suffix °C only on 130
      final String label = tickVal == 130 ? '$tickVal°C' : '$tickVal';
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: label,
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

      final Offset labelPt = Offset(
        tickEnd.dx + dirX * (tp.width * 0.6) - tp.width / 2,
        tickEnd.dy + dirY * (tp.height * 0.3) - tp.height / 2,
      );
      tp.paint(canvas, labelPt);
    }

    // Needle at current value
    final double needleAngle = angleBottom - totalAngle * fraction;
    final Offset needlePt = Offset(
      center.dx + radius * cos(needleAngle),
      center.dy + radius * sin(needleAngle),
    );
    final double ndirX = (center.dx - needlePt.dx) / radius;
    final double ndirY = (center.dy - needlePt.dy) / radius;
    canvas.drawLine(
      needlePt,
      Offset(needlePt.dx + ndirX * majorTickLen * 2.0, needlePt.dy + ndirY * majorTickLen * 2.0),
      Paint()
        ..color = animValue >= 110 ? Colors.red : Colors.white
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // ETC label at bottom
    final TextPainter etcTp = TextPainter(
      text: TextSpan(
        text: 'ETC',
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
    etcTp.paint(canvas, Offset(w * 0.02, h - bottomLabelH));
  }

  double _angleToPoint(Offset center, Offset point) {
    return atan2(point.dy - center.dy, point.dx - center.dx);
  }

  @override
  bool shouldRepaint(_EctArcPainter old) => old.animValue != animValue;
}

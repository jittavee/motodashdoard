import 'package:flutter/material.dart';

class AfrBarGauge extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final String label;
  final Color activeColor;
  final Color inactiveColor;
  final double width;
  final double height;

  const AfrBarGauge({
    super.key,
    required this.value,
    this.minValue = 10,
    this.maxValue = 18,
    this.label = 'AFR',
    this.activeColor = const Color(0xFF66FF00),
    this.inactiveColor = const Color(0xFF1A2A00),
    required this.width,
    required this.height,
  });

  @override
  State<AfrBarGauge> createState() => _AfrBarGaugeState();
}

class _AfrBarGaugeState extends State<AfrBarGauge>
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
  void didUpdateWidget(AfrBarGauge old) {
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
      builder: (_, __) {
        return _AfrBarLayout(
          animValue: _anim.value,
          minValue: widget.minValue,
          maxValue: widget.maxValue,
          label: widget.label,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
          width: widget.width,
          height: widget.height,
        );
      },
    );
  }
}

class _AfrBarLayout extends StatelessWidget {
  final double animValue;
  final double minValue;
  final double maxValue;
  final String label;
  final Color activeColor;
  final Color inactiveColor;
  final double width;
  final double height;

  const _AfrBarLayout({
    required this.animValue,
    required this.minValue,
    required this.maxValue,
    required this.label,
    required this.activeColor,
    required this.inactiveColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final double labelFontSize = height * 0.9;
    final double barHeight = height * 1.6;
    final double labelAreaHeight = height * 1.4;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: barHeight,
            child: CustomPaint(
              painter: _ChevronBarPainter(
                animValue: animValue,
                minValue: minValue,
                maxValue: maxValue,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: labelAreaHeight,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Ethnocentric',
                fontSize: labelFontSize,
                color: const Color(0xFFFF6522),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChevronBarPainter extends CustomPainter {
  final double animValue;
  final double minValue;
  final double maxValue;
  final Color activeColor;
  final Color inactiveColor;

  const _ChevronBarPainter({
    required this.animValue,
    required this.minValue,
    required this.maxValue,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int segments = (maxValue - minValue).round();
    final double filledFraction =
        ((animValue - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    final int filledSegments = (filledFraction * segments).round();

    // Each segment slot; the arrow tip overlaps into the next slot
    final double tip = size.height * 0.30;
    final double slotWidth = size.width / segments;
    final double gap = 2.5;

    // Build all paths first, then draw back-to-front so left segments sit on top
    final List<Path> paths = [];
    for (int i = 0; i < segments; i++) {
      final double x0 = i * slotWidth;       // slot left
      final double x1 = x0 + slotWidth;      // slot right (= tip base)
      final double mid = size.height / 2;

      final Path p = Path();
      if (i == 0) {
        // Flat left, pointed right
        p.moveTo(x0 + gap, 0);
        p.lineTo(x1 - gap, 0);
        p.lineTo(x1 - gap + tip, mid);
        p.lineTo(x1 - gap, size.height);
        p.lineTo(x0 + gap, size.height);
      } else if (i == segments - 1) {
        // Notched left, flat right
        p.moveTo(x0 - gap, 0);
        p.lineTo(x1 - gap, 0);
        p.lineTo(x1 - gap, size.height);
        p.lineTo(x0 - gap, size.height);
        p.lineTo(x0 - gap - tip, mid);
      } else {
        // Notched left, pointed right
        p.moveTo(x0 - gap, 0);
        p.lineTo(x1 - gap, 0);
        p.lineTo(x1 - gap + tip, mid);
        p.lineTo(x1 - gap, size.height);
        p.lineTo(x0 - gap, size.height);
        p.lineTo(x0 - gap - tip, mid);
      }
      p.close();
      paths.add(p);
    }

    // Draw right-to-left so left segments paint over right ones (gap line visible)
    for (int i = segments - 1; i >= 0; i--) {
      final bool active = i < filledSegments;
      final Color baseColor = active ? activeColor : inactiveColor;
      final Path path = paths[i];
      final double x0 = i * slotWidth;

      // Fill
      canvas.drawPath(path, Paint()..color = baseColor);

      // Gradient
      if (active) {
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.15),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(Rect.fromLTWH(x0, 0, slotWidth + tip, size.height)),
        );
      }

      // Number label centred in slot body
      final int labelValue = (minValue + i).round();
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: labelValue.toString(),
          style: TextStyle(
            fontFamily: 'Ethnocentric',
            fontSize: size.height * 0.50,
            color: active
                ? Colors.black.withValues(alpha: 0.80)
                : Colors.white.withValues(alpha: 0.25),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final double cx = x0 + slotWidth / 2;
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height / 2 - tp.height / 2));

      // Border
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_ChevronBarPainter old) =>
      old.animValue != animValue ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
}

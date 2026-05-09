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
    final double barHeight = height * .6;
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

    final double h = size.height;
    final double mid = h / 2;

    // skew: horizontal offset at top-left / bottom-right corners (parallelogram lean)
    final double skew = h * 0.30;
    final double gap = 10.0;
    // pitch: distance between segment anchors
    final double pitch = size.width / segments;
    // visible body width of each parallelogram (before gap)
    final double bodyW = pitch - gap;

    for (int i = 0; i < segments; i++) {
      final bool active = i < filledSegments;
      final Color baseColor = active ? activeColor : inactiveColor;

      // left anchor of this segment's bounding box
      final double x = i * pitch;

      // Parallelogram: top-left shifted right by skew, bottom-left flush
      // top-left=(x+skew, 0), top-right=(x+bodyW+skew, 0)
      // bottom-right=(x+bodyW, h), bottom-left=(x, h)
      final Path p = Path()
        ..moveTo(x + skew, 0)
        ..lineTo(x + bodyW + skew, 0)
        ..lineTo(x + bodyW, h)
        ..lineTo(x, h)
        ..close();

      // Fill
      canvas.drawPath(p, Paint()..color = baseColor);

      // Gradient overlay
      canvas.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: active ? 0.30 : 0.08),
              Colors.transparent,
              Colors.black.withValues(alpha: active ? 0.20 : 0.10),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(x, 0, bodyW + skew, h)),
      );

      // Number label centred horizontally in the parallelogram body
      final int labelValue = (minValue + i).round();
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: labelValue.toString(),
          style: TextStyle(
            fontFamily: 'Ethnocentric',
            fontSize: h * 0.50,
            color: active
                ? Colors.black.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.30),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      // visual centre of the parallelogram
      final double cx = x + (bodyW + skew) / 2;
      tp.paint(canvas, Offset(cx - tp.width / 2, mid - tp.height / 2));

      // Black border
      canvas.drawPath(
        p,
        Paint()
          ..color = Colors.black
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

import 'package:flutter/material.dart';

/// Irish-themed background:
///  • Very faint tricolor flag bands (green / white / orange)
///  • Gold harp silhouette watermark — bottom-right anchor
class IrishBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final bool isDark;

  const IrishBackgroundPainter({
    this.primaryColor = const Color(0xFF169B62),
    this.isDark = false,
  });

  void _drawFlag(Canvas canvas, Size size) {
    final third = size.width / 3;
    final greenOp = isDark ? 0.04 : 0.05;
    final whiteOp = isDark ? 0.02 : 0.04;
    final orangeOp = isDark ? 0.04 : 0.05;
    // RGB values hardcoded to avoid deprecated .red/.green/.blue accessors.
    final bands = [
      (0.0, Color.fromRGBO(22, 155, 98, greenOp)),       // #169B62 green
      (third, Color.fromRGBO(255, 255, 255, whiteOp)),   // white
      (third * 2, Color.fromRGBO(255, 136, 62, orangeOp)), // #FF883E orange
    ];
    for (final (x, color) in bands) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, third, size.height),
        Paint()..color = color,
      );
    }
  }

  void _drawHarp(Canvas canvas, Offset o, double sz, Paint fill) {
    final w = sz * 0.55;
    final h = sz;

    // Soundbox
    canvas.drawPath(
      Path()
        ..moveTo(o.dx + w * 0.25, o.dy + h)
        ..lineTo(o.dx + w, o.dy + h)
        ..cubicTo(o.dx + w * 1.12, o.dy + h * 0.68, o.dx + w * 1.06,
            o.dy + h * 0.28, o.dx + w * 0.70, o.dy)
        ..lineTo(o.dx + w * 0.25, o.dy + h * 0.08)
        ..close(),
      fill,
    );

    // Forepillar
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy + h * 0.10)
        ..quadraticBezierTo(o.dx - sz * 0.06, o.dy + h * 0.56,
            o.dx + w * 0.25, o.dy + h)
        ..lineTo(o.dx + w * 0.25 + sz * 0.045, o.dy + h)
        ..quadraticBezierTo(o.dx - sz * 0.01, o.dy + h * 0.56,
            o.dx + sz * 0.045, o.dy + h * 0.10)
        ..close(),
      fill,
    );

    // Neck
    canvas.drawPath(
      Path()
        ..moveTo(o.dx + sz * 0.045, o.dy + h * 0.10)
        ..cubicTo(o.dx + w * 0.20, o.dy - h * 0.09, o.dx + w * 0.52,
            o.dy - h * 0.04, o.dx + w * 0.70, o.dy)
        ..lineTo(o.dx + w * 0.68, o.dy + h * 0.065)
        ..cubicTo(o.dx + w * 0.50, o.dy + h * 0.03, o.dx + w * 0.18,
            o.dy - h * 0.01, o.dx, o.dy + h * 0.10)
        ..close(),
      fill,
    );

    // Strings — use .r/.g/.b/.a (double 0-1) to avoid deprecated int accessors.
    final alpha = (fill.color.a * 1.3).clamp(0.0, 1.0);
    final sPaint = Paint()
      ..color = Color.fromRGBO(
          (fill.color.r * 255.0).round().clamp(0, 255),
          (fill.color.g * 255.0).round().clamp(0, 255),
          (fill.color.b * 255.0).round().clamp(0, 255),
          alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sz * 0.022
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= 9; i++) {
      final t = i / 10.0;
      canvas.drawLine(
        Offset(o.dx + w * 0.045 + t * w * 0.64, o.dy + h * 0.07 - t * h * 0.045),
        Offset(o.dx + w * 0.28 + t * w * 0.57, o.dy + h * 0.91 - t * h * 0.24),
        sPaint,
      );
    }

    // Tuning knobs
    final dotPaint = Paint()
      ..color = fill.color
      ..style = PaintingStyle.fill;
    for (int i = 1; i <= 9; i++) {
      final t = i / 10.0;
      canvas.drawCircle(
        Offset(o.dx + w * 0.045 + t * w * 0.64, o.dy + h * 0.07 - t * h * 0.045),
        sz * 0.018,
        dotPaint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawFlag(canvas, size);

    final harpAlpha = isDark ? 0.10 : 0.15;
    final harpPaint = Paint()
      ..color = Color.fromRGBO(0xD4, 0xA0, 0x17, harpAlpha)
      ..style = PaintingStyle.fill;

    final harpSize = size.height * 0.60;
    _drawHarp(
      canvas,
      Offset(size.width - harpSize * 0.62, size.height - harpSize * 1.02),
      harpSize,
      harpPaint,
    );

    final ghostAlpha = isDark ? 0.04 : 0.05;
    final ghostPaint = Paint()
      ..color = Color.fromRGBO(0xD4, 0xA0, 0x17, ghostAlpha)
      ..style = PaintingStyle.fill;

    final smallSize = size.height * 0.28;
    _drawHarp(
      canvas,
      Offset(-smallSize * 0.15, -smallSize * 0.08),
      smallSize,
      ghostPaint,
    );
  }

  @override
  bool shouldRepaint(IrishBackgroundPainter old) => old.isDark != isDark;
}

/// Wraps [child] with the Irish flag + gold harp background.
class IrishBackground extends StatelessWidget {
  final Widget child;
  final Color? color;
  const IrishBackground({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: IrishBackgroundPainter(
              primaryColor: color ?? Theme.of(context).colorScheme.primary,
              isDark: isDark,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

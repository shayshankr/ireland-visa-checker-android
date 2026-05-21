import 'package:flutter/material.dart';

/// Irish-themed background:
///  • Very faint tricolor flag bands (green / white / orange)
///  • Gold harp silhouette watermark — bottom-right anchor
class IrishBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  const IrishBackgroundPainter({
    this.primaryColor = const Color(0xFF169B62),
  });

  // ── Irish flag tricolor ──────────────────────────────────────────────────────
  void _drawFlag(Canvas canvas, Size size) {
    final third = size.width / 3;
    final bands = [
      (0.0,       const Color(0xFF169B62), 0.05), // green
      (third,     const Color(0xFFFFFFFF), 0.04), // white
      (third * 2, const Color(0xFFFF883E), 0.05), // orange
    ];
    for (final (x, col, op) in bands) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, third, size.height),
        Paint()..color = col.withOpacity(op),
      );
    }
  }

  // ── Harp silhouette ──────────────────────────────────────────────────────────
  void _drawHarp(Canvas canvas, Offset o, double sz, Paint fill) {
    final w = sz * 0.55;
    final h = sz;

    // Soundbox
    canvas.drawPath(
      Path()
        ..moveTo(o.dx + w * 0.25, o.dy + h)
        ..lineTo(o.dx + w, o.dy + h)
        ..cubicTo(o.dx + w * 1.12, o.dy + h * 0.68,
                  o.dx + w * 1.06, o.dy + h * 0.28,
                  o.dx + w * 0.70, o.dy)
        ..lineTo(o.dx + w * 0.25, o.dy + h * 0.08)
        ..close(),
      fill,
    );

    // Forepillar
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy + h * 0.10)
        ..quadraticBezierTo(o.dx - sz * 0.06, o.dy + h * 0.56,
                            o.dx + w * 0.25,  o.dy + h)
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
        ..cubicTo(o.dx + w * 0.20, o.dy - h * 0.09,
                  o.dx + w * 0.52, o.dy - h * 0.04,
                  o.dx + w * 0.70, o.dy)
        ..lineTo(o.dx + w * 0.68, o.dy + h * 0.065)
        ..cubicTo(o.dx + w * 0.50, o.dy + h * 0.03,
                  o.dx + w * 0.18, o.dy - h * 0.01,
                  o.dx,             o.dy + h * 0.10)
        ..close(),
      fill,
    );

    // Strings (warm gold, slightly more visible)
    final sPaint = Paint()
      ..color = fill.color.withOpacity((fill.color.opacity * 1.3).clamp(0, 1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = sz * 0.022
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= 9; i++) {
      final t = i / 10.0;
      canvas.drawLine(
        Offset(o.dx + w * 0.045 + t * w * 0.64,
               o.dy + h * 0.07  - t * h * 0.045),
        Offset(o.dx + w * 0.28  + t * w * 0.57,
               o.dy + h * 0.91  - t * h * 0.24),
        sPaint,
      );
    }

    // Decorative tuning knobs along neck
    final dotPaint = Paint()
      ..color = fill.color
      ..style = PaintingStyle.fill;
    for (int i = 1; i <= 9; i++) {
      final t = i / 10.0;
      canvas.drawCircle(
        Offset(o.dx + w * 0.045 + t * w * 0.64,
               o.dy + h * 0.07  - t * h * 0.045),
        sz * 0.018,
        dotPaint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1 — Flag bands
    _drawFlag(canvas, size);

    // 2 — Large harp, anchored bottom-right, gold
    final harpPaint = Paint()
      ..color = const Color(0xFFD4A017).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final harpSize = size.height * 0.60;
    _drawHarp(
      canvas,
      Offset(size.width - harpSize * 0.62, size.height - harpSize * 1.02),
      harpSize,
      harpPaint,
    );

    // 3 — Second smaller harp, top-left ghost
    final ghostPaint = Paint()
      ..color = const Color(0xFFD4A017).withOpacity(0.05)
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
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Wraps [child] with the Irish flag + gold harp background.
class IrishBackground extends StatelessWidget {
  final Widget child;
  final Color? color;
  const IrishBackground({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: IrishBackgroundPainter(
              primaryColor: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

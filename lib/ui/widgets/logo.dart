import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// The three-card fan mark: two rotated outlines behind a filled centre card
/// with a diamond in it. Drawn on a 48×48 grid, like the SVG in the design.
class BookOracleLogo extends StatelessWidget {
  const BookOracleLogo({
    super.key,
    this.size = 18,
    this.strokeWidth = 3,
    this.accent,
    this.background,
  });

  final double size;

  /// In 48-unit grid space, so the mark keeps its weight when scaled.
  final double strokeWidth;
  final Color? accent;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    // Only reach for the theme when a colour was not supplied, so the mark can
    // also be drawn outside a themed tree (the app icon, for one).
    final a = accent ?? context.deck.accent;
    final b = background ?? context.deck.bg;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LogoPainter(
          accent: a,
          background: b,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Paints the mark on a 48-unit grid scaled to [size].
///
/// [strokeWidth] is in grid units — 3 at 18 px, 2 when drawn large.
void paintBookOracleLogo(
  Canvas canvas,
  Size size, {
  required Color accent,
  required Color background,
  double strokeWidth = 3,
}) {
  canvas.save();
  canvas.scale(size.width / 48, size.height / 48);

  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeJoin = StrokeJoin.round
    ..color = accent;
  final fill = Paint()..color = background;

  void card(double x, double y, double w, double h, double deg, Offset pivot) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(deg * math.pi / 180);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      stroke,
    );
    canvas.restore();
  }

  card(7, 12, 18, 26, -14, const Offset(16, 25));
  card(23, 12, 18, 26, 14, const Offset(32, 25));

  final centre = RRect.fromRectAndRadius(
      const Rect.fromLTWH(15, 8, 18, 28), const Radius.circular(3));
  canvas.drawRRect(centre, fill);
  canvas.drawRRect(centre, stroke);

  canvas.drawPath(
    Path()
      ..moveTo(24, 16)
      ..lineTo(28.5, 22)
      ..lineTo(24, 28)
      ..lineTo(19.5, 22)
      ..close(),
    stroke,
  );

  canvas.restore();
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({
    required this.accent,
    required this.background,
    required this.strokeWidth,
  });

  final Color accent;
  final Color background;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) => paintBookOracleLogo(
        canvas,
        size,
        accent: accent,
        background: background,
        strokeWidth: strokeWidth,
      );

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.accent != accent ||
      old.background != background ||
      old.strokeWidth != strokeWidth;
}

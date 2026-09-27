import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// The back of a card: either one of the deck's photos or the painted pattern.
class CardBackView extends StatelessWidget {
  const CardBackView({super.key, required this.index, this.deck});

  /// Position in the spread — photo decks cycle through their files.
  final int index;
  final DeckTheme? deck;

  @override
  Widget build(BuildContext context) {
    final d = deck ?? context.deck;
    final back = d.back;
    if (back.kind == CardBackKind.images && back.files.isNotEmpty) {
      return Image.asset(
        back.imageFor(index),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(color: back.base),
      );
    }
    return CustomPaint(painter: CardBackPainter(back), size: Size.infinite);
  }
}

class CardBackPainter extends CustomPainter {
  const CardBackPainter(this.spec);

  final CardBackSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = spec.base);

    final lines = spec.lines;
    if (lines != null) {
      _diagonals(canvas, size, lines, spec.step, math.pi / 4);
      _diagonals(canvas, size, lines, spec.step, -math.pi / 4);
    }

    final dots = spec.dots;
    if (dots != null) {
      final p = Paint()..color = dots;
      for (var y = spec.dotStep / 2; y < size.height; y += spec.dotStep) {
        for (var x = spec.dotStep / 2; x < size.width; x += spec.dotStep) {
          canvas.drawCircle(Offset(x, y), 1.2, p);
        }
      }
    }

    final scale = (size.width / 120).clamp(0.45, 1.6);
    final frame = spec.frame;
    if (frame != null) {
      final inset = size.width * 0.07;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            inset, size.height * 0.07, size.width - inset * 2, size.height * 0.86),
        Radius.circular(6 * scale),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * scale
          ..color = frame,
      );
    }

    final strokeColor = spec.emblemStroke;
    if (strokeColor != null) {
      final side = size.width * 0.26;
      final centre = Offset(size.width / 2, size.height / 2);
      final fillPaint = Paint()..color = spec.emblemFill ?? spec.base;
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale
        ..color = strokeColor;

      if (spec.emblem == Emblem.circle) {
        canvas.drawCircle(centre, side / 2, fillPaint);
        canvas.drawCircle(centre, side / 2, strokePaint);
      } else {
        canvas.save();
        canvas.translate(centre.dx, centre.dy);
        canvas.rotate(math.pi / 4);
        final r = Rect.fromCenter(
            center: Offset.zero, width: side, height: side);
        canvas.drawRect(r, fillPaint);
        canvas.drawRect(r, strokePaint);
        canvas.restore();
      }
    }
  }

  void _diagonals(
      Canvas canvas, Size size, Color color, double step, double angle) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    final reach = size.width + size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = -reach; x <= reach; x += step) {
      canvas.drawLine(Offset(x, -reach), Offset(x, reach), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CardBackPainter old) => old.spec != spec;
}

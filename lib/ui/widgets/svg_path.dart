import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Minimal SVG path-data parser, enough for the icon set: `M L H V C S Q T A Z`
/// in both absolute and relative forms.
///
/// It lets the icons keep the exact `d` strings from the design instead of
/// being re-drawn by hand.
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = _Tokenizer(d);
  var current = Offset.zero;
  var start = Offset.zero;
  Offset? lastCubicControl;
  Offset? lastQuadControl;
  String? command;

  while (!tokens.atEnd) {
    final next = tokens.peekCommand();
    if (next != null) {
      command = tokens.readCommand();
    } else if (command == null) {
      break;
    } else if (command == 'M') {
      command = 'L';
    } else if (command == 'm') {
      command = 'l';
    }

    final relative = command == command.toLowerCase();
    Offset rel(Offset p) => relative ? current + p : p;

    switch (command.toUpperCase()) {
      case 'M':
        current = rel(Offset(tokens.number(), tokens.number()));
        path.moveTo(current.dx, current.dy);
        start = current;
        lastCubicControl = null;
        lastQuadControl = null;
      case 'L':
        current = rel(Offset(tokens.number(), tokens.number()));
        path.lineTo(current.dx, current.dy);
        lastCubicControl = null;
        lastQuadControl = null;
      case 'H':
        final x = tokens.number();
        current = Offset(relative ? current.dx + x : x, current.dy);
        path.lineTo(current.dx, current.dy);
        lastCubicControl = null;
        lastQuadControl = null;
      case 'V':
        final y = tokens.number();
        current = Offset(current.dx, relative ? current.dy + y : y);
        path.lineTo(current.dx, current.dy);
        lastCubicControl = null;
        lastQuadControl = null;
      case 'C':
        final c1 = rel(Offset(tokens.number(), tokens.number()));
        final c2 = rel(Offset(tokens.number(), tokens.number()));
        final end = rel(Offset(tokens.number(), tokens.number()));
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        current = end;
        lastCubicControl = c2;
        lastQuadControl = null;
      case 'S':
        final c1 = lastCubicControl == null
            ? current
            : current * 2 - lastCubicControl;
        final c2 = rel(Offset(tokens.number(), tokens.number()));
        final end = rel(Offset(tokens.number(), tokens.number()));
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        current = end;
        lastCubicControl = c2;
        lastQuadControl = null;
      case 'Q':
        final c = rel(Offset(tokens.number(), tokens.number()));
        final end = rel(Offset(tokens.number(), tokens.number()));
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        current = end;
        lastQuadControl = c;
        lastCubicControl = null;
      case 'T':
        final c =
            lastQuadControl == null ? current : current * 2 - lastQuadControl;
        final end = rel(Offset(tokens.number(), tokens.number()));
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        current = end;
        lastQuadControl = c;
        lastCubicControl = null;
      case 'A':
        final rx = tokens.number();
        final ry = tokens.number();
        final rotation = tokens.number();
        final largeArc = tokens.flag();
        final sweep = tokens.flag();
        final end = rel(Offset(tokens.number(), tokens.number()));
        _arcTo(path, current, end, rx, ry, rotation, largeArc, sweep);
        current = end;
        lastCubicControl = null;
        lastQuadControl = null;
      case 'Z':
        path.close();
        current = start;
        lastCubicControl = null;
        lastQuadControl = null;
    }
  }
  return path;
}

/// Endpoint-to-centre arc conversion, straight out of the SVG spec, emitted as
/// cubic segments.
void _arcTo(
  Path path,
  Offset from,
  Offset to,
  double rx,
  double ry,
  double xAxisRotationDeg,
  bool largeArc,
  bool sweep,
) {
  if (rx == 0 || ry == 0) {
    path.lineTo(to.dx, to.dy);
    return;
  }
  rx = rx.abs();
  ry = ry.abs();
  final phi = xAxisRotationDeg * math.pi / 180;
  final cosPhi = math.cos(phi);
  final sinPhi = math.sin(phi);

  final dx2 = (from.dx - to.dx) / 2;
  final dy2 = (from.dy - to.dy) / 2;
  final x1p = cosPhi * dx2 + sinPhi * dy2;
  final y1p = -sinPhi * dx2 + cosPhi * dy2;

  // Scale the radii up when they are too small to span the chord.
  final lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
  if (lambda > 1) {
    final s = math.sqrt(lambda);
    rx *= s;
    ry *= s;
  }

  final sign = largeArc == sweep ? -1.0 : 1.0;
  var num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p;
  if (num < 0) num = 0;
  final den = rx * rx * y1p * y1p + ry * ry * x1p * x1p;
  final coef = den == 0 ? 0.0 : sign * math.sqrt(num / den);
  final cxp = coef * rx * y1p / ry;
  final cyp = -coef * ry * x1p / rx;

  final cx = cosPhi * cxp - sinPhi * cyp + (from.dx + to.dx) / 2;
  final cy = sinPhi * cxp + cosPhi * cyp + (from.dy + to.dy) / 2;

  double angle(double ux, double uy, double vx, double vy) {
    final dot = ux * vx + uy * vy;
    final len = math.sqrt(ux * ux + uy * uy) * math.sqrt(vx * vx + vy * vy);
    var a = math.acos((dot / len).clamp(-1.0, 1.0));
    if (ux * vy - uy * vx < 0) a = -a;
    return a;
  }

  final theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
  var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx,
      (-y1p - cyp) / ry);
  if (!sweep && delta > 0) {
    delta -= 2 * math.pi;
  } else if (sweep && delta < 0) {
    delta += 2 * math.pi;
  }

  final segments = (delta.abs() / (math.pi / 2)).ceil().clamp(1, 8);
  final step = delta / segments;
  var theta = theta1;
  for (var i = 0; i < segments; i++) {
    final t = 4 / 3 * math.tan(step / 4);
    final cosT1 = math.cos(theta);
    final sinT1 = math.sin(theta);
    final theta2 = theta + step;
    final cosT2 = math.cos(theta2);
    final sinT2 = math.sin(theta2);

    Offset point(double c, double s) => Offset(
          cx + rx * c * cosPhi - ry * s * sinPhi,
          cy + rx * c * sinPhi + ry * s * cosPhi,
        );
    Offset derivative(double c, double s) => Offset(
          -rx * s * cosPhi - ry * c * sinPhi,
          -rx * s * sinPhi + ry * c * cosPhi,
        );

    final p1 = point(cosT1, sinT1);
    final p2 = point(cosT2, sinT2);
    final d1 = derivative(cosT1, sinT1) * t;
    final d2 = derivative(cosT2, sinT2) * t;

    path.cubicTo(p1.dx + d1.dx, p1.dy + d1.dy, p2.dx - d2.dx, p2.dy - d2.dy,
        p2.dx, p2.dy);
    theta = theta2;
  }
}

class _Tokenizer {
  _Tokenizer(this.source);

  final String source;
  int i = 0;

  bool get atEnd {
    _skipSeparators();
    return i >= source.length;
  }

  void _skipSeparators() {
    while (i < source.length) {
      final c = source.codeUnitAt(i);
      // space, tab, CR, LF, comma
      if (c == 0x20 || c == 0x09 || c == 0x0D || c == 0x0A || c == 0x2C) {
        i++;
      } else {
        break;
      }
    }
  }

  static const String _commands = 'MmLlHhVvCcSsQqTtAaZz';

  String? peekCommand() {
    _skipSeparators();
    if (i >= source.length) return null;
    final ch = source[i];
    return _commands.contains(ch) ? ch : null;
  }

  String readCommand() {
    final c = peekCommand()!;
    i++;
    return c;
  }

  double number() {
    _skipSeparators();
    final start = i;
    if (i < source.length && (source[i] == '-' || source[i] == '+')) i++;
    var seenDot = false;
    var seenExponent = false;
    while (i < source.length) {
      final ch = source[i];
      if (_isDigit(ch)) {
        i++;
      } else if (ch == '.') {
        // `l.1.1` is two numbers, not one: a second dot starts the next token.
        if (seenDot || seenExponent) break;
        seenDot = true;
        i++;
      } else if ((ch == 'e' || ch == 'E') && !seenExponent && i > start) {
        seenExponent = true;
        i++;
        if (i < source.length && (source[i] == '-' || source[i] == '+')) i++;
      } else {
        break;
      }
    }
    return double.parse(source.substring(start, i));
  }

  /// Arc flags are single characters and may be packed without separators.
  bool flag() {
    _skipSeparators();
    final ch = source[i];
    i++;
    return ch == '1';
  }

  static bool _isDigit(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39;
  }
}

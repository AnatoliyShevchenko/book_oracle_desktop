import 'package:flutter/material.dart';

import 'svg_path.dart';

/// One icon: stroked path data on a 24×24 grid plus any solid dots.
@immutable
class IconSpec {
  const IconSpec(
    this.strokes, {
    this.dots = const <(double, double, double)>[],
    this.strokeWidth = 2,
    this.viewBox = 24,
    this.cap = StrokeCap.round,
    this.join = StrokeJoin.round,
  });

  final List<String> strokes;

  /// `(cx, cy, r)` filled circles.
  final List<(double, double, double)> dots;
  final double strokeWidth;
  final double viewBox;
  final StrokeCap cap;
  final StrokeJoin join;
}

/// Every icon in the app, taken verbatim from the design's SVGs.
class AppIcons {
  const AppIcons._();

  static const refresh = IconSpec(<String>[
    'M20 12a8 8 0 1 1-2.34-5.66',
    'M20 4v5h-5',
  ]);

  static const wifiOff = IconSpec(
    <String>[
      'M2 8.8a15 15 0 0 1 4.2-2.6',
      'M9.5 5.2A15 15 0 0 1 22 8.8',
      'M5 12.5a10 10 0 0 1 3.4-1.9',
      'M14.7 10.8A10 10 0 0 1 19 12.5',
      'M8.5 16a5 5 0 0 1 7 0',
      'M3 3l18 18',
    ],
    dots: <(double, double, double)>[(12, 19.5, 1)],
  );

  static const wifiOffSmall = IconSpec(
    <String>[
      'M2 8.8a15 15 0 0 1 4.2-2.6',
      'M9.5 5.2A15 15 0 0 1 22 8.8',
      'M5 12.5a10 10 0 0 1 3.4-1.9',
      'M14.7 10.8A10 10 0 0 1 19 12.5',
      'M8.5 16a5 5 0 0 1 7 0',
      'M3 3l18 18',
    ],
    strokeWidth: 2.4,
  );

  static const checkCircle = IconSpec(<String>[
    'M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z',
    'M8 12.5l2.8 2.8L16 9.5',
  ], strokeWidth: 2.2);

  static const sheet = IconSpec(<String>[
    'M6 3h12a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z',
    'M4 9h16',
    'M4 15h16',
    'M10 9v12',
  ], strokeWidth: 1.8);

  static const bookCheck = IconSpec(<String>[
    'M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5z',
    'M4 20.5A2.5 2.5 0 0 0 6.5 23H20v-5',
    'M9 10l2 2 4-4',
  ], strokeWidth: 1.8);

  static const dice = IconSpec(
    <String>[
      'M7 4h10a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3z',
    ],
    dots: <(double, double, double)>[
      (9, 9, 1.2),
      (15, 15, 1.2),
      (15, 9, 1.2),
      (9, 15, 1.2),
    ],
  );

  static const shuffle = IconSpec(<String>[
    'M16 3h5v5',
    'M4 20L21 3',
    'M21 16v5h-5',
    'M15 15l6 6',
    'M4 4l5 5',
  ], strokeWidth: 1.8);

  static const gear = IconSpec(<String>[
    'M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z',
    'M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z',
  ], strokeWidth: 1.8);

  static const arrowRight = IconSpec(<String>[
    'M5 12h14',
    'M13 6l6 6-6 6',
  ]);

  static const chevronLeft = IconSpec(<String>['M15 18l-6-6 6-6']);

  static const lock = IconSpec(<String>[
    'M7 11h10a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-6a2 2 0 0 1 2-2z',
    'M8 11V8a4 4 0 0 1 8 0v3',
  ], strokeWidth: 2.2);

  static const tableCross = IconSpec(<String>[
    'M5 4h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z',
    'M3 10h18',
    'M9 10v10',
    'M14 14l4 4',
    'M18 14l-4 4',
  ], strokeWidth: 2.2);

  static const infoCircle = IconSpec(
    <String>[
      'M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z',
      'M12 7.5v5.5',
    ],
    dots: <(double, double, double)>[(12, 16.5, 0.6)],
    strokeWidth: 2.2,
  );

  static const upload = IconSpec(<String>[
    'M12 16V4',
    'M7 9l5-5 5 5',
    'M4 16v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3',
  ], strokeWidth: 1.8);

  static const check = IconSpec(<String>['M5 12l5 5 9-10'], strokeWidth: 3);

  static const cross = IconSpec(<String>['M1 1l8 8', 'M9 1L1 9'],
      strokeWidth: 1.4, viewBox: 10, cap: StrokeCap.butt);

  /// The line–diamond–line rule on a card face (34×8 grid).
  static const ornament = IconSpec(
    <String>[
      'M0 4h12',
      'M22 4h12',
      'M17 0.8l3 3.2-3 3.2-3-3.2z',
    ],
    strokeWidth: 1.2,
    viewBox: 34,
    cap: StrokeCap.butt,
  );

  /// Same rule, wider, for the full-screen reveal (90×16 grid).
  static const ornamentLarge = IconSpec(
    <String>[
      'M0 8h34',
      'M56 8h34',
      'M45 1l7 7-7 7-7-7z',
    ],
    strokeWidth: 1.4,
    viewBox: 90,
    cap: StrokeCap.butt,
  );

  // Window controls, drawn on a 10×10 grid with hairlines.
  static const winMinimize =
      IconSpec(<String>['M0 5h10'], strokeWidth: 1, viewBox: 10, cap: StrokeCap.butt);
  static const winMaximize = IconSpec(<String>['M0.5 0.5h9v9h-9z'],
      strokeWidth: 1, viewBox: 10, cap: StrokeCap.butt, join: StrokeJoin.miter);
  static const winRestore = IconSpec(<String>[
    'M0.5 2.5h7v7h-7z',
    'M2.5 2.5v-2h7v7h-2',
  ], strokeWidth: 1, viewBox: 10, cap: StrokeCap.butt, join: StrokeJoin.miter);
  static const winClose = IconSpec(<String>['M0 0l10 10', 'M10 0L0 10'],
      strokeWidth: 1, viewBox: 10, cap: StrokeCap.butt);
}

/// Renders an [IconSpec] at [size], scaling the stroke with it.
class StrokeIcon extends StatelessWidget {
  const StrokeIcon(
    this.spec, {
    super.key,
    this.size = 18,
    this.color,
    this.width,
    this.height,
  });

  final IconSpec spec;
  final double size;
  final Color? color;

  /// For non-square grids like the ornament.
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    final w = width ?? size;
    final h = height ?? w;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(painter: _IconPainter(spec, c)),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.spec, this.color);

  final IconSpec spec;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / spec.viewBox;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = spec.strokeWidth
      ..strokeCap = spec.cap
      ..strokeJoin = spec.join
      ..color = color;
    for (final d in spec.strokes) {
      canvas.drawPath(parseSvgPath(d), stroke);
    }
    final fill = Paint()..color = color;
    for (final (cx, cy, r) in spec.dots) {
      canvas.drawCircle(Offset(cx, cy), r, fill);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.color != color || !identical(old.spec, spec);
}

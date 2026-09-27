import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tokens.dart';
import '../../state/app_state.dart';

/// The layer under the whole table: glow, a seasonal photo, a flat colour or
/// the user's own image — plus the dimming from settings.
class TableBackground extends ConsumerWidget {
  const TableBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final settings = ref.watch(settingsProvider);
    final tokens = ref.watch(tokensProvider);
    final id = settings.effectiveBackground;
    final def = tokens.background(id);

    final photo = switch (def.kind) {
      BackgroundKind.image => _Photo.asset(def.file!),
      BackgroundKind.file => settings.customBackgroundPath == null
          ? null
          : _Photo.file(settings.customBackgroundPath!),
      _ => null,
    };

    final overlayAlpha = photo != null
        ? ((deck.dark ? 0.58 : 0.62) + settings.dim / 100).clamp(0.0, 0.97)
        : settings.dim / 200;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: deck.bg),
        if (photo != null) Positioned.fill(child: photo),
        if (def.kind == BackgroundKind.animated)
          Positioned.fill(
            child: _Glow(
              colour: deck.glow,
              accent: deck.accent,
              animate: settings.animations,
            ),
          ),
        if (overlayAlpha > 0)
          Positioned.fill(
            child: ColoredBox(color: deck.bg.withValues(alpha: overlayAlpha)),
          ),
        child,
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo.asset(this.path) : isFile = false;
  const _Photo.file(this.path) : isFile = true;

  final String path;
  final bool isFile;

  @override
  Widget build(BuildContext context) => isFile
      ? Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        )
      : Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
}

/// A big soft radial bloom plus 14 slowly rising motes.
class _Glow extends StatefulWidget {
  const _Glow({
    required this.colour,
    required this.accent,
    required this.animate,
  });

  final Color colour;
  final Color accent;
  final bool animate;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with TickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  /// One minute per turn; every mote period divides it, so the loop is seamless.
  late final AnimationController _motes = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _flicker.repeat();
      _motes.repeat();
    }
  }

  @override
  void didUpdateWidget(_Glow old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_flicker.isAnimating) {
      _flicker.repeat();
      _motes.repeat();
    } else if (!widget.animate && _flicker.isAnimating) {
      _flicker.stop();
      _motes.stop();
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    _motes.dispose();
    super.dispose();
  }

  /// opacity .8 → 1 → .72 → .92 → .8, scale 1 → 1.03 → 1 over six seconds.
  (double, double) _flickerAt(double t) {
    double lerp(double a, double b, double f) => a + (b - a) * f;
    final double opacity;
    if (t < 0.30) {
      opacity = lerp(0.80, 1.00, t / 0.30);
    } else if (t < 0.55) {
      opacity = lerp(1.00, 0.72, (t - 0.30) / 0.25);
    } else if (t < 0.80) {
      opacity = lerp(0.72, 0.92, (t - 0.55) / 0.25);
    } else {
      opacity = lerp(0.92, 0.80, (t - 0.80) / 0.20);
    }
    final scale = t < 0.55
        ? lerp(1.0, 1.03, t / 0.55)
        : lerp(1.03, 1.0, (t - 0.55) / 0.45);
    return (opacity, scale);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_flicker, _motes]),
        builder: (context, _) {
          final (opacity, scale) =
              widget.animate ? _flickerAt(_flicker.value) : (0.9, 1.0);
          return CustomPaint(
            painter: _GlowPainter(
              colour: widget.colour,
              accent: widget.accent,
              opacity: opacity,
              scale: scale,
              motePhase: widget.animate ? _motes.value * 60 : null,
            ),
          );
        },
      ),
    );
  }
}

/// `(xPercent, sizePx, periodSeconds, phaseSeconds)`
const List<(double, double, double, double)> _motes =
    <(double, double, double, double)>[
  (0.06, 2, 15, 2),
  (0.14, 3, 20, 9),
  (0.22, 2, 12, 5),
  (0.31, 2, 20, 12),
  (0.39, 3, 15, 1),
  (0.47, 2, 12, 7),
  (0.55, 3, 20, 14),
  (0.62, 2, 15, 4),
  (0.70, 3, 12, 10),
  (0.78, 2, 20, 6),
  (0.86, 3, 15, 13),
  (0.93, 2, 12, 3),
  (0.18, 2, 20, 8),
  (0.51, 3, 15, 11),
];

class _GlowPainter extends CustomPainter {
  const _GlowPainter({
    required this.colour,
    required this.accent,
    required this.opacity,
    required this.scale,
    required this.motePhase,
  });

  final Color colour;
  final Color accent;
  final double opacity;
  final double scale;

  /// Seconds into the mote loop, or `null` when animations are off.
  final double? motePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width * 0.36, size.height * 0.48);
    final radius = 750.0 * scale;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          colour.withValues(alpha: colour.a * opacity),
          colour.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(Offset.zero & size, paint);

    final phase = motePhase;
    if (phase == null) return;
    for (final (xp, dot, period, delay) in _motes) {
      final p = ((phase + delay) % period) / period;
      // 0 → 0, 0.5 → (18, −700), 1 → (−12, −1500); fades in and out.
      final double dx, dy, alpha;
      if (p < 0.5) {
        final f = p / 0.5;
        dx = 18 * f;
        dy = -700 * f;
        alpha = p < 0.1 ? 0.7 * (p / 0.1) : 0.7 + (0.45 - 0.7) * ((p - 0.1) / 0.4);
      } else {
        final f = (p - 0.5) / 0.5;
        dx = 18 + (-12 - 18) * f;
        dy = -700 + (-1500 + 700) * f;
        alpha = 0.45 * (1 - f);
      }
      final y = size.height + 10 + dy;
      if (y < -dot || y > size.height + 20) continue;
      canvas.drawCircle(
        Offset(size.width * xp + dx, y),
        dot / 2,
        Paint()..color = accent.withValues(alpha: math.max(0, alpha)),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.colour != colour ||
      old.accent != accent ||
      old.opacity != opacity ||
      old.scale != scale ||
      old.motePhase != motePhase;
}

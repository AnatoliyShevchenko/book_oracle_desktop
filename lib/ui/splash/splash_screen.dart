import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tokens.dart';
import '../deal/card_back.dart';

/// Shown in the app's version corner.
const String kAppVersion = 'v1.0';

/// What the splash says while it waits.
enum SplashStatus { loading, cached, firstRun }

/// The 560×340 frameless start-up window.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, required this.statusText});

  final String statusText;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const double _cardWidth = 54;

  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _timeline.dispose();
    _bar.dispose();
    super.dispose();
  }

  double _seg(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    const fan = Cubic(0.2, 0.8, 0.2, 1);

    return ColoredBox(
      color: deck.bg,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: _SplashGlowPainter(deck.glow)),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _timeline,
              builder: (context, _) {
                final t = _timeline.value * 2.2;
                final side = fan.transform(_seg(t, 0.35, 1.15));
                final lift = fan.transform(_seg(t, 0.60, 1.30));
                final title = Curves.easeOut.transform(_seg(t, 1.05, 1.75));
                final status = Curves.easeOut.transform(_seg(t, 1.40, 2.00));

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: _cardWidth * 2.6,
                      height: _cardWidth * 1.75,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          _FanCard(
                            index: 1,
                            width: _cardWidth,
                            dx: -0.42 * _cardWidth * side,
                            angle: -14 * side,
                          ),
                          _FanCard(
                            index: 2,
                            width: _cardWidth,
                            dx: 0.42 * _cardWidth * side,
                            angle: 14 * side,
                          ),
                          _FanCard(
                            index: 0,
                            width: _cardWidth,
                            dy: -0.12 * _cardWidth * lift,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: title,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - title)),
                        child: Text(
                          'Book Oracle',
                          style: deck.display(size: 34, height: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: status,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - status)),
                        child: Text(
                          widget.statusText,
                          textAlign: TextAlign.center,
                          style: deck.body(size: 13, color: deck.muted),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            right: 14,
            bottom: 12,
            child: Text(
              kAppVersion,
              style: deck.body(size: 11, color: deck.muted),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_timeline, _bar]),
              builder: (context, _) => Opacity(
                opacity: _seg(_timeline.value * 2.2, 1.4, 1.8),
                child: SizedBox(
                  height: 3,
                  child: ColoredBox(
                    color: deck.line,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final segment = c.maxWidth * 0.3;
                        final travel = Curves.easeInOut.transform(_bar.value);
                        return Stack(
                          children: <Widget>[
                            Positioned(
                              left: -segment + (c.maxWidth + segment) * travel,
                              top: 0,
                              bottom: 0,
                              width: segment,
                              child: ColoredBox(color: deck.accent),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FanCard extends StatelessWidget {
  const _FanCard({
    required this.index,
    required this.width,
    this.dx = 0,
    this.dy = 0,
    this.angle = 0,
  });

  final int index;
  final double width;
  final double dx;
  final double dy;

  /// Degrees.
  final double angle;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        // The design pivots the fan below the cards, at 50 % / 115 %.
        alignment: const Alignment(0, 1.3),
        angle: angle * math.pi / 180,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width * 0.09),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x4D000000), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width * 0.09),
            child: CardBackView(index: index),
          ),
        ),
      ),
    );
  }
}

class _SplashGlowPainter extends CustomPainter {
  const _SplashGlowPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.46);
    final rect = Rect.fromCircle(center: centre, radius: 260);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[colour, colour.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SplashGlowPainter old) => old.colour != colour;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/card_colors.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/deal_state.dart';
import '../widgets/buttons.dart';
import '../widgets/icons.dart';
import 'card_back.dart';

/// The full-screen announcement of the winning card.
class RevealOverlay extends ConsumerStatefulWidget {
  const RevealOverlay({
    super.key,
    required this.book,
    required this.cardIndex,
    required this.animate,
  });

  final Book book;

  /// Position in the spread, so a photo deck picks the same back.
  final int cardIndex;
  final bool animate;

  @override
  ConsumerState<RevealOverlay> createState() => _RevealOverlayState();
}

class _RevealOverlayState extends ConsumerState<RevealOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  late final AnimationController _rays = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _timeline.forward();
      _rays.repeat();
    } else {
      _timeline.value = 1;
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    _rays.dispose();
    super.dispose();
  }

  /// Progress of the segment between [start] and [end] seconds.
  double _seg(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final tokens = ref.watch(tokensProvider);
    final (face, ink) = autoCardColour(widget.book.title, tokens);

    return LayoutBuilder(
      builder: (context, constraints) {
        // The card is half the window tall, in 1 : 1.4.
        final cardHeight = constraints.maxHeight * 0.5;
        final cardWidth = cardHeight / 1.4;
        final titleSize = cardHeight * 0.075;

        return AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_timeline, _rays]),
          builder: (context, _) {
            final t = _timeline.value * 3.2;
            final scrim = _seg(t, 0, 0.5);
            final header = Curves.easeOut.transform(_seg(t, 0.3, 1.0));
            final fly = Curves.easeOutCubic.transform(_seg(t, 0.2, 1.0));
            final flip = Curves.easeInOut.transform(_seg(t, 1.2, 2.2));
            final raysIn = Curves.easeOut.transform(_seg(t, 1.3, 2.5));
            final actions = Curves.easeOut.transform(_seg(t, 2.2, 2.9));

            final angle = flip * math.pi;
            final showFace = angle >= math.pi / 2;

            return Opacity(
              opacity: scrim,
              child: ColoredBox(
                color: deck.scrim,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Opacity(
                      opacity: raysIn * 0.9,
                      child: Transform.rotate(
                        angle: _rays.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(900, 900),
                          painter: _RaysPainter(deck.accent),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Opacity(
                          opacity: header,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - header)),
                            child: Column(
                              children: <Widget>[
                                Eyebrow(
                                  s.revealEyebrow,
                                  color: deck.accent,
                                  size: 13,
                                  tracking: 0.28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.revealTitle,
                                  style: deck.display(size: 36, height: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Opacity(
                          opacity: fly,
                          child: Transform.translate(
                            offset: Offset(0, 160 * (1 - fly)),
                            child: Transform.scale(
                              scale: 0.28 + 0.72 * fly,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0006)
                                  ..rotateY(angle),
                                child: Container(
                                  width: cardWidth,
                                  height: cardHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: deck.accentGlow,
                                        blurRadius: 90,
                                      ),
                                      const BoxShadow(
                                        color: Color(0x80000000),
                                        blurRadius: 80,
                                        offset: Offset(0, 30),
                                      ),
                                    ],
                                  ),
                                  foregroundDecoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border:
                                        Border.all(color: deck.accent, width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: showFace
                                        ? Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.identity()
                                              ..rotateY(math.pi),
                                            child: _BigFace(
                                              book: widget.book,
                                              face: face,
                                              ink: ink,
                                              titleSize: titleSize,
                                            ),
                                          )
                                        : CardBackView(
                                            index: widget.cardIndex,
                                            deck: deck,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Opacity(
                          opacity: actions,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - actions)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                AppButton(
                                  label: s.backToTable,
                                  style: AppButtonStyle.ghost,
                                  onPressed:
                                      ref.read(dealProvider.notifier).closeReveal,
                                ),
                                const SizedBox(width: 12),
                                AppButton(
                                  label: s.newSpread,
                                  onPressed:
                                      ref.read(dealProvider.notifier).reshuffle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BigFace extends StatelessWidget {
  const _BigFace({
    required this.book,
    required this.face,
    required this.ink,
    required this.titleSize,
  });

  final Book book;
  final Color face;
  final Color ink;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: face),
        Positioned.fill(
          left: 14,
          top: 14,
          right: 14,
          bottom: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ink.withValues(alpha: 0.5)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  book.title,
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: deck.display(size: titleSize, color: ink, height: 1.05),
                ),
              ),
              if (book.author.isNotEmpty) ...<Widget>[
                const SizedBox(height: 22),
                StrokeIcon(AppIcons.ornamentLarge,
                    width: 80, height: 14, color: ink),
                const SizedBox(height: 22),
                Text(
                  book.author.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: deck.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: ink,
                    letterSpacing: 1.5,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 24 spokes plus the r=330 circle behind the card.
class _RaysPainter extends CustomPainter {
  const _RaysPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 24; i++) {
      final paint = Paint()
        ..color = accent.withValues(alpha: i.isOdd ? 0.22 : 0.45)
        ..strokeWidth = i.isOdd ? 1 : 2
        ..strokeCap = StrokeCap.round;
      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(i * 15 * math.pi / 180);
      canvas.drawLine(
        Offset(0, -size.height / 2 + 60),
        Offset(0, -size.height / 2 + 250),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      centre,
      330,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.accent != accent;
}

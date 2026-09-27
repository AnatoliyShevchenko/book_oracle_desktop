import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../widgets/buttons.dart';
import '../widgets/icons.dart';
import 'card_back.dart';

/// `grayscale(.8) brightness(.8)` from the design, as one colour matrix.
const ColorFilter kEliminatedFilter = ColorFilter.matrix(<double>[
  0.296064, 0.457728, 0.046208, 0, 0, //
  0.136064, 0.617728, 0.046208, 0, 0, //
  0.136064, 0.457728, 0.206208, 0, 0, //
  0, 0, 0, 1, 0, //
]);

const Duration kFlipDuration = Duration(milliseconds: 700);
const Cubic kFlipCurve = Cubic(0.3, 0.8, 0.25, 1);

/// One card on the table.
class DealCard extends StatefulWidget {
  const DealCard({
    super.key,
    required this.index,
    required this.title,
    required this.author,
    required this.faceColour,
    required this.inkColour,
    required this.width,
    required this.height,
    required this.isOut,
    required this.isWinner,
    required this.isLastStanding,
    required this.semanticLabel,
    required this.eliminatedLabel,
    this.onPressed,
    this.animate = true,
  });

  final int index;
  final String title;
  final String author;
  final Color faceColour;
  final Color inkColour;
  final double width;
  final double height;
  final bool isOut;
  final bool isWinner;
  final bool isLastStanding;
  final String semanticLabel;

  /// "ВЫБЫЛА" band text.
  final String eliminatedLabel;
  final VoidCallback? onPressed;
  final bool animate;

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: kFlipDuration,
    value: widget.isOut || widget.isWinner ? 1 : 0,
  );

  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _syncBreathe();
  }

  @override
  void didUpdateWidget(DealCard old) {
    super.didUpdateWidget(old);
    final shouldFlip = widget.isOut || widget.isWinner;
    if (shouldFlip && _flip.status != AnimationStatus.forward && _flip.value < 1) {
      widget.animate ? _flip.forward() : _flip.value = 1;
    } else if (!shouldFlip && _flip.value > 0) {
      _flip.value = 0;
    }
    _syncBreathe();
  }

  void _syncBreathe() {
    final wants = widget.isLastStanding && !widget.isWinner && widget.animate;
    if (wants && !_breathe.isAnimating) {
      _breathe.repeat(reverse: true);
    } else if (!wants && _breathe.isAnimating) {
      _breathe.stop();
      _breathe.value = 0;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final radius = BorderRadius.circular(10);
    final highlight = widget.isLastStanding || widget.isWinner;

    return Pressable(
      onPressed: widget.onPressed,
      semanticLabel: widget.semanticLabel,
      builder: (context, hovered, focused) => AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_flip, _breathe]),
        builder: (context, _) {
          final t = kFlipCurve.transform(_flip.value);
          final angle = t * math.pi;
          final showFace = angle >= math.pi / 2;
          final breathing = widget.isLastStanding && !widget.isWinner
              ? 1 + 0.05 * Curves.easeInOut.transform(_breathe.value)
              : (widget.isWinner ? 1.06 : 1.0);
          final lift = hovered && widget.onPressed != null ? -5.0 : 0.0;

          return Transform.translate(
            offset: Offset(0, lift),
            child: Transform.scale(
              scale: breathing,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateY(angle),
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: <BoxShadow>[
                      ...deck.cardShadow,
                      if (highlight)
                        BoxShadow(color: deck.accentGlow, blurRadius: 28),
                    ],
                  ),
                  foregroundDecoration: (focused || highlight)
                      ? BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(color: deck.accent, width: 2),
                        )
                      : null,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: showFace
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _Face(
                              title: widget.title,
                              author: widget.author,
                              background: widget.faceColour,
                              ink: widget.inkColour,
                              width: widget.width,
                              dimmed: widget.isOut && t > 0.64,
                              eliminated: widget.isOut,
                              eliminatedLabel: widget.eliminatedLabel,
                            ),
                          )
                        : CardBackView(index: widget.index, deck: deck),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.title,
    required this.author,
    required this.background,
    required this.ink,
    required this.width,
    required this.dimmed,
    required this.eliminated,
    required this.eliminatedLabel,
  });

  final String title;
  final String author;
  final Color background;
  final Color ink;
  final double width;
  final bool dimmed;
  final bool eliminated;
  final String eliminatedLabel;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final tiny = width < 78;
    final titleSize = cardTitleFontSize(width, tiny: tiny);
    final authorSize = cardAuthorFontSize(width);
    final bandSize = tiny ? 8.0 : 10.0;
    final padding = tiny
        ? const EdgeInsets.fromLTRB(4, 5, 4, 16)
        : (width < 120
            ? const EdgeInsets.fromLTRB(7, 8, 7, 22)
            : const EdgeInsets.fromLTRB(10, 12, 10, 26));

    Widget face = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: background),
        Positioned.fill(
          left: 5,
          top: 5,
          right: 5,
          bottom: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ink.withValues(alpha: 0.45)),
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: tiny ? 4 : 5,
                  overflow: TextOverflow.ellipsis,
                  style: deck.display(
                    size: titleSize,
                    weight: FontWeight.w600,
                    color: ink,
                    height: 1.08,
                  ),
                ),
              ),
              if (!tiny && author.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                StrokeIcon(AppIcons.ornament, width: 26, height: 7, color: ink),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    author.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: deck.body(
                      size: authorSize,
                      weight: FontWeight.w600,
                      color: ink,
                      letterSpacing: authorSize * 0.04,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (eliminated)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 5),
              color: const Color(0xB8000000),
              child: Text(
                eliminatedLabel.toUpperCase(),
                textAlign: TextAlign.center,
                style: deck.body(
                  size: bandSize,
                  weight: FontWeight.w700,
                  color: const Color(0xFFF1ECE4),
                  letterSpacing: bandSize * 0.14,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );

    if (dimmed) {
      face = ColorFiltered(colorFilter: kEliminatedFilter, child: face);
    }
    return face;
  }
}

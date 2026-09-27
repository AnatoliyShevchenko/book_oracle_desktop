import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Height of the custom window title bar.
const double kTitleBarHeight = 36;

/// Height reserved under the card grid for the hint row (28) plus its gap (16).
const double kHintRowBlock = 44;

/// A book is laid out 1 : 1.4.
const double kCardRatio = 1.4;

/// Cards never grow past this width, however much room there is.
const double kMaxCardWidth = 260;

/// Responsive step, keyed on window width (logical pixels).
@immutable
class LayoutTier {
  const LayoutTier({
    required this.id,
    required this.maxWidth,
    required this.pad,
    required this.panel,
    required this.gap,
    required this.panelFont,
  });

  final String id;

  /// Exclusive upper bound; `null` for the widest tier.
  final double? maxWidth;
  final double pad;
  final double panel;
  final int gap;
  final double panelFont;

  factory LayoutTier.fromJson(Map<String, dynamic> j) => LayoutTier(
        id: j['id'] as String,
        maxWidth: (j['maxWidth'] as num?)?.toDouble(),
        pad: (j['pad'] as num).toDouble(),
        panel: (j['panel'] as num).toDouble(),
        gap: (j['gap'] as num).toInt(),
        panelFont: (j['panelFont'] as num).toDouble(),
      );

  /// Vertical padding above the body — `pad / 2`, rounded like the design does.
  double get padTop => (pad / 2).roundToDouble();
}

/// The four tiers from design_tokens.json, mirrored here so pure layout code
/// (and its tests) need no asset bundle.
const List<LayoutTier> kLayoutTiers = <LayoutTier>[
  LayoutTier(id: 'S', maxWidth: 1400, pad: 20, panel: 280, gap: 10, panelFont: 13),
  LayoutTier(id: 'M', maxWidth: 1800, pad: 28, panel: 320, gap: 14, panelFont: 14),
  LayoutTier(id: 'L', maxWidth: 2200, pad: 36, panel: 360, gap: 16, panelFont: 15),
  LayoutTier(id: 'XL', maxWidth: null, pad: 48, panel: 420, gap: 20, panelFont: 17),
];

LayoutTier tierFor(double windowWidth, [List<LayoutTier> tiers = kLayoutTiers]) {
  for (final t in tiers) {
    if (t.maxWidth == null || windowWidth < t.maxWidth!) return t;
  }
  return tiers.last;
}

/// Free area of the table, given the whole window.
///
/// `aw = width − 3·pad − panel`, `ah = height − titleBar − pad/2 − pad − 44`.
({double width, double height}) tableArea(
  double windowWidth,
  double windowHeight,
  LayoutTier tier,
) =>
    (
      width: windowWidth - tier.pad * 3 - tier.panel,
      height: windowHeight - kTitleBarHeight - tier.padTop - tier.pad - kHintRowBlock,
    );

/// Gap between cards shrinks as the deck grows.
int gapForCount(int n, LayoutTier tier) {
  if (n <= 24) return tier.gap;
  if (n <= 40) return (tier.gap * 0.7).round();
  return (tier.gap * 0.5).round();
}

@immutable
class GridSpec {
  const GridSpec({
    required this.cols,
    required this.rows,
    required this.cardWidth,
    required this.cardHeight,
    required this.gap,
  });

  final int cols;
  final int rows;
  final double cardWidth;
  final double cardHeight;
  final int gap;

  /// Below this width a card shows its title only.
  bool get tiny => cardWidth < 78;

  @override
  bool operator ==(Object other) =>
      other is GridSpec &&
      other.cols == cols &&
      other.rows == rows &&
      other.cardWidth == cardWidth &&
      other.cardHeight == cardHeight &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(cols, rows, cardWidth, cardHeight, gap);

  @override
  String toString() =>
      'GridSpec(cols: $cols, rows: $rows, card: ${cardWidth}x$cardHeight, gap: $gap)';
}

/// How much card width a full rectangle may cost before we give up on it.
///
/// A ragged last row (20 cards as 7 + 7 + 6) reads worse than a clean block
/// (5 × 4), so a column count that divides the deck exactly wins as long as its
/// cards stay within this fraction of the largest possible.
const double kRectanglePreference = 0.8;

/// Picks the column count that makes the cards as large as possible inside
/// `aw × ah`, preferring a complete rectangle, then floors the card box to
/// whole pixels.
GridSpec computeGrid({
  required double areaWidth,
  required double areaHeight,
  required int n,
  required LayoutTier tier,
}) {
  final count = math.max(1, n);
  final gap = gapForCount(count, tier);

  double widthFor(int cols) {
    final rows = (count / cols).ceil();
    return math.min(
      (areaWidth - gap * (cols - 1)) / cols,
      ((areaHeight - gap * (rows - 1)) / rows) / kCardRatio,
    );
  }

  var bestCols = 1;
  var bestW = 0.0;
  var squareCols = 0;
  var squareW = 0.0;
  for (var cols = 1; cols <= count; cols++) {
    final w = widthFor(cols);
    if (w > bestW) {
      bestW = w;
      bestCols = cols;
    }
    if (count % cols == 0 && w > squareW) {
      squareW = w;
      squareCols = cols;
    }
  }
  if (squareCols > 0 && squareW >= bestW * kRectanglePreference) {
    bestCols = squareCols;
    bestW = squareW;
  }

  final cardW = math.max(1.0, math.min(bestW, kMaxCardWidth).floorToDouble());
  final cardH = (cardW * kCardRatio).floorToDouble();
  return GridSpec(
    cols: bestCols,
    rows: (count / bestCols).ceil(),
    cardWidth: cardW,
    cardHeight: cardH,
    gap: gap,
  );
}

/// Title size on a card face: 10 % of the card width (13 % when tiny),
/// clamped to 9–24 px.
double cardTitleFontSize(double cardWidth, {required bool tiny}) =>
    (cardWidth * (tiny ? 0.13 : 0.10)).roundToDouble().clamp(9.0, 24.0);

/// Author size: 6.2 % of the card width, clamped to 8–14 px.
double cardAuthorFontSize(double cardWidth) =>
    (cardWidth * 0.062).roundToDouble().clamp(8.0, 14.0);

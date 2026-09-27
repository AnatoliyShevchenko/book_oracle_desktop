import 'package:book_oracle/core/layout.dart';
import 'package:flutter_test/flutter_test.dart';

GridSpec gridFor(double w, double h, int n) {
  final tier = tierFor(w);
  final area = tableArea(w, h, tier);
  return computeGrid(
    areaWidth: area.width,
    areaHeight: area.height,
    n: n,
    tier: tier,
  );
}

void main() {
  group('tiers', () {
    test('boundaries follow design_tokens.json', () {
      expect(tierFor(1280).id, 'S');
      expect(tierFor(1366).id, 'S');
      expect(tierFor(1399).id, 'S');
      expect(tierFor(1400).id, 'M');
      expect(tierFor(1536).id, 'M');
      expect(tierFor(1799).id, 'M');
      expect(tierFor(1800).id, 'L');
      expect(tierFor(1920).id, 'L');
      expect(tierFor(2199).id, 'L');
      expect(tierFor(2200).id, 'XL');
      expect(tierFor(2560).id, 'XL');
      expect(tierFor(4000).id, 'XL');
    });
  });

  group('gap scales with the deck size', () {
    const m = LayoutTier(
        id: 'M', maxWidth: 1800, pad: 28, panel: 320, gap: 14, panelFont: 14);
    test('24 or fewer keeps the full gap', () {
      expect(gapForCount(2, m), 14);
      expect(gapForCount(24, m), 14);
    });
    test('25–40 uses 70 %', () => expect(gapForCount(40, m), 10));
    test('over 40 uses 50 %', () => expect(gapForCount(60, m), 7));
  });

  group('reference layouts from the spec (n = 24)', () {
    test('1280×720 → 8 columns, card about 108×151', () {
      final g = gridFor(1280, 720, 24);
      expect(g.cols, 8);
      expect(g.rows, 3);
      expect(g.cardWidth, closeTo(108, 1));
      expect(g.cardHeight, closeTo(151, 2));
    });

    test('1536×864 → 8 columns, card about 129×180', () {
      final g = gridFor(1536, 864, 24);
      expect(g.cols, 8);
      expect(g.cardWidth, closeTo(129, 1));
      expect(g.cardHeight, closeTo(180, 2));
    });

    test('2560×1440 → 8 columns, card about 232×324', () {
      final g = gridFor(2560, 1440, 24);
      expect(g.cols, 8);
      expect(g.cardWidth, closeTo(232, 1));
      expect(g.cardHeight, closeTo(324, 2));
    });
  });

  group('a complete rectangle is preferred over a ragged last row', () {
    test('20 cards at 1536×864 lay out 5 × 4, not 7 + 7 + 6', () {
      final g = gridFor(1536, 864, 20);
      expect(g.cols, 5);
      expect(g.rows, 4);
      expect(g.cols * g.rows, 20);
    });

    test('20 cards at 1280×720 also come out rectangular', () {
      final g = gridFor(1280, 720, 20);
      expect(g.cols * g.rows, 20);
    });

    test('the reference n = 24 layouts are unaffected', () {
      for (final (w, h) in const <(double, double)>[
        (1280, 720),
        (1536, 864),
        (2560, 1440),
      ]) {
        expect(gridFor(w, h, 24).cols, 8, reason: '$w×$h');
      }
    });

    test('a prime count falls back to the largest cards', () {
      // 7 divides only into 1 × 7 or 7 × 1, both far too small, so the
      // ragged-but-roomy layout wins.
      final g = gridFor(1536, 864, 7);
      expect(g.cols, lessThan(7));
      expect(g.cols * g.rows, greaterThanOrEqualTo(7));
    });

    test('a rectangle is refused when it costs too much card size', () {
      // 5 × 4 must never be chosen if its cards fall below the threshold.
      final tier = tierFor(1536);
      final area = tableArea(1536, 864, tier);
      final g = computeGrid(
          areaWidth: area.width, areaHeight: area.height, n: 20, tier: tier);
      var unconstrained = 0.0;
      for (var cols = 1; cols <= 20; cols++) {
        final rows = (20 / cols).ceil();
        final gap = gapForCount(20, tier);
        final w = <double>[
          (area.width - gap * (cols - 1)) / cols,
          ((area.height - gap * (rows - 1)) / rows) / kCardRatio,
        ].reduce((a, b) => a < b ? a : b);
        if (w > unconstrained) unconstrained = w;
      }
      expect(g.cardWidth,
          greaterThanOrEqualTo(unconstrained * kRectanglePreference - 1));
    });
  });

  group('edge cases at 1280×720', () {
    test('n = 2 fits and is capped at 260 px wide', () {
      final g = gridFor(1280, 720, 2);
      expect(g.cols, 2);
      expect(g.rows, 1);
      expect(g.cardWidth, lessThanOrEqualTo(kMaxCardWidth));
      expect(g.cardHeight, lessThanOrEqualTo(610));
    });

    test('n = 60 still fits inside the free area', () {
      final g = gridFor(1280, 720, 60);
      final tier = tierFor(1280);
      final area = tableArea(1280, 720, tier);
      expect(g.cols * g.cardWidth + (g.cols - 1) * g.gap,
          lessThanOrEqualTo(area.width + 0.5));
      expect(g.rows * g.cardHeight + (g.rows - 1) * g.gap,
          lessThanOrEqualTo(area.height + 0.5));
      expect(g.cardWidth, greaterThan(0));
    });

    test('every deck size from 2 to 60 fits at every reference resolution', () {
      const sizes = <(double, double)>[
        (1280, 720),
        (1366, 768),
        (1536, 864),
        (1920, 1080),
        (2560, 1440),
      ];
      for (final (w, h) in sizes) {
        final tier = tierFor(w);
        final area = tableArea(w, h, tier);
        for (var n = 2; n <= 60; n++) {
          final g = gridFor(w, h, n);
          final usedWidth =
              g.cols * g.cardWidth + (g.cols - 1) * g.gap;
          final usedHeight =
              g.rows * g.cardHeight + (g.rows - 1) * g.gap;
          expect(usedWidth, lessThanOrEqualTo(area.width + 0.5),
              reason: 'width overflow at ${w}x$h, n=$n');
          expect(usedHeight, lessThanOrEqualTo(area.height + 0.5),
              reason: 'height overflow at ${w}x$h, n=$n');
          expect(g.cols * g.rows, greaterThanOrEqualTo(n));
        }
      }
    });
  });

  group('card typography', () {
    test('title is 10 % of the width, clamped to 9–24', () {
      expect(cardTitleFontSize(129, tiny: false), 13);
      expect(cardTitleFontSize(260, tiny: false), 24);
      expect(cardTitleFontSize(40, tiny: false), 9);
    });

    test('a tiny card uses 13 %', () {
      expect(cardTitleFontSize(70, tiny: true), 9);
      expect(cardTitleFontSize(77, tiny: true), 10);
    });

    test('author is 6.2 % of the width, clamped to 8–14', () {
      expect(cardAuthorFontSize(129), 8);
      expect(cardAuthorFontSize(260), 14);
    });
  });
}

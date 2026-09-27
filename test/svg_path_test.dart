import 'package:book_oracle/ui/widgets/icons.dart';
import 'package:book_oracle/ui/widgets/svg_path.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every icon the app draws, so a bad `d` string fails here and not in paint().
const List<(String, IconSpec)> _allIcons = <(String, IconSpec)>[
  ('refresh', AppIcons.refresh),
  ('wifiOff', AppIcons.wifiOff),
  ('wifiOffSmall', AppIcons.wifiOffSmall),
  ('checkCircle', AppIcons.checkCircle),
  ('sheet', AppIcons.sheet),
  ('bookCheck', AppIcons.bookCheck),
  ('dice', AppIcons.dice),
  ('shuffle', AppIcons.shuffle),
  ('gear', AppIcons.gear),
  ('arrowRight', AppIcons.arrowRight),
  ('chevronLeft', AppIcons.chevronLeft),
  ('lock', AppIcons.lock),
  ('tableCross', AppIcons.tableCross),
  ('infoCircle', AppIcons.infoCircle),
  ('upload', AppIcons.upload),
  ('check', AppIcons.check),
  ('cross', AppIcons.cross),
  ('ornament', AppIcons.ornament),
  ('ornamentLarge', AppIcons.ornamentLarge),
  ('winMinimize', AppIcons.winMinimize),
  ('winMaximize', AppIcons.winMaximize),
  ('winRestore', AppIcons.winRestore),
  ('winClose', AppIcons.winClose),
];

void main() {
  group('parseSvgPath', () {
    test('absolute move and line', () {
      final b = parseSvgPath('M5 12h14').getBounds();
      expect(b.left, 5);
      expect(b.right, 19);
      expect(b.top, 12);
    });

    test('relative commands chain from the current point', () {
      final b = parseSvgPath('M0 0l10 10').getBounds();
      expect(b.right, 10);
      expect(b.bottom, 10);
    });

    test('an implicit lineto after moveto', () {
      final b = parseSvgPath('M0 0 5 5 10 0').getBounds();
      expect(b.right, 10);
      expect(b.bottom, 5);
    });

    test('a dot starts a new number: "l.1.1" is two coordinates', () {
      final b = parseSvgPath('M0 0l.1.1').getBounds();
      expect(b.right, closeTo(0.1, 1e-6));
      expect(b.bottom, closeTo(0.1, 1e-6));
    });

    test('negative numbers need no separator', () {
      final b = parseSvgPath('M10 10l-5-5').getBounds();
      expect(b.left, 5);
      expect(b.top, 5);
    });

    test('h and v', () {
      final b = parseSvgPath('M0.5 0.5h9v9h-9z').getBounds();
      expect(b.left, 0.5);
      expect(b.right, 9.5);
      expect(b.bottom, 9.5);
    });

    test('an arc sweeps a half circle', () {
      final b = parseSvgPath('M0 10a10 10 0 0 1 20 0').getBounds();
      expect(b.left, closeTo(0, 0.01));
      expect(b.right, closeTo(20, 0.01));
      expect(b.top, closeTo(0, 0.05));
    });

    test('a full circle built from two arcs', () {
      final b = parseSvgPath('M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z')
          .getBounds();
      expect(b.left, closeTo(3, 0.05));
      expect(b.right, closeTo(21, 0.05));
      expect(b.top, closeTo(3, 0.05));
      expect(b.bottom, closeTo(21, 0.05));
    });

    test('cubic curves', () {
      final b = parseSvgPath('M0 0C0 10 10 10 10 0').getBounds();
      expect(b.right, 10);
      expect(b.bottom, greaterThan(0));
    });

    test('an empty string yields an empty path', () {
      expect(parseSvgPath('').getBounds(), Rect.zero);
    });
  });

  group('every icon parses and stays inside its view box', () {
    for (final (name, spec) in _allIcons) {
      test(name, () {
        for (final d in spec.strokes) {
          final path = parseSvgPath(d);
          final bounds = path.getBounds();
          // A straight horizontal or vertical stroke has zero area, so check
          // that at least one dimension came out non-zero.
          expect(bounds.width > 0 || bounds.height > 0, isTrue,
              reason: '$name: "$d" produced nothing');
          expect(bounds.left, greaterThanOrEqualTo(-1), reason: '$name left');
          expect(bounds.top, greaterThanOrEqualTo(-1), reason: '$name top');
          expect(bounds.right, lessThanOrEqualTo(spec.viewBox + 1),
              reason: '$name right');
          expect(bounds.bottom, lessThanOrEqualTo(spec.viewBox + 1),
              reason: '$name bottom');
        }
      });
    }
  });
}

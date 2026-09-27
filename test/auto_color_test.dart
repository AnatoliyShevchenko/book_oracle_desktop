import 'dart:io';

import 'package:book_oracle/core/card_colors.dart';
import 'package:book_oracle/core/hash.dart';
import 'package:book_oracle/core/layout.dart';
import 'package:book_oracle/core/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

DesignTokens loadTokensFromDisk() =>
    DesignTokens.parse(File('assets/design_tokens.json').readAsStringSync());

void main() {
  group('parseToken', () {
    test('#RRGGBB gets full alpha', () {
      expect(parseToken('#141517').toARGB32(), 0xFF141517);
    });

    test('#RRGGBBAA moves the alpha to the front', () {
      expect(parseToken('#ECEAE417').toARGB32(), 0x17ECEAE4);
      expect(parseToken('#E8A33D24').toARGB32(), 0x24E8A33D);
    });

    test('a bad token throws', () {
      expect(() => parseToken('#FFF'), throwsFormatException);
    });
  });

  group('FNV-1a', () {
    test('matches the reference values for the empty string and "a"', () {
      expect(fnv1a(''), 0x811c9dc5);
      expect(fnv1a('a'), 0xe40c292c);
      expect(fnv1a('foobar'), 0xbf9cf968);
    });

    test('stays inside 32 bits for long Cyrillic input', () {
      final h = fnv1a('Джонатан Стрендж и мистер Норрелл' * 20);
      expect(h, inInclusiveRange(0, 0xFFFFFFFF));
    });
  });

  group('auto card colours', () {
    late DesignTokens tokens;

    setUp(() => tokens = loadTokensFromDisk());

    test('the palette has 24 pairs', () {
      expect(tokens.autoCardColors.length, 24);
    });

    test('the same title always gets the same pair', () {
      const title = 'Мастер и Маргарита';
      final first = autoCardColour(title, tokens);
      for (var i = 0; i < 50; i++) {
        expect(autoCardColour(title, tokens), first);
      }
    });

    test('the index stays inside the palette', () {
      final titles = <String>[
        'Вий',
        'Цирцея',
        '1984',
        '',
        'x' * 500,
        'Дом, в котором…',
        'Solaris',
      ];
      for (final t in titles) {
        expect(autoColorIndex(t, 24), inInclusiveRange(0, 23));
      }
    });

    test('different titles generally get different pairs', () {
      const titles = <String>[
        'Вий',
        'Цирцея',
        'Дракула',
        'Ребекка',
        'Коралина',
        'Солярис',
      ];
      final indices = titles.map((t) => autoColorIndex(t, 24)).toSet();
      expect(indices.length, greaterThan(3));
    });

    test('an empty palette does not crash', () {
      expect(autoColorIndex('anything', 0), 0);
    });
  });

  group('design tokens', () {
    late DesignTokens tokens;

    setUp(() => tokens = loadTokensFromDisk());

    test('all five decks parse', () {
      expect(tokens.decks.keys.toSet(), DesignTokens.deckOrder.toSet());
      for (final id in DesignTokens.deckOrder) {
        final d = tokens.deck(id);
        expect(d.displayFont, isNotEmpty);
        expect(d.bodyFont, isNotEmpty);
        expect(d.cardShadow, isNotEmpty);
      }
    });

    test('all seven backgrounds parse', () {
      expect(tokens.backgrounds.keys.toSet(),
          DesignTokens.backgroundOrder.toSet());
    });

    test('image decks list their files', () {
      expect(tokens.deck('coven').back.kind, CardBackKind.images);
      expect(tokens.deck('coven').back.files.length, 3);
      expect(tokens.deck('coven').back.imageFor(4),
          tokens.deck('coven').back.files[1]);
      expect(tokens.deck('graphite').back.kind, CardBackKind.pattern);
    });

    test('the layout tiers match the built-in copy', () {
      expect(tokens.layoutTiers.map((t) => t.id).toList(),
          <String>['S', 'M', 'L', 'XL']);
      for (var i = 0; i < tokens.layoutTiers.length; i++) {
        final a = tokens.layoutTiers[i];
        final b = kLayoutTiers[i];
        expect(a.pad, b.pad);
        expect(a.panel, b.panel);
        expect(a.gap, b.gap);
        expect(a.panelFont, b.panelFont);
        expect(a.maxWidth, b.maxWidth);
      }
    });
  });
}

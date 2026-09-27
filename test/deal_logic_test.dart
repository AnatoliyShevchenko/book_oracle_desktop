import 'dart:math';

import 'package:book_oracle/data/models.dart';
import 'package:book_oracle/data/sheet_loader.dart';
import 'package:book_oracle/data/settings_repo.dart';
import 'package:book_oracle/state/deal_state.dart';
import 'package:flutter_test/flutter_test.dart';

List<Book> _books(int n) => List<Book>.generate(
      n,
      (i) => Book(title: 'Книга $i', author: 'Автор $i', read: false),
    );

void main() {
  group('buildDeck', () {
    test('keeps every book when there are 60 or fewer', () {
      final deck = buildDeck(_books(24), Random(1));
      expect(deck.length, 24);
      expect(deck.map((b) => b.title).toSet().length, 24);
    });

    test('caps a longer list at 60 and takes a random subset', () {
      final deck = buildDeck(_books(150), Random(1));
      expect(deck.length, kMaxDeck);
      expect(deck.map((b) => b.title).toSet().length, kMaxDeck);
    });

    test('two different seeds usually give a different order', () {
      final a = buildDeck(_books(30), Random(1)).map((b) => b.title).toList();
      final b = buildDeck(_books(30), Random(2)).map((b) => b.title).toList();
      expect(a, isNot(equals(b)));
    });
  });

  group('DealState', () {
    DealState state(int n, Set<int> out, {int? winner}) => DealState(
          cards: _books(n),
          out: out,
          winner: winner,
          poolSize: n,
        );

    test('progress is eliminated / (n − 1)', () {
      expect(state(5, <int>{}).progress, 0);
      expect(state(5, <int>{0, 1}).progress, 0.5);
      expect(state(5, <int>{0, 1, 2, 3}).progress, 1);
    });

    test('lastStanding is true only with one card left', () {
      expect(state(5, <int>{0, 1, 2}).lastStanding, isFalse);
      expect(state(5, <int>{0, 1, 2, 3}).lastStanding, isTrue);
    });

    test('available excludes the eliminated and the winner', () {
      final s = state(5, <int>{0, 1}, winner: 4);
      expect(s.available, <int>[2, 3]);
    });

    test('the log is newest first', () {
      final s = state(5, <int>{0, 2, 4});
      expect(s.log, <int>[4, 2, 0]);
    });

    test('capped reports a spread drawn from a longer list', () {
      expect(const DealState(poolSize: 90).capped, isTrue);
      expect(state(24, <int>{}).capped, isFalse);
    });
  });

  group('seasonal background', () {
    test('months map to the four seasons', () {
      expect(AppSettings.seasonForDate(DateTime(2026, 1, 15)), 'winter');
      expect(AppSettings.seasonForDate(DateTime(2026, 2, 28)), 'winter');
      expect(AppSettings.seasonForDate(DateTime(2026, 3, 1)), 'spring');
      expect(AppSettings.seasonForDate(DateTime(2026, 5, 31)), 'spring');
      expect(AppSettings.seasonForDate(DateTime(2026, 6, 1)), 'summer');
      expect(AppSettings.seasonForDate(DateTime(2026, 8, 31)), 'summer');
      expect(AppSettings.seasonForDate(DateTime(2026, 9, 27)), 'autumn');
      expect(AppSettings.seasonForDate(DateTime(2026, 11, 30)), 'autumn');
      expect(AppSettings.seasonForDate(DateTime(2026, 12, 1)), 'winter');
    });

    test('the override only applies when the switch is on', () {
      const off = AppSettings(background: 'glow');
      expect(off.effectiveBackground, 'glow');
      const on = AppSettings(background: 'glow', seasonalBackground: true);
      expect(on.effectiveBackground,
          AppSettings.seasonForDate(DateTime.now()));
    });
  });

  group('SheetLoader.parseMetaHtml', () {
    test('reads the document title and the tab list', () {
      const html = '''
<html><head><title>Что почитать - Google Sheets</title></head>
<body><ul>
<li id="sheet-button-0" class="switcherItem">Книги</li>
<li id="sheet-button-825467" class="switcherItem">Фильмы</li>
</ul></body></html>''';
      final meta = SheetLoader.parseMetaHtml(html)!;
      expect(meta.documentName, 'Что почитать');
      expect(meta.tabs.map((t) => t.gid), <String>['0', '825467']);
      expect(meta.tabs.map((t) => t.name), <String>['Книги', 'Фильмы']);
    });

    test('unescapes entities in the title', () {
      const html = '<html><head><title>A &amp; B - Google Sheets</title></head></html>';
      expect(SheetLoader.parseMetaHtml(html)!.documentName, 'A & B');
    });

    test('returns null when there is nothing to read', () {
      expect(SheetLoader.parseMetaHtml('<html><body>hi</body></html>'), isNull);
    });
  });

  group('LibraryData', () {
    test('counts unread, read and total', () {
      final data = LibraryData(
        sheetUrl: '',
        sheetId: 'x',
        gid: '0',
        columns: const <String>['title', 'author', 'read'],
        loadedAt: DateTime(2026),
        books: const <Book>[
          Book(title: 'A', author: '', read: false),
          Book(title: 'B', author: '', read: true),
          Book(title: 'C', author: '', read: false),
        ],
      );
      expect(data.total, 3);
      expect(data.deckCount, 2);
      expect(data.readCount, 1);
    });

    test('survives a JSON round trip', () {
      final data = LibraryData(
        sheetUrl: 'u',
        sheetId: 'x',
        gid: '7',
        documentName: 'Что почитать',
        tabName: 'Книги',
        tabs: const <SheetTab>[SheetTab(gid: '7', name: 'Книги')],
        columns: const <String>['title', 'author', 'read'],
        loadedAt: DateTime(2026, 9, 27, 12, 40),
        books: const <Book>[Book(title: 'A', author: 'B', read: true)],
      );
      final back = LibraryData.fromJson(data.toJson());
      expect(back.sheetId, data.sheetId);
      expect(back.gid, data.gid);
      expect(back.documentName, data.documentName);
      expect(back.tabs.single.name, 'Книги');
      expect(back.books, data.books);
      expect(back.loadedAt, data.loadedAt);
    });
  });
}

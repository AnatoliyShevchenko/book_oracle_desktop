import 'package:book_oracle/data/models.dart';
import 'package:book_oracle/data/sheet_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('headers', () {
    test('Russian headers', () {
      final r = parseSheetCsv('название,автор,прочитано\nВий,Гоголь,да\n');
      expect(r.columns, <String>['title', 'author', 'read']);
      expect(r.books.single.title, 'Вий');
      expect(r.books.single.read, isTrue);
    });

    test('English headers', () {
      final r = parseSheetCsv('title,author,read\nViy,Gogol,\n');
      expect(r.columns, <String>['title', 'author', 'read']);
      expect(r.books.single.read, isFalse);
    });

    test('mixed case and padding', () {
      final r = parseSheetCsv('  TITLE , Автор ,ReAd\nA,B,1\n');
      expect(r.columns, <String>['title', 'author', 'read']);
      expect(r.books.single.read, isTrue);
    });

    test('a UTF-8 BOM on the first header is ignored', () {
      final r = parseSheetCsv('﻿title,author,read\nA,B,\n');
      expect(r.columns, <String>['title', 'author', 'read']);
    });

    test('any column order works and extras are ignored', () {
      final r = parseSheetCsv(
          'прочитано,заметки,автор,rating,название\nда,x,Гоголь,5,Вий\n');
      expect(r.columns, <String>['read', 'author', 'title']);
      final book = r.books.single;
      expect(book.title, 'Вий');
      expect(book.author, 'Гоголь');
      expect(book.read, isTrue);
    });

    test('mixing Russian and English headers is fine', () {
      final r = parseSheetCsv('title,автор,read\nA,B,\n');
      expect(r.columns, <String>['title', 'author', 'read']);
    });
  });

  group('missing columns', () {
    test('one missing column is reported', () {
      expect(
        () => parseSheetCsv('название,автор\nВий,Гоголь\n'),
        throwsA(
          isA<SheetException>()
              .having((e) => e.kind, 'kind', SheetFailure.columns)
              .having((e) => e.missing, 'missing', <String>['read'])
              .having((e) => e.found, 'found', <String>['title', 'author']),
        ),
      );
    });

    test('two missing columns are both reported', () {
      expect(
        () => parseSheetCsv('автор\nГоголь\n'),
        throwsA(
          isA<SheetException>()
              .having((e) => e.missing, 'missing', <String>['title', 'read'])
              .having((e) => e.found, 'found', <String>['author']),
        ),
      );
    });

    test('nothing recognisable at all', () {
      expect(
        () => parseSheetCsv('a,b,c\n1,2,3\n'),
        throwsA(
          isA<SheetException>()
              .having((e) => e.missing, 'missing',
                  <String>['title', 'author', 'read'])
              .having((e) => e.found, 'found', isEmpty),
        ),
      );
    });

    test('an empty sheet', () {
      expect(
        () => parseSheetCsv(''),
        throwsA(isA<SheetException>()
            .having((e) => e.kind, 'kind', SheetFailure.columns)),
      );
    });
  });

  group('read values — anything in the cell means read', () {
    const marked = <String>[
      'да', 'Да', 'ДА', ' да ', //
      'yes', 'Y', 'y', 'TRUE', 'true', '1', '+', 'x', 'X', '✓', '✔',
      'прочитано', 'read', 'Read',
      // Free-form marks now count too — that is the point of the change.
      'ок', 'дочитала', '2026-09-27', '5/5', '★★★★', '?',
      // Including ones that look negative: the column is a tick box.
      'нет', 'no', '0', '-', 'later',
    ];
    const blank = <String>['', ' ', '   ', '\t', '  '];

    for (final v in marked) {
      test('"$v" counts as read', () => expect(isRead(v), isTrue));
    }
    for (final v in blank) {
      test('"${v.replaceAll('\t', r'\t')}" leaves the book in the deck',
          () => expect(isRead(v), isFalse));
    }

    test('a BOM alone is still an empty cell', () {
      expect(isRead('﻿'), isFalse);
      expect(isRead('﻿ '), isFalse);
    });
  });

  group('rows', () {
    test('rows with no title are skipped', () {
      final r = parseSheetCsv(
          'название,автор,прочитано\nВий,Гоголь,\n, ,да\n  ,X,\nЦирцея,Миллер,да\n');
      expect(r.books.map((b) => b.title), <String>['Вий', 'Цирцея']);
    });

    test('a short row still parses, missing cells read as empty', () {
      final r = parseSheetCsv('название,автор,прочитано\nВий\n');
      final book = r.books.single;
      expect(book.author, '');
      expect(book.read, isFalse);
    });

    test('quoted fields with commas survive', () {
      final r = parseSheetCsv(
          'название,автор,прочитано\n"Ильф, Петров","Двенадцать стульев",\n');
      expect(r.books.single.title, 'Ильф, Петров');
    });

    test('CRLF line endings', () {
      final r = parseSheetCsv('title,author,read\r\nA,B,\r\nC,D,да\r\n');
      expect(r.books.length, 2);
      expect(r.books.last.read, isTrue);
    });

    test('counts split read from unread', () {
      final r = parseSheetCsv(
          'title,author,read\nA,,да\nB,,\nC,,\nD,,1\n');
      expect(r.books.length, 4);
      expect(r.books.where((b) => !b.read).length, 2);
    });

    test('a whole column of assorted marks leaves only the blanks in the deck',
        () {
      final r = parseSheetCsv(
        'название,автор,прочитано\n'
        'A,,да\n'
        'B,,\n'
        'C,,дочитала в мае\n'
        'D,,   \n'
        'E,,✓\n'
        'F,,\n'
        'G,,нет\n',
      );
      expect(r.books.length, 7);
      expect(
        r.books.where((b) => !b.read).map((b) => b.title),
        <String>['B', 'D', 'F'],
      );
    });
  });
}

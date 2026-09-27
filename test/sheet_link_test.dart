import 'package:book_oracle/data/sheet_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSheetLink', () {
    test('plain /edit link defaults to gid 0', () {
      final link = parseSheetLink(
          'https://docs.google.com/spreadsheets/d/1bXq7Kd0AbC-dEf_123/edit');
      expect(link, isNotNull);
      expect(link!.id, '1bXq7Kd0AbC-dEf_123');
      expect(link.gid, '0');
    });

    test('reads gid from the fragment', () {
      final link = parseSheetLink(
          'https://docs.google.com/spreadsheets/d/1bXq7Kd0/edit#gid=825467');
      expect(link!.gid, '825467');
    });

    test('reads gid from the query string', () {
      final link = parseSheetLink(
          'https://docs.google.com/spreadsheets/d/1bXq7Kd0/edit?gid=42');
      expect(link!.gid, '42');
    });

    test('reads gid from a later query parameter', () {
      final link = parseSheetLink(
          'https://docs.google.com/spreadsheets/d/1bXq7Kd0/edit?usp=sharing&gid=7');
      expect(link!.gid, '7');
    });

    test('accepts an /htmlview link', () {
      final link = parseSheetLink(
          'https://docs.google.com/spreadsheets/d/1bXq7Kd0/htmlview#gid=13');
      expect(link!.id, '1bXq7Kd0');
      expect(link.gid, '13');
    });

    test('accepts a bare path without a scheme', () {
      final link =
          parseSheetLink('docs.google.com/spreadsheets/d/1bXq7Kd0/edit');
      expect(link!.id, '1bXq7Kd0');
    });

    test('trims surrounding whitespace', () {
      final link = parseSheetLink(
          '  https://docs.google.com/spreadsheets/d/1bXq7Kd0/edit  ');
      expect(link!.id, '1bXq7Kd0');
    });

    test('rejects an empty string', () {
      expect(parseSheetLink(''), isNull);
      expect(parseSheetLink('   '), isNull);
    });

    test('rejects a Drive file link', () {
      expect(parseSheetLink('https://drive.google.com/file/d/1Qp/view'), isNull);
    });

    test('rejects rubbish', () {
      expect(parseSheetLink('всё, что угодно'), isNull);
      expect(parseSheetLink('https://example.com/spreadsheets'), isNull);
    });

    test('rejects a published-to-web link, which cannot export CSV', () {
      expect(
        parseSheetLink(
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vQ/pubhtml'),
        isNull,
      );
    });

    test('builds the CSV export URL', () {
      final link = parseSheetLink(
          'https://docs.google.com/spreadsheets/d/1bXq7Kd0/edit#gid=5')!;
      expect(
        link.csvUrl,
        'https://docs.google.com/spreadsheets/d/1bXq7Kd0/export?format=csv&gid=5',
      );
    });
  });
}

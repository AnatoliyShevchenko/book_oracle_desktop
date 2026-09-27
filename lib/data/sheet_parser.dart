import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';

/// Canonical column ids, in the order the UI lists them.
const List<String> kColumnIds = <String>['title', 'author', 'read'];

/// Header spellings we accept, per canonical id.
const Map<String, List<String>> kColumnAliases = <String, List<String>>{
  'title': <String>['title', 'название'],
  'author': <String>['author', 'автор'],
  'read': <String>['read', 'прочитано'],
};

/// Trim, drop a BOM, collapse case — how headers and cells are compared.
String normalizeCell(String raw) =>
    raw.replaceAll('﻿', '').trim().toLowerCase();

/// A book counts as read as soon as the cell has anything in it.
///
/// Any mark will do — `да`, `TRUE`, `✓`, a date, a rating, a note to self —
/// so nobody has to remember a magic word. Only an empty cell keeps the book
/// in the deck. Note that this means `нет` or `0` also read as "done": the
/// column is a tick box, not an answer.
bool isRead(String raw) => normalizeCell(raw).isNotEmpty;

@immutable
class ParsedSheet {
  const ParsedSheet({required this.books, required this.columns});

  /// Every row that had a non-empty title.
  final List<Book> books;

  /// Canonical ids found in the header, in the order they appear in the sheet.
  final List<String> columns;
}

/// Parses the CSV export of one tab.
///
/// Throws [SheetException] with [SheetFailure.columns] when any of the three
/// required headers is missing.
ParsedSheet parseSheetCsv(String csv) {
  // Google always exports comma-separated UTF-8, so auto-detection would only
  // add a way to get it wrong on a sheet full of semicolons.
  final rows = Csv(
    fieldDelimiter: ',',
    autoDetect: false,
    dynamicTyping: false,
    skipEmptyLines: true,
  ).decode(csv);

  if (rows.isEmpty) {
    throw SheetException(SheetFailure.columns,
        missing: kColumnIds, found: const <String>[]);
  }

  // Map header cell -> canonical id. First occurrence of an alias wins.
  final indexOf = <String, int>{};
  final header = rows.first;
  for (var i = 0; i < header.length; i++) {
    final cell = normalizeCell('${header[i] ?? ''}');
    if (cell.isEmpty) continue;
    for (final entry in kColumnAliases.entries) {
      if (entry.value.contains(cell) && !indexOf.containsKey(entry.key)) {
        indexOf[entry.key] = i;
      }
    }
  }

  final missing = kColumnIds.where((c) => !indexOf.containsKey(c)).toList();
  if (missing.isNotEmpty) {
    // Report what we did find, ordered by their position in the sheet.
    final found = indexOf.keys.toList()
      ..sort((a, b) => indexOf[a]!.compareTo(indexOf[b]!));
    throw SheetException(SheetFailure.columns, missing: missing, found: found);
  }

  final order = indexOf.keys.toList()
    ..sort((a, b) => indexOf[a]!.compareTo(indexOf[b]!));

  String cell(List<dynamic> row, int i) =>
      i < row.length ? '${row[i] ?? ''}'.replaceAll('﻿', '').trim() : '';

  final books = <Book>[];
  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    final title = cell(row, indexOf['title']!);
    if (title.isEmpty) continue; // rows with no title are skipped
    books.add(Book(
      title: title,
      author: cell(row, indexOf['author']!),
      read: isRead(cell(row, indexOf['read']!)),
    ));
  }

  return ParsedSheet(books: books, columns: order);
}

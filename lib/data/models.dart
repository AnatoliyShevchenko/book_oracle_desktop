import 'package:flutter/foundation.dart';

@immutable
class Book {
  const Book({required this.title, required this.author, required this.read});

  final String title;
  final String author;
  final bool read;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'title': title, 'author': author, 'read': read};

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        title: (j['title'] as String?) ?? '',
        author: (j['author'] as String?) ?? '',
        read: (j['read'] as bool?) ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is Book &&
      other.title == title &&
      other.author == author &&
      other.read == read;

  @override
  int get hashCode => Object.hash(title, author, read);

  @override
  String toString() => 'Book($title, $author, read: $read)';
}

/// A sheet tab, when we manage to discover them.
@immutable
class SheetTab {
  const SheetTab({required this.gid, required this.name});

  final String gid;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{'gid': gid, 'name': name};

  factory SheetTab.fromJson(Map<String, dynamic> j) =>
      SheetTab(gid: j['gid'] as String, name: j['name'] as String);
}

/// Everything one successful load produced, and what the cache stores.
@immutable
class LibraryData {
  const LibraryData({
    required this.sheetUrl,
    required this.sheetId,
    required this.gid,
    required this.books,
    required this.columns,
    required this.loadedAt,
    this.documentName,
    this.tabName,
    this.tabs = const <SheetTab>[],
  });

  final String sheetUrl;
  final String sheetId;
  final String gid;

  /// Every row that had a title, read and unread alike.
  final List<Book> books;

  /// Canonical column ids found in the header, in sheet order.
  final List<String> columns;
  final DateTime loadedAt;
  final String? documentName;
  final String? tabName;
  final List<SheetTab> tabs;

  List<Book> get unread =>
      books.where((b) => !b.read).toList(growable: false);

  int get total => books.length;
  int get deckCount => unread.length;
  int get readCount => total - deckCount;

  String get displayName => documentName ?? tabName ?? '';

  LibraryData copyWith({String? tabName, List<SheetTab>? tabs}) => LibraryData(
        sheetUrl: sheetUrl,
        sheetId: sheetId,
        gid: gid,
        books: books,
        columns: columns,
        loadedAt: loadedAt,
        documentName: documentName,
        tabName: tabName ?? this.tabName,
        tabs: tabs ?? this.tabs,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sheetUrl': sheetUrl,
        'sheetId': sheetId,
        'gid': gid,
        'documentName': documentName,
        'tabName': tabName,
        'tabs': tabs.map((t) => t.toJson()).toList(),
        'columns': columns,
        'books': books.map((b) => b.toJson()).toList(),
        'loadedAt': loadedAt.toIso8601String(),
      };

  factory LibraryData.fromJson(Map<String, dynamic> j) => LibraryData(
        sheetUrl: j['sheetUrl'] as String,
        sheetId: j['sheetId'] as String,
        gid: (j['gid'] as String?) ?? '0',
        documentName: j['documentName'] as String?,
        tabName: j['tabName'] as String?,
        tabs: ((j['tabs'] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => SheetTab.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        columns: ((j['columns'] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => e as String)
            .toList(growable: false),
        books: ((j['books'] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        loadedAt: DateTime.tryParse((j['loadedAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// The error states the onboarding screen distinguishes.
enum SheetFailure { format, access, columns, network, unknown }

class SheetException implements Exception {
  SheetException(
    this.kind, {
    this.missing = const <String>[],
    this.found = const <String>[],
  });

  final SheetFailure kind;

  /// Canonical column ids (`title` / `author` / `read`).
  final List<String> missing;
  final List<String> found;

  @override
  String toString() => 'SheetException(${kind.name}, missing: $missing)';
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'sheet_link.dart';
import 'sheet_parser.dart';

/// Metadata scraped from the spreadsheet's `htmlview` page. Entirely
/// best-effort: a failure here never blocks a load.
class SheetMeta {
  const SheetMeta({this.documentName, this.tabs = const <SheetTab>[]});

  final String? documentName;
  final List<SheetTab> tabs;
}

class SheetLoader {
  SheetLoader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration timeout = Duration(seconds: 8);
  static const Duration metaTimeout = Duration(seconds: 5);
  static const int _maxRedirects = 6;

  /// Loads and parses one tab.
  ///
  /// Throws [SheetException] — `access` for a closed or missing sheet,
  /// `columns` for a bad header, `network` for no connection or a timeout.
  Future<LibraryData> load(SheetLink link, {String? originalUrl}) async {
    final body = await _fetchCsv(link);
    final parsed = parseSheetCsv(body);
    final meta = await _fetchMeta(link);
    final tabName = meta?.tabs
        .cast<SheetTab?>()
        .firstWhere((t) => t?.gid == link.gid, orElse: () => null)
        ?.name;
    return LibraryData(
      sheetUrl: originalUrl ?? link.htmlUrl,
      sheetId: link.id,
      gid: link.gid,
      books: parsed.books,
      columns: parsed.columns,
      loadedAt: DateTime.now(),
      documentName: meta?.documentName,
      tabName: tabName,
      tabs: meta?.tabs ?? const <SheetTab>[],
    );
  }

  Future<String> _fetchCsv(SheetLink link) async {
    var uri = Uri.parse(link.csvUrl);
    try {
      for (var hop = 0; hop < _maxRedirects; hop++) {
        final request = http.Request('GET', uri)..followRedirects = false;
        final res = await _client.send(request).timeout(timeout);

        if (res.statusCode >= 300 && res.statusCode < 400) {
          final location = res.headers['location'];
          await res.stream.drain<void>();
          if (location == null) throw SheetException(SheetFailure.access);
          final next = uri.resolve(location);
          // A bounce to the sign-in page means the sheet is not public.
          if (next.host.contains('accounts.google.com')) {
            throw SheetException(SheetFailure.access);
          }
          uri = next;
          continue;
        }

        if (res.statusCode != 200) {
          await res.stream.drain<void>();
          throw SheetException(SheetFailure.access);
        }

        final contentType = res.headers['content-type'] ?? '';
        final body = await res.stream.bytesToString();
        if (contentType.contains('text/html') || _looksLikeHtml(body)) {
          throw SheetException(SheetFailure.access);
        }
        return body;
      }
      throw SheetException(SheetFailure.access);
    } on SheetException {
      rethrow;
    } on TimeoutException {
      throw SheetException(SheetFailure.network);
    } on SocketException {
      throw SheetException(SheetFailure.network);
    } on http.ClientException {
      throw SheetException(SheetFailure.network);
    } on HandshakeException {
      throw SheetException(SheetFailure.network);
    }
  }

  static bool _looksLikeHtml(String body) {
    final head = body.trimLeft();
    if (head.length > 200) {
      return head.substring(0, 200).toLowerCase().startsWith('<!doctype html') ||
          head.substring(0, 200).toLowerCase().startsWith('<html');
    }
    final lower = head.toLowerCase();
    return lower.startsWith('<!doctype html') || lower.startsWith('<html');
  }

  static final RegExp _titleRe =
      RegExp(r'<title>(.*?)</title>', caseSensitive: false, dotAll: true);
  static final RegExp _tabRe = RegExp(r'sheet-button-(\d+)"[^>]*>([^<]*)');

  /// Google appends its own product name in the user's locale — " - Google
  /// Sheets", " - Google Диск", and so on.
  static final RegExp _productSuffixRe =
      RegExp(r'\s[-–—]\s*Google\s+\S+\s*$');

  /// Reads the document title and tab list off `/htmlview`. Returns `null`
  /// whenever anything at all goes wrong.
  Future<SheetMeta?> _fetchMeta(SheetLink link) async {
    try {
      final res = await _client
          .get(Uri.parse(link.htmlViewUrl))
          .timeout(metaTimeout);
      if (res.statusCode != 200) return null;
      final html = utf8.decode(res.bodyBytes, allowMalformed: true);
      return parseMetaHtml(html);
    } catch (_) {
      return null;
    }
  }

  /// Exposed for tests.
  static SheetMeta? parseMetaHtml(String html) {
    String? name = _titleRe.firstMatch(html)?.group(1)?.trim();
    if (name != null) {
      name = _unescape(name).replaceFirst(_productSuffixRe, '').trim();
      if (name.isEmpty) name = null;
    }

    final tabs = <SheetTab>[];
    final seen = <String>{};
    for (final m in _tabRe.allMatches(html)) {
      final gid = m.group(1)!;
      final label = _unescape(m.group(2)!).trim();
      if (label.isEmpty || !seen.add(gid)) continue;
      tabs.add(SheetTab(gid: gid, name: label));
    }
    if (name == null && tabs.isEmpty) return null;
    return SheetMeta(documentName: name, tabs: tabs);
  }

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');

  void close() => _client.close();
}

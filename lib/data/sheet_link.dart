import 'package:flutter/foundation.dart';

/// The spreadsheet id and tab id pulled out of a Google Sheets URL.
@immutable
class SheetLink {
  const SheetLink({required this.id, required this.gid});

  final String id;
  final String gid;

  /// The CSV export endpoint for this tab.
  String get csvUrl =>
      'https://docs.google.com/spreadsheets/d/$id/export?format=csv&gid=$gid';

  /// The page a human would open.
  String get htmlUrl => 'https://docs.google.com/spreadsheets/d/$id/edit#gid=$gid';

  /// Best-effort tab listing lives here.
  String get htmlViewUrl => 'https://docs.google.com/spreadsheets/d/$id/htmlview';

  SheetLink withGid(String newGid) => SheetLink(id: id, gid: newGid);

  @override
  bool operator ==(Object other) =>
      other is SheetLink && other.id == id && other.gid == gid;

  @override
  int get hashCode => Object.hash(id, gid);

  @override
  String toString() => 'SheetLink($id, gid: $gid)';
}

final RegExp _idRe = RegExp(r'/spreadsheets/d/([a-zA-Z0-9\-_]+)');
final RegExp _gidRe = RegExp(r'[#?&]gid=([0-9]+)');

/// Returns `null` when [input] is not a Google Sheets URL — the `format` error.
SheetLink? parseSheetLink(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;
  final idMatch = _idRe.firstMatch(s);
  if (idMatch == null) return null;
  final id = idMatch.group(1)!;
  // `/spreadsheets/d/e/…` is a published-to-web link, which export?format=csv
  // cannot serve; treat it as an unusable link rather than a valid id.
  if (id == 'e') return null;
  final gid = _gidRe.firstMatch(s)?.group(1) ?? '0';
  return SheetLink(id: id, gid: gid);
}

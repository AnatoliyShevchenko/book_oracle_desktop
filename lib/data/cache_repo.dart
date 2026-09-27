import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Stores the last successful load so the app still deals cards offline.
class CacheRepo {
  const CacheRepo();

  static const String fileName = 'cache.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  Future<LibraryData?> read() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return null;
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return LibraryData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(LibraryData data) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(data.toJson()));
    } catch (_) {
      // A cache we cannot write is not worth failing a load over.
    }
  }

  Future<void> clear() async {
    try {
      final f = await _file();
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}

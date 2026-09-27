import 'package:book_oracle/data/cache_repo.dart';
import 'package:book_oracle/data/models.dart';
import 'package:book_oracle/data/sheet_link.dart';
import 'package:book_oracle/data/sheet_loader.dart';
import 'package:book_oracle/data/settings_repo.dart';
import 'package:book_oracle/state/app_state.dart';
import 'package:book_oracle/state/deal_state.dart';
import 'package:book_oracle/state/library_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLoader extends SheetLoader {
  _FakeLoader();

  LibraryData? next;
  SheetFailure? failure;
  int calls = 0;

  @override
  Future<LibraryData> load(SheetLink link, {String? originalUrl}) async {
    calls++;
    final f = failure;
    if (f != null) throw SheetException(f);
    return next!;
  }
}

class _FakeCache extends CacheRepo {
  const _FakeCache(this.box);

  final List<LibraryData?> box;

  @override
  Future<LibraryData?> read() async => box.first;

  @override
  Future<void> write(LibraryData data) async => box[0] = data;

  @override
  Future<void> clear() async => box[0] = null;
}

LibraryData _library(List<String> unreadTitles, {DateTime? at}) => LibraryData(
      sheetUrl: 'https://docs.google.com/spreadsheets/d/abc/edit',
      sheetId: 'abc',
      gid: '0',
      columns: const <String>['title', 'author', 'read'],
      loadedAt: at ?? DateTime(2026, 9, 27, 12, 40),
      documentName: 'Что почитать',
      books: <Book>[
        for (final t in unreadTitles) Book(title: t, author: 'A', read: false),
      ],
    );

/// The deal notifier reads the sounds setting, so every container here needs
/// a settings store as well.
Future<({ProviderContainer container, _FakeLoader loader, List<LibraryData?> cache})>
    _setUp() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = SettingsRepo(await SharedPreferences.getInstance());
  final loader = _FakeLoader();
  final box = <LibraryData?>[null];
  final container = ProviderContainer(
    overrides: [
      sheetLoaderProvider.overrideWithValue(loader),
      cacheRepoProvider.overrideWithValue(_FakeCache(box)),
      settingsRepoProvider.overrideWithValue(repo),
    ],
  );
  return (container: container, loader: loader, cache: box);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adopting a cached list enters offline mode', () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);

    container
        .read(libraryProvider.notifier)
        .adoptCached(_library(<String>['A', 'B', 'C']));

    final state = container.read(libraryProvider);
    expect(state.offline, isTrue);
    expect(state.net, NetStatus.offline);
    expect(state.data!.deckCount, 3);
    expect(loader.calls, 0);
  });

  test('"check again" that succeeds leaves offline and reports no change',
      () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);
    final notifier = container.read(libraryProvider.notifier);

    notifier.adoptCached(_library(<String>['A', 'B', 'C']));
    loader.next = _library(<String>['A', 'B', 'C']);

    await notifier.checkAgain();

    final state = container.read(libraryProvider);
    expect(loader.calls, 1);
    expect(state.offline, isFalse);
    expect(state.checking, isFalse);
    expect(state.notice, isNotNull);
    expect(state.notice!.isEmpty, isTrue);
  });

  test('a changed list reports the delta', () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);
    final notifier = container.read(libraryProvider.notifier);

    notifier.adoptCached(_library(<String>['A', 'B', 'C']));
    loader.next = _library(<String>['A', 'B', 'D', 'E']);

    await notifier.checkAgain();

    final delta = container.read(libraryProvider).notice!;
    expect(delta.added, 2); // D, E
    expect(delta.removed, 1); // C
    expect(delta.isEmpty, isFalse);
    expect(container.read(libraryProvider).data!.deckCount, 4);
  });

  test('"check again" that still fails stays offline and shows no banner',
      () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);
    final notifier = container.read(libraryProvider.notifier);

    notifier.adoptCached(_library(<String>['A', 'B']));
    loader.failure = SheetFailure.network;

    await notifier.checkAgain();

    final state = container.read(libraryProvider);
    expect(state.offline, isTrue);
    expect(state.notice, isNull);
    expect(state.checking, isFalse);
  });

  test('the banner can be dismissed by hand', () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);
    final notifier = container.read(libraryProvider.notifier);

    notifier.adoptCached(_library(<String>['A', 'B']));
    loader.next = _library(<String>['A', 'B']);
    await notifier.checkAgain();
    expect(container.read(libraryProvider).notice, isNotNull);

    notifier.dismissNotice();
    expect(container.read(libraryProvider).notice, isNull);
  });

  test('losing the connection on a refresh drops into offline mode', () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);
    final notifier = container.read(libraryProvider.notifier);

    notifier.adopt(_library(<String>['A', 'B', 'C']));
    expect(container.read(libraryProvider).offline, isFalse);

    loader.failure = SheetFailure.network;
    await notifier.refresh();

    final state = container.read(libraryProvider);
    expect(state.offline, isTrue);
    // The list we already had is kept.
    expect(state.data!.deckCount, 3);
    expect(state.notice, isNull);
  });

  test('a refresh that changes the list reports it, but not as "back online"',
      () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);
    final notifier = container.read(libraryProvider.notifier);

    notifier.adopt(_library(<String>['A']));
    loader.next = _library(<String>['A', 'B']);
    await notifier.refresh();

    final state = container.read(libraryProvider);
    expect(state.data!.deckCount, 2);
    expect(state.notice, isNotNull);
    expect(state.notice!.added, 1);
    expect(state.noticeAfterOffline, isFalse);
  });

  test('a refresh that changes nothing shows no banner at all', () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);
    final notifier = container.read(libraryProvider.notifier);

    notifier.adopt(_library(<String>['A', 'B']));
    loader.next = _library(<String>['A', 'B']);
    await notifier.refresh();

    expect(container.read(libraryProvider).notice, isNull);
  });

  group('a refresh and the table', () {
    test('an untouched table picks the new list up at once', () async {
      final (:container, :loader, cache: _) = await _setUp();
      addTearDown(container.dispose);
      final library = container.read(libraryProvider.notifier);
      final deal = container.read(dealProvider.notifier);

      library.adopt(_library(<String>['A', 'B', 'C', 'D']));
      deal.deal(container.read(libraryProvider).data!.unread);
      expect(container.read(dealProvider).total, 4);

      // Two books have just been marked read in the sheet.
      loader.next = _library(<String>['A', 'B']);
      await library.refresh();

      expect(container.read(dealProvider).total, 2);
      expect(container.read(libraryProvider).noticeRedealt, isTrue);
    });

    test('a spread in progress keeps its cards', () async {
      final (:container, :loader, cache: _) = await _setUp();
      addTearDown(container.dispose);
      final library = container.read(libraryProvider.notifier);
      final deal = container.read(dealProvider.notifier);

      library.adopt(_library(<String>['A', 'B', 'C', 'D']));
      deal.deal(container.read(libraryProvider).data!.unread);
      deal.eliminate(0);
      expect(container.read(dealProvider).out.length, 1);

      loader.next = _library(<String>['A', 'B']);
      await library.refresh();

      // Still the four cards that were dealt; the notice explains why.
      expect(container.read(dealProvider).total, 4);
      expect(container.read(dealProvider).out.length, 1);
      expect(container.read(libraryProvider).noticeRedealt, isFalse);
      expect(container.read(libraryProvider).data!.deckCount, 2);
    });

    test('an unchanged list leaves the dealt order alone', () async {
      final (:container, :loader, cache: _) = await _setUp();
      addTearDown(container.dispose);
      final library = container.read(libraryProvider.notifier);
      final deal = container.read(dealProvider.notifier);

      library.adopt(_library(<String>['A', 'B', 'C', 'D']));
      deal.deal(container.read(libraryProvider).data!.unread);
      final before = container.read(dealProvider).cards.map((b) => b.title).toList();

      loader.next = _library(<String>['A', 'B', 'C', 'D']);
      await library.refresh();

      expect(
        container.read(dealProvider).cards.map((b) => b.title).toList(),
        before,
      );
    });
  });

  test('an access error on refresh keeps the current list', () async {
    final (:container, :loader, cache: _) = await _setUp();
    addTearDown(container.dispose);
    final notifier = container.read(libraryProvider.notifier);

    notifier.adopt(_library(<String>['A', 'B', 'C']));
    loader.failure = SheetFailure.access;
    await notifier.refresh();

    final state = container.read(libraryProvider);
    expect(state.offline, isFalse);
    expect(state.data!.deckCount, 3);
  });

  test('a successful load is written to the cache', () async {
    final (:container, loader: _, :cache) = await _setUp();
    addTearDown(container.dispose);

    container.read(libraryProvider.notifier).adopt(_library(<String>['A']));
    expect(cache.first, isNotNull);
    expect(cache.first!.deckCount, 1);
  });

  test('the demo list is not cached', () async {
    final (:container, loader: _, :cache) = await _setUp();
    addTearDown(container.dispose);

    container
        .read(libraryProvider.notifier)
        .adopt(_library(<String>['A']), cache: false);
    expect(cache.first, isNull);
  });

  group('the sheet title drops Google\'s product suffix', () {
    for (final suffix in const <String>[
      ' - Google Sheets',
      ' - Google Таблицы',
      ' - Google Диск',
      ' - Google Drive',
    ]) {
      test('"$suffix"', () {
        final meta = SheetLoader.parseMetaHtml(
            '<html><head><title>Что почитать$suffix</title></head></html>')!;
        expect(meta.documentName, 'Что почитать');
      });
    }

    test('a title that merely mentions Google is left alone', () {
      final meta = SheetLoader.parseMetaHtml(
          '<html><head><title>Google и я</title></head></html>')!;
      expect(meta.documentName, 'Google и я');
    });
  });
}

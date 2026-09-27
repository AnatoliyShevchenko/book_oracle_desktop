import 'dart:io';

import 'package:book_oracle/app.dart';
import 'package:book_oracle/core/tokens.dart';
import 'package:book_oracle/data/models.dart';
import 'package:book_oracle/data/settings_repo.dart';
import 'package:book_oracle/state/app_state.dart';
import 'package:book_oracle/state/deal_state.dart';
import 'package:book_oracle/state/library_state.dart';
import 'package:book_oracle/ui/deal/card_widget.dart';
import 'package:book_oracle/ui/deal/deal_screen.dart';
import 'package:book_oracle/ui/deal/reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<Book> _fiveBooks = <Book>[
  Book(title: 'Вий', author: 'Николай Гоголь', read: false),
  Book(title: 'Цирцея', author: 'Мадлен Миллер', read: false),
  Book(title: 'Дракула', author: 'Брэм Стокер', read: false),
  Book(title: 'Ребекка', author: 'Дафна дю Морье', read: false),
  Book(title: 'Коралина', author: 'Нил Гейман', read: false),
];

LibraryData _library(List<Book> books) => LibraryData(
      sheetUrl: 'https://docs.google.com/spreadsheets/d/test/edit',
      sheetId: 'test',
      gid: '0',
      books: books,
      columns: const <String>['title', 'author', 'read'],
      loadedAt: DateTime.now(),
      documentName: 'Что почитать',
    );

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final tokens =
      DesignTokens.parse(File('assets/design_tokens.json').readAsStringSync());
  final repo = SettingsRepo(await SharedPreferences.getInstance());
  return ProviderContainer(
    overrides: [
      tokensProvider.overrideWithValue(tokens),
      settingsRepoProvider.overrideWithValue(repo),
    ],
  );
}

Widget _harness(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final deck = ref.watch(deckThemeProvider);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeForDeck(deck),
            home: Material(color: deck.bg, child: const DealScreen()),
          );
        },
      ),
    );

void main() {
  testWidgets('five cards: four turns bring up the reveal', (tester) async {
    tester.view.physicalSize = const Size(1536, 864);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = await _container();
    addTearDown(container.dispose);

    container.read(libraryProvider.notifier).adopt(_library(_fiveBooks), cache: false);
    container.read(dealProvider.notifier).deal(_fiveBooks);

    await tester.pumpWidget(_harness(container));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(DealCard), findsNWidgets(5));
    expect(find.byType(RevealOverlay), findsNothing);
    expect(container.read(dealProvider).left, 5);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(DealCard).at(i));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
    }

    expect(container.read(dealProvider).out.length, 4);
    expect(container.read(dealProvider).left, 1);

    // The reveal waits 1.1 s after the last card is turned.
    expect(find.byType(RevealOverlay), findsNothing);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RevealOverlay), findsOneWidget);
    expect(find.text('Выбор сделан'), findsOneWidget);

    final deal = container.read(dealProvider);
    expect(deal.winner, isNotNull);
    expect(deal.winnerBook, isNotNull);
    expect(deal.out.contains(deal.winner), isFalse);
  });

  testWidgets('the last card standing cannot be turned', (tester) async {
    tester.view.physicalSize = const Size(1536, 864);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = await _container();
    addTearDown(container.dispose);

    final two = _fiveBooks.take(2).toList();
    container.read(libraryProvider.notifier).adopt(_library(two), cache: false);
    container.read(dealProvider.notifier).deal(two);

    await tester.pumpWidget(_harness(container));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byType(DealCard).at(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(container.read(dealProvider).left, 1);

    // Tapping the survivor must do nothing.
    await tester.tap(find.byType(DealCard).at(1), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(dealProvider).out.length, 1);

    // Let the reveal timer fire so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(dealProvider).winner, 1);
  });

  testWidgets('a sheet with fewer than two unread books shows the notice',
      (tester) async {
    tester.view.physicalSize = const Size(1536, 864);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = await _container();
    addTearDown(container.dispose);

    const one = <Book>[
      Book(title: 'Вий', author: 'Николай Гоголь', read: false),
      Book(title: 'Цирцея', author: 'Мадлен Миллер', read: true),
    ];
    container.read(libraryProvider.notifier).adopt(_library(one), cache: false);
    container.read(dealProvider.notifier).deal(
          one.where((b) => !b.read).toList(),
        );

    await tester.pumpWidget(_harness(container));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DealCard), findsNothing);
    expect(find.text('В таблице меньше двух непрочитанных книг'),
        findsOneWidget);
  });
}

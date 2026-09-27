import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/card_colors.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../state/deal_state.dart';
import '../../state/library_state.dart';
import '../widgets/buttons.dart';
import '../window/title_bar.dart';
import 'card_widget.dart';
import 'panel.dart';
import 'reveal.dart';
import 'table_background.dart';

class DealScreen extends ConsumerStatefulWidget {
  const DealScreen({super.key});

  @override
  ConsumerState<DealScreen> createState() => _DealScreenState();
}

class _DealScreenState extends ConsumerState<DealScreen> {
  final FocusNode _keyboard = FocusNode(debugLabel: 'deal-shortcuts');

  @override
  void dispose() {
    _keyboard.dispose();
    super.dispose();
  }

  Future<void> _toggleFullScreen() async {
    try {
      await windowManager.setFullScreen(!await windowManager.isFullScreen());
    } catch (_) {}
  }

  Future<void> _escape() async {
    final deal = ref.read(dealProvider);
    if (deal.showReveal) {
      ref.read(dealProvider.notifier).closeReveal();
      return;
    }
    try {
      if (await windowManager.isFullScreen()) {
        await windowManager.setFullScreen(false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final library = ref.watch(libraryProvider);
    final deal = ref.watch(dealProvider);
    final listName = (library.data?.displayName.isNotEmpty ?? false)
        ? library.data!.displayName
        : s.defaultListName;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space):
            ref.read(dealProvider.notifier).pickRandom,
        const SingleActivator(LogicalKeyboardKey.keyR):
            ref.read(dealProvider.notifier).reshuffle,
        const SingleActivator(LogicalKeyboardKey.f11): _toggleFullScreen,
        const SingleActivator(LogicalKeyboardKey.escape): _escape,
      },
      child: Focus(
        focusNode: _keyboard,
        autofocus: true,
        child: Column(
          children: <Widget>[
            AppTitleBar(screenName: listName),
            Expanded(
              child: Stack(
                children: <Widget>[
                  TableBackground(child: _Body(deal: deal)),
                  if (deal.showReveal && settings.fullscreenReveal)
                    Positioned.fill(
                      child: RevealOverlay(
                        book: deal.winnerBook!,
                        cardIndex: deal.winner!,
                        animate: settings.animations,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.deal});

  final DealState deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = tierFor(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.fromLTRB(tier.pad, tier.padTop, tier.pad, tier.pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: deal.isEmpty
                      ? const TooFewBooks()
                      : _CardGrid(deal: deal, tier: tier),
                ),
                const SizedBox(height: 16),
                SizedBox(height: 28, child: _HintRow(tier: tier)),
              ],
            ),
          ),
          SizedBox(width: tier.pad),
          DealPanel(tier: tier),
        ],
      ),
    );
  }
}

class _HintRow extends ConsumerWidget {
  const _HintRow({required this.tier});

  final LayoutTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final hint = deck.body(size: 13, color: deck.muted);

    Widget key(String cap, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Kbd(cap),
            const SizedBox(width: 6),
            Text(label, style: hint),
          ],
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(s.dealHint,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: hint),
        ),
        const SizedBox(width: 16),
        key(s.keySpace, s.keySpaceHint),
        const SizedBox(width: 14),
        key(s.keyR, s.keyRHint),
        const SizedBox(width: 14),
        key(s.keyF11, s.keyF11Hint),
      ],
    );
  }
}

class _CardGrid extends ConsumerWidget {
  const _CardGrid({required this.deal, required this.tier});

  final DealState deal;
  final LayoutTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final tokens = ref.watch(tokensProvider);
    final animate = ref.watch(settingsProvider.select((x) => x.animations));
    final notifier = ref.read(dealProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final grid = computeGrid(
          areaWidth: constraints.maxWidth,
          areaHeight: constraints.maxHeight,
          n: deal.total,
          tier: tier,
        );

        final rows = <Widget>[];
        for (var r = 0; r < grid.rows; r++) {
          final cells = <Widget>[];
          for (var c = 0; c < grid.cols; c++) {
            final i = r * grid.cols + c;
            if (i >= deal.total) break;
            if (c > 0) cells.add(SizedBox(width: grid.gap.toDouble()));
            final book = deal.cards[i];
            final (face, ink) = autoCardColour(book.title, tokens);
            final isOut = deal.out.contains(i);
            final isWinner = deal.winner == i;
            final isLast = !isOut && !isWinner && deal.lastStanding;
            cells.add(DealCard(
              index: i,
              title: book.title,
              author: book.author,
              faceColour: face,
              inkColour: ink,
              width: grid.cardWidth,
              height: grid.cardHeight,
              isOut: isOut,
              isWinner: isWinner,
              isLastStanding: isLast,
              animate: animate,
              eliminatedLabel: s.cardOutBand,
              semanticLabel: isOut
                  ? s.cardEliminated(book.title)
                  : (isWinner
                      ? s.cardWinner(book.title)
                      : s.cardClosed(i + 1)),
              onPressed: isOut || isWinner || isLast || deal.shuffling
                  ? null
                  : () => notifier.eliminate(i),
            ));
          }
          if (r > 0) rows.add(SizedBox(height: grid.gap.toDouble()));
          rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: cells));
        }

        final table = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );

        return Center(
          child: AnimatedScale(
            scale: deal.shuffling ? 0.8 : 1,
            duration: animate ? kGatherDuration : Duration.zero,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: deal.shuffling ? 0 : 1,
              duration: animate ? kGatherDuration : Duration.zero,
              curve: Curves.easeInOut,
              child: animate
                  ? _DealIn(
                      key: ValueKey<int>(deal.round),
                      fromLeft: deal.round.isEven,
                      child: table,
                    )
                  : table,
            ),
          ),
        );
      },
    );
  }
}

/// Cards fly in from above, tilted one way or the other on alternate rounds.
class _DealIn extends StatefulWidget {
  const _DealIn({super.key, required this.child, required this.fromLeft});

  final Widget child;
  final bool fromLeft;

  @override
  State<_DealIn> createState() => _DealInState();
}

class _DealInState extends State<_DealIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = const Cubic(0.2, 0.8, 0.2, 1).transform(_c.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, -40 * (1 - t)),
              child: Transform.rotate(
                angle: (widget.fromLeft ? -6 : 6) * (1 - t) * 3.1415926 / 180,
                child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
              ),
            ),
          );
        },
        child: widget.child,
      );
}

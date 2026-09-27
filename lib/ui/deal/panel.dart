import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/card_colors.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../state/deal_state.dart';
import '../../state/library_state.dart';
import '../widgets/banners.dart';
import '../widgets/buttons.dart';
import '../widgets/icons.dart';

/// The right-hand column: source, counters, the log and the actions.
class DealPanel extends ConsumerWidget {
  const DealPanel({super.key, required this.tier});

  final LayoutTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final tokens = ref.watch(tokensProvider);
    final library = ref.watch(libraryProvider);
    final deal = ref.watch(dealProvider);
    final em = tier.panelFont;
    final data = library.data;

    final listName = (data?.displayName.isNotEmpty ?? false)
        ? data!.displayName
        : s.defaultListName;

    return Container(
      width: tier.panel,
      padding: EdgeInsets.all(em * 1.6),
      decoration: BoxDecoration(
        color: deck.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: deck.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Eyebrow(s.panelEyebrowList),
          SizedBox(height: em * 0.5),
          Text(
            listName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: deck.display(size: em * 1.75, height: 1.1),
          ),
          SizedBox(height: em * 0.7),

          if (library.offline)
            _OfflineBox(em: em)
          else
            _SourceRow(em: em),

          if (library.notice != null) ...<Widget>[
            SizedBox(height: em * 0.8),
            _NoticeBox(em: em),
          ],

          if (data != null && data.readCount > 0) ...<Widget>[
            SizedBox(height: em * 0.8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                StrokeIcon(AppIcons.bookCheck, size: 16, color: deck.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.sheetTotalLine(data.total, data.readCount),
                    style: deck.body(
                        size: em * 0.92, color: deck.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ],

          if (deal.capped) ...<Widget>[
            SizedBox(height: em * 0.5),
            Text(
              s.spreadCapped(deal.total, deal.poolSize),
              style: deck.body(size: em * 0.92, color: deck.muted, height: 1.4),
            ),
          ],

          SizedBox(height: em * 1.2),
          Container(height: 1, color: deck.line),
          SizedBox(height: em * 1.2),

          if (deal.winnerBook == null)
            _Counter(em: em, deal: deal)
          else
            _ChoiceBlock(em: em, deal: deal, tokens: tokens),

          SizedBox(height: em * 1.2),
          Expanded(child: _Log(em: em, deal: deal, tokens: tokens)),
          SizedBox(height: em * 1.2),

          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: s.pickRandom,
                  icon: const StrokeIcon(AppIcons.dice, size: 18),
                  expand: true,
                  onPressed: deal.available.length < 2 || deal.winner != null
                      ? null
                      : ref.read(dealProvider.notifier).pickRandom,
                ),
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: const StrokeIcon(AppIcons.shuffle, size: 18),
                label: s.reshuffle,
                onPressed: ref.read(dealProvider.notifier).reshuffle,
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: const StrokeIcon(AppIcons.gear, size: 18),
                label: s.settings,
                onPressed: () =>
                    ref.read(routeProvider.notifier).go(AppRoute.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends ConsumerWidget {
  const _SourceRow({required this.em});

  final double em;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final library = ref.watch(libraryProvider);
    final data = library.data;
    if (data == null) return const SizedBox.shrink();

    return Row(
      children: <Widget>[
        StrokeIcon(AppIcons.sheet, size: 16, color: deck.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${s.sourceSheet} · ${s.relativeDateTime(data.loadedAt)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: deck.body(size: em * 0.92, color: deck.muted, height: 1.35),
          ),
        ),
        AppIconButton(
          icon: const StrokeIcon(AppIcons.refresh, size: 16),
          label: s.refresh,
          small: true,
          spinning: library.refreshing,
          onPressed: library.refreshing
              ? null
              : ref.read(libraryProvider.notifier).refresh,
        ),
      ],
    );
  }
}

class _OfflineBox extends ConsumerWidget {
  const _OfflineBox({required this.em});

  final double em;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final library = ref.watch(libraryProvider);
    final savedAt = library.data == null
        ? ''
        : s.relativeDateTime(library.data!.loadedAt);

    return StatusBox(
      tone: BannerTone.accent,
      leading: StrokeIcon(AppIcons.wifiOff, size: 20, color: deck.accent),
      title: s.netOfflineTitle,
      body: s.netOfflineBody(savedAt),
      action: AppButton(
        label: library.checking ? s.netChecking : s.netRecheck,
        style: AppButtonStyle.ghost,
        size: AppButtonSize.small,
        icon: const StrokeIcon(AppIcons.refresh, size: 15),
        spinning: library.checking,
        onPressed: library.checking
            ? null
            : ref.read(libraryProvider.notifier).checkAgain,
      ),
    );
  }
}

/// "Связь восстановлена" after an offline spell, or "Список обновлён" after a
/// plain refresh that actually changed something.
class _NoticeBox extends ConsumerWidget {
  const _NoticeBox({required this.em});

  final double em;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final library = ref.watch(libraryProvider);
    final delta = library.notice;
    if (delta == null) return const SizedBox.shrink();

    return StatusBox(
      tone: BannerTone.ok,
      leading: StrokeIcon(AppIcons.checkCircle, size: 20, color: deck.ok),
      title: library.noticeAfterOffline
          ? s.netRestoredTitle
          : s.listUpdatedTitle,
      body: delta.isEmpty
          ? s.netRestoredNoChange
          : s.listChanged(delta.added, delta.removed,
              redealt: library.noticeRedealt),
      trailing: AppIconButton(
        icon: const StrokeIcon(AppIcons.cross, size: 12),
        label: s.netHide,
        small: true,
        dimension: 28,
        onPressed: ref.read(libraryProvider.notifier).dismissNotice,
      ),
    );
  }
}

class _Counter extends ConsumerWidget {
  const _Counter({required this.em, required this.deal});

  final double em;
  final DealState deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(s.panelLeft,
                style: deck.body(size: em * 0.95, color: deck.muted)),
            const SizedBox(width: 8),
            Text(
              '${deal.left}',
              style: deck.display(
                  size: em * 2.6,
                  weight: FontWeight.w700,
                  color: deck.accent,
                  height: 1),
            ),
            const SizedBox(width: 8),
            Text('${s.panelOutOf} ${deal.total}',
                style: deck.body(size: em * 0.95, color: deck.muted)),
          ],
        ),
        SizedBox(height: em * 0.8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: ColoredBox(color: deck.surface2)),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  widthFactor: deal.progress,
                  heightFactor: 1,
                  alignment: Alignment.centerLeft,
                  child: ColoredBox(color: deck.accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceBlock extends ConsumerWidget {
  const _ChoiceBlock({
    required this.em,
    required this.deal,
    required this.tokens,
  });

  final double em;
  final DealState deal;
  final DesignTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final book = deal.winnerBook!;
    final (face, _) = autoCardColour(book.title, tokens);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 46,
          height: 64,
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: deck.accent, width: 1.5),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Eyebrow(s.panelEyebrowChoice, color: deck.accent),
              const SizedBox(height: 3),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: deck.display(size: em * 1.45, height: 1.1),
              ),
              if (book.author.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: deck.body(size: em * 0.92, color: deck.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Log extends ConsumerWidget {
  const _Log({required this.em, required this.deal, required this.tokens});

  final double em;
  final DealState deal;
  final DesignTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final log = deal.log;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Eyebrow('${s.panelEliminated} · ${deal.out.length}'),
        SizedBox(height: em * 0.6),
        if (log.isEmpty)
          Text(
            s.panelLogEmpty,
            style: deck.body(size: em * 0.95, color: deck.muted, height: 1.45),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: log.length,
              itemBuilder: (context, i) {
                final pos = log[i];
                final book = deal.cards[pos];
                final (face, _) = autoCardColour(book.title, tokens);
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: deck.line)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 14,
                        decoration: BoxDecoration(
                          color: face,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: deck.line2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: deck.body(size: em * 0.95),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${log.length - i}',
                        style: deck.body(size: em * 0.82, color: deck.muted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Shown instead of the table when the sheet has fewer than two unread books.
class TooFewBooks extends ConsumerWidget {
  const TooFewBooks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final url = ref.watch(libraryProvider).data?.sheetUrl;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              s.tooFewTitle,
              textAlign: TextAlign.center,
              style: deck.display(size: 22, height: 1.25),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                AppButton(
                  label: s.refresh,
                  icon: const StrokeIcon(AppIcons.refresh, size: 18),
                  onPressed: ref.read(libraryProvider.notifier).refresh,
                ),
                if (url != null && url.isNotEmpty)
                  AppButton(
                    label: s.openSheet,
                    style: AppButtonStyle.ghost,
                    onPressed: () => launchUrl(Uri.parse(url)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

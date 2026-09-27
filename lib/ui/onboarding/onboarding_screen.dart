import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/card_colors.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../state/onboarding_state.dart';
import '../deal/card_back.dart';
import '../widgets/banners.dart';
import '../widgets/buttons.dart';
import '../widgets/controls.dart';
import '../widgets/icons.dart';
import '../window/title_bar.dart';

const String kShareHelpUrl =
    'https://support.google.com/docs/answer/2494822';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _url =
      TextEditingController(text: ref.read(onboardingProvider).url);

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final state = ref.watch(onboardingProvider);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1400;
    final big = width >= 1800;

    final pad = compact ? 32.0 : 48.0;
    final colGap = compact ? 48.0 : (big ? 120.0 : 88.0);
    final leftW = compact ? 420.0 : (big ? 560.0 : 480.0);
    final panelW = compact ? 560.0 : (big ? 660.0 : 600.0);
    final panelPad = compact ? 28.0 : 36.0;
    final h1 = compact ? 48.0 : (big ? 72.0 : 60.0);
    final fanScale = compact ? 0.8 : (big ? 1.15 : 1.0);

    return ColoredBox(
      color: deck.bg,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: _OnboardingGlow(deck.glow)),
          ),
          Column(
            children: <Widget>[
              const AppTitleBar(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: SizedBox(
                          width: leftW,
                          child: _LeftColumn(
                            titleSize: h1,
                            fanScale: fanScale,
                          ),
                        ),
                      ),
                      SizedBox(width: colGap),
                      Flexible(
                        flex: 2,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: panelW),
                          child: _Panel(
                            padding: panelPad,
                            compact: compact,
                            controller: _url,
                            state: state,
                            strings: s,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeftColumn extends ConsumerWidget {
  const _LeftColumn({required this.titleSize, required this.fanScale});

  final double titleSize;
  final double fanScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Transform.scale(
          scale: fanScale,
          alignment: Alignment.bottomLeft,
          child: const _Fan(),
        ),
        const SizedBox(height: 28),
        Text('Book Oracle', style: deck.display(size: titleSize, height: 1)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            s.onbLead,
            style: deck.body(size: 17, color: deck.muted, height: 1.5),
          ),
        ),
      ],
    );
  }
}

/// Five backs spread across a 340×240 box.
class _Fan extends StatefulWidget {
  const _Fan();

  @override
  State<_Fan> createState() => _FanState();
}

class _FanState extends State<_Fan> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 340,
        height: 240,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * 1.4;
            return Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                for (var k = -2; k <= 2; k++)
                  _fanCard(context, k, t),
              ],
            );
          },
        ),
      );

  Widget _fanCard(BuildContext context, int k, double t) {
    final delay = 0.1 + k.abs() * 0.12;
    final p = const Cubic(0.2, 0.8, 0.2, 1)
        .transform(((t - delay) / 0.9).clamp(0.0, 1.0));
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(k * 46.0 * p, 20 * (1 - p)),
        child: Transform.rotate(
          alignment: const Alignment(0, 1.4),
          angle: k * 9 * p * math.pi / 180,
          child: Container(
            width: 120,
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                    color: Color(0x4D000000), blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CardBackView(index: k + 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends ConsumerWidget {
  const _Panel({
    required this.padding,
    required this.compact,
    required this.controller,
    required this.state,
    required this.strings,
  });

  final double padding;
  final bool compact;
  final TextEditingController controller;
  final OnboardingState state;
  final Strings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = strings;
    final notifier = ref.read(onboardingProvider.notifier);

    // On the narrow tier the example table is dropped once we have a result,
    // so the card still fits the window height.
    final showColumns = !(compact && state.status == OnbStatus.ok);
    final showTable = !compact ||
        state.status == OnbStatus.empty ||
        state.status == OnbStatus.checking;

    return Container(
      decoration: BoxDecoration(
        color: deck.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: deck.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x2E000000), blurRadius: 60, offset: Offset(0, 20)),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Eyebrow(s.onbEyebrow),
            const SizedBox(height: 8),
            Text(s.onbTitle, style: deck.display(size: 28, height: 1.15)),
            const SizedBox(height: 8),
            Text(s.onbIntro,
                style: deck.body(size: 14, color: deck.muted, height: 1.5)),

            if (showColumns) ...<Widget>[
              const SizedBox(height: 20),
              Text(s.onbColumnsTitle,
                  style: deck.body(size: 13, weight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  RequiredColumnChip(
                      english: 'title', russian: s.onbColTitle, or: s.onbOr),
                  RequiredColumnChip(
                      english: 'author', russian: s.onbColAuthor, or: s.onbOr),
                  RequiredColumnChip(
                      english: 'read', russian: s.onbColRead, or: s.onbOr),
                ],
              ),
              if (showTable) ...<Widget>[
                const SizedBox(height: 10),
                _SampleTable(strings: s),
              ],
              const SizedBox(height: 10),
              Text(s.onbColumnsNote,
                  style: deck.body(size: 12, color: deck.muted, height: 1.45)),
            ],

            const SizedBox(height: 20),
            Text(s.onbUrlLabel,
                style: deck.body(size: 13, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: controller,
                    placeholder: s.onbUrlPlaceholder,
                    error: state.isError,
                    onChanged: notifier.setUrl,
                    onSubmitted: (_) => notifier.connect(),
                    semanticLabel: s.onbUrlLabel,
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: s.onbConnect,
                  size: AppButtonSize.large,
                  onPressed: state.status == OnbStatus.checking
                      ? null
                      : () => notifier.connect(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    s.onbAccessHelp,
                    style: deck.body(size: 12, color: deck.muted, height: 1.45),
                  ),
                ),
                const SizedBox(width: 8),
                AppLinkButton(
                  label: s.onbAccessHelpLink,
                  onPressed: () => launchUrl(Uri.parse(kShareHelpUrl)),
                ),
              ],
            ),

            ..._status(context, ref, s),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                AppLinkButton(
                  label: s.onbTrySample,
                  onPressed: notifier.useSample,
                ),
                if (state.status == OnbStatus.ok)
                  AppButton(
                    label: s.onbStart,
                    size: AppButtonSize.large,
                    trailingIcon: const StrokeIcon(AppIcons.arrowRight, size: 18),
                    autofocus: true,
                    onPressed: notifier.start,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _status(BuildContext context, WidgetRef ref, Strings s) {
    final deck = context.deck;
    final notifier = ref.read(onboardingProvider.notifier);

    Widget box(Widget w) => Padding(padding: const EdgeInsets.only(top: 16), child: w);

    return switch (state.status) {
      OnbStatus.empty => const <Widget>[],
      OnbStatus.checking => <Widget>[
          box(StatusBox(
            tone: BannerTone.info,
            leading: const AppSpinner(size: 20),
            title: s.onbChecking,
          )),
        ],
      OnbStatus.ok => <Widget>[box(_OkBox(state: state, strings: s))],
      OnbStatus.access => <Widget>[
          box(StatusBox(
            tone: BannerTone.error,
            leading: StrokeIcon(AppIcons.lock, size: 20, color: deck.error),
            title: s.errAccessTitle,
            body: s.errAccessBody,
          )),
        ],
      OnbStatus.columns => <Widget>[
          box(StatusBox(
            tone: BannerTone.error,
            leading:
                StrokeIcon(AppIcons.tableCross, size: 20, color: deck.error),
            title: s.errColumnsTitle(state.missing),
            body: s.errColumnsBody(state.found),
          )),
        ],
      OnbStatus.format => <Widget>[
          box(StatusBox(
            tone: BannerTone.error,
            leading:
                StrokeIcon(AppIcons.infoCircle, size: 20, color: deck.error),
            title: s.errFormatTitle,
            body: s.errFormatBody,
          )),
        ],
      OnbStatus.offline => <Widget>[
          box(StatusBox(
            tone: BannerTone.accent,
            leading: StrokeIcon(AppIcons.wifiOff, size: 20, color: deck.accent),
            title: s.errOfflineTitle,
            body: s.errOfflineBody,
            action: AppButton(
              label: s.onbRetry,
              style: AppButtonStyle.ghost,
              size: AppButtonSize.small,
              icon: const StrokeIcon(AppIcons.refresh, size: 15),
              onPressed: () => notifier.connect(),
            ),
          )),
        ],
      OnbStatus.unknown => <Widget>[
          box(StatusBox(
            tone: BannerTone.error,
            leading:
                StrokeIcon(AppIcons.infoCircle, size: 20, color: deck.error),
            title: s.errUnknownTitle,
            body: s.errUnknownBody,
          )),
        ],
    };
  }
}

class _OkBox extends ConsumerWidget {
  const _OkBox({required this.state, required this.strings});

  final OnboardingState state;
  final Strings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = strings;
    final tokens = ref.watch(tokensProvider);
    final data = state.candidate!;
    final name = data.displayName.isEmpty ? s.defaultListName : data.displayName;
    final firstThree = data.unread.take(3).toList();
    final rest = data.deckCount - firstThree.length;

    return StatusBox(
      tone: BannerTone.ok,
      leading: StrokeIcon(AppIcons.checkCircle, size: 20, color: deck.ok),
      title: '«$name» · ${s.books(data.total)}, '
          '${s.inDeck(data.deckCount)}, ${s.readCount(data.readCount)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (data.tabs.length > 1) ...<Widget>[
            Row(
              children: <Widget>[
                Text('${s.onbSheetLabel} ',
                    style: deck.body(size: 13, color: deck.muted)),
                const SizedBox(width: 6),
                _TabPicker(data: data),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final b in firstThree)
                AppChip(
                  label: b.title,
                  swatch: autoCardColour(b.title, tokens).$1,
                ),
              if (rest > 0) AppChip(label: s.andMore(rest)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabPicker extends ConsumerWidget {
  const _TabPicker({required this.data});

  final LibraryData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final hasGid = data.tabs.any((t) => t.gid == data.gid);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: deck.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: deck.line2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: hasGid ? data.gid : null,
          isDense: true,
          dropdownColor: deck.surface2,
          style: deck.body(size: 14, weight: FontWeight.w500),
          items: <DropdownMenuItem<String>>[
            for (final t in data.tabs)
              DropdownMenuItem<String>(
                value: t.gid,
                child: Text(t.name),
              ),
          ],
          onChanged: (gid) {
            if (gid != null) {
              ref.read(onboardingProvider.notifier).selectTab(gid);
            }
          },
        ),
      ),
    );
  }
}

/// The A/B/C mini-spreadsheet that shows what the header should look like.
class _SampleTable extends StatelessWidget {
  const _SampleTable({required this.strings});

  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final s = strings;

    Widget head(String label) => Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          color: deck.surface2,
          child: Text(
            label,
            style: deck.body(
                size: 11, weight: FontWeight.w600, color: deck.muted),
          ),
        );

    Widget rowNumber(String n) => Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          color: deck.surface2,
          child: Text(n, style: deck.body(size: 11, color: deck.muted)),
        );

    Widget cell(
      String text, {
      bool bold = false,
      bool dim = false,
      bool strike = false,
    }) =>
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: deck.body(
              size: 13,
              weight: bold ? FontWeight.w700 : FontWeight.w400,
              color: dim ? deck.muted : deck.text,
              decoration: strike ? TextDecoration.lineThrough : null,
            ),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: deck.line2),
        ),
        child: Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FixedColumnWidth(32),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(0.8),
          },
          border: TableBorder.symmetric(
            inside: BorderSide(color: deck.line),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: <TableRow>[
            TableRow(children: <Widget>[
              head(''),
              head('A'),
              head('B'),
              head('C'),
            ]),
            TableRow(children: <Widget>[
              rowNumber('1'),
              cell(s.onbSampleHeaderTitle, bold: true),
              cell(s.onbSampleHeaderAuthor, bold: true),
              cell(s.onbSampleHeaderRead, bold: true),
            ]),
            TableRow(children: <Widget>[
              rowNumber('2'),
              cell(s.onbSampleRow1Title),
              cell(s.onbSampleRow1Author),
              cell(''),
            ]),
            TableRow(children: <Widget>[
              rowNumber('3'),
              cell(s.onbSampleRow2Title, dim: true, strike: true),
              cell(s.onbSampleRow2Author, dim: true),
              cell(s.onbSampleRow2Read),
            ]),
          ],
        ),
      ),
    );
  }
}

class _OnboardingGlow extends CustomPainter {
  const _OnboardingGlow(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width * 0.26, size.height * 0.5);
    final rect = Rect.fromCircle(center: centre, radius: 650);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[colour, colour.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_OnboardingGlow old) => old.colour != colour;
}

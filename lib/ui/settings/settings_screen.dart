import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/card_colors.dart';
import '../../core/layout.dart';
import '../../core/sound.dart';
import '../../core/tokens.dart';
import '../../data/settings_repo.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../state/library_state.dart';
import '../../state/onboarding_state.dart';
import '../deal/card_back.dart';
import '../widgets/buttons.dart';
import '../widgets/controls.dart';
import '../widgets/icons.dart';
import '../window/title_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1400;
    final pad = tierFor(width).pad;
    final previewWidth = compact ? 330.0 : 420.0;

    return ColoredBox(
      color: deck.bg,
      child: Column(
        children: <Widget>[
          AppTitleBar(screenName: s.settingsTitle),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      AppButton(
                        label: s.backToTable,
                        style: AppButtonStyle.ghost,
                        icon: const StrokeIcon(AppIcons.chevronLeft, size: 18),
                        onPressed: () =>
                            ref.read(routeProvider.notifier).go(AppRoute.deal),
                      ),
                      const SizedBox(width: 20),
                      Text(s.settingsTitle,
                          style: deck.display(size: 30, height: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.only(right: 4),
                            children: const <Widget>[
                              _DeckSection(),
                              SizedBox(height: 16),
                              _BackgroundSection(),
                              SizedBox(height: 16),
                              _ListSection(),
                              SizedBox(height: 16),
                              _BehaviourSection(),
                              SizedBox(height: 16),
                              _LanguageSection(),
                            ],
                          ),
                        ),
                        SizedBox(width: pad),
                        SizedBox(
                          width: previewWidth,
                          child: const _Preview(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, required this.children});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: deck.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: deck.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: deck.display(size: 20, height: 1.2)),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: deck.body(size: 13, color: deck.muted, height: 1.45)),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Shared chrome for a selectable tile.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.selected,
    required this.onPressed,
    required this.label,
    required this.child,
  });

  final bool selected;
  final VoidCallback onPressed;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, hovered, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: deck.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? deck.accent : deck.line2,
            width: selected ? 2 : 1,
          ),
          boxShadow: focused
              ? <BoxShadow>[BoxShadow(color: deck.accentGlow, blurRadius: 10)]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            child,
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: deck.accent, shape: BoxShape.circle),
                  child: StrokeIcon(AppIcons.check,
                      size: 14, color: deck.accentInk),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeckSection extends ConsumerWidget {
  const _DeckSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final tokens = ref.watch(tokensProvider);
    final current = ref.watch(settingsProvider.select((x) => x.deck));

    return _Section(
      title: s.secDeck,
      subtitle: s.secDeckSub,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final id in DesignTokens.deckOrder) ...<Widget>[
              if (id != DesignTokens.deckOrder.first) const SizedBox(width: 12),
              Expanded(
                child: _DeckTile(
                  deck: tokens.deck(id),
                  selected: id == current,
                  onPressed: () =>
                      ref.read(settingsProvider.notifier).setDeck(id),
                  label: deckName(s, id, tokens.deck(id).name),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({
    required this.deck,
    required this.selected,
    required this.onPressed,
    required this.label,
  });

  final DeckTheme deck;
  final bool selected;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.deck;

    Widget mini(int index, {double dx = 0, double dy = 0, double turn = 0}) =>
        Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: turn * 3.1415926 / 180,
            child: Container(
              width: 52,
              height: 73,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                      color: Color(0x4D000000),
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CardBackView(index: index, deck: deck),
              ),
            ),
          ),
        );

    Widget swatch(Color c) => Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.line2),
          ),
        );

    return _Tile(
      selected: selected,
      onPressed: onPressed,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 118,
            child: ColoredBox(
              color: deck.bg,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  mini(1, dx: -30, turn: -12),
                  mini(2, dx: 30, turn: 12),
                  mini(0, dy: -4),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.body(size: 15, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          swatch(deck.bg),
                          const SizedBox(width: 4),
                          swatch(deck.surface),
                          const SizedBox(width: 4),
                          swatch(deck.accent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Аа',
                  style: fontStyle(deck.displayFont,
                      fontSize: 26, color: theme.muted, height: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundSection extends ConsumerWidget {
  const _BackgroundSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final tokens = ref.watch(tokensProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final ids = DesignTokens.backgroundOrder;

    final rows = <Widget>[];
    for (var i = 0; i < ids.length; i += 4) {
      final slice = ids.sublist(i, (i + 4).clamp(0, ids.length));
      rows.add(Row(
        children: <Widget>[
          for (var k = 0; k < 4; k++) ...<Widget>[
            if (k > 0) const SizedBox(width: 12),
            Expanded(
              child: k < slice.length
                  ? _BackgroundTile(
                      def: tokens.background(slice[k]),
                      selected: settings.background == slice[k] &&
                          !settings.seasonalBackground,
                      onPressed: () => notifier.setBackground(slice[k]),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
      if (i + 4 < ids.length) rows.add(const SizedBox(height: 12));
    }

    return _Section(
      title: s.secBackground,
      children: <Widget>[
        ...rows,
        const SizedBox(height: 16),
        if (settings.background == 'custom') ...<Widget>[
          Row(
            children: <Widget>[
              AppButton(
                label: s.bgPickFile,
                style: AppButtonStyle.ghost,
                onPressed: () async {
                  final picked = await FilePicker.pickFile(
                    type: FileType.custom,
                    allowedExtensions: const <String>['png', 'jpg', 'jpeg'],
                  );
                  final path = picked?.path;
                  if (path == null) return;
                  final stored = await SettingsRepo.importBackground(path);
                  notifier.setCustomBackground(stored);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  settings.customBackgroundPath == null
                      ? '${s.bgNoFile} · ${s.bgFileHint}'
                      : '${_fileName(settings.customBackgroundPath!)} · ${s.bgFileHint}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: deck.body(size: 13, color: deck.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: <Widget>[
            Text(s.bgDim, style: deck.body(size: 14)),
            const SizedBox(width: 16),
            Expanded(
              child: AppSlider(
                value: settings.dim.toDouble(),
                min: 0,
                max: 80,
                divisions: 16,
                label: '${settings.dim}%',
                onChanged: (v) => notifier.setDim(v.round()),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${settings.dim}%',
                textAlign: TextAlign.right,
                style: deck.body(size: 14, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        AppSwitchRow(
          label: s.bgSeasonal,
          subtitle: s.bgSeasonalSub,
          value: settings.seasonalBackground,
          onChanged: notifier.setSeasonal,
        ),
      ],
    );
  }

  static String _fileName(String path) =>
      path.split(Platform.pathSeparator).last;
}

class _BackgroundTile extends ConsumerWidget {
  const _BackgroundTile({
    required this.def,
    required this.selected,
    required this.onPressed,
  });

  final BackgroundDef def;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final customPath =
        ref.watch(settingsProvider.select((x) => x.customBackgroundPath));
    final name = backgroundName(s, def.id, def.name);

    Widget thumb;
    switch (def.kind) {
      case BackgroundKind.image:
        thumb = Image.asset(def.file!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: deck.surface2));
      case BackgroundKind.animated:
        thumb = CustomPaint(painter: _GlowThumb(deck.glow, deck.bg));
      case BackgroundKind.file:
        thumb = customPath == null
            ? CustomPaint(
                painter: _HatchThumb(deck.surface2, deck.line2),
                child: Center(
                  child: StrokeIcon(AppIcons.upload, size: 26, color: deck.muted),
                ),
              )
            : Image.file(File(customPath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: deck.surface2));
      case BackgroundKind.color:
        thumb = ColoredBox(color: deck.bg);
    }

    return _Tile(
      selected: selected,
      onPressed: onPressed,
      label: name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 86, child: thumb),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: deck.body(size: 14, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  backgroundSubtitle(s, def.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: deck.body(size: 12, color: deck.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSection extends ConsumerStatefulWidget {
  const _ListSection();

  @override
  ConsumerState<_ListSection> createState() => _ListSectionState();
}

class _ListSectionState extends ConsumerState<_ListSection> {
  final TextEditingController _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final library = ref.watch(libraryProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final data = library.data;
    final url = settings.sheetUrl ?? '';
    if (_url.text != url) _url.text = url;

    return _Section(
      title: s.secList,
      children: <Widget>[
        Text(s.setUrlLabel, style: deck.body(size: 13, color: deck.muted)),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: AppTextField(
                controller: _url,
                readOnly: true,
                height: 44,
                semanticLabel: s.setUrlLabel,
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: library.refreshing ? s.refreshing : s.refresh,
              style: AppButtonStyle.ghost,
              icon: const StrokeIcon(AppIcons.refresh, size: 16),
              spinning: library.refreshing,
              onPressed: library.refreshing || data == null
                  ? null
                  : ref.read(libraryProvider.notifier).refresh,
            ),
            const SizedBox(width: 8),
            AppButton(
              label: s.setChangeSheet,
              style: AppButtonStyle.ghost,
              onPressed: () {
                ref
                    .read(onboardingProvider.notifier)
                    .prefill(settings.sheetUrl ?? '');
                ref.read(routeProvider.notifier).go(AppRoute.onboarding);
              },
            ),
          ],
        ),
        if (data != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            s.sheetSummary(
              sheetName: data.tabName,
              total: data.total,
              deck: data.deckCount,
              read: data.readCount,
              columns: data.columns.map(s.columnLabel).toList(),
              updated: s.relativeDateTime(data.loadedAt),
            ),
            style: deck.body(size: 13, color: deck.muted, height: 1.45),
          ),
        ],
        const SizedBox(height: 8),
        AppSwitchRow(
          label: s.swRefreshOnStart,
          value: settings.refreshOnStart,
          onChanged: notifier.setRefreshOnStart,
          first: true,
        ),
        AppSwitchRow(
          label: s.swUseCacheOffline,
          value: settings.useCacheOffline,
          onChanged: notifier.setUseCacheOffline,
        ),
      ],
    );
  }
}

class _BehaviourSection extends ConsumerWidget {
  const _BehaviourSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return _Section(
      title: s.secBehaviour,
      children: <Widget>[
        AppSwitchRow(
          label: s.swAnimations,
          value: settings.animations,
          onChanged: notifier.setAnimations,
          first: true,
        ),
        // Hidden while card sounds are off for the build; see kCardSoundsEnabled.
        if (kCardSoundsEnabled)
          AppSwitchRow(
            label: s.swSounds,
            value: settings.sounds,
            onChanged: (v) {
              notifier.setSounds(v);
              // Turning them on plays one, so you hear what you just enabled.
              if (v) ref.read(soundBoardProvider).play(Sfx.flip);
            },
          ),
        AppSwitchRow(
          label: s.swFullscreenReveal,
          value: settings.fullscreenReveal,
          onChanged: notifier.setFullscreenReveal,
        ),
        AppSwitchRow(
          label: s.swRememberWindow,
          value: settings.rememberWindow,
          onChanged: notifier.setRememberWindow,
        ),
      ],
    );
  }
}

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final current = ref.watch(settingsProvider.select((x) => x.language));
    final notifier = ref.read(settingsProvider.notifier);

    Widget option(Strings variant) {
      final selected = variant.localeCode == current;
      return Pressable(
        onPressed: () => notifier.setLanguage(variant.localeCode),
        semanticLabel: variant.languageName,
        builder: (context, hovered, focused) => Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? deck.accentSoft
                : (hovered ? deck.surface2 : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? deck.accent : deck.line2),
          ),
          foregroundDecoration: focused
              ? BoxDecoration(
                  border: Border.all(color: deck.accent, width: 2),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: Text(
            variant.languageName,
            style: deck.body(
              size: 14,
              weight: FontWeight.w600,
              color: selected ? deck.accent : deck.text,
            ),
          ),
        ),
      );
    }

    return _Section(
      title: s.secLanguage,
      children: <Widget>[
        Row(
          children: <Widget>[
            option(Strings.ru),
            const SizedBox(width: 12),
            option(Strings.en),
          ],
        ),
      ],
    );
  }
}

/// The mini table on the right: current deck, background and dimming.
class _Preview extends ConsumerWidget {
  const _Preview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final tokens = ref.watch(tokensProvider);
    final settings = ref.watch(settingsProvider);
    final bgId = settings.effectiveBackground;
    final def = tokens.background(bgId);
    final isPhoto = def.kind == BackgroundKind.image ||
        (def.kind == BackgroundKind.file && settings.customBackgroundPath != null);
    final dim = isPhoto
        ? (0.25 + settings.dim / 100).clamp(0.0, 0.95)
        : settings.dim / 200;

    final sample1 = autoCardColour(s.sampleFace1, tokens);
    final sample2 = autoCardColour(s.sampleFace2, tokens);
    final faces = <(String, Color, Color)>[
      (s.sampleFace1, sample1.$1, sample1.$2),
      (s.sampleFace2, sample2.$1, sample2.$2),
    ];

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: deck.body(size: 13, color: deck.muted)),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: deck.body(size: 13, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: deck.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: deck.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Align(alignment: Alignment.centerLeft, child: Eyebrow(s.preview)),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: deck.bg),
                  if (def.kind == BackgroundKind.animated)
                    CustomPaint(painter: _GlowThumb(deck.glow, deck.bg)),
                  if (def.kind == BackgroundKind.image)
                    Image.asset(def.file!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  if (def.kind == BackgroundKind.file &&
                      settings.customBackgroundPath != null)
                    Image.file(File(settings.customBackgroundPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  if (dim > 0)
                    ColoredBox(color: deck.bg.withValues(alpha: dim)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (var r = 0; r < 2; r++) ...<Widget>[
                          if (r > 0) const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (var c = 0; c < 4; c++) ...<Widget>[
                                if (c > 0) const SizedBox(width: 8),
                                _previewCard(context, r * 4 + c, faces),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          row(s.previewDeck, deckName(s, deck.id, deck.name)),
          row(s.previewBackground, backgroundName(s, def.id, def.name)),
          row(s.previewFonts, deck.fontLabel),
        ],
      ),
    );
  }

  Widget _previewCard(
      BuildContext context, int i, List<(String, Color, Color)> faces) {
    final deck = context.deck;
    final isFace = i == 2 || i == 5;
    final eliminated = i == 5;

    Widget card = SizedBox(
      width: 44,
      height: 62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: isFace
            ? Builder(builder: (context) {
                final (title, face, ink) = faces[i == 2 ? 0 : 1];
                return ColoredBox(
                  color: face,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: fontStyle(deck.displayFont,
                            fontSize: 8, color: ink, height: 1.1),
                      ),
                    ),
                  ),
                );
              })
            : CardBackView(index: i),
      ),
    );

    if (eliminated) {
      card = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.296064, 0.457728, 0.046208, 0, 0, //
          0.136064, 0.617728, 0.046208, 0, 0, //
          0.136064, 0.457728, 0.206208, 0, 0, //
          0, 0, 0, 1, 0, //
        ]),
        child: card,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: card,
    );
  }
}

class _GlowThumb extends CustomPainter {
  const _GlowThumb(this.glow, this.bg);

  final Color glow;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final rect = Rect.fromCircle(
      center: Offset(size.width * 0.4, size.height * 0.5),
      radius: size.width * 0.7,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[glow, glow.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlowThumb old) => old.glow != glow || old.bg != bg;
}

class _HatchThumb extends CustomPainter {
  const _HatchThumb(this.base, this.line);

  final Color base;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_HatchThumb old) => old.base != base || old.line != line;
}

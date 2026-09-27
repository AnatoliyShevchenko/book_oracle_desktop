import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../state/library_state.dart';
import '../widgets/buttons.dart';
import '../widgets/icons.dart';
import '../widgets/logo.dart';

/// The app's own title bar: 36 px tall, painted in the deck background.
class AppTitleBar extends ConsumerStatefulWidget {
  const AppTitleBar({super.key, this.screenName});

  /// Shown after the separator, e.g. the list name or "Настройки".
  final String? screenName;

  @override
  ConsumerState<AppTitleBar> createState() => _AppTitleBarState();
}

class _AppTitleBarState extends ConsumerState<AppTitleBar> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    try {
      final value = await windowManager.isMaximized();
      if (mounted && value != _maximized) setState(() => _maximized = value);
    } catch (_) {
      // No window plugin (tests) — the title bar still renders.
    }
  }

  @override
  void onWindowMaximize() => _syncMaximized();

  @override
  void onWindowUnmaximize() => _syncMaximized();

  Future<void> _toggleMaximize() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final s = ref.watch(stringsProvider);
    final offline = ref.watch(libraryProvider.select((l) => l.offline));

    return SizedBox(
      height: kTitleBarHeight,
      child: ColoredBox(
        color: deck.bg,
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) {
                  try {
                    windowManager.startDragging();
                  } catch (_) {}
                },
                onDoubleTap: _toggleMaximize,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    children: <Widget>[
                      const BookOracleLogo(size: 18),
                      const SizedBox(width: 10),
                      Text(
                        s.appName,
                        style: deck.body(size: 13, weight: FontWeight.w600),
                      ),
                      if (widget.screenName != null) ...<Widget>[
                        const SizedBox(width: 10),
                        Container(width: 1, height: 14, color: deck.line),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.screenName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: deck.body(size: 13, color: deck.muted),
                          ),
                        ),
                      ],
                      if (offline) ...<Widget>[
                        const SizedBox(width: 10),
                        _OfflineChip(label: s.offlineChip),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _WindowButton(
              icon: AppIcons.winMinimize,
              label: s.minimize,
              onPressed: () async {
                try {
                  await windowManager.minimize();
                } catch (_) {}
              },
            ),
            _WindowButton(
              icon: _maximized ? AppIcons.winRestore : AppIcons.winMaximize,
              label: _maximized ? s.restore : s.maximize,
              onPressed: _toggleMaximize,
            ),
            _WindowButton(
              icon: AppIcons.winClose,
              label: s.close,
              danger: true,
              onPressed: () async {
                try {
                  await windowManager.close();
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final IconSpec icon;
  final String label;
  final VoidCallback onPressed;
  final bool danger;

  static const Color _closeHover = Color(0xFFC42B1C);

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      canRequestFocus: false,
      builder: (context, hovered, focused) => Container(
        width: 46,
        height: kTitleBarHeight,
        alignment: Alignment.center,
        color: hovered
            ? (danger ? _closeHover : deck.line)
            : Colors.transparent,
        child: StrokeIcon(
          icon,
          size: 10,
          color: hovered && danger ? Colors.white : deck.text,
        ),
      ),
    );
  }
}

class _OfflineChip extends StatelessWidget {
  const _OfflineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: deck.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StrokeIcon(AppIcons.wifiOffSmall, size: 12, color: deck.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: deck.body(
                size: 12, weight: FontWeight.w600, color: deck.accent, height: 1),
          ),
        ],
      ),
    );
  }
}

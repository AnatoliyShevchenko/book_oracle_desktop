import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/tokens.dart';

/// Hover + focus plumbing shared by every clickable thing in the app.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.canRequestFocus = true,
  });

  final Widget Function(BuildContext context, bool hovered, bool focused) builder;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool canRequestFocus;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _focused = false;

  bool get _active => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    Widget child = FocusableActionDetector(
      enabled: _active && widget.canRequestFocus,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      mouseCursor:
          _active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) {
        if (_hovered != v) setState(() => _hovered = v);
      },
      onShowFocusHighlight: (v) {
        if (_focused != v) setState(() => _focused = v);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (_active) widget.onPressed!();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _active ? widget.onPressed : null,
        child: widget.builder(context, _hovered && _active, _focused),
      ),
    );
    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }
    if (widget.semanticLabel != null) {
      child = Semantics(
        label: widget.semanticLabel,
        button: true,
        enabled: _active,
        child: ExcludeSemantics(child: child),
      );
    }
    return child;
  }
}

enum AppButtonStyle { primary, ghost }

enum AppButtonSize { small, normal, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.normal,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.spinning = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool expand;

  /// Spins [icon] — used for "Обновляем…" / "Проверяем…".
  final bool spinning;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final (height, basePadding, fontSize, radius) = switch (size) {
      AppButtonSize.small => (36.0, 14.0, 13.0, 8.0),
      AppButtonSize.normal => (44.0, 18.0, 14.0, 10.0),
      AppButtonSize.large => (48.0, 22.0, 15.0, 10.0),
    };
    // A stretched button lives in a fixed-width column (the panel on the
    // narrow tier is only 280 px), so it gives up padding before its label.
    final padding = expand ? basePadding * 0.66 : basePadding;
    final enabled = onPressed != null;
    final primary = style == AppButtonStyle.primary;

    return Pressable(
      onPressed: onPressed,
      autofocus: autofocus,
      builder: (context, hovered, focused) {
        final background = primary
            ? (hovered ? _brighten(deck.accent, 0.08) : deck.accent)
            : (hovered ? deck.accentSoft : Colors.transparent);
        final foreground = primary ? deck.accentInk : deck.text;
        return Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: padding),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(radius),
              border: primary ? null : Border.all(color: deck.line2),
            ),
            foregroundDecoration: focused
                ? BoxDecoration(
                    border: Border.all(color: deck.accent, width: 2),
                    borderRadius: BorderRadius.circular(radius),
                  )
                : null,
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  IconTheme(
                    data: IconThemeData(color: foreground, size: 18),
                    child: spinning ? _Spinner(child: icon!) : icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: deck.body(
                      size: fontSize,
                      weight: FontWeight.w600,
                      color: foreground,
                      height: 1.1,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...<Widget>[
                  const SizedBox(width: 8),
                  IconTheme(
                    data: IconThemeData(color: foreground, size: 18),
                    child: trailingIcon!,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A square icon button: 44×44 with a border, or 36×36 borderless (`sm`).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.small = false,
    this.spinning = false,
    this.dimension,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  final bool spinning;
  final double? dimension;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final size = dimension ?? (small ? 36.0 : 44.0);
    final radius = small ? 8.0 : 10.0;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      tooltip: label,
      builder: (context, hovered, focused) => Opacity(
        opacity: onPressed == null ? 0.45 : 1,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hovered ? deck.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            border: small ? null : Border.all(color: deck.line2),
          ),
          foregroundDecoration: focused
              ? BoxDecoration(
                  border: Border.all(color: deck.accent, width: 2),
                  borderRadius: BorderRadius.circular(radius),
                )
              : null,
          child: IconTheme(
            data: IconThemeData(color: deck.text, size: small ? 16 : 18),
            child: spinning ? _Spinner(child: icon) : icon,
          ),
        ),
      ),
    );
  }
}

class AppLinkButton extends StatelessWidget {
  const AppLinkButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Pressable(
      onPressed: onPressed,
      builder: (context, hovered, focused) => Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        foregroundDecoration: focused
            ? BoxDecoration(
                border: Border.all(color: deck.accent, width: 2),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Text(
          label,
          style: deck.body(
            size: 14,
            weight: FontWeight.w600,
            color: hovered ? _brighten(deck.accent, 0.12) : deck.accent,
            height: 1.4,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

/// `Пробел`, `R`, `F11` — a key cap with a thick bottom border.
class Kbd extends StatelessWidget {
  const Kbd(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border(
          top: BorderSide(color: deck.line2),
          left: BorderSide(color: deck.line2),
          right: BorderSide(color: deck.line2),
          bottom: BorderSide(color: deck.line2, width: 2),
        ),
      ),
      child: Text(
        label,
        style: deck.body(size: 11, weight: FontWeight.w600, height: 1),
      ),
    );
  }
}

/// Small uppercase label with wide tracking.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.label, {super.key, this.color, this.size = 11, this.tracking = 0.14});

  final String label;
  final Color? color;
  final double size;
  final double tracking;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Text(
      label.toUpperCase(),
      style: deck.body(
        size: size,
        weight: FontWeight.w700,
        color: color ?? deck.muted,
        letterSpacing: size * tracking,
        height: 1.2,
      ),
    );
  }
}

Color _brighten(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

class _Spinner extends StatefulWidget {
  const _Spinner({required this.child});

  final Widget child;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _c, child: widget.child);
}

/// The app's own spinner arc, matching the design's stroked circle.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 20, this.color, this.strokeWidth = 2.4});

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round,
          color: color ?? context.deck.accent,
        ),
      );
}

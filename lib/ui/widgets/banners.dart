import 'package:flutter/material.dart';

import '../../core/tokens.dart';

enum BannerTone { info, ok, error, accent }

/// The rounded status plate used for onboarding states and network notices.
class StatusBox extends StatelessWidget {
  const StatusBox({
    super.key,
    required this.tone,
    this.leading,
    this.title,
    this.body,
    this.child,
    this.action,
    this.trailing,
  });

  final BannerTone tone;
  final Widget? leading;
  final String? title;
  final String? body;

  /// Extra content below the title/body block.
  final Widget? child;

  /// Button below the text, e.g. "Проверить снова".
  final Widget? action;

  /// Right-hand affordance, e.g. the dismiss cross.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final (background, border) = switch (tone) {
      BannerTone.info => (deck.surface2, null),
      BannerTone.ok => (
          deck.ok.withValues(alpha: 0.12),
          deck.ok.withValues(alpha: 0.40)
        ),
      BannerTone.error => (deck.error.withValues(alpha: 0.10), null),
      BannerTone.accent => (deck.accentSoft, deck.line2),
    };

    return _FadeIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  Padding(padding: const EdgeInsets.only(top: 1), child: leading),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (title != null)
                        Text(
                          title!,
                          style: deck.body(
                              size: 14, weight: FontWeight.w700, height: 1.3),
                        ),
                      if (body != null) ...<Widget>[
                        if (title != null) const SizedBox(height: 4),
                        Text(
                          body!,
                          style: deck.body(
                              size: 13, color: deck.muted, height: 1.45),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            if (child != null) ...<Widget>[
              const SizedBox(height: 14),
              child!,
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.04),
            end: Offset.zero,
          ).animate(_fade),
          child: widget.child,
        ),
      );
}

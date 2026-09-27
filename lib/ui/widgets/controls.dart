import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import 'buttons.dart';

/// The pill switch from the design: 40×22 track, 16 px knob.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Pressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      builder: (context, hovered, focused) => Container(
        width: 40,
        height: 22,
        decoration: BoxDecoration(
          color: value ? deck.accent : deck.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: value ? deck.accent : deck.line2),
        ),
        foregroundDecoration: focused
            ? BoxDecoration(
                border: Border.all(color: deck.accent, width: 2),
                borderRadius: BorderRadius.circular(999),
              )
            : null,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? deck.accentInk : deck.muted,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full settings row: label on the left, switch on the right.
class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.first = false,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Pressable(
      onPressed: () => onChanged(!value),
      builder: (context, hovered, focused) => Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: deck.line)),
        ),
        foregroundDecoration: focused
            ? BoxDecoration(
                border: Border.all(color: deck.accent, width: 2),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(label, style: deck.body(size: 14, height: 1.3)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: deck.body(
                            size: 12, color: deck.muted, height: 1.35),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IgnorePointer(
              child: AppSwitch(value: value, onChanged: (_) {}),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dimming slider: 4 px track, 18 px accent thumb.
class AppSlider extends StatelessWidget {
  const AppSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.label,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: deck.accent,
        inactiveTrackColor: deck.surface2,
        thumbColor: deck.accent,
        overlayColor: deck.accentSoft,
        valueIndicatorColor: deck.accent,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}

/// A text field styled like `.field` in the design.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.error = false,
    this.readOnly = false,
    this.height = 48,
    this.autofocus = false,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool error;
  final bool readOnly;
  final double height;
  final bool autofocus;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        readOnly: readOnly,
        autofocus: autofocus,
        cursorColor: deck.accent,
        style: deck.body(size: 15, weight: FontWeight.w500, height: 1.2),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: deck.bg,
          hintText: placeholder,
          hintStyle: deck.body(size: 15, weight: FontWeight.w500, color: deck.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: error ? deck.error : deck.line2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: error ? deck.error : deck.line2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: deck.accent, width: 2),
          ),
        ),
      ),
    );
  }
}

/// Rounded chip with an optional colour swatch — used for the first books.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.swatch, this.maxWidth = 180});

  final String label;
  final Color? swatch;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    return Container(
      height: 28,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: deck.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (swatch != null) ...<Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: swatch,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: deck.body(size: 12, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// `title` **или** `название` — the required-column pill.
class RequiredColumnChip extends StatelessWidget {
  const RequiredColumnChip({
    super.key,
    required this.english,
    required this.russian,
    required this.or,
  });

  final String english;
  final String russian;
  final String or;

  @override
  Widget build(BuildContext context) {
    final deck = context.deck;
    final mono = deck.body(
      size: 12.5,
      weight: FontWeight.w700,
      color: deck.text,
      height: 1.2,
    );
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: deck.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: deck.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(english, style: mono),
          if (english != russian) ...<Widget>[
            Text(' $or ', style: deck.body(size: 13, color: deck.muted, height: 1.2)),
            Text(russian, style: mono),
          ],
        ],
      ),
    );
  }
}

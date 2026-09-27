import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'layout.dart';

/// Parses `#RRGGBB` / `#RRGGBBAA` (alpha last, as written in design_tokens.json)
/// into a Flutter [Color] (`0xAARRGGBB`, alpha first).
Color parseToken(String hex) {
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) return Color(0xFF000000 | int.parse(s, radix: 16));
  if (s.length == 8) {
    final rgb = int.parse(s.substring(0, 6), radix: 16);
    final a = int.parse(s.substring(6, 8), radix: 16);
    return Color((a << 24) | rgb);
  }
  throw FormatException('Unsupported colour token: $hex');
}

// ---------------------------------------------------------------------------
// Fonts
// ---------------------------------------------------------------------------

const _variableFamilies = <String>{
  'Unbounded',
  'Onest',
  'Cormorant Garamond',
  'Manrope',
};

/// Clamps a requested weight to what the bundled face can actually render, so
/// we never fall back to synthetic bolding.
FontWeight _resolveWeight(String family, FontWeight w) {
  switch (family) {
    case 'Prata':
    case 'Yeseva One':
      return FontWeight.w400;
    case 'Old Standard TT':
      return w.value >= 600 ? FontWeight.w700 : FontWeight.w400;
    case 'Cormorant Garamond':
      if (w.value > 700) return FontWeight.w700;
      if (w.value < 300) return FontWeight.w300;
      return w;
    default:
      return w;
  }
}

/// Builds a [TextStyle] for one of the bundled families. Variable faces get an
/// explicit `wght` axis value; static ones rely on plain weight matching.
TextStyle fontStyle(
  String family, {
  double? fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
  Color? decorationColor,
  FontStyle? fontStyle,
}) {
  final w = _resolveWeight(family, fontWeight);
  return TextStyle(
    fontFamily: family,
    fontSize: fontSize,
    fontWeight: w,
    fontVariations: _variableFamilies.contains(family)
        ? <FontVariation>[FontVariation('wght', w.value.toDouble())]
        : null,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor,
    fontStyle: fontStyle,
  );
}

// ---------------------------------------------------------------------------
// Card backs
// ---------------------------------------------------------------------------

enum CardBackKind { pattern, images }

enum Emblem { diamond, circle }

@immutable
class CardBackSpec {
  const CardBackSpec({
    required this.kind,
    required this.base,
    this.lines,
    this.dots,
    this.dotStep = 11,
    this.frame,
    this.emblem = Emblem.diamond,
    this.emblemFill,
    this.emblemStroke,
    this.step = 9,
    this.files = const <String>[],
  });

  final CardBackKind kind;
  final Color base;
  final Color? lines;
  final Color? dots;
  final double dotStep;
  final Color? frame;
  final Emblem emblem;
  final Color? emblemFill;
  final Color? emblemStroke;
  final double step;
  final List<String> files;

  factory CardBackSpec.fromJson(Map<String, dynamic> j) {
    final kind = j['type'] == 'images' ? CardBackKind.images : CardBackKind.pattern;
    return CardBackSpec(
      kind: kind,
      base: parseToken((j['base'] ?? j['fallback'] ?? '#000000') as String),
      lines: j['lines'] == null ? null : parseToken(j['lines'] as String),
      dots: j['dots'] == null ? null : parseToken(j['dots'] as String),
      dotStep: (j['dotStep'] as num?)?.toDouble() ?? 11,
      frame: j['frame'] == null ? null : parseToken(j['frame'] as String),
      emblem: j['emblem'] == 'circle' ? Emblem.circle : Emblem.diamond,
      emblemFill: j['emblemFill'] == null ? null : parseToken(j['emblemFill'] as String),
      emblemStroke:
          j['emblemStroke'] == null ? null : parseToken(j['emblemStroke'] as String),
      step: (j['step'] as num?)?.toDouble() ?? 9,
      files: ((j['files'] as List<dynamic>?) ?? const <dynamic>[])
          .map((e) => e as String)
          .toList(growable: false),
    );
  }

  /// The image used for card index [i] (`files[i % files.length]`).
  String imageFor(int i) => files.isEmpty ? '' : files[i % files.length];

  @override
  bool operator ==(Object other) =>
      other is CardBackSpec &&
      other.kind == kind &&
      other.base == base &&
      other.lines == lines &&
      other.dots == dots &&
      other.dotStep == dotStep &&
      other.frame == frame &&
      other.emblem == emblem &&
      other.emblemFill == emblemFill &&
      other.emblemStroke == emblemStroke &&
      other.step == step &&
      listEquals(other.files, files);

  @override
  int get hashCode => Object.hash(kind, base, lines, dots, dotStep, frame,
      emblem, emblemFill, emblemStroke, step, Object.hashAll(files));
}

// ---------------------------------------------------------------------------
// Deck theme
// ---------------------------------------------------------------------------

/// Drop shadows for cards. These come from the visual design rather than
/// design_tokens.json, which carries no shadow tokens.
const Map<String, List<BoxShadow>> _deckShadows = <String, List<BoxShadow>>{
  'graphite': <BoxShadow>[
    BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 6)),
  ],
  'coven': <BoxShadow>[
    BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6)),
  ],
  'library': <BoxShadow>[
    BoxShadow(color: Color(0x73000000), blurRadius: 18, offset: Offset(0, 6)),
  ],
  'paper': <BoxShadow>[
    BoxShadow(color: Color(0x2E3C2814), blurRadius: 12, offset: Offset(0, 4)),
  ],
  'garden': <BoxShadow>[
    BoxShadow(color: Color(0x2E1E3223), blurRadius: 12, offset: Offset(0, 4)),
  ],
};

@immutable
class DeckTheme extends ThemeExtension<DeckTheme> {
  const DeckTheme({
    required this.id,
    required this.name,
    required this.dark,
    required this.displayFont,
    required this.bodyFont,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.line2,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.accentGlow,
    required this.glow,
    required this.scrim,
    required this.ok,
    required this.error,
    required this.back,
    required this.cardShadow,
  });

  final String id;
  final String name;
  final bool dark;
  final String displayFont;
  final String bodyFont;

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color line2;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color accentGlow;
  final Color glow;
  final Color scrim;
  final Color ok;
  final Color error;

  final CardBackSpec back;
  final List<BoxShadow> cardShadow;

  factory DeckTheme.fromJson(String id, Map<String, dynamic> j) {
    final c = j['colors'] as Map<String, dynamic>;
    final f = j['fonts'] as Map<String, dynamic>;
    Color col(String k) => parseToken(c[k] as String);
    return DeckTheme(
      id: id,
      name: j['name'] as String,
      dark: j['dark'] as bool,
      displayFont: f['display'] as String,
      bodyFont: f['body'] as String,
      bg: col('bg'),
      surface: col('surface'),
      surface2: col('surface2'),
      line: col('line'),
      line2: col('line2'),
      text: col('text'),
      muted: col('muted'),
      accent: col('accent'),
      accentInk: col('accentInk'),
      accentSoft: col('accentSoft'),
      accentGlow: col('accentGlow'),
      glow: col('glow'),
      scrim: col('scrim'),
      ok: col('ok'),
      error: col('error'),
      back: CardBackSpec.fromJson(j['back'] as Map<String, dynamic>),
      cardShadow: _deckShadows[id] ?? _deckShadows['graphite']!,
    );
  }

  /// Short "Unbounded · Onest" label used in the settings preview.
  String get fontLabel {
    const short = <String, String>{
      'Cormorant Garamond': 'Cormorant',
      'Old Standard TT': 'Old Standard',
    };
    return '${short[displayFont] ?? displayFont} · ${short[bodyFont] ?? bodyFont}';
  }

  TextStyle display({
    double? size,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      fontStyle(displayFont,
          fontSize: size,
          fontWeight: weight,
          color: color ?? text,
          height: height,
          letterSpacing: letterSpacing);

  TextStyle body({
    double? size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) =>
      fontStyle(bodyFont,
          fontSize: size,
          fontWeight: weight,
          color: color ?? text,
          height: height,
          letterSpacing: letterSpacing,
          decoration: decoration,
          decorationColor: color ?? text);

  @override
  DeckTheme copyWith() => this;

  @override
  DeckTheme lerp(ThemeExtension<DeckTheme>? other, double t) {
    if (other is! DeckTheme) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    // Fonts and card backs cannot be interpolated; they flip at the midpoint
    // while the palette cross-fades.
    final late = t < 0.5 ? this : other;
    return DeckTheme(
      id: late.id,
      name: late.name,
      dark: late.dark,
      displayFont: late.displayFont,
      bodyFont: late.bodyFont,
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      line: c(line, other.line),
      line2: c(line2, other.line2),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      accent: c(accent, other.accent),
      accentInk: c(accentInk, other.accentInk),
      accentSoft: c(accentSoft, other.accentSoft),
      accentGlow: c(accentGlow, other.accentGlow),
      glow: c(glow, other.glow),
      scrim: c(scrim, other.scrim),
      ok: c(ok, other.ok),
      error: c(error, other.error),
      back: late.back,
      cardShadow: late.cardShadow,
    );
  }
}

extension DeckThemeContext on BuildContext {
  /// The deck palette currently in force, already lerped by [AnimatedTheme].
  DeckTheme get deck => Theme.of(this).extension<DeckTheme>()!;
}

// ---------------------------------------------------------------------------
// Backgrounds
// ---------------------------------------------------------------------------

enum BackgroundKind { animated, image, color, file }

@immutable
class BackgroundDef {
  const BackgroundDef({
    required this.id,
    required this.name,
    required this.kind,
    this.file,
  });

  final String id;
  final String name;
  final BackgroundKind kind;
  final String? file;

  factory BackgroundDef.fromJson(String id, Map<String, dynamic> j) => BackgroundDef(
        id: id,
        name: j['name'] as String,
        kind: switch (j['type'] as String) {
          'animated' => BackgroundKind.animated,
          'image' => BackgroundKind.image,
          'file' => BackgroundKind.file,
          _ => BackgroundKind.color,
        },
        file: j['file'] as String?,
      );
}

// ---------------------------------------------------------------------------
// The whole token file
// ---------------------------------------------------------------------------

@immutable
class DesignTokens {
  const DesignTokens({
    required this.decks,
    required this.backgrounds,
    required this.autoCardColors,
    required this.layoutTiers,
  });

  final Map<String, DeckTheme> decks;
  final Map<String, BackgroundDef> backgrounds;

  /// 24 `(background, ink)` pairs; a book keeps its pair for life.
  final List<(Color, Color)> autoCardColors;
  final List<LayoutTier> layoutTiers;

  static const String assetPath = 'assets/design_tokens.json';

  static DesignTokens parse(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final decks = <String, DeckTheme>{};
    (j['decks'] as Map<String, dynamic>).forEach((id, v) {
      decks[id] = DeckTheme.fromJson(id, v as Map<String, dynamic>);
    });
    final backgrounds = <String, BackgroundDef>{};
    (j['backgrounds'] as Map<String, dynamic>).forEach((id, v) {
      backgrounds[id] = BackgroundDef.fromJson(id, v as Map<String, dynamic>);
    });
    final colors = (j['autoCardColors'] as List<dynamic>)
        .map((e) {
          final pair = e as List<dynamic>;
          return (parseToken(pair[0] as String), parseToken(pair[1] as String));
        })
        .toList(growable: false);
    final tiers = (j['layoutTiers'] as List<dynamic>)
        .map((e) => LayoutTier.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return DesignTokens(
      decks: decks,
      backgrounds: backgrounds,
      autoCardColors: colors,
      layoutTiers: tiers,
    );
  }

  static Future<DesignTokens> load() async =>
      parse(await rootBundle.loadString(assetPath));

  DeckTheme deck(String id) => decks[id] ?? decks['graphite']!;

  BackgroundDef background(String id) => backgrounds[id] ?? backgrounds['glow']!;

  /// Deck order as shown in settings.
  static const List<String> deckOrder = <String>[
    'graphite',
    'coven',
    'library',
    'paper',
    'garden',
  ];

  /// Background order as shown in settings.
  static const List<String> backgroundOrder = <String>[
    'glow',
    'autumn',
    'winter',
    'spring',
    'summer',
    'plain',
    'custom',
  ];
}

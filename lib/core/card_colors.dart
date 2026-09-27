import 'dart:ui';

import 'hash.dart';
import 'tokens.dart';

/// The `(face, ink)` pair a book always gets, from its title alone.
(Color, Color) autoCardColour(String title, DesignTokens tokens) {
  final palette = tokens.autoCardColors;
  if (palette.isEmpty) return (const Color(0xFF222222), const Color(0xFFEEEEEE));
  return palette[autoColorIndex(title, palette.length)];
}

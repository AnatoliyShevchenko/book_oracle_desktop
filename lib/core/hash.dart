import 'dart:convert';

/// 32-bit FNV-1a over the UTF-8 bytes of [s].
///
/// Stable across runs and platforms, so a book keeps the same card colour
/// forever.
int fnv1a(String s) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(s)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Index into `autoCardColors` for a book title.
int autoColorIndex(String title, int paletteLength) =>
    paletteLength == 0 ? 0 : fnv1a(title) % paletteLength;

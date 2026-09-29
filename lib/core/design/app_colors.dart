import 'dart:convert';
import 'dart:ui';

/// Colours of Спільно members (docs/DESIGN.md): coral, sage, sky,
/// lavender, sand, rose. Muted so each stays visible in both themes.
const List<int> memberColors = [
  0xFFE8927C,
  0xFF8DB596,
  0xFF7FA7D9,
  0xFFA99BD3,
  0xFFD9B26F,
  0xFFD98BA9,
];

/// A member's colour, the same on every device: FNV-1a of the user id,
/// modulo the palette. Collisions inside one Спільно are possible until
/// the backend assigns colours (stage 5).
int memberColorFor(String userId) =>
    memberColors[fnv1a32(userId) % memberColors.length];

/// 32-bit FNV-1a hash of [text]'s UTF-8 bytes.
int fnv1a32(String text) {
  var hash = 0x811C9DC5;
  for (final byte in utf8.encode(text)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

extension ArgbColor on int {
  /// This ARGB int as a Flutter [Color].
  Color get color => Color(this);
}

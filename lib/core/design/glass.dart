import 'package:flutter/painting.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';

/// Matte glass surfaces ("C" on the visual companion): a dense tint over a
/// light blur, no border, a soft shadow (docs/DESIGN.md).
abstract final class GlassStyle {
  /// White at 68%, over light skies (morning, day).
  static const Color lightTint = Color(0xADFFFFFF);

  /// `#161C38` at 72%, over dark skies.
  static const Color darkTint = Color(0xB8161C38);

  static const double blurSigma = 12;

  static const BoxShadow shadow = BoxShadow(
    color: Color(0x29000000),
    offset: Offset(0, 6),
    blurRadius: 18,
  );

  /// Text and icons on glass over light skies.
  static const Color onLight = Color(0xFF18293A);

  /// Text and icons on glass over dark skies.
  static const Color onDark = Color(0xFFFFFFFF);

  /// The glass tint for a sky's [tone].
  static Color tintFor(SurfaceTone tone) => switch (tone) {
    SurfaceTone.light => lightTint,
    SurfaceTone.dark => darkTint,
  };

  /// The text colour on glass for a sky's [tone].
  static Color onGlass(SurfaceTone tone) => switch (tone) {
    SurfaceTone.light => onLight,
    SurfaceTone.dark => onDark,
  };
}

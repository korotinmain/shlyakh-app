import 'package:flutter/painting.dart';

/// Matte glass surfaces ("C" on the visual companion): a dense tint over a
/// light blur, no border, a soft shadow (docs/DESIGN.md). The tint and the
/// text colour come from the theme's `AppPalette` (`glass`, `onGlass`).
abstract final class GlassStyle {
  static const double blurSigma = 12;

  static const BoxShadow shadow = BoxShadow(
    color: Color(0x29000000),
    offset: Offset(0, 6),
    blurRadius: 18,
  );

  /// Opacity of the text colour for tracks (ring, progress bar) on glass.
  static const double trackOpacity = 0.18;

  /// Opacity of the text colour for secondary text on glass (the date).
  static const double secondaryOpacity = 0.72;

  /// Opacity of the text colour for secondary marks (other days' bars).
  static const double mutedOpacity = 0.28;
}

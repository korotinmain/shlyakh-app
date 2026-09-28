import 'package:flutter/material.dart';

/// What is drawn over the sky gradient.
enum Backdrop {
  /// A soft violet nebula (dark theme).
  nebula,

  /// A faint ink grid of a star chart (light theme).
  chart,
}

/// Colours of one theme (docs/DESIGN.md, "Themes"). `sky` is the gradient
/// top → bottom (at 0%, 55%, 100%), `hills` far → near; `onSky` is text
/// drawn directly on the sky, `onGlass` text on glass surfaces.
final class AppPalette extends ThemeExtension<AppPalette> {
  const new({
    required this.brightness,
    required this.sky,
    required this.hills,
    required this.accent,
    required this.onAccent,
    required this.onSky,
    required this.onSkyMuted,
    required this.glass,
    required this.onGlass,
    required this.grainOpacity,
    required this.backdrop,
  });

  /// The night sky with a gold accent.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    sky: [Color(0xFF070B1E), Color(0xFF161E46), Color(0xFF2C3670)],
    hills: [Color(0xFF1B2250), Color(0xFF141A40), Color(0xFF0E1333)],
    accent: Color(0xFFF3D9A0),
    onAccent: Color(0xFF1A2440),
    onSky: Color(0xFFF4F1EA),
    onSkyMuted: Color(0xFFC8D2F0),
    glass: Color(0xB8121836),
    onGlass: Color(0xFFF4F1EA),
    grainOpacity: 0.12,
    backdrop: Backdrop.nebula,
  );

  /// An ink star chart on a pale sky.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    sky: [Color(0xFFDCE6F4), Color(0xFFEEF1F6), Color(0xFFF6F1E8)],
    hills: [Color(0xFFE6ECF2), Color(0xFFDCE4EC), Color(0xFFC9D5DF)],
    accent: Color(0xFF3D4F9A),
    onAccent: Color(0xFFFFFFFF),
    onSky: Color(0xFF1A2440),
    onSkyMuted: Color(0xFF3D4F9A),
    glass: Color(0xADFFFFFF),
    onGlass: Color(0xFF1A2440),
    grainOpacity: 0.06,
    backdrop: Backdrop.chart,
  );

  final Brightness brightness;
  final List<Color> sky;
  final List<Color> hills;
  final Color accent;
  final Color onAccent;
  final Color onSky;
  final Color onSkyMuted;
  final Color glass;
  final Color onGlass;
  final double grainOpacity;
  final Backdrop backdrop;

  @override
  AppPalette copyWith({
    Brightness? brightness,
    List<Color>? sky,
    List<Color>? hills,
    Color? accent,
    Color? onAccent,
    Color? onSky,
    Color? onSkyMuted,
    Color? glass,
    Color? onGlass,
    double? grainOpacity,
    Backdrop? backdrop,
  }) => AppPalette(
    brightness: brightness ?? this.brightness,
    sky: sky ?? this.sky,
    hills: hills ?? this.hills,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    onSky: onSky ?? this.onSky,
    onSkyMuted: onSkyMuted ?? this.onSkyMuted,
    glass: glass ?? this.glass,
    onGlass: onGlass ?? this.onGlass,
    grainOpacity: grainOpacity ?? this.grainOpacity,
    backdrop: backdrop ?? this.backdrop,
  );

  /// Colours blend; brightness and backdrop switch halfway.
  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> mixAll(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) mix(a[i], b[i]),
    ];
    final late = t >= 0.5;
    return AppPalette(
      brightness: late ? other.brightness : brightness,
      sky: mixAll(sky, other.sky),
      hills: mixAll(hills, other.hills),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      onSky: mix(onSky, other.onSky),
      onSkyMuted: mix(onSkyMuted, other.onSkyMuted),
      glass: mix(glass, other.glass),
      onGlass: mix(onGlass, other.onGlass),
      grainOpacity: grainOpacity + (other.grainOpacity - grainOpacity) * t,
      backdrop: late ? other.backdrop : backdrop,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette of the current theme.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

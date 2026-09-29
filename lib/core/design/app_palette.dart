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
    required this.backdropTint,
    required this.star,
    required this.starGlow,
    required this.starLine,
    required this.starAhead,
    required this.aheadLine,
    required this.marker,
    required this.done,
    required this.doneLine,
    required this.doneGlow,
    required this.seal,
    required this.onSeal,
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
    backdropTint: Color(0x526E5AA8),
    star: Color(0xFFFFFFFF),
    starGlow: Color(0x38F3E3BE),
    starLine: Color(0xCCF3E3BE),
    starAhead: Color(0x73C8D2F0),
    aheadLine: Color(0x4DC8D2F0),
    marker: Color(0xFFFFE9B8),
    done: Color(0xFFF3D9A0),
    doneLine: Color(0xE6F7E2B4),
    doneGlow: Color(0x4DF3D9A0),
    seal: Color(0xFFEBC57F),
    onSeal: Color(0xFF2A1D08),
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
    backdropTint: Color(0x0D3D4F9A),
    star: Color(0xFF3D4F9A),
    starGlow: Color(0x003D4F9A),
    starLine: Color(0xB33D4F9A),
    starAhead: Color(0x613D4F9A),
    aheadLine: Color(0x403D4F9A),
    marker: Color(0xFF3D4F9A),
    done: Color(0xFF8A5E0B),
    doneLine: Color(0xCC8A5E0B),
    doneGlow: Color(0x008A5E0B),
    seal: Color(0xFF8A5E0B),
    onSeal: Color(0xFFFFFFFF),
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

  /// Colour of the backdrop: the nebula's centre, or the chart grid's ink.
  final Color backdropTint;

  /// A lit star of the figure.
  final Color star;

  /// The soft glow around a lit star (none in the light theme).
  final Color starGlow;

  /// A figure line behind the current star.
  final Color starLine;

  /// The ring of a star ahead.
  final Color starAhead;

  /// A dashed figure line ahead.
  final Color aheadLine;

  /// The current star's marker.
  final Color marker;

  /// A completed constellation: its stars and its "Complete" label.
  final Color done;

  /// A completed constellation's lines.
  final Color doneLine;

  /// The glow around its stars (none in the light theme).
  final Color doneGlow;

  /// The "Completed on a date" seal.
  final Color seal;

  /// Text on the seal.
  final Color onSeal;

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
    Color? backdropTint,
    Color? star,
    Color? starGlow,
    Color? starLine,
    Color? starAhead,
    Color? aheadLine,
    Color? marker,
    Color? done,
    Color? doneLine,
    Color? doneGlow,
    Color? seal,
    Color? onSeal,
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
    backdropTint: backdropTint ?? this.backdropTint,
    star: star ?? this.star,
    starGlow: starGlow ?? this.starGlow,
    starLine: starLine ?? this.starLine,
    starAhead: starAhead ?? this.starAhead,
    aheadLine: aheadLine ?? this.aheadLine,
    marker: marker ?? this.marker,
    done: done ?? this.done,
    doneLine: doneLine ?? this.doneLine,
    doneGlow: doneGlow ?? this.doneGlow,
    seal: seal ?? this.seal,
    onSeal: onSeal ?? this.onSeal,
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
      backdropTint: mix(backdropTint, other.backdropTint),
      star: mix(star, other.star),
      starGlow: mix(starGlow, other.starGlow),
      starLine: mix(starLine, other.starLine),
      starAhead: mix(starAhead, other.starAhead),
      aheadLine: mix(aheadLine, other.aheadLine),
      marker: mix(marker, other.marker),
      done: mix(done, other.done),
      doneLine: mix(doneLine, other.doneLine),
      doneGlow: mix(doneGlow, other.doneGlow),
      seal: mix(seal, other.seal),
      onSeal: mix(onSeal, other.onSeal),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette of the current theme.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

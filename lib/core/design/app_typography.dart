import 'package:flutter/material.dart';

const _family = 'Geologica';

/// Geologica is bundled as one variable font. The engine sets its `wght`
/// axis from `fontWeight` (verified on the simulator), so styles set only
/// `fontWeight`: a pinned axis would compete with later
/// `copyWith(fontWeight: ...)` calls.
TextStyle _style(double size, int weight, {bool tight = false}) => TextStyle(
  fontFamily: _family,
  fontSize: size,
  fontWeight: FontWeight.values[weight ~/ 100 - 1],
  letterSpacing: tight ? -0.02 * size : null,
);

/// Type scale (docs/DESIGN.md): size / weight.
abstract final class AppTypography {
  static final TextStyle hero = _style(44, 700, tight: true);
  static final TextStyle display = _style(30, 700, tight: true);
  static final TextStyle title = _style(22, 700, tight: true);
  static final TextStyle headline = _style(17, 500);
  static final TextStyle body = _style(15, 400);
  static final TextStyle footnote = _style(13, 400);
  static final TextStyle caption = _style(11, 300);
}

/// [style] with tabular figures, so counting numbers do not jump.
TextStyle tabular(TextStyle style) => style.copyWith(
  fontFeatures: [...?style.fontFeatures, const FontFeature.tabularFigures()],
);

/// The scale mapped onto Material text roles.
TextTheme appTextTheme() => TextTheme(
  displayLarge: AppTypography.hero,
  displayMedium: AppTypography.display,
  titleLarge: AppTypography.title,
  titleMedium: AppTypography.headline,
  bodyLarge: AppTypography.body,
  bodyMedium: AppTypography.body,
  bodySmall: AppTypography.footnote,
  labelLarge: AppTypography.headline,
  labelMedium: AppTypography.footnote,
  labelSmall: AppTypography.caption,
);

import 'package:flutter/material.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_typography.dart';

/// App theme for [brightness] from the design tokens (docs/DESIGN.md);
/// screens read the colours through `context.palette`.
ThemeData buildAppTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
  return ThemeData(
    brightness: brightness,
    fontFamily: 'Geologica',
    textTheme: appTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
    ),
    extensions: [palette],
  );
}

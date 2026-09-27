import 'package:flutter/material.dart';
import 'package:shlyakh/core/design/app_colors.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';

/// App theme from the design tokens (docs/DESIGN.md). Sky-aware screens
/// take colours from `skyAt`; this scheme covers everything else.
ThemeData buildAppTheme() => ThemeData(
  fontFamily: 'Geologica',
  textTheme: appTextTheme(),
  colorScheme: ColorScheme.fromSeed(
    seedColor: skyKeyframes[SkyKeyframe.day]!.accent.color,
  ),
);

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';

/// The status bar style over [palette]'s sky. The status bar is drawn
/// directly on the sky, so its icons follow `onSky`: light icons where
/// text on the sky is light, dark icons where it is dark.
SystemUiOverlayStyle statusBarStyleFor(SkyPalette palette) =>
    switch (ThemeData.estimateBrightnessForColor(Color(palette.onSky))) {
      Brightness.light => SystemUiOverlayStyle.light,
      Brightness.dark => SystemUiOverlayStyle.dark,
    };

import 'package:flutter/services.dart';

/// The status bar style for a theme of [brightness]: it is drawn directly
/// on the sky, so a dark theme gets light icons and a light theme dark ones.
SystemUiOverlayStyle statusBarStyleFor(Brightness brightness) =>
    switch (brightness) {
      Brightness.dark => SystemUiOverlayStyle.light,
      Brightness.light => SystemUiOverlayStyle.dark,
    };

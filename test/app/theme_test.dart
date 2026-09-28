import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/theme.dart';
import 'package:shlyakh/core/design/app_palette.dart';

void main() {
  for (final (brightness, palette) in [
    (Brightness.dark, AppPalette.dark),
    (Brightness.light, AppPalette.light),
  ]) {
    test('the ${brightness.name} theme carries its palette', () {
      final theme = buildAppTheme(brightness);

      expect(theme.brightness, brightness);
      expect(theme.extension<AppPalette>(), same(palette));
      expect(theme.textTheme.bodyMedium!.fontFamily, 'Geologica');
    });
  }
}

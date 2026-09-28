import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/launch_screen.dart';
import 'package:shlyakh/app/theme.dart';
import 'package:shlyakh/core/design/app_palette.dart';

void main() {
  for (final (brightness, palette) in [
    (Brightness.dark, AppPalette.dark),
    (Brightness.light, AppPalette.light),
  ]) {
    testWidgets('the launch screen draws the ${brightness.name} sky', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(brightness),
          home: const LaunchScreen(),
        ),
      );

      final gradients = [
        for (final box in tester.widgetList<DecoratedBox>(
          find.byType(DecoratedBox),
        ))
          if (box.decoration case BoxDecoration(:final LinearGradient gradient))
            gradient.colors,
      ];
      expect(gradients, contains(palette.sky));
    });
  }
}

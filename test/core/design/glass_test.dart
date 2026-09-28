import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/theme.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/glass_panel.dart';

void main() {
  for (final (brightness, palette) in [
    (Brightness.dark, AppPalette.dark),
    (Brightness.light, AppPalette.light),
  ]) {
    testWidgets('glass in the ${brightness.name} theme uses its palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(brightness),
          home: const GlassPanel(
            shape: RoundedRectangleBorder(),
            child: Text('on glass'),
          ),
        ),
      );

      final tint = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(GlassPanel),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(tint.color, palette.glass);
      final text = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('on glass'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, palette.onGlass);
    });
  }
}

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/app_typography.dart';

void main() {
  group('AppTypography scale', () {
    // (name, style, size, weight) from docs/DESIGN.md.
    final scale = <(String, TextStyle, double, int)>[
      ('hero', AppTypography.hero, 44, 700),
      ('display', AppTypography.display, 30, 700),
      ('title', AppTypography.title, 22, 700),
      ('headline', AppTypography.headline, 17, 500),
      ('body', AppTypography.body, 15, 400),
      ('footnote', AppTypography.footnote, 13, 400),
      ('caption', AppTypography.caption, 11, 300),
    ];

    for (final (name, style, size, weight) in scale) {
      test('$name is Geologica $size/$weight', () {
        expect(style.fontFamily, 'Geologica');
        expect(style.fontSize, size);
        expect(style.fontWeight, FontWeight.values[weight ~/ 100 - 1]);
        // fontWeight alone drives the variable font's wght axis; a pinned
        // axis would compete with later copyWith(fontWeight: ...) calls.
        expect(style.fontVariations, isNull);
      });
    }

    test('tightens large styles by 2%', () {
      expect(AppTypography.hero.letterSpacing, closeTo(-0.88, 1e-9));
      expect(AppTypography.title.letterSpacing, closeTo(-0.44, 1e-9));
      expect(AppTypography.body.letterSpacing, isNull);
    });
  });

  test('tabular adds tabular figures', () {
    expect(
      tabular(AppTypography.hero).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('appTextTheme maps the scale onto Material roles', () {
    final theme = appTextTheme();

    expect(theme.displayLarge, AppTypography.hero);
    expect(theme.bodyMedium, AppTypography.body);
    expect(theme.labelSmall, AppTypography.caption);
  });
}

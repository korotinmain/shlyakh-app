import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/app_palette.dart';

import '../../helpers/contrast.dart';

const AppPalette _dark = AppPalette.dark;
const AppPalette _light = AppPalette.light;

void main() {
  group('the dark palette', () {
    test('is a night sky with gold', () {
      expect(_dark.brightness, Brightness.dark);
      expect(_dark.sky, const [
        Color(0xFF070B1E),
        Color(0xFF161E46),
        Color(0xFF2C3670),
      ]);
      expect(_dark.hills, const [
        Color(0xFF1B2250),
        Color(0xFF141A40),
        Color(0xFF0E1333),
      ]);
      expect(_dark.accent, const Color(0xFFF3D9A0));
      expect(_dark.onAccent, const Color(0xFF1A2440));
      expect(_dark.onSky, const Color(0xFFF4F1EA));
      expect(_dark.onSkyMuted, const Color(0xFFC8D2F0));
      expect(_dark.glass, const Color(0xB8121836));
      expect(_dark.onGlass, const Color(0xFFF4F1EA));
      expect(_dark.grainOpacity, 0.12);
      expect(_dark.backdrop, Backdrop.nebula);
      expect(_dark.backdropTint, const Color(0x526E5AA8));
      expect(_dark.star, const Color(0xFFFFFFFF));
      expect(_dark.starGlow, const Color(0x38F3E3BE));
      expect(_dark.starLine, const Color(0xCCF3E3BE));
      expect(_dark.starAhead, const Color(0x73C8D2F0));
      expect(_dark.aheadLine, const Color(0x4DC8D2F0));
      expect(_dark.marker, const Color(0xFFFFE9B8));
      expect(_dark.done, const Color(0xFFF3D9A0));
      expect(_dark.doneLine, const Color(0xE6F7E2B4));
      expect(_dark.doneGlow, const Color(0x4DF3D9A0));
      expect(_dark.seal, const Color(0xFFEBC57F));
      expect(_dark.onSeal, const Color(0xFF2A1D08));
    });
  });

  group('the light palette', () {
    test('is an ink star chart on a pale sky', () {
      expect(_light.brightness, Brightness.light);
      expect(_light.sky, const [
        Color(0xFFDCE6F4),
        Color(0xFFEEF1F6),
        Color(0xFFF6F1E8),
      ]);
      expect(_light.hills, const [
        Color(0xFFE6ECF2),
        Color(0xFFDCE4EC),
        Color(0xFFC9D5DF),
      ]);
      expect(_light.accent, const Color(0xFF3D4F9A));
      expect(_light.onAccent, const Color(0xFFFFFFFF));
      expect(_light.onSky, const Color(0xFF1A2440));
      expect(_light.onSkyMuted, const Color(0xFF3D4F9A));
      expect(_light.glass, const Color(0xADFFFFFF));
      expect(_light.onGlass, const Color(0xFF1A2440));
      expect(_light.grainOpacity, 0.06);
      expect(_light.backdrop, Backdrop.chart);
      expect(_light.backdropTint, const Color(0x0D3D4F9A));
      expect(_light.star, const Color(0xFF3D4F9A));
      expect(_light.starGlow, const Color(0x003D4F9A));
      expect(_light.starLine, const Color(0xB33D4F9A));
      expect(_light.starAhead, const Color(0x613D4F9A));
      expect(_light.aheadLine, const Color(0x403D4F9A));
      expect(_light.marker, const Color(0xFF3D4F9A));
      expect(_light.done, const Color(0xFF8A5E0B));
      expect(_light.doneLine, const Color(0xCC8A5E0B));
      expect(_light.doneGlow, const Color(0x008A5E0B));
      expect(_light.seal, const Color(0xFF8A5E0B));
      expect(_light.onSeal, const Color(0xFFFFFFFF));
    });
  });

  for (final palette in [_dark, _light]) {
    group('${palette.brightness.name} contrast (WCAG AA)', () {
      test('text on every sky colour', () {
        for (final sky in palette.sky) {
          expect(contrastRatio(palette.onSky, sky), greaterThanOrEqualTo(4.5));
        }
      });

      test('muted text on every sky colour', () {
        for (final sky in palette.sky) {
          expect(
            contrastRatio(palette.onSkyMuted, sky),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test('text on the accent', () {
        expect(
          contrastRatio(palette.onAccent, palette.accent),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('text on glass over every sky colour', () {
        for (final sky in palette.sky) {
          expect(
            contrastRatio(palette.onGlass, over(palette.glass, sky)),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test('stars and the marker on every sky colour', () {
        for (final sky in palette.sky) {
          expect(contrastRatio(palette.star, sky), greaterThanOrEqualTo(3));
          expect(contrastRatio(palette.marker, sky), greaterThanOrEqualTo(3));
        }
      });

      test('gold on every sky colour, and text on the seal', () {
        for (final sky in palette.sky) {
          expect(contrastRatio(palette.done, sky), greaterThanOrEqualTo(3));
        }
        expect(
          contrastRatio(palette.onSeal, palette.seal),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('the accent on glass', () {
        expect(
          contrastRatio(palette.accent, over(palette.glass, palette.sky.first)),
          greaterThanOrEqualTo(3),
        );
      });
    });
  }

  group('lerp', () {
    test('returns the ends at 0 and 1', () {
      expect(_dark.lerp(_light, 0).accent, _dark.accent);
      expect(_dark.lerp(_light, 1).accent, _light.accent);
      expect(_dark.lerp(_light, 1).sky, _light.sky);
      expect(_dark.lerp(_light, 1).brightness, Brightness.light);
    });

    test('blends colours and switches the rest halfway', () {
      final half = _dark.lerp(_light, 0.5);

      expect(half.sky, hasLength(3));
      expect(half.hills, hasLength(3));
      expect(half.accent, Color.lerp(_dark.accent, _light.accent, 0.5));
      expect(
        half.backdropTint,
        Color.lerp(_dark.backdropTint, _light.backdropTint, 0.5),
      );
      expect(half.grainOpacity, closeTo(0.09, 1e-9));
      expect(half.star, Color.lerp(_dark.star, _light.star, 0.5));
      expect(half.starGlow, Color.lerp(_dark.starGlow, _light.starGlow, 0.5));
      expect(half.starLine, Color.lerp(_dark.starLine, _light.starLine, 0.5));
      expect(
        half.starAhead,
        Color.lerp(_dark.starAhead, _light.starAhead, 0.5),
      );
      expect(
        half.aheadLine,
        Color.lerp(_dark.aheadLine, _light.aheadLine, 0.5),
      );
      expect(half.marker, Color.lerp(_dark.marker, _light.marker, 0.5));
      expect(half.done, Color.lerp(_dark.done, _light.done, 0.5));
      expect(half.doneLine, Color.lerp(_dark.doneLine, _light.doneLine, 0.5));
      expect(half.doneGlow, Color.lerp(_dark.doneGlow, _light.doneGlow, 0.5));
      expect(half.seal, Color.lerp(_dark.seal, _light.seal, 0.5));
      expect(half.onSeal, Color.lerp(_dark.onSeal, _light.onSeal, 0.5));
      expect(half.brightness, Brightness.light);
      expect(half.backdrop, Backdrop.chart);
      expect(_dark.lerp(_light, 0.49).backdrop, Backdrop.nebula);
    });

    test('keeps itself when the other is not a palette', () {
      expect(_dark.lerp(null, 0.5).accent, _dark.accent);
    });
  });

  test('copyWith changes only what is given', () {
    final copy = _dark.copyWith(accent: const Color(0xFF000000));

    expect(copy.accent, const Color(0xFF000000));
    expect(copy.sky, _dark.sky);
    expect(copy.onGlass, _dark.onGlass);
    expect(copy.star, _dark.star);
    expect(copy.done, _dark.done);
    expect(
      _dark.copyWith(seal: const Color(0xFF000000)).seal,
      const Color(0xFF000000),
    );
    expect(_dark.copyWith(star: const Color(0xFF000000)).marker, _dark.marker);
    expect(
      _dark.copyWith(star: const Color(0xFF000000)).star,
      const Color(0xFF000000),
    );
    expect(copy.brightness, Brightness.dark);
  });
}

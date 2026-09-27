import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/sky/oklab.dart';

// Every colour of the sky keyframe table in the design foundation spec.
const _paletteColours = <int>[
  0xFF2E345E, 0xFF5D5F8E, 0xFF9A8FAE, 0xFF7A7597, 0xFF565673, 0xFF34364F, //
  0xFF545784, 0xFFCF98A2, 0xFFF2C7A8, 0xFFC29AAB, 0xFF8B7790, 0xFF4F4D63,
  0xFF7EA8CF, 0xFFBCD6E6, 0xFFF2EBDD, 0xFFB7D0C6, 0xFF8CB392, 0xFF5B8C64,
  0xFF6C9DCC, 0xFFA2C8E5, 0xFFE0EEF1, 0xFFAECFC2, 0xFF7EAF85, 0xFF4D8259,
  0xFFD38A6C, 0xFFEEB385, 0xFFF7DCB0, 0xFFDCA689, 0xFFA8786A, 0xFF634448,
  0xFF2C3868, 0xFF546A9C, 0xFFA2B0CF, 0xFF5C6A92, 0xFF3C4870, 0xFF252D4A,
  0xFF121831, 0xFF222B54, 0xFF364378, 0xFF323C6C, 0xFF222A4D, 0xFF141A35,
  0xFF000000, 0xFFFFFFFF,
];

int _channel(int argb, int shift) => (argb >> shift) & 0xFF;

void _expectClose(int actual, int expected, {int tolerance = 1}) {
  for (final shift in [24, 16, 8, 0]) {
    expect(
      (_channel(actual, shift) - _channel(expected, shift)).abs(),
      lessThanOrEqualTo(tolerance),
      reason:
          '${actual.toRadixString(16)} vs ${expected.toRadixString(16)} '
          'at bit $shift',
    );
  }
}

void main() {
  group('toOklab / fromOklab', () {
    for (final colour in _paletteColours) {
      test('round-trips 0x${colour.toRadixString(16)}', () {
        _expectClose(fromOklab(toOklab(colour)), colour);
      });
    }
  });

  group('lerpArgb', () {
    test('returns the endpoints at 0 and 1', () {
      expect(lerpArgb(0xFF6C9DCC, 0xFFD38A6C, 0), 0xFF6C9DCC);
      expect(lerpArgb(0xFF6C9DCC, 0xFFD38A6C, 1), 0xFFD38A6C);
    });

    test('clamps t outside 0-1', () {
      expect(lerpArgb(0xFF6C9DCC, 0xFFD38A6C, -1), 0xFF6C9DCC);
      expect(lerpArgb(0xFF6C9DCC, 0xFFD38A6C, 2), 0xFFD38A6C);
    });

    test('interpolates in Oklab, not sRGB', () {
      // Perceptual midpoint of black and white is darker than sRGB 0x80.
      _expectClose(lerpArgb(0xFF000000, 0xFFFFFFFF, .5), 0xFF636363);
    });

    test('a warm-to-cool blend keeps its colour instead of going grey', () {
      final mid = toOklab(lerpArgb(0xFFF7DCB0, 0xFFA2B0CF, .5));

      expect(math.sqrt(mid.a * mid.a + mid.b * mid.b), greaterThan(0.02));
    });

    test('changes lightness evenly', () {
      final from = toOklab(0xFFF7DCB0);
      final to = toOklab(0xFFA2B0CF);
      final mid = toOklab(lerpArgb(0xFFF7DCB0, 0xFFA2B0CF, .5));

      expect(mid.l, closeTo((from.l + to.l) / 2, 0.01));
    });

    test('interpolates alpha linearly', () {
      expect(_channel(lerpArgb(0x00FFFFFF, 0xFFFFFFFF, .5), 24), 0x80);
    });
  });
}

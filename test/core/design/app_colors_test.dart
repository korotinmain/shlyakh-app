import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/app_colors.dart';

void main() {
  group('fnv1a32', () {
    // Reference values of the FNV-1a 32-bit definition.
    test('of an empty string is the offset basis', () {
      expect(fnv1a32(''), 0x811C9DC5);
    });

    test('of "a"', () => expect(fnv1a32('a'), 0xE40C292C));
  });

  group('memberColorFor', () {
    test('is stable for a user id', () {
      expect(memberColorFor('user-a'), memberColorFor('user-a'));
      // FNV-1a('user-a') % 6 == 0, computed independently.
      expect(memberColorFor('user-a'), memberColors[0]);
    });

    test('spreads users over all six colours', () {
      final used = {for (var i = 0; i < 60; i++) memberColorFor('user-$i')};

      expect(used, memberColors.toSet());
    });
  });

  test('ARGB ints convert to Flutter colours', () {
    expect(0xFF6C9DCC.color, const Color(0xFF6C9DCC));
  });
}

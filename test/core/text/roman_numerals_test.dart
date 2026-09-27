import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/text/roman_numerals.dart';

void main() {
  group('toRoman', () {
    final cases = <(int, String)>[
      (1, 'I'),
      (2, 'II'),
      (4, 'IV'),
      (9, 'IX'),
      (14, 'XIV'),
      (40, 'XL'),
      (76, 'LXXVI'),
      (90, 'XC'),
      (400, 'CD'),
      (1994, 'MCMXCIV'),
      (3999, 'MMMCMXCIX'),
    ];
    for (final (value, roman) in cases) {
      test('writes $value as $roman', () => expect(toRoman(value), roman));
    }

    test('rejects 0', () => expect(() => toRoman(0), throwsArgumentError));
    test('rejects values above 3999', () {
      expect(() => toRoman(4000), throwsArgumentError);
    });
  });
}

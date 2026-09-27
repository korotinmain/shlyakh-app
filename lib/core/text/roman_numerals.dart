const _numerals = <(int, String)>[
  (1000, 'M'),
  (900, 'CM'),
  (500, 'D'),
  (400, 'CD'),
  (100, 'C'),
  (90, 'XC'),
  (50, 'L'),
  (40, 'XL'),
  (10, 'X'),
  (9, 'IX'),
  (5, 'V'),
  (4, 'IV'),
  (1, 'I'),
];

/// Writes [value] (1–3999) in Roman numerals, e.g. for title degrees.
///
/// Throws [ArgumentError] outside 1–3999, the range standard numerals cover.
String toRoman(int value) {
  if (value < 1 || value > 3999) {
    throw ArgumentError.value(value, 'value', 'must be in 1–3999');
  }
  final buffer = StringBuffer();
  var rest = value;
  for (final (amount, numeral) in _numerals) {
    while (rest >= amount) {
      buffer.write(numeral);
      rest -= amount;
    }
  }
  return buffer.toString();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/sky/solar.dart';

// Reference: sunrise-sunset.org API for lat 50.45, lng 30.52 (Kyiv), UTC.
final _reference = <(int, int, int, DateTime, DateTime, DateTime)>[
  (
    2026,
    3,
    20,
    DateTime.utc(2026, 3, 20, 3, 58, 50),
    DateTime.utc(2026, 3, 20, 10, 5, 24),
    DateTime.utc(2026, 3, 20, 16, 11, 57),
  ),
  (
    2026,
    6,
    21,
    DateTime.utc(2026, 6, 21, 1, 44, 9),
    DateTime.utc(2026, 6, 21, 9, 59, 43),
    DateTime.utc(2026, 6, 21, 18, 15, 18),
  ),
  (
    2026,
    9,
    22,
    DateTime.utc(2026, 9, 22, 3, 42, 38),
    DateTime.utc(2026, 9, 22, 9, 50, 39),
    DateTime.utc(2026, 9, 22, 15, 58, 40),
  ),
  (
    2026,
    12,
    21,
    DateTime.utc(2026, 12, 21, 5, 53, 48),
    DateTime.utc(2026, 12, 21, 9, 55, 56),
    DateTime.utc(2026, 12, 21, 13, 58, 4),
  ),
];

void _within3Minutes(DateTime actual, DateTime expected) {
  expect(
    actual.difference(expected).inSeconds.abs(),
    lessThanOrEqualTo(180),
    reason: '$actual vs $expected',
  );
}

void main() {
  group('sunTimesUtc in Kyiv', () {
    for (final (year, month, day, sunrise, noon, sunset) in _reference) {
      test('matches the reference on $year-$month-$day', () {
        final times = sunTimesUtc(
          year: year,
          month: month,
          day: day,
          latitude: kyivLatitude,
          longitude: kyivLongitude,
        )!;

        expect(times.sunrise.isUtc, isTrue);
        _within3Minutes(times.sunrise, sunrise);
        _within3Minutes(times.solarNoon, noon);
        _within3Minutes(times.sunset, sunset);
      });
    }
  });

  group('polar latitudes', () {
    test('return null for the polar day', () {
      expect(
        sunTimesUtc(year: 2026, month: 6, day: 21, latitude: 80, longitude: 0),
        isNull,
      );
    });

    test('return null for the polar night', () {
      expect(
        sunTimesUtc(year: 2026, month: 12, day: 21, latitude: 80, longitude: 0),
        isNull,
      );
    });
  });
}

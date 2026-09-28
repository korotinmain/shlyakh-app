import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/eta.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

final _today = LocalDate.parse('2026-10-20');

DailySteps _day(int daysAgo, int steps) => (
  userId: 'me',
  localDate: _today.addDays(-daysAgo),
  timezone: 'Europe/Kyiv',
  steps: steps,
);

/// [count] days of [steps] each, ending yesterday.
List<DailySteps> _history(int count, int steps) => [
  for (var ago = count; ago >= 1; ago--) _day(ago, steps),
];

int? _eta(List<DailySteps> days, int xpLeft) =>
    daysToNextStar(days: days, today: _today, xpLeft: xpLeft);

void main() {
  group('daysToNextStar', () {
    test('is unknown without history', () {
      expect(_eta(const [], 25000), isNull);
    });

    test('is unknown with 6 days of history', () {
      expect(_eta(_history(6, 7000), 25000), isNull);
    });

    test('rounds up the days at the pace of 7 days', () {
      expect(_eta(_history(7, 7000), 25000), 4);
    });

    test('uses only the last 14 days', () {
      final days = [
        for (var ago = 20; ago >= 15; ago--) _day(ago, 30000),
        ..._history(14, 5000),
      ];

      expect(_eta(days, 10000), 2);
    });

    test("ignores today's partial day", () {
      final days = [..._history(7, 7000), _day(0, 30000)];

      expect(_eta(days, 25000), 4);
    });

    test('counts a day without a record as 0 XP', () {
      final days = [
        for (final ago in [10, 8, 6, 4, 2]) _day(ago, 10000),
      ];

      expect(_eta(days, 12000), 3);
    });

    test('is unknown when the recent pace is zero', () {
      expect(_eta(_history(14, 0), 25000), isNull);
    });

    test('is 0 when no XP is left', () {
      expect(_eta(_history(7, 7000), 0), 0);
    });

    test('scores days above 10 000 steps at half rate', () {
      // 14 000 steps = 12 000 XP a day.
      expect(_eta(_history(7, 14000), 24000), 2);
    });
  });
}

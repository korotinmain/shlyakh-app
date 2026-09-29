import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/completion_dates.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

import '../../../helpers/small_route.dart';

DailySteps _day(String iso, int steps) => (
  userId: 'me',
  localDate: LocalDate.parse(iso),
  timezone: 'Europe/Kyiv',
  steps: steps,
);

LocalDate _d(String iso) => LocalDate.parse(iso);

void main() {
  group('completionDates', () {
    final route = smallRoute();

    test('dates each constellation by the day its XP was reached', () {
      // A needs 9 000 XP, B 15 000.
      final dates = completionDates([
        _day('2026-09-01', 10000),
        _day('2026-09-02', 10000),
      ], route);

      expect(dates, {0: _d('2026-09-01'), 1: _d('2026-09-02')});
    });

    test(
      'gives two constellations the same day when one day finishes both',
      () {
        final dates = completionDates([_day('2026-09-01', 30000)], route);

        expect(dates, {0: _d('2026-09-01'), 1: _d('2026-09-01')});
      },
    );

    test('sorts the days first', () {
      final dates = completionDates([
        _day('2026-09-02', 10000),
        _day('2026-09-01', 10000),
      ], route);

      expect(dates, {0: _d('2026-09-01'), 1: _d('2026-09-02')});
    });

    test('follows the data when a day loses steps', () {
      final dates = completionDates([
        _day('2026-09-01', 5000),
        _day('2026-09-02', 9000),
      ], route);

      expect(dates, {0: _d('2026-09-02')});
    });

    test('is empty without days', () {
      expect(completionDates(const [], route), isEmpty);
    });
  });
}

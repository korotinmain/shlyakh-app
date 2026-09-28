import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/sync_rules.dart';

JourneyStart _start(DateTime startedAt) =>
    (userId: 'local', startedAt: startedAt, timezone: 'Europe/Kyiv');

DailySteps _day(String iso, int steps, {String timezone = 'Europe/Kyiv'}) => (
  userId: 'local',
  localDate: LocalDate.parse(iso),
  timezone: timezone,
  steps: steps,
);

void main() {
  final now = DateTime(2026, 9, 28, 12);

  group('syncFrom', () {
    test('first sync starts at the journey start', () {
      final startedAt = DateTime.utc(2026, 9, 1, 8);

      expect(
        syncFrom(start: _start(startedAt), now: now, lastStoredDate: null),
        startedAt,
      );
    });

    test('later syncs re-query seven days', () {
      expect(
        syncFrom(
          start: _start(DateTime.utc(2026, 9)),
          now: now,
          lastStoredDate: LocalDate.parse('2026-09-27'),
        ),
        DateTime(2026, 9, 21),
      );
    });

    test('a start inside the window wins', () {
      final startedAt = DateTime.utc(2026, 9, 26, 7, 20);

      expect(
        syncFrom(
          start: _start(startedAt),
          now: now,
          lastStoredDate: LocalDate.parse('2026-09-27'),
        ),
        startedAt,
      );
    });

    test('the window follows local midnight across DST', () {
      expect(
        syncFrom(
          start: _start(DateTime.utc(2026, 9)),
          now: DateTime(2026, 10, 27, 9),
          lastStoredDate: LocalDate.parse('2026-10-26'),
        ),
        DateTime(2026, 10, 20),
      );
    });
  });

  group('syncFrom after a gap', () {
    test('a gap longer than the window starts at the last stored day', () {
      expect(
        syncFrom(
          start: _start(DateTime.utc(2026, 9)),
          now: now,
          lastStoredDate: LocalDate.parse('2026-09-16'),
        ),
        DateTime(2026, 9, 16),
      );
    });

    test('never before the journey start', () {
      final startedAt = DateTime.utc(2026, 9, 16, 10);

      expect(
        syncFrom(
          start: _start(startedAt),
          now: now,
          lastStoredDate: LocalDate.parse('2026-09-16'),
        ),
        startedAt,
      );
    });
  });

  group('mergeDays', () {
    test('writes new days', () {
      final fetched = [_day('2026-09-27', 5000), _day('2026-09-28', 6870)];

      expect(mergeDays(stored: const [], fetched: fetched), fetched);
    });

    test('writes a changed count, also lower', () {
      final lower = _day('2026-09-27', 4200);

      expect(mergeDays(stored: [_day('2026-09-27', 5000)], fetched: [lower]), [
        lower,
      ]);
    });

    test('skips an identical day', () {
      expect(
        mergeDays(
          stored: [_day('2026-09-27', 5000)],
          fetched: [_day('2026-09-27', 5000)],
        ),
        isEmpty,
      );
    });

    test('keeps a day counted in another zone', () {
      final newDay = _day('2026-09-28', 3000, timezone: 'Europe/Lisbon');

      expect(
        mergeDays(
          stored: [_day('2026-09-27', 5000)],
          fetched: [
            _day('2026-09-27', 5400, timezone: 'Europe/Lisbon'),
            newDay,
          ],
        ),
        [newDay],
      );
    });
  });
}

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/steps/data/demo/demo_steps_repository.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

void main() {
  final clock = Clock.fixed(DateTime(2026, 9, 28, 12));
  final today = LocalDate.parse('2026-09-28');

  group('DemoStepsRepository', () {
    test('covers 120 consecutive days ending today', () async {
      final days = await _all(clock);

      expect(days, hasLength(120));
      expect(days.last.localDate, today);
      expect(days.first.localDate, today.addDays(-119));
      for (var i = 1; i < days.length; i++) {
        expect(days[i].localDate, days[i - 1].localDate.addDays(1));
      }
    });

    test('is deterministic', () async {
      final a = await _all(clock);
      final b = await _all(clock);

      expect(
        [for (final d in a) (d.localDate, d.steps)],
        [for (final d in b) (d.localDate, d.steps)],
      );
    });

    test('keeps steps between 0 and 14 000 and varies them', () async {
      final days = await _all(clock);
      final steps = [for (final d in days) d.steps];

      expect(steps, everyElement(inInclusiveRange(0, 14000)));
      expect(steps.toSet().length, greaterThan(50));
    });

    test('filters by inclusive from and to', () async {
      final from = LocalDate.parse('2026-09-22');
      final to = LocalDate.parse('2026-09-24');

      final days = await DemoStepsRepository(clock)
          .watchDays(userId: 'u', from: from, to: to)
          .first;

      expect([for (final d in days) d.localDate], [from, from.addDays(1), to]);
    });

    test('carries the user id', () async {
      final days = await DemoStepsRepository(clock)
          .watchDays(userId: 'user-a')
          .first;

      expect(days.map((d) => d.userId).toSet(), {'user-a'});
    });

    test('honours a custom number of days', () async {
      final days = await DemoStepsRepository(
        clock,
        days: 3,
      ).watchDays(userId: 'u').first;

      expect(days, hasLength(3));
    });
  });
}

Future<List<DailySteps>> _all(Clock clock) =>
    DemoStepsRepository(clock).watchDays(userId: 'u').first;

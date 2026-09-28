import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/progress/domain/level_curve.dart';
import 'package:shlyakh/features/progress/domain/xp_rules.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';
import 'package:shlyakh/features/today/presentation/providers/current_user_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/today_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/today_view.dart';

final class _FakeRepository implements StepsRepository {
  new(this.days);

  final List<DailySteps> days;
  String? requestedUserId;

  @override
  Stream<List<DailySteps>> watchDays({
    required String userId,
    LocalDate? from,
    LocalDate? to,
  }) {
    requestedUserId = userId;
    return Stream.value(days);
  }
}

DailySteps _day(String iso, int steps) => (
  userId: 'local',
  localDate: LocalDate.parse(iso),
  timezone: 'Europe/Kyiv',
  steps: steps,
);

LocalDate _d(String iso) => LocalDate.parse(iso);

Future<TodayView> _view(
  DateTime now,
  List<DailySteps> days, {
  _FakeRepository? repository,
}) async {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(Clock.fixed(now)),
      stepsRepositoryProvider.overrideWithValue(
        repository ?? _FakeRepository(days),
      ),
    ],
  );
  addTearDown(container.dispose);
  // todayProvider is auto-dispose: keep it alive while awaiting its value.
  container.listen(todayProvider, (_, _) {});
  return await container.read(todayProvider.future);
}

void main() {
  group('the week', () {
    final cases = <(String, DateTime, String, String)>[
      ('Monday', DateTime(2026, 9, 28, 9), '2026-09-28', '2026-10-04'),
      ('Wednesday', DateTime(2026, 9, 30, 9), '2026-09-28', '2026-10-04'),
      ('Sunday', DateTime(2026, 9, 27, 23, 30), '2026-09-21', '2026-09-27'),
      ('across a year', DateTime(2026, 12, 31, 9), '2026-12-28', '2027-01-03'),
    ];
    for (final (name, now, monday, sunday) in cases) {
      test('on a $name runs from $monday to $sunday', () async {
        final view = await _view(now, const []);
        final today = LocalDate.fromDateTime(now);

        expect(view.week, hasLength(7));
        expect(view.week.first.date, _d(monday));
        expect(view.week.last.date, _d(sunday));
        for (var i = 1; i < 7; i++) {
          expect(view.week[i].date, view.week[i - 1].date.addDays(1));
        }
        expect(
          [
            for (final d in view.week)
              if (d.isToday) d.date,
          ],
          [today],
        );
      });
    }

    test('fills missing days with 0 and sums the week', () async {
      final view = await _view(DateTime(2026, 9, 30, 9), [
        _day('2026-09-27', 9999), // the previous week
        _day('2026-09-28', 1000),
        _day('2026-09-30', 2500),
      ]);

      expect([for (final d in view.week) d.steps], [1000, 0, 2500, 0, 0, 0, 0]);
      expect(view.weekSteps, 3500);
    });
  });

  group('today', () {
    test('has its steps, XP and approximate distance', () async {
      final view = await _view(DateTime(2026, 9, 28, 12), [
        _day('2026-09-27', 3000),
        _day('2026-09-28', 12000),
      ]);

      expect(view.steps, 12000);
      expect(view.xp, dailyXp(12000));
      expect(view.distanceMeters, 8880);
    });

    test('has 0 steps when the day is missing', () async {
      final view = await _view(DateTime(2026, 9, 28, 12), [
        _day('2026-09-27', 3000),
      ]);

      expect((view.steps, view.xp, view.distanceMeters), (0, 0, 0));
    });
  });

  group('the level', () {
    test('comes from the XP of all days', () async {
      final days = [
        for (var i = 0; i < 30; i++)
          _day(_d('2026-08-30').addDays(i).toIsoString(), 11000),
      ];

      final view = await _view(DateTime(2026, 9, 28, 12), days);
      final expected = levelProgress(totalXp(days.map((d) => d.steps)));

      expect(view.level, expected);
      expect(view.levelStartXp, xpToReachLevel(expected.level));
      expect(view.nextLevelXp, xpToReachLevel(expected.level + 1));
      expect(view.nextLevelXp - view.levelStartXp, expected.xpForNextLevel);
    });

    test('is 1 with no days at all', () async {
      final view = await _view(DateTime(2026, 9, 28, 12), const []);

      expect(view.level.level, 1);
      expect(view.levelStartXp, 0);
      expect(view.steps, 0);
      expect(view.weekSteps, 0);
    });
  });

  test('reads the days of the current user', () async {
    final repository = _FakeRepository(const []);

    await _view(DateTime(2026, 9, 28, 12), const [], repository: repository);

    expect(repository.requestedUserId, 'local');
  });

  test('the current user is local until registration', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(currentUserIdProvider), 'local');
  });
}

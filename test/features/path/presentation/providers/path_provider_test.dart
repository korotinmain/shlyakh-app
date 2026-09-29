import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/path/domain/path_pages.dart';
import 'package:shlyakh/features/path/presentation/providers/path_provider.dart';
import 'package:shlyakh/features/path/presentation/providers/path_view.dart';
import 'package:shlyakh/features/path/presentation/providers/route_provider.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';

import '../../../../helpers/route_fixture.dart';

final class _Repository implements StepsRepository {
  new(this.days);

  final List<DailySteps> days;

  @override
  Stream<List<DailySteps>> watchDays({
    required String userId,
    LocalDate? from,
    LocalDate? to,
  }) => Stream.value(days);
}

DailySteps _day(String iso, int steps) => (
  userId: 'local',
  localDate: LocalDate.parse(iso),
  timezone: 'Europe/Kyiv',
  steps: steps,
);

/// [count] days of [steps] each, ending on 2026-09-27.
List<DailySteps> _days(int count, int steps) => [
  for (var i = count; i >= 1; i--)
    _day(LocalDate.parse('2026-09-28').addDays(-i).toIsoString(), steps),
];

Future<PathView> _view(List<DailySteps> days) async {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 9, 28, 12))),
      routeProvider.overrideWith((ref) async => testRoute()),
      stepsRepositoryProvider.overrideWithValue(_Repository(days)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(pathProvider, (_, _) {});
  return await container.read(pathProvider.future);
}

void main() {
  group('pathProvider', () {
    test(
      'shows the completed, the current and the next constellation',
      () async {
        // 16 870 XP: Стріла complete on 09-28, Лисичка's first star current.
        final view = await _view([
          _day('2026-09-27', 10000),
          _day('2026-09-28', 6870),
        ]);

        expect(
          [for (final p in view.pages) p.constellation.id],
          ['Sge', 'Vul', 'Cyg'],
        );
        expect(
          [for (final p in view.pages) p.state],
          [PageState.done, PageState.current, PageState.ahead],
        );
        expect(view.currentPage, 1);
        expect(view.completedCount, 1);
        expect(view.pages.first.completedOn, LocalDate.parse('2026-09-28'));
        expect(view.pages[1].completedOn, isNull);
        expect(view.pages.first.ownStars, 4);
      },
    );

    test('has an ETA with a week of history', () async {
      final view = await _view(_days(7, 7000));

      expect(view.etaDays, isNotNull);
      expect(view.etaDays, greaterThan(0));
    });

    test('has no ETA with three days of history', () async {
      final view = await _view(_days(3, 7000));

      expect(view.etaDays, isNull);
    });

    test('shows every page done when the whole route is lit', () async {
      final view = await _view(_days(400, 30000));

      expect(view.pages, hasLength(16));
      expect(view.pages.map((p) => p.state), everyElement(PageState.done));
      expect(view.currentPage, 15);
      expect(view.completedCount, 16);
      expect(view.etaDays, isNull);
    });

    test('starts on Sagitta without days', () async {
      final view = await _view(const []);

      expect(view.pages, hasLength(2));
      expect(view.currentPage, 0);
      expect(view.completedCount, 0);
      expect(view.progress.starsLit, 0);
    });
  });
}

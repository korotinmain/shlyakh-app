import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';
import 'package:shlyakh/features/path/presentation/providers/route_provider.dart';
import 'package:shlyakh/features/progress/domain/xp_rules.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/distance.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/today/presentation/providers/current_user_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/today_view.dart';

part 'today_provider.g.dart';

/// The Today screen's data for the current user.
@riverpod
Stream<TodayView> today(Ref ref) async* {
  final clock = ref.watch(clockProvider);
  final repository = ref.watch(stepsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  final route = await ref.watch(routeProvider.future);
  // "Today" is read per emission, so new data after midnight lands on the
  // new day.
  yield* repository
      .watchDays(userId: userId)
      .map(
        (days) => _buildView(days, LocalDate.fromDateTime(clock.now()), route),
      );
}

TodayView _buildView(List<DailySteps> days, LocalDate today, SkyRoute route) {
  final stepsOn = {for (final d in days) d.localDate: d.steps};
  final monday = today.addDays(1 - today.weekday);
  final week = <WeekDay>[
    for (var i = 0; i < 7; i++)
      (
        date: monday.addDays(i),
        steps: stepsOn[monday.addDays(i)] ?? 0,
        isToday: monday.addDays(i) == today,
      ),
  ];
  final steps = stepsOn[today] ?? 0;
  final progress = pathProgress(totalXp(days.map((d) => d.steps)), route);
  final next = progress.next;
  return (
    steps: steps,
    xp: dailyXp(steps),
    distanceMeters: approximateDistanceMeters(steps),
    progress: progress,
    constellationId: route
        .constellations[next?.constellationIndex ??
            route.constellations.length - 1]
        .id,
    starPercent: next == null ? 100 : next.xpIntoStar * 100 ~/ next.xpForStar,
    week: week,
    weekSteps: week.fold(0, (sum, d) => sum + d.steps),
  );
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/progress/domain/level_curve.dart';
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
Stream<TodayView> today(Ref ref) {
  final clock = ref.watch(clockProvider);
  final repository = ref.watch(stepsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  // "Today" is read per emission, so new data after midnight lands on the
  // new day.
  return repository
      .watchDays(userId: userId)
      .map((days) => _buildView(days, LocalDate.fromDateTime(clock.now())));
}

TodayView _buildView(List<DailySteps> days, LocalDate today) {
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
  final level = levelProgress(totalXp(days.map((d) => d.steps)));
  return (
    steps: steps,
    xp: dailyXp(steps),
    distanceMeters: approximateDistanceMeters(steps),
    level: level,
    levelStartXp: xpToReachLevel(level.level),
    nextLevelXp: xpToReachLevel(level.level + 1),
    week: week,
    weekSteps: week.fold(0, (sum, d) => sum + d.steps),
  );
}

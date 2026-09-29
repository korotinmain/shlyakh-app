import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/path/domain/completion_dates.dart';
import 'package:shlyakh/features/path/domain/eta.dart';
import 'package:shlyakh/features/path/domain/figure_state.dart';
import 'package:shlyakh/features/path/domain/path_pages.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';
import 'package:shlyakh/features/path/presentation/providers/path_view.dart';
import 'package:shlyakh/features/path/presentation/providers/route_provider.dart';
import 'package:shlyakh/features/progress/domain/xp_rules.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/presentation/providers/current_date_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/current_user_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';

part 'path_provider.g.dart';

/// The Path tab's data for the current user.
@riverpod
Stream<PathView> path(Ref ref) async* {
  final clock = ref.watch(clockProvider);
  final repository = ref.watch(stepsRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  final route = await ref.watch(routeProvider.future);
  // Rebuilt at midnight; "today" is also read per emission, so new data
  // after a time zone change lands on the right day.
  ref.watch(currentDateProvider);
  yield* repository
      .watchDays(userId: userId)
      .map(
        (days) => _buildView(days, LocalDate.fromDateTime(clock.now()), route),
      );
}

PathView _buildView(List<DailySteps> days, LocalDate today, SkyRoute route) {
  final progress = pathProgress(totalXp(days.map((d) => d.steps)), route);
  final dates = completionDates(days, route);
  final pages = [
    for (final page in pathPages(route, progress))
      (
        constellation: route.constellations[page.constellationIndex],
        state: page.state,
        figure: figureStatesFor(route, progress, page.constellationIndex),
        completedOn: page.state == PageState.done
            ? dates[page.constellationIndex]
            : null,
        ownStars: route.ownOrder(page.constellationIndex).length,
      ),
  ];
  final next = progress.next;
  final current = pages.indexWhere((p) => p.state == PageState.current);
  return (
    route: route,
    progress: progress,
    pages: List.unmodifiable(pages),
    currentPage: current < 0 ? pages.length - 1 : current,
    completedCount: pages.where((p) => p.state == PageState.done).length,
    etaDays: next == null
        ? null
        : daysToNextStar(
            days: days,
            today: today,
            xpLeft: next.xpForStar - next.xpIntoStar,
          ),
  );
}

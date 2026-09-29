// The day each constellation was completed, recomputed from daily steps
// (docs/superpowers/specs/2026-09-28-constellation-path-design.md,
// "Completed look").
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';
import 'package:shlyakh/features/progress/domain/xp_rules.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

/// Constellation index → the first local day on which the cumulative XP
/// reached the cost of its last own star. Constellations not yet complete
/// are left out.
Map<int, LocalDate> completionDates(List<DailySteps> days, SkyRoute route) {
  final sorted = [...days]..sort((a, b) => a.localDate.compareTo(b.localDate));
  // XP that completes each constellation, in route order.
  final thresholds = <int>[];
  var stars = 0;
  for (var i = 0; i < route.constellations.length; i++) {
    stars += route.ownOrder(i).length;
    thresholds.add(xpToLight(stars));
  }
  final dates = <int, LocalDate>{};
  var xp = 0;
  var next = 0;
  for (final day in sorted) {
    xp += dailyXp(day.steps);
    while (next < thresholds.length && thresholds[next] <= xp) {
      dates[next++] = day.localDate;
    }
  }
  return dates;
}

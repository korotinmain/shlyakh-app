// Days to the next star at the recent pace
// (docs/superpowers/specs/2026-09-28-constellation-path-design.md, "ETA").
import 'package:shlyakh/features/progress/domain/xp_rules.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

/// Full days the pace is averaged over.
const _window = 14;

/// Fewest full days of history that give a pace.
const _minHistory = 7;

/// Days until [xpLeft] more XP is earned at the average daily XP of the
/// last 14 full days before [today].
///
/// The window starts no earlier than the first day in [days]; a day inside
/// it without a record counts as 0 XP. Today is left out: it is not over.
/// Null when there are fewer than 7 days of history or the pace is zero.
int? daysToNextStar({
  required List<DailySteps> days,
  required LocalDate today,
  required int xpLeft,
}) {
  if (days.isEmpty) return null;
  final first = days
      .map((d) => d.localDate)
      .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  final windowStart = today.addDays(-_window);
  final start = first.compareTo(windowStart) > 0 ? first : windowStart;
  var length = 0;
  for (var d = start; d.compareTo(today) < 0; d = d.addDays(1)) {
    length++;
  }
  if (length < _minHistory) return null;
  var sum = 0;
  for (final day in days) {
    if (day.localDate.compareTo(start) >= 0 &&
        day.localDate.compareTo(today) < 0) {
      sum += dailyXp(day.steps);
    }
  }
  if (sum == 0) return null;
  if (xpLeft <= 0) return 0;
  return (xpLeft * length + sum - 1) ~/ sum;
}

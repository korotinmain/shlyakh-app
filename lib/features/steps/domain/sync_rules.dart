import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

/// Days re-queried on every sync after the first: Watch data can arrive
/// late and samples can be deleted in Health.
const int syncWindowDays = 7;

/// The instant a sync queries HealthKit from.
///
/// The journey start on the first sync ([lastStoredDate] is null).
/// Otherwise local midnight [windowDays] days before [now] (local
/// wall-clock time), or local midnight of [lastStoredDate] when that is
/// earlier, so days missed while no sync succeeded are filled; never
/// before the journey start.
DateTime syncFrom({
  required JourneyStart start,
  required DateTime now,
  required LocalDate? lastStoredDate,
  int windowDays = syncWindowDays,
}) {
  if (lastStoredDate == null) return start.startedAt;
  // DateTime(y, m, d - n) is local midnight, correct across DST.
  final windowStart = DateTime(now.year, now.month, now.day - windowDays);
  final lastStored = DateTime(
    lastStoredDate.year,
    lastStoredDate.month,
    lastStoredDate.day,
  );
  final from = lastStored.isBefore(windowStart) ? lastStored : windowStart;
  return from.isAfter(start.startedAt) ? from : start.startedAt;
}

/// The [fetched] days to write, in fetched order.
///
/// A day is written when nothing is stored for it, or when the stored day
/// was counted in the same zone with a different count (also a lower one:
/// HealthKit is the source of truth). A day stored in another zone keeps
/// its local boundaries from where the user was; an identical day is
/// skipped so a repeated sync writes nothing.
List<DailySteps> mergeDays({
  required List<DailySteps> stored,
  required List<DailySteps> fetched,
}) {
  assert(
    {...stored.map((d) => d.userId), ...fetched.map((d) => d.userId)}.length <=
        1,
    'mergeDays compares the days of one user',
  );
  final byDate = {for (final day in stored) day.localDate: day};
  bool shouldWrite(DailySteps day) => switch (byDate[day.localDate]) {
    null => true,
    final old => old.timezone == day.timezone && old.steps != day.steps,
  };
  return fetched.where(shouldWrite).toList();
}

// XP from daily steps. Rules and tables:
// docs/superpowers/specs/2026-09-27-xp-rules-design.md

/// Steps per day that earn 1 XP each; beyond this, 1 XP per 2 steps.
const _fullRateSteps = 10000;

/// Maximum XP a single day can earn (reached at 30 000 steps).
const _dailyXpCap = 20000;

/// XP earned by one local day with [steps] steps.
///
/// Throws [ArgumentError] for negative steps: HealthKit never reports them,
/// so they indicate a data bug.
int dailyXp(int steps) {
  if (steps < 0) throw ArgumentError.value(steps, 'steps', 'must be >= 0');
  final fullRate = steps < _fullRateSteps ? steps : _fullRateSteps;
  final halfRate = (steps - fullRate) ~/ 2;
  final xp = fullRate + halfRate;
  return xp < _dailyXpCap ? xp : _dailyXpCap;
}

/// Total XP of all days, each scored on its own by [dailyXp].
///
/// Recomputed from daily steps, never stored as a counter.
int totalXp(Iterable<int> dailySteps) =>
    dailySteps.fold(0, (sum, steps) => sum + dailyXp(steps));

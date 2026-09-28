import 'package:shlyakh/features/progress/domain/level_curve.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

/// One day of the Monday–Sunday week shown on the Today screen.
typedef WeekDay = ({LocalDate date, int steps, bool isToday});

/// Everything the Today screen shows, computed from the user's days.
typedef TodayView = ({
  /// Today's steps.
  int steps,

  /// XP of today's steps.
  int xp,

  /// Approximate distance of today's steps, in metres.
  int distanceMeters,

  /// Level from the XP of all days.
  LevelProgress level,

  /// Total XP at which [level] starts.
  int levelStartXp,

  /// Total XP at which the next level starts.
  int nextLevelXp,

  /// Monday..Sunday of the current week, 7 entries; missing days are 0.
  List<WeekDay> week,

  /// Sum of [week].
  int weekSteps,
});

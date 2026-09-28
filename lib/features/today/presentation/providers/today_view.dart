import 'package:shlyakh/features/path/domain/figure_state.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';
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

  /// Stars lit with the XP of all days, and the next one.
  PathProgress progress,

  /// The constellation of the next star; the last one on the route when
  /// every star is lit.
  Constellation constellation,

  /// How that constellation's stars and lines look now.
  FigureStates figure,

  /// How full the next star is, 0–99; 100 when every star is lit.
  int starPercent,

  /// Monday..Sunday of the current week, 7 entries; missing days are 0.
  List<WeekDay> week,

  /// Sum of [week].
  int weekSteps,
});

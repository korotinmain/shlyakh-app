import 'package:shlyakh/features/path/domain/figure_state.dart';
import 'package:shlyakh/features/path/domain/path_pages.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

/// One page of the Path tab.
typedef PathPageView = ({
  Constellation constellation,
  PageState state,

  /// How its stars and lines look now.
  FigureStates figure,

  /// The day it was completed; null unless done.
  LocalDate? completedOn,

  /// Stars it lights itself (a shared star counts in the first one).
  int ownStars,
});

/// Everything the Path tab and its map show.
typedef PathView = ({
  SkyRoute route,
  PathProgress progress,
  List<PathPageView> pages,

  /// Index into [pages] of the current constellation (the last page when
  /// every star is lit).
  int currentPage,

  /// Constellations completed so far.
  int completedCount,

  /// Days to the next star at the recent pace; null without enough
  /// history or when every star is lit.
  int? etaDays,
});

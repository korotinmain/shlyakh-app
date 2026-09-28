import 'package:shlyakh/features/progress/domain/level_curve.dart';
import 'package:shlyakh/features/progress/domain/level_titles.dart';

/// Where a node sits across the trail, so the line winds.
enum TrailSide { left, centre, right }

/// One level's node on the trail.
typedef TrailNode = ({
  int level,
  int chapter,
  TrailSide side,
  bool startsChapter,
});

/// The node of [level]: sides repeat centre, left, centre, right; the
/// first level of each main-path chapter starts it. Continuation levels
/// stay in the last chapter.
///
/// Throws [ArgumentError] for levels below 1.
TrailNode trailNode(int level) => (
  level: level,
  chapter: chapterOf(level),
  side: const [
    TrailSide.centre,
    TrailSide.left,
    TrailSide.centre,
    TrailSide.right,
  ][(level - 1) % 4],
  startsChapter: isOnMainPath(level) && (level - 1) % levelsPerChapter == 0,
);

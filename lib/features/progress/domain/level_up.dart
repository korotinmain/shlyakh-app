import 'package:shlyakh/features/progress/domain/level_curve.dart';
import 'package:shlyakh/features/progress/domain/level_titles.dart';

/// A rise from the last celebrated level to the current one
/// (docs/superpowers/specs/2026-09-28-level-up-moment-design.md).
///
/// `passed` are the levels strictly between, ascending; `newChapter` is
/// the chapter opened on the way (the highest if several), null if none;
/// `finishesMainPath` is true when level 25 is reached on the way.
typedef LevelUp = ({
  int from,
  int to,
  List<int> passed,
  int? newChapter,
  bool finishesMainPath,
});

/// What to celebrate when [current] is above [celebrated], or null. A
/// level that went down (samples deleted in Health) is never celebrated.
///
/// Throws [ArgumentError] for levels below 1.
LevelUp? levelUp({required int celebrated, required int current}) {
  for (final level in [celebrated, current]) {
    if (level < 1) throw ArgumentError.value(level, 'level', 'must be >= 1');
  }
  if (current <= celebrated) return null;
  final reached = [for (var l = celebrated + 1; l <= current; l++) l];
  final chapterStarts = reached.where(_startsChapter);
  return (
    from: celebrated,
    to: current,
    passed: reached.sublist(0, reached.length - 1),
    newChapter: chapterStarts.isEmpty ? null : chapterOf(chapterStarts.last),
    finishesMainPath: reached.contains(mainPathLevels),
  );
}

/// Whether [level] opens a chapter after the first (6, 11, 16, 21).
bool _startsChapter(int level) =>
    level > 1 && isOnMainPath(level) && (level - 1) % levelsPerChapter == 0;

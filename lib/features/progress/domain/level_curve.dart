// Levels from total XP. Rules and tables:
// docs/superpowers/specs/2026-09-27-xp-rules-design.md

/// Number of levels on the main path.
const mainPathLevels = 25;

/// XP that completes the main path ("a million steps").
const mainPathXp = 1000000;

/// Where a user is on the level curve.
typedef LevelProgress = ({
  /// Current level, starting at 1.
  int level,

  /// XP earned since reaching [level].
  int xpIntoLevel,

  /// XP between [level] and the next level. XP, not steps: above 10 000
  /// steps a day one XP costs two steps.
  int xpForNextLevel,
});

/// XP per level after the main path: the size of the last main-path level.
final int _continuationStep =
    _mainPathThreshold(mainPathLevels) - _mainPathThreshold(mainPathLevels - 1);

/// `round_to_100(mainPathXp * ((level - 1) / 24)^2)` in integers.
int _mainPathThreshold(int level) {
  final steps = level - 1;
  const divisor = (mainPathLevels - 1) * (mainPathLevels - 1) * 100;
  return (mainPathXp * steps * steps + divisor ~/ 2) ~/ divisor * 100;
}

/// Total XP needed to reach [level] (level 1 needs 0).
///
/// Throws [ArgumentError] for levels below 1.
int xpToReachLevel(int level) {
  if (level < 1) throw ArgumentError.value(level, 'level', 'must be >= 1');
  if (level <= mainPathLevels) return _mainPathThreshold(level);
  return mainPathXp + (level - mainPathLevels) * _continuationStep;
}

/// The level reached with [totalXp] and the progress within it.
///
/// Throws [ArgumentError] for negative XP.
LevelProgress levelProgress(int totalXp) {
  if (totalXp < 0) {
    throw ArgumentError.value(totalXp, 'totalXp', 'must be >= 0');
  }

  final int level;
  if (totalXp >= mainPathXp) {
    level = mainPathLevels + (totalXp - mainPathXp) ~/ _continuationStep;
  } else {
    var candidate = 1;
    while (xpToReachLevel(candidate + 1) <= totalXp) {
      candidate++;
    }
    level = candidate;
  }

  final reached = xpToReachLevel(level);
  return (
    level: level,
    xpIntoLevel: totalXp - reached,
    xpForNextLevel: xpToReachLevel(level + 1) - reached,
  );
}

/// Whether [level] is part of the main path (not the continuation).
bool isOnMainPath(int level) => level <= mainPathLevels;

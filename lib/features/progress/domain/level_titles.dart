// Structure of level titles: 5 chapters of 5 titles on the main path, then
// the last title with a growing degree ("Star Wanderer II, III, …").
// The titles themselves are user-facing text and live in the ARB files.
import 'package:shlyakh/features/progress/domain/level_curve.dart';

/// Grammatical gender of the user, used only to pick the form of a title
/// ("Мандрівник" / "Мандрівниця"). Chosen at registration (PRODUCT.md).
enum GrammaticalGender { feminine, masculine }

/// Levels per chapter on the main path.
const levelsPerChapter = 5;

/// Chapter (1–5) that [level] belongs to; continuation levels stay in the
/// last chapter.
///
/// Throws [ArgumentError] for levels below 1.
int chapterOf(int level) {
  _checkLevel(level);
  final mainPathLevel = isOnMainPath(level) ? level : mainPathLevels;
  return (mainPathLevel - 1) ~/ levelsPerChapter + 1;
}

/// Degree shown after the last title on the continuation: level 26 is II,
/// 27 is III. Null on the main path, where every level has its own title.
///
/// Throws [ArgumentError] for levels below 1.
int? continuationDegree(int level) {
  _checkLevel(level);
  return isOnMainPath(level) ? null : level - mainPathLevels + 1;
}

void _checkLevel(int level) {
  if (level < 1) throw ArgumentError.value(level, 'level', 'must be >= 1');
}

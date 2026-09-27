import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/text/roman_numerals.dart';
import 'package:shlyakh/features/progress/domain/level_curve.dart';
import 'package:shlyakh/features/progress/domain/level_titles.dart';
import 'package:shlyakh/l10n/app_localizations.dart';

part 'level_title.g.dart';

/// Grammatical gender used for level titles.
///
/// Masculine until registration exists; registration will make choosing it
/// mandatory (docs/PRODUCT.md) and this provider will read the profile.
@Riverpod(keepAlive: true)
GrammaticalGender grammaticalGender(Ref ref) => GrammaticalGender.masculine;

/// Localized title of [level] in the form for [gender]: one of the 25
/// main-path titles, or the last one with a Roman degree after the main path.
///
/// Throws [ArgumentError] for levels below 1.
String levelTitle(AppLocalizations l10n, int level, GrammaticalGender gender) {
  final degree = continuationDegree(level);
  if (degree != null) {
    return l10n.levelTitleContinuation(
      _mainPathTitle(l10n, mainPathLevels, gender),
      toRoman(degree),
    );
  }
  return _mainPathTitle(l10n, level, gender);
}

/// Localized name of the chapter [level] belongs to.
///
/// Throws [ArgumentError] for levels below 1.
String levelChapter(AppLocalizations l10n, int level) =>
    switch (chapterOf(level)) {
      1 => l10n.levelChapter1,
      2 => l10n.levelChapter2,
      3 => l10n.levelChapter3,
      4 => l10n.levelChapter4,
      5 => l10n.levelChapter5,
      _ => throw StateError('chapterOf returned an unknown chapter'),
    };

String _mainPathTitle(
  AppLocalizations l10n,
  int level,
  GrammaticalGender gender,
) {
  // ARB select keys: "feminine", anything else is the masculine form.
  final form = gender.name;
  return switch (level) {
    1 => l10n.levelTitle1(form),
    2 => l10n.levelTitle2(form),
    3 => l10n.levelTitle3(form),
    4 => l10n.levelTitle4(form),
    5 => l10n.levelTitle5(form),
    6 => l10n.levelTitle6(form),
    7 => l10n.levelTitle7(form),
    8 => l10n.levelTitle8(form),
    9 => l10n.levelTitle9(form),
    10 => l10n.levelTitle10(form),
    11 => l10n.levelTitle11(form),
    12 => l10n.levelTitle12(form),
    13 => l10n.levelTitle13(form),
    14 => l10n.levelTitle14(form),
    15 => l10n.levelTitle15(form),
    16 => l10n.levelTitle16(form),
    17 => l10n.levelTitle17(form),
    18 => l10n.levelTitle18(form),
    19 => l10n.levelTitle19(form),
    20 => l10n.levelTitle20(form),
    21 => l10n.levelTitle21(form),
    22 => l10n.levelTitle22(form),
    23 => l10n.levelTitle23(form),
    24 => l10n.levelTitle24(form),
    25 => l10n.levelTitle25(form),
    _ => throw StateError('no main-path title for level $level'),
  };
}

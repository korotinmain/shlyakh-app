// Stars from total XP (docs/superpowers/specs/2026-09-28-constellation-path-design.md,
// "Numbers"): the n-th star costs min(25 000, 1 500 × n) XP.
import 'package:shlyakh/features/path/domain/route.dart';

const _costStep = 1500;
const _costCap = 25000;

/// Stars whose cost still grows; from the next one on each costs the cap.
const _growingStars = 16;

/// XP of the first [_growingStars] stars together.
const int _growingXp = _costStep * _growingStars * (_growingStars + 1) ~/ 2;

/// XP of the [n]-th star (1-based).
///
/// Throws [ArgumentError] for `n < 1`.
int starCost(int n) {
  if (n < 1) throw ArgumentError.value(n, 'n', 'must be >= 1');
  final cost = _costStep * n;
  return cost < _costCap ? cost : _costCap;
}

/// Total XP that lights the first [stars] stars.
///
/// Throws [ArgumentError] for a negative count.
int xpToLight(int stars) {
  if (stars < 0) throw ArgumentError.value(stars, 'stars', 'must be >= 0');
  if (stars <= _growingStars) return _costStep * stars * (stars + 1) ~/ 2;
  return _growingXp + _costCap * (stars - _growingStars);
}

/// The star being filled: where it is on the route and how much of its
/// cost is earned.
typedef NextStar = ({
  int constellationIndex,
  int starInConstellation,
  int xpIntoStar,
  int xpForStar,
});

/// Stars lit so far and the next one; `next` is null when every star of
/// the route is lit.
typedef PathProgress = ({int starsLit, NextStar? next});

/// Progress along [route] with [totalXp].
///
/// Throws [ArgumentError] for negative XP.
PathProgress pathProgress(int totalXp, Route route) {
  if (totalXp < 0) {
    throw ArgumentError.value(totalXp, 'totalXp', 'must be >= 0');
  }
  final total = route.stars.length;
  var lit = 0;
  while (lit < total && xpToLight(lit + 1) <= totalXp) {
    lit++;
  }
  if (lit == total) return (starsLit: lit, next: null);
  final star = route.stars[lit];
  return (
    starsLit: lit,
    next: (
      constellationIndex: star.constellationIndex,
      starInConstellation: star.starInConstellation,
      xpIntoStar: totalXp - xpToLight(lit),
      xpForStar: starCost(lit + 1),
    ),
  );
}

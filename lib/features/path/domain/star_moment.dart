// The stars to celebrate since the last celebration
// (docs/superpowers/specs/2026-09-28-constellation-path-design.md,
// "New-star moment").
import 'package:shlyakh/features/path/domain/sky_route.dart';

/// Newly lit stars in lighting order and the constellations they complete.
typedef StarMoment = ({
  List<RouteStar> stars,
  List<int> completedConstellations,
});

/// The stars lit after the first [celebratedStars] up to [currentStars]
/// (clamped to the route), or null when there are none: also when XP went
/// down, so a moment never repeats.
///
/// Throws [ArgumentError] for negative counts.
StarMoment? starMoment({
  required int celebratedStars,
  required int currentStars,
  required SkyRoute route,
}) {
  if (celebratedStars < 0) {
    throw ArgumentError.value(celebratedStars, 'celebratedStars', 'negative');
  }
  if (currentStars < 0) {
    throw ArgumentError.value(currentStars, 'currentStars', 'negative');
  }
  final end = currentStars < route.stars.length
      ? currentStars
      : route.stars.length;
  if (end <= celebratedStars) return null;
  final stars = route.stars.sublist(celebratedStars, end);
  final completed = <int>[
    for (final (i, star) in stars.indexed)
      if (i == stars.length - 1 ||
          stars[i + 1].constellationIndex != star.constellationIndex)
        if (route.isComplete(star.constellationIndex, celebratedStars + i + 1))
          star.constellationIndex,
  ];
  return (
    stars: List.unmodifiable(stars),
    completedConstellations: List.unmodifiable(completed),
  );
}

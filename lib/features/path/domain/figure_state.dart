// How the current constellation's figure looks: which stars are lit, which
// one is being filled, which lie ahead
// (docs/superpowers/specs/2026-09-28-constellation-path-design.md, "Today").
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';

/// A figure star's state on the current constellation.
enum StarState { lit, current, ahead }

/// The current constellation and the state of each of its figure stars
/// (indexed like `Constellation.stars`) and lines (like
/// `Constellation.lines`; solid when neither end is ahead).
typedef FigureStates = ({
  int constellationIndex,
  List<StarState> stars,
  List<bool> solidLines,
});

/// The figure of the constellation holding the next star, or of the last
/// constellation, fully lit, once every star is lit.
FigureStates figureStates(SkyRoute route, PathProgress progress) =>
    figureStatesFor(
      route,
      progress,
      progress.next?.constellationIndex ?? route.constellations.length - 1,
    );

/// The figure of the constellation at [constellationIndex] with
/// [progress]: a star is lit once the route has lit it (in any
/// constellation that owns it), current when it is the next star of this
/// constellation, and ahead otherwise.
FigureStates figureStatesFor(
  SkyRoute route,
  PathProgress progress,
  int constellationIndex,
) {
  final routeIndexOf = {
    for (final (i, star) in route.stars.indexed) star.hip: i,
  };
  final isCurrent = progress.next?.constellationIndex == constellationIndex;
  final constellation = route.constellations[constellationIndex];
  final stars = [
    for (final star in constellation.stars)
      switch (routeIndexOf[star.hip]!) {
        final i when i < progress.starsLit => StarState.lit,
        final i when isCurrent && i == progress.starsLit => StarState.current,
        _ => StarState.ahead,
      },
  ];
  return (
    constellationIndex: constellationIndex,
    stars: List.unmodifiable(stars),
    solidLines: List.unmodifiable([
      for (final (a, b) in constellation.lines)
        stars[a] != StarState.ahead && stars[b] != StarState.ahead,
    ]),
  );
}

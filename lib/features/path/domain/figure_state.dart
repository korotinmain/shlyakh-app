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
FigureStates figureStates(SkyRoute route, PathProgress progress) {
  final next = progress.next;
  final index = next?.constellationIndex ?? route.constellations.length - 1;
  final constellation = route.constellations[index];
  final own = route.ownOrder(index);
  final stars = [
    for (var i = 0; i < constellation.stars.length; i++)
      _state(own.indexOf(i), next?.starInConstellation),
  ];
  return (
    constellationIndex: index,
    stars: List.unmodifiable(stars),
    solidLines: List.unmodifiable([
      for (final (a, b) in constellation.lines)
        stars[a] != StarState.ahead && stars[b] != StarState.ahead,
    ]),
  );
}

/// [position] among the constellation's own stars (-1 when an earlier
/// constellation lit it) against the next star's position (null when the
/// whole route is lit).
StarState _state(int position, int? next) {
  if (position < 0 || next == null || position < next) return StarState.lit;
  return position == next ? StarState.current : StarState.ahead;
}

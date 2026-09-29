// The Path tab's pages: completed constellations, the current one and the
// next one; the rest stay in the fog
// (docs/superpowers/specs/2026-09-28-constellation-path-design.md, "Path").
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';

/// Where a page's constellation is on the journey.
enum PageState { done, current, ahead }

typedef PathPage = ({int constellationIndex, PageState state});

/// Pages up to the one after the current constellation, in route order.
/// Once every star is lit, every page is done.
List<PathPage> pathPages(SkyRoute route, PathProgress progress) {
  final last = route.constellations.length - 1;
  final next = progress.next;
  if (next == null) {
    return [
      for (var i = 0; i <= last; i++)
        (constellationIndex: i, state: PageState.done),
    ];
  }
  final current = next.constellationIndex;
  return [
    for (var i = 0; i <= current + 1 && i <= last; i++)
      (
        constellationIndex: i,
        state: i < current
            ? PageState.done
            : i == current
            ? PageState.current
            : PageState.ahead,
      ),
  ];
}

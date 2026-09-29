import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/path_pages.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';

import '../../../helpers/route_fixture.dart';
import '../../../helpers/small_route.dart';

const PageState _done = PageState.done;
const PageState _current = PageState.current;
const PageState _ahead = PageState.ahead;

void main() {
  group('pathPages', () {
    final route = smallRoute();

    List<(int, PageState)> at(int xp) => [
      for (final p in pathPages(route, pathProgress(xp, route)))
        (p.constellationIndex, p.state),
    ];

    test('starts with the first constellation and the next one ahead', () {
      expect(at(0), [(0, _current), (1, _ahead)]);
    });

    test('shows completed constellations, the current and the next', () {
      expect(at(9000), [(0, _done), (1, _current), (2, _ahead)]);
    });

    test('has no page ahead on the last constellation', () {
      expect(at(15000), [(0, _done), (1, _done), (2, _current)]);
    });

    test('marks every page done when the whole route is lit', () {
      expect(at(22500), [(0, _done), (1, _done), (2, _done)]);
    });

    test('opens the branch once the main route is done', () {
      final sky = testRoute();
      final pages = pathPages(sky, pathProgress(xpToLight(140), sky));

      expect(pages, hasLength(15));
      expect(pages.take(13).map((p) => p.state), everyElement(_done));
      final ids = [
        for (final p in pages.skip(13))
          (sky.constellations[p.constellationIndex].id, p.state),
      ];
      expect(ids, [('Aql', _current), ('Sct', _ahead)]);
    });
  });
}

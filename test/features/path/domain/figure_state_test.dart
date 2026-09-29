import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/figure_state.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';

import '../../../helpers/route_fixture.dart';
import '../../../helpers/small_route.dart';

const StarState _lit = StarState.lit;
const StarState _current = StarState.current;
const StarState _ahead = StarState.ahead;

FigureStates _at(SkyRoute route, int xp) =>
    figureStates(route, pathProgress(xp, route));

void main() {
  group('figureStates', () {
    final route = smallRoute();

    test('starts with the first star current and the rest ahead', () {
      final f = _at(route, 0);

      expect(f.constellationIndex, 0);
      expect(f.stars, [_current, _ahead, _ahead]);
      expect(f.solidLines, [false, false]);
    });

    test('draws a solid line from a lit star to the current one', () {
      final f = _at(route, 1500);

      expect(f.stars, [_lit, _current, _ahead]);
      expect(f.solidLines, [true, false]);
    });

    test('shows a star lit by an earlier constellation as lit', () {
      final f = _at(route, 9000);

      expect(f.constellationIndex, 1);
      expect(f.stars, [_lit, _current]);
      expect(f.solidLines, [true]);
    });

    test('lights the whole last constellation at the end of the route', () {
      final f = _at(route, 22500);

      expect(f.constellationIndex, 2);
      expect(f.stars, [_lit]);
      expect(f.solidLines, isEmpty);
    });

    test('dashes a line between two stars ahead', () {
      final f = _at(route, 0);

      expect(f.solidLines[1], isFalse);
      expect((f.stars[1], f.stars[2]), (_ahead, _ahead));
    });

    group('on the bundled route', () {
      final sky = testRoute();

      test('has one current star in the constellation of the next star', () {
        final progress = pathProgress(xpToLight(50), sky);
        final f = figureStates(sky, progress);
        final next = sky.stars[50];

        expect(f.constellationIndex, next.constellationIndex);
        expect(f.stars.where((s) => s == _current), hasLength(1));
        final c = sky.constellations[f.constellationIndex];
        final shared =
            c.stars.length - sky.ownOrder(f.constellationIndex).length;
        expect(
          f.stars.where((s) => s == _lit),
          hasLength(next.starInConstellation + shared),
        );
      });

      test('shows Elnath lit when Taurus begins', () {
        final taurus = sky.constellations.indexWhere((c) => c.id == 'Tau');
        final first = sky.stars.indexWhere(
          (s) => s.constellationIndex == taurus,
        );
        final f = figureStates(sky, pathProgress(xpToLight(first), sky));
        final elnath = sky.constellations[taurus].stars.indexWhere(
          (s) => s.hip == 25428,
        );

        expect(f.constellationIndex, taurus);
        expect(f.stars[elnath], _lit);
      });
    });
  });
}

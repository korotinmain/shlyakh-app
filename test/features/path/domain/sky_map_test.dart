import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/sky_map.dart';

import '../../../helpers/route_fixture.dart';

void main() {
  group('galacticEquator', () {
    for (final (l, ra, dec) in [
      (0.0, 266.40, -28.94), // the galactic centre, in Sagittarius
      (90.0, 318.00, 48.33), // in Cygnus
      (180.0, 86.40, 28.94), // the anticentre, near Taurus and Auriga
    ]) {
      test('puts l = $l at RA $ra, Dec $dec', () {
        final p = galacticEquator(l);

        expect(p.ra, closeTo(ra, 0.01));
        expect(p.dec, closeTo(dec, 0.01));
      });
    }
  });

  group('skyMapLayout on the bundled route', () {
    final route = testRoute();
    final layout = skyMapLayout(route, width: 390, lastVisible: 15);
    int index(String id) => route.constellations.indexWhere((c) => c.id == id);

    test('turns the chart so north is right and RA grows upwards', () {
      final low = mapPoint(layout, 300, 10);
      final north = mapPoint(layout, 300, 40);
      final east = mapPoint(layout, 330, 10);

      expect(north.x, greaterThan(low.x));
      expect(north.y, closeTo(low.y, 1e-9));
      expect(east.y, lessThan(low.y));
      expect(east.x, closeTo(low.x, 1e-9));
    });

    test('unwraps RA across 0h', () {
      final before = mapPoint(layout, 350, 0);
      final after = mapPoint(layout, 10, 0);

      expect(before.y - after.y, closeTo(20 * layout.pxPerDeg, 1e-9));
    });

    test('places every constellation inside the chart width', () {
      for (final p in layout.constellations) {
        expect(p.x, inInclusiveRange(0, 390));
        expect(p.y, inInclusiveRange(0, layout.height));
      }
    });

    test('runs the route from Sagitta at the bottom to Canis Major', () {
      final sge = layout.constellations[index('Sge')];
      final cma = layout.constellations[index('CMa')];

      expect(sge.y, greaterThan(cma.y));
    });

    test('sizes a figure by its angular span', () {
      final ori = index('Ori');

      expect(
        layout.constellations[ori].side,
        closeTo(route.constellations[ori].spanDeg * layout.pxPerDeg, 1e-9),
      );
    });

    test('fits the declinations of the route into the width', () {
      expect(layout.width, 390);
      expect(layout.pxPerDeg, greaterThan(0));
      expect(layout.height, greaterThan(layout.width));
    });
  });

  group('the Milky Way band', () {
    final route = testRoute();

    double unwrapped(double ra) => (ra - 260) % 360;

    test('covers only the visible stretch plus 20°', () {
      final layout = skyMapLayout(route, width: 390, lastVisible: 1);
      final topRa =
          [
            for (final c in route.constellations.take(2))
              unwrapped(c.centre.ra) + c.spanDeg / 2,
          ].reduce((a, b) => a > b ? a : b) +
          20;
      final top = mapPoint(layout, topRa + 260, 0).y;

      expect(layout.band, isNotEmpty);
      for (final p in layout.band) {
        expect(p.y, greaterThanOrEqualTo(top - 1e-6));
      }
    });

    test('reaches the galactic centre once the branch is visible', () {
      final layout = skyMapLayout(route, width: 390, lastVisible: 15);
      final centre = mapPoint(layout, 266.4, -28.94);

      expect(
        layout.band.any(
          (p) =>
              (p.y - centre.y).abs() < 2 * layout.pxPerDeg &&
              (p.x - centre.x).abs() < 2 * layout.pxPerDeg,
        ),
        isTrue,
      );
    });
  });
}

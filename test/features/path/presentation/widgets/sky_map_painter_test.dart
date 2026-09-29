import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/sky_map.dart';
import 'package:shlyakh/features/path/presentation/widgets/sky_map_painter.dart';

import '../../../../helpers/route_fixture.dart';

void main() {
  final route = testRoute();
  int index(String id) => route.constellations.indexWhere((c) => c.id == id);

  group('mapStarPoint', () {
    test('draws a star at its place on the sky, so a shared star is one '
        'point', () {
      final layout = skyMapLayout(route, width: 390, lastVisible: 8);
      final aur = route.constellations[index('Aur')];
      final tau = route.constellations[index('Tau')];
      final inAur = aur.stars.firstWhere((s) => s.hip == 25428);
      final inTau = tau.stars.firstWhere((s) => s.hip == 25428);

      expect(mapStarPoint(layout, inAur), mapStarPoint(layout, inTau));
      final p = mapPoint(layout, inAur.ra, inAur.dec);
      expect(mapStarPoint(layout, inAur), Offset(p.x, p.y));
    });
  });

  group('mapLabelTop', () {
    test('sits just under the lowest drawn star', () {
      final layout = skyMapLayout(route, width: 390, lastVisible: 2);
      final cyg = route.constellations[index('Cyg')];
      final lowest = cyg.stars
          .map((s) => mapStarPoint(layout, s).dy)
          .reduce((a, b) => a > b ? a : b);

      expect(mapLabelTop(layout, cyg), lowest + mapLabelGap);
    });
  });

  group('bandFade', () {
    test('fades upwards past the next constellation on the main route', () {
      final fade = bandFade(
        currentY: 500,
        lastY: 300,
        bandTop: 50,
        bandBottom: 900,
        allLit: false,
      );

      expect(fade, (from: 300.0, to: 50.0));
    });

    test('fades downwards on the branch, which lies below the main route', () {
      final fade = bandFade(
        currentY: 700,
        lastY: 800,
        bandTop: 50,
        bandBottom: 900,
        allLit: false,
      );

      expect(fade, (from: 800.0, to: 900.0));
    });

    test('does not fade once the whole route is lit', () {
      expect(
        bandFade(
          currentY: 700,
          lastY: 700,
          bandTop: 50,
          bandBottom: 900,
          allLit: true,
        ),
        isNull,
      );
    });
  });

  group('placeLabels', () {
    test('keeps labels that do not touch', () {
      const a = Rect.fromLTWH(0, 0, 100, 20);
      const b = Rect.fromLTWH(200, 0, 100, 20);

      expect(placeLabels([a, b]), [a, b]);
    });

    test('pushes an overlapping label below the one above it', () {
      const a = Rect.fromLTWH(0, 100, 100, 20);
      const b = Rect.fromLTWH(50, 110, 100, 20);

      final placed = placeLabels([b, a]);

      expect(placed[1], a);
      expect(placed[0].top, 120 + mapLabelGap);
      expect(placed[0].left, 50);
      expect(placed[0].overlaps(placed[1]), isFalse);
    });

    test('keeps pushing through a stack of labels', () {
      final placed = placeLabels([
        const Rect.fromLTWH(0, 0, 100, 20),
        const Rect.fromLTWH(0, 5, 100, 20),
        const Rect.fromLTWH(0, 10, 100, 20),
      ]);

      for (var i = 0; i < placed.length; i++) {
        for (var j = i + 1; j < placed.length; j++) {
          expect(placed[i].overlaps(placed[j]), isFalse, reason: '$i/$j');
        }
      }
    });
  });
}

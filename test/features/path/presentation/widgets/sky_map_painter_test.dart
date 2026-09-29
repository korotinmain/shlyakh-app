import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/presentation/widgets/sky_map_painter.dart';

import '../../../../helpers/small_route.dart';

void main() {
  group('mapStarPoint', () {
    const at = (x: 100.0, y: 200.0, side: 40.0);

    test('turns north to the right and east upwards', () {
      final c = testConstellation('A', [1, 2]);
      final centre = mapStarPoint((
        hip: 1,
        x: 0.5,
        y: 0.5,
        mag: 1,
        ra: 0,
        dec: 0,
      ), at);
      // y = 0 is north in the unit box; x = 0 is east.
      final north = mapStarPoint((
        hip: 1,
        x: 0.5,
        y: 0,
        mag: 1,
        ra: 0,
        dec: 0,
      ), at);
      final east = mapStarPoint((
        hip: 1,
        x: 0,
        y: 0.5,
        mag: 1,
        ra: 0,
        dec: 0,
      ), at);

      expect(c.stars, hasLength(2));
      expect(centre, const Offset(100, 200));
      expect(north, const Offset(120, 200));
      expect(east, const Offset(100, 180));
    });
  });

  group('mapLabelTop', () {
    test('sits just under the lowest drawn star', () {
      const at = (x: 100.0, y: 200.0, side: 40.0);
      final c = testConstellation('A', [1, 2]);
      // Both fixture stars are at the unit-box origin: drawn at (120, 180).

      expect(mapLabelTop(c, at), 180 + mapLabelGap);
    });
  });
}

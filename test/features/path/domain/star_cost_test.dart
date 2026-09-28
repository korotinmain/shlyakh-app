import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';

import '../../../helpers/small_route.dart';

void main() {
  group('starCost', () {
    for (final (n, cost) in [
      (1, 1500),
      (2, 3000),
      (16, 24000),
      (17, 25000),
      (100, 25000),
    ]) {
      test('star $n costs $cost XP', () => expect(starCost(n), cost));
    }

    test('rejects star 0', () {
      expect(() => starCost(0), throwsArgumentError);
    });
  });

  group('xpToLight', () {
    for (final (stars, xp) in [
      (0, 0),
      (1, 1500),
      (4, 15000),
      (16, 204000),
      (17, 229000),
      (140, 3304000),
    ]) {
      test('$stars stars need $xp XP', () => expect(xpToLight(stars), xp));
    }

    test('equals the sum of star costs', () {
      var sum = 0;
      for (var k = 1; k <= 40; k++) {
        sum += starCost(k);
        expect(xpToLight(k), sum, reason: 'k = $k');
      }
    });

    test('rejects a negative count', () {
      expect(() => xpToLight(-1), throwsArgumentError);
    });
  });

  group('pathProgress', () {
    final route = smallRoute();

    void expectProgress(
      int xp, {
      required int starsLit,
      required (int, int, int, int)? next,
    }) {
      final progress = pathProgress(xp, route);
      expect(progress.starsLit, starsLit, reason: 'starsLit at $xp XP');
      final actual = progress.next;
      expect(
        actual == null
            ? null
            : (
                actual.constellationIndex,
                actual.starInConstellation,
                actual.xpIntoStar,
                actual.xpForStar,
              ),
        next,
        reason: 'next at $xp XP',
      );
    }

    test('starts at the first star with no XP', () {
      expectProgress(0, starsLit: 0, next: (0, 0, 0, 1500));
    });

    test('keeps a star unlit 1 XP short of its cost', () {
      expectProgress(1499, starsLit: 0, next: (0, 0, 1499, 1500));
    });

    test('lights a star at exactly its cost', () {
      expectProgress(1500, starsLit: 1, next: (0, 1, 0, 3000));
    });

    test('moves to the next constellation when one is complete', () {
      expectProgress(9000, starsLit: 3, next: (1, 0, 0, 6000));
    });

    test('continues into the branch after the main route', () {
      expectProgress(15000, starsLit: 4, next: (2, 0, 0, 7500));
    });

    test('has no next star when the whole route is lit', () {
      expectProgress(22500, starsLit: 5, next: null);
      expectProgress(1000000, starsLit: 5, next: null);
    });

    test('rejects negative XP', () {
      expect(() => pathProgress(-1, route), throwsArgumentError);
    });
  });
}

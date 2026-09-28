import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/star_moment.dart';

import '../../../helpers/small_route.dart';

void main() {
  group('starMoment', () {
    final route = smallRoute();

    List<(int, int, int)> starsOf(StarMoment moment) => [
      for (final s in moment.stars)
        (s.constellationIndex, s.starInConstellation, s.hip),
    ];

    StarMoment? moment(int celebrated, int current) => starMoment(
      celebratedStars: celebrated,
      currentStars: current,
      route: route,
    );

    test('is none when no new star is lit', () {
      expect(moment(1, 1), isNull);
    });

    test('shows one new star', () {
      final m = moment(0, 1)!;

      expect(starsOf(m), [(0, 0, 1)]);
      expect(m.completedConstellations, isEmpty);
    });

    test('shows several new stars in order', () {
      expect(starsOf(moment(0, 2)!), [(0, 0, 1), (0, 1, 2)]);
    });

    test('completes the constellations it passes', () {
      final m = moment(1, 4)!;

      expect(starsOf(m), [(0, 1, 2), (0, 2, 3), (1, 0, 4)]);
      expect(m.completedConstellations, [0, 1]);
    });

    test('is none after XP went down', () {
      expect(moment(4, 2), isNull);
    });

    test('stops at the end of the route', () {
      final m = moment(0, 99)!;

      expect(m.stars, hasLength(5));
      expect(m.completedConstellations, [0, 1, 2]);
    });

    test('rejects negative counts', () {
      expect(() => moment(-1, 2), throwsArgumentError);
      expect(() => moment(0, -1), throwsArgumentError);
    });
  });
}

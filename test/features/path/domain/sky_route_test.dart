import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';

import '../../../helpers/small_route.dart';

Matcher _throwsNaming(String text) => throwsA(
  isA<RouteException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  test('RouteException describes itself with its message', () {
    expect(
      const RouteException('Sge: no stars').toString(),
      'RouteException: Sge: no stars',
    );
  });

  group('SkyRoute', () {
    test('lists every star once in lighting order', () {
      final stars = smallRoute().stars;

      expect(stars, hasLength(5));
      final flat = [
        for (final s in stars) (s.constellationIndex, s.starInConstellation),
      ];
      expect(flat, [(0, 0), (0, 1), (0, 2), (1, 0), (2, 0)]);
      expect([for (final s in stars) s.hip], [1, 2, 3, 4, 5]);
    });

    test('lights a shared star in the first constellation that has it', () {
      final route = smallRoute();

      expect(route.ownOrder(1), [1]);
      expect(route.ownerOf(3), 0);
      expect(route.ownerOf(4), 1);
    });

    test('rejects a star that is not on the route', () {
      expect(() => smallRoute().ownerOf(99), throwsArgumentError);
    });

    test('keeps the main route length', () {
      expect(smallRoute().mainLength, 2);
    });

    test('knows when a constellation is complete', () {
      final route = smallRoute();

      expect(route.isComplete(0, 3), isTrue);
      expect(route.isComplete(0, 2), isFalse);
      expect(route.isComplete(1, 3), isFalse);
      expect(route.isComplete(1, 4), isTrue);
    });

    test('follows the lighting order, not the star list', () {
      final route = SkyRoute(
        constellations: [
          testConstellation(
            'A',
            [1, 2, 3],
            lines: [(0, 1), (0, 2)],
            order: [2, 0, 1],
          ),
        ],
        mainLength: 1,
      );

      expect([for (final s in route.stars) s.hip], [3, 1, 2]);
      expect(route.ownOrder(0), [2, 0, 1]);
    });

    group('rejects', () {
      test('no constellations', () {
        expect(
          () => SkyRoute(constellations: const [], mainLength: 0),
          throwsA(isA<RouteException>()),
        );
      });

      test('a main route length of 0 or beyond the route', () {
        final list = [
          testConstellation('A', [1]),
        ];
        expect(
          () => SkyRoute(constellations: list, mainLength: 0),
          throwsA(isA<RouteException>()),
        );
        expect(
          () => SkyRoute(constellations: list, mainLength: 2),
          throwsA(isA<RouteException>()),
        );
      });

      test('a duplicate id', () {
        expect(
          () => SkyRoute(
            constellations: [
              testConstellation('A', [1]),
              testConstellation('A', [2]),
            ],
            mainLength: 2,
          ),
          _throwsNaming('A'),
        );
      });

      test('a constellation without stars', () {
        expect(
          () => SkyRoute(
            constellations: [testConstellation('Empty', const [])],
            mainLength: 1,
          ),
          _throwsNaming('Empty'),
        );
      });

      for (final (name, order) in [
        ('a missing index', [0, 1]),
        ('a duplicate index', [0, 1, 1]),
        ('an index out of range', [0, 1, 3]),
      ]) {
        test('an order with $name', () {
          expect(
            () => SkyRoute(
              constellations: [
                testConstellation('Bad', [1, 2, 3], order: order),
              ],
              mainLength: 1,
            ),
            _throwsNaming('Bad'),
          );
        });
      }

      test('a line index out of range', () {
        expect(
          () => SkyRoute(
            constellations: [
              testConstellation('Bad', [1, 2], lines: [(0, 2)]),
            ],
            mainLength: 1,
          ),
          _throwsNaming('Bad'),
        );
      });

      test('a line from a star to itself', () {
        expect(
          () => SkyRoute(
            constellations: [
              testConstellation('Bad', [1, 2], lines: [(1, 1)]),
            ],
            mainLength: 1,
          ),
          _throwsNaming('Bad'),
        );
      });

      test('a constellation whose stars were all lit earlier', () {
        expect(
          () => SkyRoute(
            constellations: [
              testConstellation('A', [1, 2]),
              testConstellation('Echo', [2, 1]),
            ],
            mainLength: 2,
          ),
          _throwsNaming('Echo'),
        );
      });
    });
  });
}

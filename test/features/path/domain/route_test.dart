import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/path/domain/route.dart';

SkyPoint _star(int hip) => (hip: hip, x: 0, y: 0, mag: 1, ra: 0, dec: 0);

Constellation _constellation(
  String id,
  List<int> hips, {
  List<(int, int)>? lines,
  List<int>? order,
}) => Constellation(
  id: id,
  stars: [for (final hip in hips) _star(hip)],
  lines: lines ?? [for (var i = 1; i < hips.length; i++) (i - 1, i)],
  order: order ?? [for (var i = 0; i < hips.length; i++) i],
  milkyWay: MilkyWay.inside,
  centre: (ra: 0, dec: 0),
  spanDeg: 1,
);

/// A (hip 1, 2, 3), B (hip 3 shared with A, 4), C (hip 5); main route A, B.
Route _fixture() => Route(
  constellations: [
    _constellation('A', [1, 2, 3]),
    _constellation('B', [3, 4]),
    _constellation('C', [5]),
  ],
  mainLength: 2,
);

Matcher _throwsNaming(String text) => throwsA(
  isA<RouteException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  group('Route', () {
    test('lists every star once in lighting order', () {
      final stars = _fixture().stars;

      expect(stars, hasLength(5));
      final flat = [
        for (final s in stars) (s.constellationIndex, s.starInConstellation),
      ];
      expect(flat, [(0, 0), (0, 1), (0, 2), (1, 0), (2, 0)]);
      expect([for (final s in stars) s.hip], [1, 2, 3, 4, 5]);
    });

    test('lights a shared star in the first constellation that has it', () {
      final route = _fixture();

      expect(route.ownOrder(1), [1]);
      expect(route.ownerOf(3), 0);
      expect(route.ownerOf(4), 1);
    });

    test('keeps the main route length', () {
      expect(_fixture().mainLength, 2);
    });

    test('knows when a constellation is complete', () {
      final route = _fixture();

      expect(route.isComplete(0, 3), isTrue);
      expect(route.isComplete(0, 2), isFalse);
      expect(route.isComplete(1, 3), isFalse);
      expect(route.isComplete(1, 4), isTrue);
    });

    test('follows the lighting order, not the star list', () {
      final route = Route(
        constellations: [
          _constellation(
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
          () => Route(constellations: const [], mainLength: 0),
          throwsA(isA<RouteException>()),
        );
      });

      test('a main route length of 0 or beyond the route', () {
        final list = [
          _constellation('A', [1]),
        ];
        expect(
          () => Route(constellations: list, mainLength: 0),
          throwsA(isA<RouteException>()),
        );
        expect(
          () => Route(constellations: list, mainLength: 2),
          throwsA(isA<RouteException>()),
        );
      });

      test('a duplicate id', () {
        expect(
          () => Route(
            constellations: [
              _constellation('A', [1]),
              _constellation('A', [2]),
            ],
            mainLength: 2,
          ),
          _throwsNaming('A'),
        );
      });

      test('a constellation without stars', () {
        expect(
          () => Route(
            constellations: [_constellation('Empty', const [])],
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
            () => Route(
              constellations: [
                _constellation('Bad', [1, 2, 3], order: order),
              ],
              mainLength: 1,
            ),
            _throwsNaming('Bad'),
          );
        });
      }

      test('a line index out of range', () {
        expect(
          () => Route(
            constellations: [
              _constellation('Bad', [1, 2], lines: [(0, 2)]),
            ],
            mainLength: 1,
          ),
          _throwsNaming('Bad'),
        );
      });

      test('a line from a star to itself', () {
        expect(
          () => Route(
            constellations: [
              _constellation('Bad', [1, 2], lines: [(1, 1)]),
            ],
            mainLength: 1,
          ),
          _throwsNaming('Bad'),
        );
      });

      test('a constellation whose stars were all lit earlier', () {
        expect(
          () => Route(
            constellations: [
              _constellation('A', [1, 2]),
              _constellation('Echo', [2, 1]),
            ],
            mainLength: 2,
          ),
          _throwsNaming('Echo'),
        );
      });
    });
  });
}

import 'package:shlyakh/features/path/domain/sky_route.dart';

SkyPoint _star(int hip) => (hip: hip, x: 0, y: 0, mag: 1, ra: 0, dec: 0);

/// A constellation with stars [hips], lines along the list and the list
/// order as its lighting order unless given.
Constellation testConstellation(
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

/// Five route stars: A (hip 1, 2, 3), B (hip 3 shared with A, 4), then the
/// branch C (hip 5). Cumulative star costs: 1 500, 4 500, 9 000, 15 000,
/// 22 500 XP.
SkyRoute smallRoute() => SkyRoute(
  constellations: [
    testConstellation('A', [1, 2, 3]),
    testConstellation('B', [3, 4]),
    testConstellation('C', [5]),
  ],
  mainLength: 2,
);

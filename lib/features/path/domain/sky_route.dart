// The constellation route: real constellations in a fixed order along the
// Milky Way (docs/superpowers/specs/2026-09-28-constellation-path-design.md).

/// The route data is inconsistent. The message names the constellation.
class RouteException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'RouteException: $message';
}

/// Where a constellation lies relative to the Milky Way band.
enum MilkyWay { inside, edge }

/// A figure star: HIP id, position in the constellation's unit box
/// (north up, east left), visual magnitude and J2000 RA/Dec in degrees.
typedef SkyPoint = ({
  int hip,
  double x,
  double y,
  double mag,
  double ra,
  double dec,
});

/// A star on the route: its constellation, its position among the stars
/// that constellation lights itself (0-based), and its HIP id.
typedef RouteStar = ({
  int constellationIndex,
  int starInConstellation,
  int hip,
});

/// One constellation of the route with its standard figure.
final class Constellation {
  const new({
    required this.id,
    required this.stars,
    required this.lines,
    required this.order,
    required this.milkyWay,
    required this.centre,
    required this.spanDeg,
  });

  /// IAU abbreviation, e.g. `Sge`.
  final String id;

  /// Every figure star, including ones another constellation lights.
  final List<SkyPoint> stars;

  /// Figure segments as index pairs into [stars].
  final List<(int, int)> lines;

  /// Lighting order: every index into [stars] once.
  final List<int> order;

  final MilkyWay milkyWay;

  /// Centre on the sky, degrees.
  final ({double ra, double dec}) centre;

  /// Largest angular distance between two of its stars, degrees.
  final double spanDeg;
}

/// The whole route: the main route followed by the branch.
///
/// A star that is in two figures (Elnath in Auriga and Taurus) lights once,
/// in the first constellation on the route that has it.
final class SkyRoute {
  /// Throws [RouteException] when the data is inconsistent.
  factory({
    required List<Constellation> constellations,
    required int mainLength,
  }) {
    if (constellations.isEmpty) {
      throw const RouteException('the route has no constellations');
    }
    if (mainLength < 1 || mainLength > constellations.length) {
      throw RouteException(
        'main route length $mainLength is outside 1..${constellations.length}',
      );
    }
    final ids = <String>{};
    final lit = <int, int>{};
    final ownOrders = <List<int>>[];
    final stars = <RouteStar>[];
    for (final (index, c) in constellations.indexed) {
      if (!ids.add(c.id)) throw RouteException('${c.id}: duplicate id');
      _validate(c);
      final own = <int>[];
      for (final starIndex in c.order) {
        final hip = c.stars[starIndex].hip;
        if (lit.containsKey(hip)) continue;
        lit[hip] = index;
        stars.add((
          constellationIndex: index,
          starInConstellation: own.length,
          hip: hip,
        ));
        own.add(starIndex);
      }
      if (own.isEmpty) {
        throw RouteException('${c.id}: every star is lit by an earlier one');
      }
      ownOrders.add(List.unmodifiable(own));
    }
    return SkyRoute._(
      List.unmodifiable(constellations),
      mainLength,
      List.unmodifiable(stars),
      List.unmodifiable(ownOrders),
      Map.unmodifiable(lit),
    );
  }

  const new _(
    this.constellations,
    this.mainLength,
    this.stars,
    this._ownOrders,
    this._owners,
  );

  /// Main route first, then the branch.
  final List<Constellation> constellations;

  /// How many of [constellations] form the main route.
  final int mainLength;

  /// Every star of the route in lighting order, each HIP once.
  final List<RouteStar> stars;

  final List<List<int>> _ownOrders;
  final Map<int, int> _owners;

  /// Indices into the constellation's `stars` that it lights itself, in
  /// its lighting order.
  List<int> ownOrder(int constellationIndex) => _ownOrders[constellationIndex];

  /// Index of the constellation that lights the star [hip].
  ///
  /// Throws [ArgumentError] for a star not on the route.
  int ownerOf(int hip) =>
      _owners[hip] ?? (throw ArgumentError.value(hip, 'hip', 'not on route'));

  /// Whether the constellation is complete once [starsLit] route stars
  /// are lit.
  bool isComplete(int constellationIndex, int starsLit) {
    var before = 0;
    for (var i = 0; i <= constellationIndex; i++) {
      before += _ownOrders[i].length;
    }
    return starsLit >= before;
  }

  static void _validate(Constellation c) {
    final count = c.stars.length;
    if (count == 0) throw RouteException('${c.id}: no stars');
    final seen = <int>{};
    for (final i in c.order) {
      if (i < 0 || i >= count || !seen.add(i)) {
        throw RouteException('${c.id}: bad lighting order ${c.order}');
      }
    }
    if (seen.length != count) {
      throw RouteException('${c.id}: the lighting order misses stars');
    }
    for (final (a, b) in c.lines) {
      if (a < 0 || a >= count || b < 0 || b >= count || a == b) {
        throw RouteException('${c.id}: bad line ($a, $b)');
      }
    }
  }
}

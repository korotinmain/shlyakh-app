// Pure functions for building the route asset from d3-celestial data
// (docs/decisions/0009-sky-data.md). No I/O here; see build_route.dart.
import 'dart:convert';
import 'dart:math';

/// The sky data cannot be built: a vertex has no catalogue star, a figure
/// is missing or not connected. The message names what failed.
class SkyDataException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SkyDataException: $message';
}

/// A catalogue star: HIP id, right ascension and declination in degrees
/// (ra 0–360), visual magnitude.
typedef SkyStar = ({int hip, double ra, double dec, double mag});

/// A constellation figure: its distinct stars, the segments between them
/// (indices into `stars`) and the order the stars first appear when the
/// polylines are walked as stored.
typedef Figure = ({
  List<SkyStar> stars,
  List<(int, int)> lines,
  List<int> lightingOrder,
});

/// Constellation id → polylines of (lon, lat) vertices, as d3-celestial
/// stores them (lon −180…180).
Map<String, List<List<(double, double)>>> parseFigures(String geoJson) {
  final features = (jsonDecode(geoJson) as Map)['features'] as List;
  return {
    for (final feature in features.cast<Map<String, Object?>>())
      feature['id']! as String: [
        for (final line
            in ((feature['geometry']! as Map)['coordinates']! as List)
                .cast<List<Object?>>())
          [for (final point in line.cast<List<Object?>>()) _point(point)],
      ],
  };
}

/// Every star of a d3-celestial `stars.*.json` file.
List<SkyStar> parseStars(String geoJson) {
  final features = (jsonDecode(geoJson) as Map)['features'] as List;
  return [
    for (final feature in features.cast<Map<String, Object?>>()) _star(feature),
  ];
}

SkyStar _star(Map<String, Object?> feature) {
  final (lon, lat) = _point(
    (feature['geometry']! as Map)['coordinates']! as List<Object?>,
  );
  final mag = ((feature['properties']! as Map)['mag']! as num).toDouble();
  return (
    hip: (feature['id']! as num).toInt(),
    ra: _ra(lon),
    dec: lat,
    mag: mag,
  );
}

(double, double) _point(List<Object?> point) =>
    ((point[0]! as num).toDouble(), (point[1]! as num).toDouble());

double _ra(double lon) => lon < 0 ? lon + 360 : lon;

/// The catalogue star nearest to a figure [vertex] (lon, lat).
///
/// Throws [SkyDataException] when none is within [toleranceDeg]: the build must
/// never guess a star.
SkyStar matchStar(
  (double, double) vertex,
  List<SkyStar> stars, {
  double toleranceDeg = 0.05,
}) {
  final ra = _ra(vertex.$1);
  final dec = vertex.$2;
  SkyStar? best;
  var bestDistance = double.infinity;
  for (final star in stars) {
    final distance = _angularDistance(ra, dec, star.ra, star.dec);
    if (distance < bestDistance) {
      best = star;
      bestDistance = distance;
    }
  }
  if (best == null || bestDistance > toleranceDeg) {
    throw SkyDataException('no star within $toleranceDeg° of ($ra, $dec)');
  }
  return best;
}

/// The figure for [polylines]: stars deduped by HIP, each segment once.
Figure buildFigure(
  List<List<(double, double)>> polylines,
  List<SkyStar> catalogue,
) {
  final stars = <SkyStar>[];
  final indexByHip = <int, int>{};
  final lines = <(int, int)>[];
  final seen = <(int, int)>{};
  for (final line in polylines) {
    int? previous;
    for (final vertex in line) {
      final star = matchStar(vertex, catalogue);
      final index = indexByHip.putIfAbsent(star.hip, () {
        stars.add(star);
        return stars.length - 1;
      });
      if (previous != null && previous != index) {
        final key = previous < index ? (previous, index) : (index, previous);
        if (seen.add(key)) lines.add(key);
      }
      previous = index;
    }
  }
  return (stars: stars, lines: lines, lightingOrder: _walk(stars, lines));
}

/// Star indices in the order they light: from the first star, each next
/// star is the first one, in stored line order, joined by a line to a star
/// already lit, so every new star draws a line from the figure.
///
/// Throws [SkyDataException] when the figure is not connected.
List<int> _walk(List<SkyStar> stars, List<(int, int)> lines) {
  if (stars.isEmpty) return const [];
  final lit = <int>{0};
  final order = <int>[0];
  while (order.length < stars.length) {
    int? next;
    for (final (a, b) in lines) {
      if (lit.contains(a) != lit.contains(b)) {
        next = lit.contains(a) ? b : a;
        break;
      }
    }
    if (next == null) {
      throw const SkyDataException('the figure is not connected');
    }
    lit.add(next);
    order.add(next);
  }
  return order;
}

/// A route constellation: its figure, where it sits on the sky (the
/// centre, degrees) and its angular size (the largest distance between two
/// of its stars, degrees).
typedef RouteConstellation = ({
  Figure figure,
  ({double ra, double dec}) centre,
  double spanDeg,
});

/// The figures of [ids], each checked and measured. A failure names the
/// constellation: `SkyDataException('<id>: …')`.
Map<String, RouteConstellation> buildRoute(
  Map<String, List<List<(double, double)>>> figures,
  List<SkyStar> catalogue,
  List<String> ids,
) => {for (final id in ids) id: _constellation(id, figures, catalogue)};

RouteConstellation _constellation(
  String id,
  Map<String, List<List<(double, double)>>> figures,
  List<SkyStar> catalogue,
) {
  final polylines = figures[id];
  if (polylines == null) throw SkyDataException('$id: no figure');
  final Figure figure;
  try {
    figure = buildFigure(polylines, catalogue);
  } on SkyDataException catch (e) {
    throw SkyDataException('$id: ${e.message}');
  }
  final stars = figure.stars;
  final centre = _normalize(
    stars
        .map((s) => _unit(s.ra, s.dec))
        .reduce((a, b) => (a.$1 + b.$1, a.$2 + b.$2, a.$3 + b.$3)),
  );
  var span = 0.0;
  for (final a in stars) {
    for (final b in stars) {
      span = max(span, _angularDistance(a.ra, a.dec, b.ra, b.dec));
    }
  }
  final ra = atan2(centre.$2, centre.$1) * 180 / pi;
  return (
    figure: figure,
    centre: (
      ra: _round(ra < 0 ? ra + 360 : ra),
      dec: _round(asin(centre.$3) * 180 / pi),
    ),
    spanDeg: _round(span),
  );
}

/// Screen positions of [stars] in a unit box: gnomonic projection around
/// the figure's centre, north up and east to the left (as seen on the
/// sky), scaled so the larger side spans 0–1 and the smaller is centred.
/// Rounded to 4 decimals for a stable asset.
List<(double, double)> project(List<SkyStar> stars) {
  final vectors = [for (final s in stars) _unit(s.ra, s.dec)];
  final centre = _normalize(
    vectors.reduce((a, b) => (a.$1 + b.$1, a.$2 + b.$2, a.$3 + b.$3)),
  );
  final east = _normalize(_cross((0, 0, 1), centre));
  final north = _cross(centre, east);
  final raw = [
    for (final v in vectors)
      (-_dot(v, east) / _dot(v, centre), -_dot(v, north) / _dot(v, centre)),
  ];
  final xs = raw.map((p) => p.$1);
  final ys = raw.map((p) => p.$2);
  final minX = xs.reduce(min);
  final minY = ys.reduce(min);
  final width = xs.reduce(max) - minX;
  final height = ys.reduce(max) - minY;
  final span = max(width, height);
  final offsetX = (1 - width / span) / 2;
  final offsetY = (1 - height / span) / 2;
  return [
    for (final (x, y) in raw)
      (
        _round((x - minX) / span + offsetX),
        _round((y - minY) / span + offsetY),
      ),
  ];
}

double _round(double value) => (value * 10000).round() / 10000;

typedef _Vec = (double, double, double);

_Vec _unit(double raDeg, double decDeg) {
  final ra = raDeg * pi / 180;
  final dec = decDeg * pi / 180;
  return (cos(dec) * cos(ra), cos(dec) * sin(ra), sin(dec));
}

double _dot(_Vec a, _Vec b) => a.$1 * b.$1 + a.$2 * b.$2 + a.$3 * b.$3;

_Vec _cross(_Vec a, _Vec b) => (
  a.$2 * b.$3 - a.$3 * b.$2,
  a.$3 * b.$1 - a.$1 * b.$3,
  a.$1 * b.$2 - a.$2 * b.$1,
);

_Vec _normalize(_Vec v) {
  final length = sqrt(_dot(v, v));
  return (v.$1 / length, v.$2 / length, v.$3 / length);
}

double _angularDistance(double ra1, double dec1, double ra2, double dec2) {
  final a = _unit(ra1, dec1);
  final b = _unit(ra2, dec2);
  return acos(_dot(a, b).clamp(-1.0, 1.0)) * 180 / pi;
}

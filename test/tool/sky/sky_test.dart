import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/sky/sky.dart';

// Two figures in d3-celestial's shape: "Aaa" is A-B-C plus B-D; "Zer"
// straddles 0h (lon -1 and +1).
const _lines = '''
{"type": "FeatureCollection", "features": [
  {"type": "Feature", "id": "Aaa", "properties": {"rank": "1"},
   "geometry": {"type": "MultiLineString", "coordinates": [
     [[10.0, 20.0], [12.0, 21.0], [14.0, 23.0]],
     [[12.0, 21.0], [11.0, 25.0]]]}},
  {"type": "Feature", "id": "Zer", "properties": {"rank": "1"},
   "geometry": {"type": "MultiLineString", "coordinates": [
     [[-1.0, 10.0], [1.0, 10.0]]]}}
]}
''';

const _stars = '''
{"type": "FeatureCollection", "features": [
  {"type": "Feature", "id": 1, "properties": {"mag": 1.5, "bv": "0.1"},
   "geometry": {"type": "Point", "coordinates": [10.0, 20.0]}},
  {"type": "Feature", "id": 2, "properties": {"mag": 2.5, "bv": "0.1"},
   "geometry": {"type": "Point", "coordinates": [12.005, 21.0]}},
  {"type": "Feature", "id": 3, "properties": {"mag": 3.5, "bv": "0.1"},
   "geometry": {"type": "Point", "coordinates": [14.0, 23.0]}},
  {"type": "Feature", "id": 4, "properties": {"mag": 4.0, "bv": "0.1"},
   "geometry": {"type": "Point", "coordinates": [11.0, 25.0]}},
  {"type": "Feature", "id": 5, "properties": {"mag": 2.0, "bv": "0.1"},
   "geometry": {"type": "Point", "coordinates": [-1.0, 10.0]}},
  {"type": "Feature", "id": 6, "properties": {"mag": 2.0, "bv": "0.1"},
   "geometry": {"type": "Point", "coordinates": [1.0, 10.0]}}
]}
''';

void main() {
  final catalogue = parseStars(_stars);
  final figures = parseFigures(_lines);

  test('parseFigures reads every figure and its polylines', () {
    expect(figures.keys, unorderedEquals(['Aaa', 'Zer']));
    expect(figures['Aaa'], hasLength(2));
    expect(figures['Aaa']!.first, [(10.0, 20.0), (12.0, 21.0), (14.0, 23.0)]);
  });

  test('parseStars converts negative longitudes to right ascension', () {
    final star = catalogue.firstWhere((s) => s.hip == 5);
    expect(star.ra, 359.0);
    expect(star.dec, 10.0);
    expect(star.mag, 2.0);
  });

  test('matchStar finds the nearest star within the tolerance', () {
    expect(matchStar((12.0, 21.0), catalogue).hip, 2);
  });

  test('matchStar fails when no star is close enough', () {
    expect(() => matchStar((30.0, 40.0), catalogue), throwsStateError);
  });

  test('buildFigure dedupes stars and keeps each segment once', () {
    final figure = buildFigure(figures['Aaa']!, catalogue);

    expect(figure.stars.map((s) => s.hip), [1, 2, 3, 4]);
    expect(figure.lines, unorderedEquals([(0, 1), (1, 2), (1, 3)]));
    expect(figure.lightingOrder, [0, 1, 2, 3]);
  });

  test('a repeated vertex is one star', () {
    final figure = buildFigure([
      [(10.0, 20.0), (12.0, 21.0)],
      [(12.0, 21.0), (10.0, 20.0)],
    ], catalogue);

    expect(figure.stars, hasLength(2));
    expect(figure.lines, [(0, 1)]);
  });

  test('project keeps a figure across 0h contiguous', () {
    final stars = buildFigure(figures['Zer']!, catalogue).stars;
    final points = project(stars);

    expect(points, hasLength(2));
    // Two degrees apart on the sky: the whole box width, not wrapped.
    expect((points[0].$1 - points[1].$1).abs(), closeTo(1, 1e-3));
  });

  test('project puts east on the left, north up, inside the unit box', () {
    final stars = buildFigure(figures['Aaa']!, catalogue).stars;
    final points = project(stars);

    for (final (x, y) in points) {
      expect(x, inInclusiveRange(0, 1));
      expect(y, inInclusiveRange(0, 1));
    }
    // Star 3 (ra 14) is east of star 1 (ra 10): smaller x.
    expect(points[2].$1, lessThan(points[0].$1));
    // Star 4 (dec 25) is north of star 1 (dec 20): smaller y (screen up).
    expect(points[3].$2, lessThan(points[0].$2));
    expect(points.map((p) => max(p.$1, p.$2)).reduce(max), closeTo(1, 1e-3));
  });
}

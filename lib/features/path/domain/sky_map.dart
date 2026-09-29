// Geometry of the Milky Way map
// (docs/superpowers/specs/2026-09-28-constellation-path-design.md, "Path").
// A plate carrée star chart turned 90° clockwise: north is to the right and
// right ascension grows upwards, so the route climbs the screen from
// Sagitta. A rotation, not a mirror: shapes keep their handedness.
import 'dart:math' as math;

import 'package:shlyakh/features/path/domain/sky_route.dart';

/// North galactic pole and the galactic longitude of the north celestial
/// pole, J2000, degrees.
const _poleRa = 192.85948;
const _poleDec = 27.12825;
const _ncpLongitude = 122.93192;

/// RA that sits at the bottom of the unwrapped axis: the route (RA about
/// 280° to 115°) never crosses it.
const _raOrigin = 260;

/// Margin around the chart, pixels.
const double _margin = 24;

/// Band samples: every 2° of galactic longitude, and how far past the
/// visible constellations the band runs.
const _bandStep = 2;
const _bandPastVisible = 20;

/// The point of the galactic equator at galactic longitude [l], in
/// equatorial J2000 degrees (RA 0–360).
({double ra, double dec}) galacticEquator(double l) {
  const toRad = math.pi / 180;
  const poleDec = _poleDec * toRad;
  final d = (_ncpLongitude - l) * toRad;
  final dec = math.asin(math.cos(poleDec) * math.cos(d));
  final ra =
      _poleRa +
      math.atan2(math.sin(d), -math.sin(poleDec) * math.cos(d)) / toRad;
  return (ra: ra % 360, dec: dec / toRad);
}

/// Where a figure goes on the chart: its centre and the side of its
/// square, pixels from the chart's top left.
typedef MapPlacement = ({double x, double y, double side});

/// The chart for a width: its scale, its height, one placement per route
/// constellation and the band's centre line. `decMin` and `raTop` (RA
/// unwrapped from 260°) anchor [mapPoint].
typedef SkyMapLayout = ({
  double width,
  double height,
  double pxPerDeg,
  double decMin,
  double raTop,
  List<MapPlacement> constellations,
  List<({double x, double y})> band,
});

double _unwrap(double ra) => (ra - _raOrigin) % 360;

/// The chart of [route] fitted to [width]; the band covers the stretch of
/// constellations `0 … lastVisible` and 20° beyond either end, so with the
/// branch open it reaches the galactic centre.
SkyMapLayout skyMapLayout(
  SkyRoute route, {
  required double width,
  required int lastVisible,
}) {
  final all = route.constellations;
  double lo(Constellation c, double v) => v - c.spanDeg / 2;
  double hi(Constellation c, double v) => v + c.spanDeg / 2;
  final decMin = all.map((c) => lo(c, c.centre.dec)).reduce(math.min);
  final decMax = all.map((c) => hi(c, c.centre.dec)).reduce(math.max);
  final raBottom = all.map((c) => lo(c, _unwrap(c.centre.ra))).reduce(math.min);
  final raTop = all.map((c) => hi(c, _unwrap(c.centre.ra))).reduce(math.max);
  final pxPerDeg = (width - 2 * _margin) / (decMax - decMin);
  final height = (raTop - raBottom) * pxPerDeg + 2 * _margin;

  ({double x, double y}) at(double unwrappedRa, double dec) => (
    x: _margin + (dec - decMin) * pxPerDeg,
    y: _margin + (raTop - unwrappedRa) * pxPerDeg,
  );

  final visible = all.take(lastVisible + 1);
  final bandLo =
      visible.map((c) => lo(c, _unwrap(c.centre.ra))).reduce(math.min) -
      _bandPastVisible;
  final bandHi =
      visible.map((c) => hi(c, _unwrap(c.centre.ra))).reduce(math.max) +
      _bandPastVisible;
  final band = <({double x, double y})>[];
  // Over this range of longitude the unwrapped RA grows with l.
  for (var l = -90; l <= 270; l += _bandStep) {
    final p = galacticEquator(l.toDouble());
    final u = _unwrap(p.ra);
    if (u >= bandLo && u <= bandHi) band.add(at(u, p.dec));
  }

  return (
    width: width,
    height: height,
    pxPerDeg: pxPerDeg,
    decMin: decMin,
    raTop: raTop,
    constellations: [
      for (final c in all)
        (
          x: at(_unwrap(c.centre.ra), c.centre.dec).x,
          y: at(_unwrap(c.centre.ra), c.centre.dec).y,
          side: c.spanDeg * pxPerDeg,
        ),
    ],
    band: List.unmodifiable(band),
  );
}

/// The chart position of the sky point [ra], [dec] (degrees).
({double x, double y}) mapPoint(SkyMapLayout layout, double ra, double dec) => (
  x: _margin + (dec - layout.decMin) * layout.pxPerDeg,
  y: _margin + (layout.raTop - _unwrap(ra)) * layout.pxPerDeg,
);

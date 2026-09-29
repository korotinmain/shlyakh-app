import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/features/path/domain/path_pages.dart';
import 'package:shlyakh/features/path/domain/sky_map.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/presentation/providers/path_view.dart';
import 'package:shlyakh/features/today/presentation/widgets/constellation_figure.dart';

/// The band's width on the sky, its opacity and blur (docs/DESIGN.md,
/// "Map").
const double _bandWidthDeg = 20;
const double _bandOpacity = 0.12;
const double _bandBlurSigma = 12;

/// Where [star] lands on the chart: at its own RA and Dec, so a star in
/// two figures (Elnath) is one point and every figure has its true size.
Offset mapStarPoint(SkyMapLayout layout, SkyPoint star) {
  final p = mapPoint(layout, star.ra, star.dec);
  return Offset(p.x, p.y);
}

/// Gap between a constellation's lowest star and its name, and between
/// names pushed apart, pixels.
const double mapLabelGap = 6;

/// Where the name of [constellation] starts: just under its lowest drawn
/// star.
double mapLabelTop(SkyMapLayout layout, Constellation constellation) =>
    constellation.stars
        .map((star) => mapStarPoint(layout, star).dy)
        .reduce((a, b) => a > b ? a : b) +
    mapLabelGap;

/// [labels] moved down, top to bottom, until none overlaps another; the
/// result keeps the input order.
List<Rect> placeLabels(List<Rect> labels) {
  final order = [for (var i = 0; i < labels.length; i++) i]
    ..sort((a, b) => labels[a].top.compareTo(labels[b].top));
  final placed = List<Rect>.of(labels);
  final done = <int>[];
  for (final i in order) {
    var rect = labels[i];
    var moved = true;
    while (moved) {
      moved = false;
      for (final j in done) {
        if (rect.overlaps(placed[j])) {
          rect = rect.translate(0, placed[j].bottom + mapLabelGap - rect.top);
          moved = true;
        }
      }
    }
    placed[i] = rect;
    done.add(i);
  }
  return placed;
}

/// The band's fog: opaque at [lastY] (the last constellation out of the
/// fog) fading to nothing at the band's end beyond it, away from the
/// current constellation at [currentY]. Null once every star is lit.
({double from, double to})? bandFade({
  required double currentY,
  required double lastY,
  required double bandTop,
  required double bandBottom,
  required bool allLit,
}) {
  if (allLit) return null;
  // The main route climbs the chart; the branch lies below it.
  return (from: lastY, to: lastY <= currentY ? bandTop : bandBottom);
}

/// The Milky Way chart: the band fading into the fog past the next
/// constellation, and the figures of the visible pages.
class SkyMapPainter extends CustomPainter {
  new({required this.layout, required this.view, required this.palette});

  final SkyMapLayout layout;
  final PathView view;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    _band(canvas, size);
    // Done first, then the current one, then the next one on top.
    final order = [
      ...view.pages.where((p) => p.state == PageState.done),
      ...view.pages.where((p) => p.state == PageState.current),
      ...view.pages.where((p) => p.state == PageState.ahead),
    ];
    for (final page in order) {
      paintFigure(
        canvas,
        constellation: page.constellation,
        figure: page.figure,
        palette: palette,
        done: page.state == PageState.done,
        points: [
          for (final star in page.constellation.stars)
            mapStarPoint(layout, star),
        ],
      );
    }
  }

  void _band(Canvas canvas, Size size) {
    final points = layout.band;
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.x, points.first.y);
    for (final p in points.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    final color = palette.onSkyMuted.withValues(alpha: _bandOpacity);
    double yOf(Constellation c) =>
        layout.constellations[view.route.constellations.indexOf(c)].y;
    final ys = points.map((p) => p.y);
    final fade = bandFade(
      currentY: yOf(view.pages[view.currentPage].constellation),
      lastY: yOf(view.pages.last.constellation),
      bandTop: ys.reduce((a, b) => a < b ? a : b),
      bandBottom: ys.reduce((a, b) => a > b ? a : b),
      allLit: view.progress.next == null,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _bandWidthDeg * layout.pxPerDeg
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _bandBlurSigma);
    if (fade == null) {
      paint.color = color;
    } else {
      paint.shader = ui.Gradient.linear(
        Offset(0, fade.from),
        Offset(0, fade.to),
        [color, color.withValues(alpha: 0)],
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SkyMapPainter oldDelegate) =>
      !identical(oldDelegate.view, view) ||
      !identical(oldDelegate.palette, palette) ||
      oldDelegate.layout.width != layout.width;
}

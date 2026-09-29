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

/// Where [star] of a constellation placed at [at] lands on the chart: its
/// unit box (north up, east left) turned 90° clockwise, like the chart.
Offset mapStarPoint(SkyPoint star, MapPlacement at) {
  final u = (star.x - 0.5) * at.side;
  final v = (star.y - 0.5) * at.side;
  return Offset(at.x - v, at.y + u);
}

/// Gap between a constellation's lowest star and its name, pixels.
const double mapLabelGap = 6;

/// Where the name of [constellation] placed at [at] starts: just under its
/// lowest drawn star, so neighbours' names do not stack under empty boxes.
double mapLabelTop(Constellation constellation, MapPlacement at) =>
    constellation.stars
        .map((star) => mapStarPoint(star, at).dy)
        .reduce((a, b) => a > b ? a : b) +
    mapLabelGap;

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
      final index = view.route.constellations.indexOf(page.constellation);
      final at = layout.constellations[index];
      paintFigure(
        canvas,
        constellation: page.constellation,
        figure: page.figure,
        palette: palette,
        done: page.state == PageState.done,
        points: [
          for (final star in page.constellation.stars) mapStarPoint(star, at),
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
    // Fog: the band fades out from the last visible constellation to the
    // band's upper end.
    final last =
        layout.constellations[view.route.constellations.indexOf(
          view.pages.last.constellation,
        )];
    final top = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _bandWidthDeg * layout.pxPerDeg
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _bandBlurSigma)
        ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, last.y), [
          color.withValues(alpha: 0),
          color,
        ]),
    );
  }

  @override
  bool shouldRepaint(SkyMapPainter oldDelegate) =>
      !identical(oldDelegate.view, view) ||
      !identical(oldDelegate.palette, palette) ||
      oldDelegate.layout.width != layout.width;
}

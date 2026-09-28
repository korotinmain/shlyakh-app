import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/path/domain/figure_state.dart';
import 'package:shlyakh/features/path/domain/sky_route.dart';
import 'package:shlyakh/features/path/presentation/providers/constellation_name.dart';

// Sizes of the figure in logical pixels (docs/DESIGN.md, "Constellation
// figure").
const double _padding = 24;
const double _solidStroke = 1;
const double _dashedStroke = 0.8;
const double _dash = 2;
const double _gap = 4;
const double _aheadRadius = 3;
const double _aheadStroke = 0.8;
const double _glowFactor = 3;

// The static marker; plan 6 animates it through Rive.
const double _markerCore = 3.2;
const double _markerRing = 9;
const double _markerRingStroke = 0.8;
const double _markerRingDash = 40;
const double _markerRingGap = 16.5;
const double _markerSpike = 16;
const double _markerSpikeStroke = 0.7;
const double _markerDisc = 16;
const double _markerRingAlpha = 0.6;
const double _markerSpikeAlpha = 0.5;
const double _markerDiscAlpha = 0.12;

/// Below this height the name is left out and only the figure is drawn.
const double _minHeightForName = 64;

/// Where [star] (in its unit box) lands in [zone]: the unit box is fitted
/// into the largest square that leaves [_padding] on each side, centred.
@visibleForTesting
Offset figurePoint(SkyPoint star, Rect zone) {
  final side = math.min(zone.width, zone.height) - 2 * _padding;
  final left = zone.left + (zone.width - side) / 2;
  final top = zone.top + (zone.height - side) / 2;
  return Offset(left + star.x * side, top + star.y * side);
}

/// Core radius of a star of visual magnitude [mag]: brighter is larger.
double _coreRadius(double mag) => (3.5 - 0.5 * mag).clamp(1.5, 3.5);

/// The current constellation on the sky: lit stars, the current star's
/// marker, rings for the stars ahead, solid lines behind and dashed lines
/// ahead, with its name below.
class ConstellationFigure extends StatelessWidget {
  const new({required this.constellation, required this.figure, super.key});

  final Constellation constellation;
  final FigureStates figure;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = constellationName(context.l10n, constellation.id);
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight <= 0) return const SizedBox.shrink();
          final painter = CustomPaint(
            painter: _FigurePainter(constellation, figure, palette),
            size: Size.infinite,
          );
          if (constraints.maxHeight < _minHeightForName) return painter;
          return Column(
            children: [
              Expanded(child: painter),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: Text(
                  name,
                  style: AppTypography.footnote.copyWith(
                    color: palette.onSkyMuted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  new(this.constellation, this.figure, this.palette);

  final Constellation constellation;
  final FigureStates figure;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final zone = Offset.zero & size;
    if (math.min(size.width, size.height) - 2 * _padding <= 0) return;
    final points = [
      for (final star in constellation.stars) figurePoint(star, zone),
    ];

    final dashed = Paint()
      ..color = palette.aheadLine
      ..strokeWidth = _dashedStroke
      ..style = PaintingStyle.stroke;
    final solid = Paint()
      ..color = palette.starLine
      ..strokeWidth = _solidStroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final (i, (a, b)) in constellation.lines.indexed) {
      if (!figure.solidLines[i]) {
        _dashedLine(canvas, points[a], points[b], dashed);
      }
    }
    for (final (i, (a, b)) in constellation.lines.indexed) {
      if (figure.solidLines[i]) canvas.drawLine(points[a], points[b], solid);
    }

    final glow = Paint()..color = palette.starGlow;
    final core = Paint()..color = palette.star;
    final ahead = Paint()
      ..color = palette.starAhead
      ..strokeWidth = _aheadStroke
      ..style = PaintingStyle.stroke;
    for (final (i, state) in figure.stars.indexed) {
      final radius = _coreRadius(constellation.stars[i].mag);
      if (state == StarState.lit) {
        canvas.drawCircle(points[i], radius * _glowFactor, glow);
      }
    }
    for (final (i, state) in figure.stars.indexed) {
      final radius = _coreRadius(constellation.stars[i].mag);
      switch (state) {
        case StarState.lit:
          canvas.drawCircle(points[i], radius, core);
        case StarState.ahead:
          canvas.drawCircle(points[i], _aheadRadius, ahead);
        case StarState.current:
          break;
      }
    }
    for (final (i, state) in figure.stars.indexed) {
      if (state == StarState.current) _marker(canvas, points[i]);
    }
  }

  void _marker(Canvas canvas, Offset at) {
    final marker = palette.marker;
    canvas.drawCircle(
      at,
      _markerDisc,
      Paint()..color = marker.withValues(alpha: _markerDiscAlpha),
    );
    final spike = Paint()
      ..color = marker.withValues(alpha: _markerSpikeAlpha)
      ..strokeWidth = _markerSpikeStroke;
    canvas
      ..drawLine(
        at.translate(-_markerSpike, 0),
        at.translate(_markerSpike, 0),
        spike,
      )
      ..drawLine(
        at.translate(0, -_markerSpike),
        at.translate(0, _markerSpike),
        spike,
      );
    // The ring with one gap: an arc covering dash / (dash + gap) of it.
    const sweep =
        2 * math.pi * _markerRingDash / (_markerRingDash + _markerRingGap);
    canvas
      ..drawArc(
        Rect.fromCircle(center: at, radius: _markerRing),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = marker.withValues(alpha: _markerRingAlpha)
          ..strokeWidth = _markerRingStroke
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      )
      ..drawCircle(at, _markerCore, Paint()..color = palette.star);
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final length = (to - from).distance;
    if (length == 0) return;
    final step = (to - from) / length;
    for (var d = 0.0; d < length; d += _dash + _gap) {
      final end = math.min(d + _dash, length);
      canvas.drawLine(from + step * d, from + step * end, paint);
    }
  }

  @override
  bool shouldRepaint(_FigurePainter oldDelegate) =>
      !identical(oldDelegate.constellation, constellation) ||
      !identical(oldDelegate.figure, figure) ||
      !identical(oldDelegate.palette, palette);
}

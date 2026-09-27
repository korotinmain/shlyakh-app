import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

/// One grain dot per cell of this size, in logical pixels.
const double _cellSize = 3;

/// Fixed seed: the same grain on every frame and every launch.
const int _seed = 0x6EA1;

/// A static film grain of light and dark dots at [opacity].
class Grain extends StatelessWidget {
  const new({required this.opacity, super.key});

  final double opacity;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _GrainPainter(opacity), size: Size.infinite),
  );
}

class _GrainPainter extends CustomPainter {
  new(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    var state = _seed;
    int next() => state = (1103515245 * state + 12345) & 0x7FFFFFFF;

    final light = <Offset>[];
    final dark = <Offset>[];
    for (var y = 0.0; y < size.height; y += _cellSize) {
      for (var x = 0.0; x < size.width; x += _cellSize) {
        final dx = next() % 1000 / 1000 * _cellSize;
        final dy = next() % 1000 / 1000 * _cellSize;
        (next().isEven ? light : dark).add(Offset(x + dx, y + dy));
      }
    }
    final paint = Paint()..strokeWidth = 1;
    canvas
      ..drawPoints(
        PointMode.points,
        light,
        paint..color = Color.fromRGBO(255, 255, 255, opacity),
      )
      ..drawPoints(
        PointMode.points,
        dark,
        paint..color = Color.fromRGBO(0, 0, 0, opacity),
      );
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

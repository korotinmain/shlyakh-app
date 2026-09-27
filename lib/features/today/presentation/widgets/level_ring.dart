import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Stroke width of the ring, in logical pixels.
const double _strokeWidth = 8;

/// Progress through the current level: a [track] circle with an [arc]
/// from the top, clockwise, covering [fraction] (clamped to 0..1).
class LevelRing extends StatelessWidget {
  const new({
    required this.fraction,
    required this.arc,
    required this.track,
    this.child,
    super.key,
  });

  final double fraction;
  final Color arc;
  final Color track;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _RingPainter(fraction.clamp(0, 1), arc, track),
    child: Center(child: child),
  );
}

class _RingPainter extends CustomPainter {
  new(this.fraction, this.arc, this.track);

  final double fraction;
  final Color arc;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _strokeWidth) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        paint..color = arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.arc != arc ||
      oldDelegate.track != track;
}

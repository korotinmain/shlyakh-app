import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_colors.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';

// Placeholder geometry until the illustrated landscape (phase D), as
// fractions of the screen: where each hill's ridge starts, peaks and ends.
const _ridges = <(double, double, double)>[
  (0.52, 0.44, 0.56),
  (0.62, 0.54, 0.60),
  (0.72, 0.66, 0.70),
];
const double _pathStrokeWidth = 2;
const double _pathOpacity = 0.6;
const double _dotRadius = 7;
const double _dotRingWidth = 2;

/// Three hills in [palette]'s colours, a path, and the user's dot.
class PlaceholderHills extends StatelessWidget {
  const new({required this.palette, required this.dotColor, super.key});

  final SkyPalette palette;
  final Color dotColor;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _HillsPainter(palette, dotColor),
    size: Size.infinite,
  );
}

class _HillsPainter extends CustomPainter {
  new(this.palette, this.dotColor);

  final SkyPalette palette;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (i, (start, peak, end)) in _ridges.indexed) {
      final path = Path()
        ..moveTo(0, size.height * start)
        ..quadraticBezierTo(
          size.width * (i.isEven ? 0.35 : 0.65),
          size.height * (2 * peak - (start + end) / 2),
          size.width,
          size.height * end,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = palette.hills[i].color);
    }

    // A path winding up the nearest hill, with the user's dot on it.
    final start = Offset(size.width * 0.2, size.height);
    final control = Offset(size.width * 0.75, size.height * 0.85);
    final end = Offset(size.width * 0.5, size.height * 0.71);
    canvas
      ..drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _pathStrokeWidth
          ..color = palette.onSky.color.withValues(alpha: _pathOpacity),
      )
      ..drawCircle(end, _dotRadius, Paint()..color = dotColor)
      ..drawCircle(
        end,
        _dotRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _dotRingWidth
          ..color = palette.onSky.color,
      );
  }

  @override
  bool shouldRepaint(_HillsPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.dotColor != dotColor;
}

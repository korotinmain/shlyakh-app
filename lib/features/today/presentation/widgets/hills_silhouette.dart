import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_palette.dart';

// Where each hill's ridge starts, peaks and ends, as fractions of the
// screen height, far to near.
const _ridges = <(double, double, double)>[
  (0.52, 0.44, 0.56),
  (0.62, 0.54, 0.60),
  (0.72, 0.66, 0.70),
];

/// A silhouette of three hills in the theme's colours, under the sky.
class HillsSilhouette extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _HillsPainter(context.palette), size: Size.infinite);
}

class _HillsPainter extends CustomPainter {
  new(this.palette);

  final AppPalette palette;

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
      canvas.drawPath(path, Paint()..color = palette.hills[i]);
    }
  }

  @override
  bool shouldRepaint(_HillsPainter oldDelegate) =>
      !identical(oldDelegate.palette, palette);
}

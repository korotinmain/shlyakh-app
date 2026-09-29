import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_palette.dart';

// Where each hill's ridge starts, peaks and ends, as fractions of the
// silhouette's height from its top, far to near. The near ridge sits under
// the sheet's glass.
const _ridges = <(double, double, double)>[
  (0.10, 0, 0.14),
  (0.20, 0.12, 0.19),
  (0.32, 0.26, 0.30),
];

/// A silhouette of three hills in the theme's colours, under the sky. It
/// fills its box: the ridges start at its top edge.
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

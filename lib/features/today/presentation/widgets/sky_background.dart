import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/features/today/presentation/widgets/grain.dart';

/// Where the three sky colours sit in the gradient, top to bottom.
const List<double> _skyStops = [0, 0.55, 1];

/// The nebula of the dark theme: a violet glow at 32%, fading out.
const Color _nebula = Color(0x526E5AA8);
const Alignment _nebulaCentre = Alignment(-0.4, -0.4);
const double _nebulaRadius = 0.7;

/// The star-chart grid of the light theme: squares of this side, in ink at
/// 5%, over the top two thirds of the screen.
const double _gridCell = 24;
const Color _gridInk = Color(0x0D3D4F9A);
const double _gridHeight = 2 / 3;

/// The theme's sky: its gradient, its backdrop and a fine grain.
class SkyBackground extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.sky,
          stops: _skyStops,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          switch (palette.backdrop) {
            Backdrop.nebula => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: _nebulaCentre,
                  radius: _nebulaRadius,
                  colors: [_nebula, Color(0x006E5AA8)],
                ),
              ),
            ),
            Backdrop.chart => const CustomPaint(painter: _ChartGrid()),
          },
          Grain(opacity: palette.grainOpacity),
        ],
      ),
    );
  }
}

class _ChartGrid extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _gridInk;
    final bottom = size.height * _gridHeight;
    for (var x = _gridCell; x < size.width; x += _gridCell) {
      canvas.drawLine(Offset(x, 0), Offset(x, bottom), paint);
    }
    for (var y = _gridCell; y < bottom; y += _gridCell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ChartGrid oldDelegate) => false;
}

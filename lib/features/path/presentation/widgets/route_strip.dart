import 'package:flutter/material.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';

/// The fog dot and the dashes of the line, in logical pixels.
const double _dotRadius = 2;
const double _dash = 2;
const double _gap = 4;

/// The route around a constellation: the previous name, this one (bold)
/// and the next one over a dashed line. A slot with no page (before the
/// first, or in the fog after the next) shows a faint dot.
class RouteStrip extends StatelessWidget {
  const new({
    required this.current,
    this.previous,
    this.next,
    this.onPrevious,
    this.onNext,
    super.key,
  });

  /// Key of the dot shown for a missing neighbour.
  static const Key fogKey = Key('routeStripFog');

  final String? previous;
  final String current;
  final String? next;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget neighbour(String? name, VoidCallback? onTap) => Expanded(
      child: name == null
          ? Center(
              child: CircleAvatar(
                key: fogKey,
                radius: _dotRadius,
                backgroundColor: palette.starAhead,
              ),
            )
          : Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.footnote.copyWith(
                    color: palette.onSkyMuted,
                  ),
                ),
              ),
            ),
    );
    return CustomPaint(
      painter: _DashedLine(palette.aheadLine),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            neighbour(previous, onPrevious),
            Expanded(
              child: Text(
                current,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headline.copyWith(color: palette.onSky),
              ),
            ),
            neighbour(next, onNext),
          ],
        ),
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final y = size.height - 1;
    for (var x = 0.0; x < size.width; x += _dash + _gap) {
      canvas.drawLine(Offset(x, y), Offset(x + _dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLine oldDelegate) => oldDelegate.color != color;
}

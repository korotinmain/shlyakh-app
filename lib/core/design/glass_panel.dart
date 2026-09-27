import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/glass.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';

/// A matte glass surface of [shape] over the sky: blur, tint and text
/// colour follow the sky's [tone] (docs/DESIGN.md).
class GlassPanel extends StatelessWidget {
  const new({
    required this.tone,
    required this.shape,
    required this.child,
    super.key,
  });

  final SurfaceTone tone;
  final ShapeBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final foreground = GlassStyle.onGlass(tone);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: const [GlassStyle.shadow],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassStyle.blurSigma,
            sigmaY: GlassStyle.blurSigma,
          ),
          child: ColoredBox(
            color: GlassStyle.tintFor(tone),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: IconTheme.merge(
                data: IconThemeData(color: foreground),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

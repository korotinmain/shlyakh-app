import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/glass.dart';

/// A matte glass surface of [shape] over the sky: blur, and the tint and
/// text colour of the theme's palette (docs/DESIGN.md).
class GlassPanel extends StatelessWidget {
  const new({required this.shape, required this.child, super.key});

  final ShapeBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = palette.onGlass;
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
            color: palette.glass,
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

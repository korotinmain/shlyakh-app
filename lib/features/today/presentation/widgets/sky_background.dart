import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_colors.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';
import 'package:shlyakh/features/today/presentation/widgets/grain.dart';

/// The sky gradient of [palette] with a fine grain over it.
class SkyBackground extends StatelessWidget {
  const new({required this.palette, super.key});

  final SkyPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [for (final c in palette.sky) c.color],
          stops: skyGradientStops,
        ),
      ),
      child: const Grain(opacity: skyGrainOpacity),
    );
  }
}

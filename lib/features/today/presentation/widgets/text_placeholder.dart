import 'package:flutter/widgets.dart';
import 'package:shlyakh/core/design/app_radii.dart';

/// A neutral bar the size of one line of [style], shown while loading.
class TextPlaceholder extends StatelessWidget {
  const new({
    required this.style,
    required this.width,
    required this.color,
    super.key,
  });

  final TextStyle style;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: MediaQuery.textScalerOf(context).scale(style.fontSize!),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.bar),
    ),
  );
}

import 'package:flutter/animation.dart';

/// Motion tokens (docs/DESIGN.md); the animations themselves are phase F.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);

  /// The one easing curve: a soft deceleration.
  static const Curve curve = Curves.easeOutCubic;
}

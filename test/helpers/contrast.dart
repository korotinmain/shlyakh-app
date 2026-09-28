import 'dart:math' as math;
import 'dart:ui';

/// WCAG 2 contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  double luminance(Color c) {
    double channel(double v) => v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  final la = luminance(a);
  final lb = luminance(b);
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// [top] composited over the opaque [bottom] (source-over).
Color over(Color top, Color bottom) {
  final a = top.a;
  double mix(double t, double b) => t * a + b * (1 - a);
  return Color.from(
    alpha: 1,
    red: mix(top.r, bottom.r),
    green: mix(top.g, bottom.g),
    blue: mix(top.b, bottom.b),
  );
}

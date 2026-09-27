// Oklab colour space (Björn Ottosson, 2020): perceptually even blends, so
// the sky moves between keyframes without greyish midpoints.
// Colours are ARGB ints (0xAARRGGBB); no Flutter dependency.
import 'dart:math' as math;

typedef Oklab = ({double l, double a, double b});

/// Converts an ARGB colour to Oklab (alpha is ignored).
Oklab toOklab(int argb) {
  final r = _toLinear((argb >> 16) & 0xFF);
  final g = _toLinear((argb >> 8) & 0xFF);
  final b = _toLinear(argb & 0xFF);

  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);

  return (
    l: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

/// Converts Oklab back to an ARGB colour, clamping to the sRGB gamut.
int fromOklab(Oklab c, {int alpha = 0xFF}) {
  final l = math.pow(c.l + 0.3963377774 * c.a + 0.2158037573 * c.b, 3);
  final m = math.pow(c.l - 0.1055613458 * c.a - 0.0638541728 * c.b, 3);
  final s = math.pow(c.l - 0.0894841775 * c.a - 1.2914855480 * c.b, 3);

  final r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
  final g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
  final b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

  return (alpha.clamp(0, 255) << 24) |
      (_fromLinear(r) << 16) |
      (_fromLinear(g) << 8) |
      _fromLinear(b);
}

/// Blends [from] to [to] by [t] (clamped to 0–1); alpha blends linearly.
///
/// Interpolates in OkLCh (the polar form of Oklab): lightness and chroma
/// linearly, hue along the shorter arc. A straight Oklab line between
/// opposite hues (warm golden hour → cool blue hour) passes through grey;
/// the hue arc keeps the colour, like real twilight.
int lerpArgb(int from, int to, double t) {
  final k = t.clamp(0.0, 1.0);
  if (k == 0) return from;
  if (k == 1) return to;
  final a = toOklab(from);
  final b = toOklab(to);
  final chromaA = math.sqrt(a.a * a.a + a.b * a.b);
  final chromaB = math.sqrt(b.a * b.a + b.b * b.b);
  // A near-grey endpoint has no meaningful hue: borrow the other one's.
  var hueA = math.atan2(a.b, a.a);
  var hueB = math.atan2(b.b, b.a);
  if (chromaA < _greyChroma) hueA = hueB;
  if (chromaB < _greyChroma) hueB = hueA;
  var deltaHue = hueB - hueA;
  if (deltaHue > math.pi) deltaHue -= 2 * math.pi;
  if (deltaHue < -math.pi) deltaHue += 2 * math.pi;

  final lightness = a.l + (b.l - a.l) * k;
  final chroma = chromaA + (chromaB - chromaA) * k;
  final hue = hueA + deltaHue * k;
  final alpha =
      ((from >> 24) & 0xFF) + (((to >> 24) & 0xFF) - ((from >> 24) & 0xFF)) * k;
  return fromOklab((
    l: lightness,
    a: chroma * math.cos(hue),
    b: chroma * math.sin(hue),
  ), alpha: alpha.round());
}

const _greyChroma = 0.02;

double _toLinear(int channel) {
  final c = channel / 255;
  return c <= 0.04045
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

int _fromLinear(num linear) {
  final c = linear.clamp(0.0, 1.0).toDouble();
  final srgb = c <= 0.0031308
      ? 12.92 * c
      : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
  return (srgb * 255).round().clamp(0, 255);
}

double _cbrt(double x) =>
    x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

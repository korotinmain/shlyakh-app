import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/glass.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';

void main() {
  test('light skies get the light tint and dark text', () {
    expect(GlassStyle.tintFor(SurfaceTone.light), GlassStyle.lightTint);
    expect(GlassStyle.onGlass(SurfaceTone.light), const Color(0xFF18293A));
  });

  test('dark skies get the dark tint and white text', () {
    expect(GlassStyle.tintFor(SurfaceTone.dark), GlassStyle.darkTint);
    expect(GlassStyle.onGlass(SurfaceTone.dark), const Color(0xFFFFFFFF));
  });
}

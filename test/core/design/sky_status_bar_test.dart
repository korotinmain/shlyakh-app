import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';
import 'package:shlyakh/core/design/sky_status_bar.dart';

void main() {
  test('night sky: light status bar icons', () {
    expect(
      statusBarStyleFor(skyKeyframes[SkyKeyframe.night]!),
      SystemUiOverlayStyle.light,
    );
  });

  test('day sky: dark status bar icons', () {
    expect(
      statusBarStyleFor(skyKeyframes[SkyKeyframe.day]!),
      SystemUiOverlayStyle.dark,
    );
  });

  test('every keyframe matches the brightness of its text on the sky', () {
    for (final MapEntry(key: frame, value: palette) in skyKeyframes.entries) {
      final lightText = palette.onSky == 0xFFFFFFFF;
      expect(
        statusBarStyleFor(palette),
        lightText ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        reason: frame.name,
      );
    }
  });
}

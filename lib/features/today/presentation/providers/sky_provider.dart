import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';
import 'package:shlyakh/core/design/sky/sky_palette.dart';
import 'package:shlyakh/core/time/clock_provider.dart';

part 'sky_provider.g.dart';

/// The sky for the current time, updated at every minute boundary.
///
/// Synchronous, so the first frame already has the right sky.
@Riverpod(keepAlive: true)
class Sky extends _$Sky {
  @override
  SkyPalette build() {
    final clock = ref.watch(clockProvider);
    void update() => state = skyAt(clock.now());

    final now = clock.now();
    final intoMinute = Duration(
      seconds: now.second,
      milliseconds: now.millisecond,
      microseconds: now.microsecond,
    );
    Timer? periodic;
    final first = Timer(const Duration(minutes: 1) - intoMinute, () {
      update();
      periodic = Timer.periodic(const Duration(minutes: 1), (_) => update());
    });
    ref.onDispose(() {
      first.cancel();
      periodic?.cancel();
    });

    return skyAt(now);
  }
}

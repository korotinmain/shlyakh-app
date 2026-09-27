import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';
import 'package:shlyakh/core/design/sky/sky_palette.dart';
import 'package:shlyakh/core/time/clock_provider.dart';

part 'sky_provider.g.dart';

/// The sky for the current time: now, then again at every minute boundary.
@Riverpod(keepAlive: true)
Stream<SkyPalette> sky(Ref ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<SkyPalette>();
  void emit() => controller.add(skyAt(clock.now()));

  final now = clock.now();
  final intoMinute = Duration(
    seconds: now.second,
    milliseconds: now.millisecond,
    microseconds: now.microsecond,
  );
  Timer? periodic;
  final first = Timer(const Duration(minutes: 1) - intoMinute, () {
    emit();
    periodic = Timer.periodic(const Duration(minutes: 1), (_) => emit());
  });
  ref.onDispose(() {
    first.cancel();
    periodic?.cancel();
    unawaited(controller.close());
  });

  emit();
  return controller.stream;
}

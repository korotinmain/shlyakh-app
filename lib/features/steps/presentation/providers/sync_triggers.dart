import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';

part 'sync_triggers.g.dart';

/// Syncs steps when the journey starts or the app launches with one, and
/// every time the app returns to the foreground. All triggers share one
/// `StepsSync`, so a burst folds into at most two runs; `sync()` never
/// throws a failure, so the calls are not awaited.
@Riverpod(keepAlive: true)
void syncTriggers(Ref ref) {
  var started = false;
  void sync() => unawaited(ref.read(stepsSyncProvider).sync());

  ref.listen(journeyStartProvider, (_, next) {
    if (started || next.value == null) return;
    started = true;
    sync();
  }, fireImmediately: true);

  final lifecycle = AppLifecycleListener(
    onResume: () {
      if (started) sync();
    },
  );
  ref.onDispose(lifecycle.dispose);
}

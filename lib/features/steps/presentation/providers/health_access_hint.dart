import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/presentation/providers/steps_providers.dart';
import 'package:shlyakh/features/today/presentation/providers/current_user_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';

part 'health_access_hint.g.dart';

/// How long after the start a journey with no steps at all looks like
/// denied read access (iOS never tells an app it was denied).
const Duration _hintAfter = Duration(hours: 24);

/// Whether Today shows the "check Health access" hint: at least a day
/// after the journey start, and every stored day has zero steps.
@riverpod
Stream<bool> healthAccessHint(Ref ref) async* {
  final start = await ref.watch(journeyStartProvider.future);
  if (start == null) {
    yield false;
    return;
  }
  final clock = ref.watch(clockProvider);
  final days = ref
      .watch(stepsRepositoryProvider)
      .watchDays(userId: ref.watch(currentUserIdProvider));
  // The clock is read per emission, so the hint appears on the next
  // update after the 24 hours pass.
  yield* days.map(
    (days) =>
        !clock.now().isBefore(start.startedAt.add(_hintAfter)) &&
        days.every((day) => day.steps == 0),
  );
}

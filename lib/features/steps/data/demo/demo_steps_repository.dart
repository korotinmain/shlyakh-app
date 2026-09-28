// Demo data until the HealthKit → Drift repository exists; never ship to
// TestFlight with it (docs/superpowers/specs/2026-09-28-today-screen-design.md).
import 'package:clock/clock.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';

/// In-memory, deterministic step days ending "today" of [Clock].
final class DemoStepsRepository implements StepsRepository {
  new(this._clock, {this._days = 120});

  final Clock _clock;
  final int _days;

  static const _seed = 0x5EED;
  static const _maxSteps = 14000;
  static const _timezone = 'Europe/Kyiv';

  @override
  Stream<List<DailySteps>> watchDays({
    required String userId,
    LocalDate? from,
    LocalDate? to,
  }) {
    final today = LocalDate.fromDateTime(_clock.now());
    var state = _seed;
    final days = <DailySteps>[];
    for (var i = 0; i < _days; i++) {
      // 31-bit LCG (glibc constants).
      state = (1103515245 * state + 12345) & 0x7FFFFFFF;
      final date = today.addDays(i - (_days - 1));
      if (from != null && date.isBefore(from)) continue;
      if (to != null && date.isAfter(to)) continue;
      days.add((
        userId: userId,
        localDate: date,
        timezone: _timezone,
        steps: state % (_maxSteps + 1),
      ));
    }
    return Stream.value(days);
  }
}

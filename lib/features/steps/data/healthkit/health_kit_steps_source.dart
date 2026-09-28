import 'package:flutter/services.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

/// HealthKit through the native `StepsHostApi` (ADR 0007).
///
/// Known native error codes become [Failure]s; any other code is a bug and
/// is rethrown (ADR 0005).
final class HealthKitStepsSource {
  new(this._api);

  final StepsHostApi _api;

  /// Whether HealthKit is available on this device.
  Future<bool> isAvailable() => _guard(_api.isAvailable);

  /// Shows the system prompt for read access to steps. Completes without
  /// saying what the user chose.
  Future<void> requestAccess() => _guard(_api.requestAccess);

  /// Every local day from [from] to the end of today for [userId], counted
  /// in the device's current time zone; the first day is partial when
  /// [from] is not a local midnight.
  Future<List<DailySteps>> dailySteps({
    required String userId,
    required DateTime from,
  }) => _guard(() async {
    final days = await _api.dailySteps(from.millisecondsSinceEpoch);
    if (days.isEmpty) return const [];
    final timezone = await _api.timeZoneId();
    return [
      for (final day in days)
        (
          userId: userId,
          localDate: LocalDate.parse(day.localDate),
          timezone: timezone,
          steps: day.steps,
        ),
    ];
  });

  /// The device's IANA time zone identifier.
  Future<String> timeZoneId() => _guard(_api.timeZoneId);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      final failure = switch (e.code) {
        'unavailable' => HealthUnavailable(cause: e),
        'locked' => HealthDataLocked(cause: e),
        _ => null,
      };
      if (failure == null) rethrow;
      throw failure;
    }
  }
}

import 'package:flutter/services.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

/// HealthKit through the native `StepsHostApi` (ADR 0007).
///
/// The native error codes become [Failure]s (ADR 0005); an undocumented
/// code (e.g. Pigeon's `channel-error`) is a setup bug and is rethrown.
final class HealthKitStepsSource {
  new(this._api);

  final StepsHostApi _api;

  /// Whether HealthKit is available on this device.
  Future<bool> isAvailable() => _guard(_api.isAvailable);

  /// Shows the system prompt for read access to steps. Completes without
  /// saying what the user chose.
  Future<void> requestAccess() => _guard(_api.requestAccess);

  /// Every local day from [from] to the end of today for [userId], each
  /// with the zone it was counted in (the device's, from the same native
  /// call); the first day is partial when [from] is not a local midnight.
  Future<List<DailySteps>> dailySteps({
    required String userId,
    required DateTime from,
  }) => _guard(() async {
    final result = await _api.dailySteps(from.millisecondsSinceEpoch);
    return [
      for (final day in result.days)
        (
          userId: userId,
          localDate: LocalDate.parse(day.localDate),
          timezone: result.timeZoneId,
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
        'healthkit' => UnexpectedFailure(cause: e),
        _ => null,
      };
      if (failure == null) rethrow;
      throw failure;
    }
  }
}

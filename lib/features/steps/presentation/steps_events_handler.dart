import 'package:shlyakh/core/logging/app_logger.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';

/// Receives HealthKit's background wakeups from Swift (ADR 0007): each one
/// runs the shared sync, and the reply lets Swift end the wakeup.
///
/// The sync logs its own failures and never throws them; anything else is
/// a bug, logged here and rethrown, which Pigeon turns into an error
/// reply that still ends the wakeup.
final class StepsEventsHandler implements StepsEventsApi {
  new({required this._sync, required this._logger});

  final Future<void> Function() _sync;
  final AppLogger _logger;

  @override
  Future<void> onStepsChanged() async {
    try {
      await _sync();
    } on Object catch (error, stackTrace) {
      _logger.error(error, stackTrace);
      rethrow;
    }
  }
}

import 'package:clock/clock.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:drift/native.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/logging/app_logger.dart';
import 'package:shlyakh/core/logging/log_events.dart';
import 'package:shlyakh/features/steps/data/healthkit/health_kit_steps_source.dart';
import 'package:shlyakh/features/steps/data/local/daily_steps_dao.dart';
import 'package:shlyakh/features/steps/data/local/journey_start_dao.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/sync_rules.dart';

/// Copies a user's daily totals from HealthKit into Drift
/// (docs/superpowers/specs/2026-09-28-healthkit-steps-sync-design.md).
///
/// One run at a time: a call during a run is folded into one more run
/// after it. Expected failures are logged, never thrown; the UI reads
/// Drift and at worst shows slightly stale days.
final class StepsSync {
  new({
    required this._source,
    required this._starts,
    required this._days,
    required this._clock,
    required this._logger,
    required this._userId,
  });

  final HealthKitStepsSource _source;
  final JourneyStartDao _starts;
  final DailyStepsDao _days;
  final Clock _clock;
  final AppLogger _logger;
  final String _userId;

  Future<void>? _running;
  var _again = false;

  /// Syncs now, or once more after the run in progress.
  Future<void> sync() {
    if (_running case final running?) {
      _again = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      await _guardedRun();
    } while (_again);
  }

  Future<void> _guardedRun() async {
    try {
      await _run();
    } on Failure catch (failure) {
      _logger.failure(failure);
    } on SqliteException catch (e) {
      _logger.failure(StorageFailure(cause: e));
    } on DriftRemoteException catch (e) {
      // The app's database runs on a background isolate (drift_flutter),
      // which wraps SQLite errors; anything else stays a bug.
      if (e.remoteCause is! SqliteException) rethrow;
      _logger.failure(StorageFailure(cause: e));
    }
  }

  Future<void> _run() async {
    final start = await _starts.get(_userId);
    if (start == null) return;
    final watch = _clock.stopwatch()..start();

    final stored = await _days.watchForUser(_userId).first;
    final from = syncFrom(
      start: start,
      now: _clock.now(),
      // watchForUser is oldest first.
      lastStoredDate: stored.lastOrNull?.localDate,
    );
    final fetched = await _source.dailySteps(userId: _userId, from: from);
    final fromDate = LocalDate.fromDateTime(from.toLocal());
    final write = mergeDays(
      stored: [
        for (final day in stored)
          if (!day.localDate.isBefore(fromDate)) day,
      ],
      fetched: fetched,
    );
    await _days.transaction(() async {
      for (final day in write) {
        await _days.upsert(day);
      }
    });

    _logger.log(
      StepsSyncCompleted(duration: watch.elapsed, daysWritten: write.length),
    );
  }
}

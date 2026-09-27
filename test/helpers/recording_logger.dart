import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/logging/app_logger.dart';
import 'package:shlyakh/core/logging/log_events.dart';

/// Remembers what was logged, for tests of code that logs.
final class RecordingLogger implements AppLogger {
  final events = <LogEvent>[];
  final failures = <Failure>[];
  final errors = <Object>[];

  @override
  void log(LogEvent event) => events.add(event);

  @override
  void failure(Failure failure) => failures.add(failure);

  @override
  void error(Object error, StackTrace stackTrace) => errors.add(error);
}

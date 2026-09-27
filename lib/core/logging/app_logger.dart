import 'dart:developer' as developer;

import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/logging/log_events.dart';

/// The only way to log (docs/decisions/0006-logging.md). Never writes an
/// exception's message: it may contain user or health data.
abstract interface class AppLogger {
  void log(LogEvent event);

  /// Logs the failure variant and the type of its cause, nothing else.
  void failure(Failure failure);

  /// Logs an unhandled error's type and stack trace, never its message.
  void error(Object error, StackTrace stackTrace);
}

typedef LogSink = void Function(String message, {StackTrace? stackTrace});

void _developerSink(String message, {StackTrace? stackTrace}) =>
    developer.log(message, name: 'shlyakh', stackTrace: stackTrace);

/// Writes to the debug console through `dart:developer`; writes nothing
/// when [enabled] is false (release builds, until crash reporting exists).
final class DeveloperLogger implements AppLogger {
  const new({required this.enabled, this.sink = _developerSink});

  final bool enabled;
  final LogSink sink;

  @override
  void log(LogEvent event) {
    if (!enabled) return;
    final fields = event.fields.entries
        .map((field) => ' ${field.key}=${field.value.render()}')
        .join();
    sink('event ${event.name}$fields');
  }

  @override
  void failure(Failure failure) {
    if (!enabled) return;
    final cause = failure.cause;
    sink(
      'failure ${failure.variantName} '
      'cause=${cause == null ? 'none' : _typeName(cause)}',
    );
  }

  @override
  void error(Object error, StackTrace stackTrace) {
    if (!enabled) return;
    sink('error ${_typeName(error)}', stackTrace: stackTrace);
  }

  // Debug-only diagnostics: an obfuscated name is harmless, unlike the
  // message, which is never read.
  static String _typeName(Object value) => value.runtimeType.toString();
}

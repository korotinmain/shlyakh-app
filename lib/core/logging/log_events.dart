// Everything the app may log (docs/decisions/0006-logging.md).
//
// All events live in this file so every field is reviewed in one place.
// Fields are LogValues only: no free-form strings, and never steps, XP,
// dates or ids (AGENT_RULES 5).

/// A value that is safe to log.
sealed class LogValue {
  const new();

  const factory flag({required bool value}) = _Flag;

  /// Rendered as the enum value's name.
  const factory kind(Enum value) = _Kind;

  const factory duration(Duration value) = _Duration;

  /// A number of objects (days, rows). Never steps, XP, dates or ids:
  /// the compiler cannot tell them apart, review does.
  const factory count(int value) = _Count;

  String render();
}

final class _Flag extends LogValue {
  const new({required this.value});
  final bool value;

  @override
  String render() => '$value';
}

final class _Kind extends LogValue {
  const new(this.value);
  final Enum value;

  @override
  String render() => value.name;
}

final class _Duration extends LogValue {
  const new(this.value);
  final Duration value;

  @override
  String render() => '${value.inMilliseconds}ms';
}

final class _Count extends LogValue {
  const new(this.value);
  final int value;

  @override
  String render() => '$value';
}

/// A loggable event. Abstract rather than sealed so tests can declare
/// test-only events; production events are declared in this file only.
abstract class LogEvent {
  const new();

  String get name;

  Map<String, LogValue> get fields;
}

/// A steps sync from HealthKit finished (docs/superpowers/specs/
/// 2026-09-28-healthkit-steps-sync-design.md). Only how long it took and
/// how many days were written; never steps or dates.
final class StepsSyncCompleted extends LogEvent {
  const new({required this.duration, required this.daysWritten});

  final Duration duration;
  final int daysWritten;

  @override
  String get name => 'steps_sync_completed';

  @override
  Map<String, LogValue> get fields => {
    'duration': LogValue.duration(duration),
    'days_written': LogValue.count(daysWritten),
  };
}

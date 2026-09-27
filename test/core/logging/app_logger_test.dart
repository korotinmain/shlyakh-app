import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/logging/app_logger.dart';
import 'package:shlyakh/core/logging/log_events.dart';

enum _Trigger { background }

final class _TestEvent extends LogEvent {
  const new();

  @override
  String get name => 'test_event';

  @override
  Map<String, LogValue> get fields => {
    'ok': const LogValue.flag(value: true),
    'trigger': const LogValue.kind(_Trigger.background),
    'took': const LogValue.duration(Duration(milliseconds: 1234)),
    'days': const LogValue.count(3),
  };
}

void main() {
  late List<String> lines;
  late List<StackTrace?> stacks;

  void sink(String message, {StackTrace? stackTrace}) {
    lines.add(message);
    stacks.add(stackTrace);
  }

  setUp(() {
    lines = [];
    stacks = [];
  });

  DeveloperLogger logger({bool enabled = true}) =>
      DeveloperLogger(enabled: enabled, sink: sink);

  test('log renders the event and every value type', () {
    logger().log(const _TestEvent());

    expect(lines, [
      'event test_event ok=true trigger=background took=1234ms days=3',
    ]);
  });

  test('failure writes the variant and cause type only', () {
    logger().failure(
      const StorageFailure(cause: FormatException('steps=12345 user=abc')),
    );

    expect(lines, ['failure StorageFailure cause=FormatException']);
    expect(lines.join(), isNot(contains('12345')));
    expect(lines.join(), isNot(contains('abc')));
  });

  test('failure without a cause', () {
    logger().failure(const HealthAccessDenied());

    expect(lines, ['failure HealthAccessDenied cause=none']);
  });

  test('error writes the type and passes the stack trace', () {
    final stack = StackTrace.current;

    logger().error(StateError('steps=12345'), stack);

    expect(lines, ['error StateError']);
    expect(stacks, [stack]);
    expect(lines.join(), isNot(contains('12345')));
  });

  test('writes nothing when disabled', () {
    logger(enabled: false)
      ..log(const _TestEvent())
      ..failure(const StorageFailure())
      ..error(StateError('x'), StackTrace.current);

    expect(lines, isEmpty);
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/error_handlers.dart';

import '../helpers/recording_logger.dart';

void main() {
  late RecordingLogger logger;

  setUp(() => logger = RecordingLogger());

  test('flutter errors reach the logger', () {
    flutterErrorHandler(logger, presentInDebug: false)(
      FlutterErrorDetails(
        exception: StateError('x'),
        stack: StackTrace.current,
      ),
    );

    expect(logger.errors, [isA<StateError>()]);
  });

  test('platform errors are logged and marked handled', () {
    final handled = platformErrorHandler(logger)(
      StateError('x'),
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(logger.errors, [isA<StateError>()]);
  });
}

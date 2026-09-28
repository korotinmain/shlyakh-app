import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/steps/presentation/steps_events_handler.dart';

import '../../../helpers/recording_logger.dart';

void main() {
  late RecordingLogger logger;

  setUp(() => logger = RecordingLogger());

  test('a wakeup runs the sync and completes', () async {
    var syncs = 0;
    final handler = StepsEventsHandler(
      sync: () async => syncs++,
      logger: logger,
    );

    await handler.onStepsChanged();

    expect(syncs, 1);
    expect(logger.errors, isEmpty);
  });

  test('a bug in the sync is logged and replied as an error', () async {
    final bug = StateError('a bug');
    final handler = StepsEventsHandler(
      sync: () async => throw bug,
      logger: logger,
    );

    await expectLater(handler.onStepsChanged(), throwsA(same(bug)));
    expect(logger.errors, [same(bug)]);
  });
}

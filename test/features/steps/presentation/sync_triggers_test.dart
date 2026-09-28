import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/steps_test_overrides.dart';

final Override _clock = clockProvider.overrideWithValue(
  Clock.fixed(DateTime(2026, 9, 28, 12)),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _resume(WidgetTester tester) async {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await _settle(tester);
}

void main() {
  late MockStepsHostApi api;

  setUp(() => api = MockStepsHostApi());

  testWidgets('syncs on launch when the journey started', (tester) async {
    await pumpApp(tester, api: api, overrides: [_clock]);
    await _settle(tester);

    verify(() => api.dailySteps(any())).called(1);
  });

  testWidgets('does not sync before the journey starts', (tester) async {
    await pumpApp(tester, api: api, journeyStarted: false, overrides: [_clock]);
    await _settle(tester);

    verifyNever(() => api.dailySteps(any()));
  });

  testWidgets('syncs when the journey starts', (tester) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await pumpApp(
      tester,
      db: db,
      api: api,
      journeyStarted: false,
      overrides: [_clock],
    );

    await tester.runAsync(() => startTestJourney(db));
    await _settle(tester);

    verify(() => api.dailySteps(any())).called(1);
  });

  testWidgets('syncs on resume', (tester) async {
    await pumpApp(tester, api: api, overrides: [_clock]);
    await _settle(tester);
    clearInteractions(api);

    await _resume(tester);

    verify(() => api.dailySteps(any())).called(1);
  });

  testWidgets('many resumes fold into at most two syncs', (tester) async {
    await pumpApp(tester, api: api, overrides: [_clock]);
    await _settle(tester);
    final held = Completer<NativeDays>();
    var calls = 0;
    when(() => api.dailySteps(any())).thenAnswer((_) {
      calls++;
      return calls == 1
          ? held.future
          : Future.value(NativeDays(timeZoneId: 'Europe/Kyiv', days: []));
    });

    for (var i = 0; i < 5; i++) {
      await _resume(tester);
    }
    held.complete(NativeDays(timeZoneId: 'Europe/Kyiv', days: []));
    await _settle(tester);

    expect(calls, 2);
  });
}

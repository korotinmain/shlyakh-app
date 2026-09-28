import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/time/clock_provider.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/steps_test_overrides.dart';

final Override _clock = clockProvider.overrideWithValue(
  Clock.fixed(DateTime(2026, 9, 28, 12)),
);

void main() {
  testWidgets('before the journey starts the access screen shows', (
    tester,
  ) async {
    await pumpApp(tester, journeyStarted: false, overrides: [_clock]);

    expect(find.text('Every step counts'), findsOneWidget);
    expect(find.byType(FloatingTabBar), findsNothing);
  });

  testWidgets('the access screen sits on a Material surface', (tester) async {
    // Without one, Flutter draws the debug yellow underline under text.
    await pumpApp(tester, journeyStarted: false, overrides: [_clock]);

    expect(
      find.ancestor(
        of: find.text('Every step counts'),
        matching: find.byType(Material),
      ),
      findsWidgets,
    );
  });

  testWidgets('Allow opens Today', (tester) async {
    await pumpApp(tester, journeyStarted: false, overrides: [_clock]);

    await tester.tap(find.text('Allow'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingTabBar), findsOneWidget);
    expect(find.text('Every step counts'), findsNothing);
  });

  testWidgets('shows the access screen in Ukrainian', (tester) async {
    await pumpApp(
      tester,
      journeyStarted: false,
      systemLocales: const [Locale('uk')],
      overrides: [_clock],
    );

    expect(find.text('Кожен крок рахується'), findsOneWidget);
    expect(find.text('Дозволити'), findsOneWidget);
  });

  testWidgets('without HealthKit there is no Allow button', (tester) async {
    final api = MockStepsHostApi();
    when(api.isAvailable).thenAnswer((_) async => false);

    await pumpApp(tester, journeyStarted: false, api: api, overrides: [_clock]);

    expect(find.text("Health data isn't available on this device."), findsOne);
    expect(find.text('Allow'), findsNothing);
  });

  for (final (brightness, background, label) in [
    (Brightness.light, const Color(0xFF3D4F9A), const Color(0xFFFFFFFF)),
    (Brightness.dark, const Color(0xFFF3D9A0), const Color(0xFF1A2440)),
  ]) {
    testWidgets('Allow reads well in the ${brightness.name} theme', (
      tester,
    ) async {
      await pumpApp(
        tester,
        journeyStarted: false,
        brightness: brightness,
        overrides: [_clock],
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style!;
      expect(style.backgroundColor!.resolve({}), background);
      expect(style.foregroundColor!.resolve({}), label);
      expect(
        Theme.of(tester.element(find.text('Allow')))
            .extension<AppPalette>()!
            .brightness,
        brightness,
      );
    });
  }

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester, journeyStarted: false, overrides: [_clock]);

    expect(tester.takeException(), isNull);
    expect(find.text('Allow'), findsOneWidget);
  });
}

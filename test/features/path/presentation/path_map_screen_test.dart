import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/path/domain/star_cost.dart';
import 'package:shlyakh/features/path/presentation/path_map_screen.dart';
import 'package:shlyakh/features/path/presentation/providers/route_provider.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/route_fixture.dart';

final class _Repository implements StepsRepository {
  new(this.days);

  final List<DailySteps> days;

  @override
  Stream<List<DailySteps>> watchDays({
    required String userId,
    LocalDate? from,
    LocalDate? to,
  }) => Stream.value(days);
}

DailySteps _day(String iso, int steps) => (
  userId: 'local',
  localDate: LocalDate.parse(iso),
  timezone: 'Europe/Kyiv',
  steps: steps,
);

// 16 870 XP: Стріла complete, Лисичка current, Лебідь next.
final List<DailySteps> _days = [
  _day('2026-09-27', 10000),
  _day('2026-09-28', 6870),
];

/// Days at the daily cap whose XP reaches [xp] or a little more.
List<DailySteps> _daysFor(int xp) => [
  for (var i = 0; i * 20000 < xp; i++)
    _day(LocalDate.parse('2025-01-01').addDays(i).toIsoString(), 30000),
];

List<Override> _overrides(List<DailySteps> days) => [
  clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 9, 28, 12))),
  routeProvider.overrideWith((ref) async => testRoute()),
  stepsRepositoryProvider.overrideWithValue(_Repository(days)),
];

Finder _tab(String label) => find.descendant(
  of: find.byType(FloatingTabBar),
  matching: find.text(label),
);

Future<void> _openMap(
  WidgetTester tester, {
  List<DailySteps>? days,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 186, bottom: 102);
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    brightness: brightness,
    overrides: _overrides(days ?? _days),
  );
  await tester.tap(_tab('Path'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Map of the path'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens the Milky Way map from the Path tab', (tester) async {
    await _openMap(tester);

    expect(find.byType(PathMapScreen), findsOneWidget);
    expect(find.text('The Milky Way'), findsOneWidget);
    expect(find.text('1 constellation complete'), findsOneWidget);
    expect(find.text('4 stars lit · further on, in the fog'), findsOneWidget);
  });

  testWidgets('names only the constellations out of the fog', (tester) async {
    await _openMap(tester);

    for (final name in ['Sagitta', 'Vulpecula', 'Cygnus']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text('Lacerta'), findsNothing);
  });

  testWidgets('opens with the current constellation on screen', (tester) async {
    await _openMap(tester);

    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final label = tester.getRect(find.text('Vulpecula'));
    expect(label.top, greaterThanOrEqualTo(viewport.top));
    expect(label.bottom, lessThanOrEqualTo(viewport.bottom));
  });

  testWidgets('shows the branch once the main route is done', (tester) async {
    await _openMap(tester, days: _daysFor(xpToLight(140)));

    expect(find.text('Aquila'), findsOneWidget);
    expect(find.text('Sagittarius'), findsNothing);
  });

  testWidgets('back returns to the constellation pages', (tester) async {
    await _openMap(tester);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(PathMapScreen), findsNothing);
    expect(find.text('You are here'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders in the ${brightness.name} theme with large text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openMap(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      final tabBarTop = tester.getRect(find.byType(FloatingTabBar)).top;
      expect(
        tester.getRect(find.text('The Milky Way')).bottom,
        lessThan(tabBarTop),
      );
    });
  }
}

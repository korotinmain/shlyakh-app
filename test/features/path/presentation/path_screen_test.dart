import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/path/presentation/providers/route_provider.dart';
import 'package:shlyakh/features/path/presentation/widgets/path_info_card.dart';
import 'package:shlyakh/features/path/presentation/widgets/route_strip.dart';
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

// 16 870 XP: Стріла complete on 2026-09-28, Лисичка's first star at 24 %.
final List<DailySteps> _days = [
  _day('2026-09-27', 10000),
  _day('2026-09-28', 6870),
];

/// [count] days of [steps] each, ending the day before 2026-09-28.
List<DailySteps> _history(int count, int steps) => [
  for (var i = count; i >= 1; i--)
    _day(LocalDate.parse('2026-09-28').addDays(-i).toIsoString(), steps),
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

Future<void> _openPath(
  WidgetTester tester, {
  List<DailySteps>? days,
  List<Locale> locales = const [Locale('en')],
  Brightness brightness = Brightness.light,
}) async {
  // iPhone 16 Pro, with its status bar and home indicator insets.
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 186, bottom: 102);
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    systemLocales: locales,
    brightness: brightness,
    overrides: _overrides(days ?? _days),
  );
  await tester.tap(_tab(locales.first.languageCode == 'uk' ? 'Шлях' : 'Path'));
  await tester.pumpAndSettle();
}

Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.drag(find.byType(PageView), Offset(dx, 0));
  await tester.pumpAndSettle();
}

/// The strip of the page on screen.
Finder _strip() => find.byWidgetPredicate((w) => w is RouteStrip).hitTestable();

void main() {
  testWidgets('opens on the current constellation', (tester) async {
    await _openPath(tester);

    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Vulpecula').hitTestable(), findsWidgets);
    expect(find.text('1 constellation complete'), findsOneWidget);
    expect(find.text('5,630 XP to the next star'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('at your pace'), findsNothing);
  });

  testWidgets('the strip shows the neighbours', (tester) async {
    await _openPath(tester);

    final strip = tester.widget<RouteStrip>(_strip().first);
    expect(
      (strip.previous, strip.current, strip.next),
      ('Sagitta', 'Vulpecula', 'Cygnus'),
    );
  });

  testWidgets('swiping on shows the next constellation, locked', (
    tester,
  ) async {
    await _openPath(tester);
    await _swipe(tester, -300);

    expect(find.text('Ahead'), findsOneWidget);
    expect(
      find.text('Opens once the current constellation is complete'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('there is no page past the next one', (tester) async {
    await _openPath(tester);
    await _swipe(tester, -300);
    await _swipe(tester, -300);

    expect(find.text('Ahead'), findsOneWidget);
    expect(find.text('Lacerta'), findsNothing);
  });

  testWidgets('swiping back shows a completed constellation with its seal', (
    tester,
  ) async {
    await _openPath(tester);
    await _swipe(tester, 300);

    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('Completed September 28'), findsOneWidget);
    expect(find.text('4 stars'), findsOneWidget);
  });

  testWidgets('tapping a neighbour on the strip opens it', (tester) async {
    await _openPath(tester);

    await tester.tap(find.text('Cygnus').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('Ahead'), findsOneWidget);
  });

  testWidgets('shows the ETA with two weeks of history', (tester) async {
    await _openPath(tester, days: _history(14, 7000));

    expect(find.text('≈ 1 day at your pace'), findsOneWidget);
  });

  testWidgets('speaks Ukrainian', (tester) async {
    await _openPath(tester, locales: const [Locale('uk')]);

    expect(find.text('Зараз тут'), findsOneWidget);
    expect(find.text("Складено 1 сузір'я"), findsOneWidget);
    await _swipe(tester, 300);
    expect(find.text('Складено 28 вересня'), findsOneWidget);
    expect(find.text('4 зорі'), findsOneWidget);
  });

  testWidgets('shows the ETA in Ukrainian', (tester) async {
    await _openPath(
      tester,
      days: _history(14, 7000),
      locales: const [Locale('uk')],
    );

    expect(find.text('≈ 1 день у твоєму темпі'), findsOneWidget);
  });

  testWidgets('with large text the card and strip stay above the tab bar', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openPath(tester);

    expect(tester.takeException(), isNull);
    final tabBarTop = tester.getRect(find.byType(FloatingTabBar)).top;
    expect(
      tester.getRect(find.byType(PathInfoCard).hitTestable().first).bottom,
      lessThanOrEqualTo(tabBarTop),
    );
    expect(tester.getRect(_strip().first).bottom, lessThanOrEqualTo(tabBarTop));
  });

  for (final (brightness, palette) in [
    (Brightness.dark, AppPalette.dark),
    (Brightness.light, AppPalette.light),
  ]) {
    testWidgets('a completed page is gold in the ${brightness.name} theme', (
      tester,
    ) async {
      await _openPath(tester, brightness: brightness);
      await _swipe(tester, 300);

      expect(
        tester.widget<Text>(find.text('Complete')).style?.color,
        palette.done,
      );
      final seal = tester.widget<DecoratedBox>(
        find.byKey(PathInfoCard.sealKey),
      );
      expect((seal.decoration as BoxDecoration).color, palette.seal);
    });
  }

  testWidgets('on the first star nothing comes before Sagitta', (tester) async {
    await _openPath(tester, days: const []);

    final strip = tester.widget<RouteStrip>(_strip().first);
    expect(strip.previous, isNull);
    expect(strip.current, 'Sagitta');
    expect(find.text('Your first constellation is ahead'), findsOneWidget);
  });
}

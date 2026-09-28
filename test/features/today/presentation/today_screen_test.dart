import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';
import 'package:shlyakh/features/today/presentation/widgets/today_card.dart';
import 'package:shlyakh/features/today/presentation/widgets/week_bars.dart';

import '../../../helpers/pump_app.dart';

final class _Repository implements StepsRepository {
  new(this._stream);

  final Stream<List<DailySteps>> Function() _stream;

  @override
  Stream<List<DailySteps>> watchDays({
    required String userId,
    LocalDate? from,
    LocalDate? to,
  }) => _stream();
}

DailySteps _day(String iso, int steps) => (
  userId: 'local',
  localDate: LocalDate.parse(iso),
  timezone: 'Europe/Kyiv',
  steps: steps,
);

// 16 870 XP in total: level 4 (15 600 – 27 800).
// 2026-09-27 is the Sunday before this week: in the level, not the week.
final List<DailySteps> _days = [
  _day('2026-09-27', 10000),
  _day('2026-09-28', 6870),
];

List<Override> _overrides(Stream<List<DailySteps>> Function() stream) => [
  clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 9, 28, 12))),
  stepsRepositoryProvider.overrideWithValue(_Repository(stream)),
];

Future<void> _pump(
  WidgetTester tester, {
  List<Locale> locales = const [Locale('en')],
  List<DailySteps>? days,
  Stream<List<DailySteps>> Function()? stream,
}) async {
  // iPhone 16 Pro.
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    systemLocales: locales,
    overrides: _overrides(stream ?? () => Stream.value(days ?? _days)),
  );
}

Future<void> _expandSheet(WidgetTester tester) async {
  // Drag the sheet by its level line: the sheet's own centre is above it.
  await tester.drag(
    find.textContaining(RegExp(r'^Level \d+ · ')),
    const Offset(0, -700),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows today in English', (tester) async {
    await _pump(tester);

    expect(find.text('6,870'), findsOneWidget);
    expect(find.textContaining('steps today · Monday, September 28'), findsOne);
    expect(find.textContaining('Level 4 · '), findsOneWidget);
    expect(find.text('Pathfinder'), findsOneWidget);
  });

  testWidgets('the card hugs its content', (tester) async {
    await _pump(tester);

    final card = tester.getSize(find.byType(TodayCard));
    expect(card.height, lessThan(874 / 4));
  });

  testWidgets('shows today in Ukrainian', (tester) async {
    await _pump(tester, locales: const [Locale('uk')]);

    expect(find.text('6 870'), findsOneWidget);
    expect(
      find.textContaining('кроків сьогодні · понеділок, 28 вересня'),
      findsOneWidget,
    );
    expect(find.textContaining('Рівень 4 · '), findsOneWidget);
    expect(find.text('Шукач стежок'), findsOneWidget);
  });

  testWidgets('the expanded sheet shows the week and the history link', (
    tester,
  ) async {
    await _pump(tester);
    await _expandSheet(tester);

    expect(find.byType(WeekBars), findsOneWidget);
    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(day), findsOneWidget, reason: day);
    }
    expect(find.text('6,870 steps in total'), findsOneWidget);
    expect(find.text('≈ 5.1 km'), findsOneWidget);
    expect(find.text('15,600 → 27,800 XP'), findsOneWidget);
  });

  testWidgets('the history link opens History', (tester) async {
    await _pump(tester);
    await _expandSheet(tester);

    await tester.tap(find.text('All history →'));
    await tester.pumpAndSettle();

    expect(find.text('History is coming soon'), findsOneWidget);
  });

  testWidgets('a week with no steps renders', (tester) async {
    await _pump(tester, days: const []);
    await _expandSheet(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester);

    expect(tester.takeException(), isNull);
    await _expandSheet(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing repository shows the failure message', (tester) async {
    await _pump(tester, stream: () => Stream.error(const StorageFailure()));

    expect(
      find.text(
        "Couldn't save your data on this device. Try restarting the app.",
      ),
      findsOneWidget,
    );
  });
}

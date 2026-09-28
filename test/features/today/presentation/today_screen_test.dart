import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/path/presentation/providers/route_provider.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';
import 'package:shlyakh/features/today/presentation/providers/steps_repository_provider.dart';
import 'package:shlyakh/features/today/presentation/widgets/progress_ring.dart';
import 'package:shlyakh/features/today/presentation/widgets/today_card.dart';
import 'package:shlyakh/features/today/presentation/widgets/week_bars.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/route_fixture.dart';

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

// 16 870 XP in total: Стріла's 4 stars (15 000 XP) and 1 870 of the
// 7 500 XP of Лисичка's first star (24 %).
// 2026-09-27 is the Sunday before this week: in the path, not the week.
final List<DailySteps> _days = [
  _day('2026-09-27', 10000),
  _day('2026-09-28', 6870),
];

List<Override> _overrides(
  Stream<List<DailySteps>> Function() stream,
  DateTime now,
) => [
  clockProvider.overrideWithValue(Clock.fixed(now)),
  routeProvider.overrideWith((ref) async => testRoute()),
  stepsRepositoryProvider.overrideWithValue(_Repository(stream)),
];

Future<void> _pump(
  WidgetTester tester, {
  List<Locale> locales = const [Locale('en')],
  List<DailySteps>? days,
  Stream<List<DailySteps>> Function()? stream,
  DateTime? now,
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
    overrides: _overrides(
      stream ?? () => Stream.value(days ?? _days),
      now ?? DateTime(2026, 9, 28, 12),
    ),
  );
}

Future<void> _expandSheet(WidgetTester tester) async {
  // Drag the sheet by its first line: the sheet's own centre is above it.
  await tester.drag(find.text('You are here'), const Offset(0, -700));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows today in English', (tester) async {
    await _pump(tester);

    expect(find.text('6,870'), findsOneWidget);
    expect(find.textContaining('steps today · Monday, September 28'), findsOne);
    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Vulpecula'), findsOneWidget);
    expect(find.text('24%'), findsOneWidget);
    expect(find.textContaining('Level'), findsNothing);
  });

  testWidgets('the card hugs its content', (tester) async {
    await _pump(tester);

    final card = tester.getSize(find.byType(TodayCard));
    expect(card.height, lessThan(874 / 4));
  });

  testWidgets('the sheet reaches the bottom of the screen', (tester) async {
    await _pump(tester);

    final sheet = find.ancestor(
      of: find.text('Vulpecula'),
      matching: find.byType(GlassPanel),
    );
    expect(tester.getRect(sheet).bottom, 874);
  });

  testWidgets('the collapsed sheet shows its constellation above the tab bar', (
    tester,
  ) async {
    await _pump(tester);

    final tabBarTop = tester.getRect(find.byType(FloatingTabBar)).top;
    expect(tester.getRect(find.text('Vulpecula')).bottom, lessThan(tabBarTop));
  });

  testWidgets('the expanded sheet scrolls its last line above the tab bar', (
    tester,
  ) async {
    await _pump(tester);
    await _expandSheet(tester);
    await tester.drag(find.text('This week'), const Offset(0, -700));
    await tester.pumpAndSettle();

    final tabBarTop = tester.getRect(find.byType(FloatingTabBar)).top;
    expect(
      tester.getRect(find.text('All history →')).bottom,
      lessThan(tabBarTop),
    );
  });

  testWidgets('the expanded sheet stops below the card', (tester) async {
    await _pump(tester);
    await _expandSheet(tester);

    final sheet = find.ancestor(
      of: find.text('Vulpecula'),
      matching: find.byType(GlassPanel),
    );
    final cardBottom = tester.getRect(find.byType(TodayCard)).bottom;
    expect(tester.getRect(sheet).top, greaterThan(cardBottom));
  });

  testWidgets('with large text the expanded sheet still stops below the card', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester);
    await _expandSheet(tester);

    final sheet = find.ancestor(
      of: find.byType(ListView),
      matching: find.byType(GlassPanel),
    );
    final cardBottom = tester.getRect(find.byType(TodayCard)).bottom;
    expect(tester.getRect(sheet).top, greaterThan(cardBottom));
  });

  testWidgets('status bar icons are dark in the light theme', (tester) async {
    await _pump(tester);

    expect(_statusBarBrightness(tester), Brightness.light);
  });

  testWidgets('status bar icons are light in the dark theme', (tester) async {
    await _pump(tester, brightness: Brightness.dark);

    expect(_statusBarBrightness(tester), Brightness.dark);
  });

  for (final (brightness, palette) in [
    (Brightness.dark, AppPalette.dark),
    (Brightness.light, AppPalette.light),
  ]) {
    testWidgets('the ${brightness.name} theme colours the glass and ring', (
      tester,
    ) async {
      await _pump(tester, brightness: brightness);

      expect(_sheetGlass(tester), palette.glass);
      expect(
        tester.widget<ProgressRing>(find.byType(ProgressRing)).arc,
        palette.accent,
      );
    });

    testWidgets('the collapsed sheet keeps its text above the tab bar '
        'in the ${brightness.name} theme', (tester) async {
      await _pump(tester, brightness: brightness);

      final tabBarTop = tester.getRect(find.byType(FloatingTabBar)).top;
      expect(
        tester.getRect(find.text('Vulpecula')).bottom,
        lessThan(tabBarTop),
      );
    });

    testWidgets(
      'large text does not overflow in the ${brightness.name} theme',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pump(tester, brightness: brightness);
        await _expandSheet(tester);

        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('switching the system theme recolours Today', (tester) async {
    await _pump(tester);
    expect(_sheetGlass(tester), AppPalette.light.glass);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    expect(_sheetGlass(tester), AppPalette.dark.glass);
    expect(_statusBarBrightness(tester), Brightness.dark);
  });

  testWidgets('shows today in Ukrainian', (tester) async {
    await _pump(tester, locales: const [Locale('uk')]);

    expect(find.text('6 870'), findsOneWidget);
    expect(
      find.textContaining('кроків сьогодні · понеділок, 28 вересня'),
      findsOneWidget,
    );
    expect(find.text('Зараз тут'), findsOneWidget);
    expect(find.text('Лисичка'), findsOneWidget);
    expect(find.text('24\u00a0%'), findsOneWidget);
    expect(find.textContaining('Рівень'), findsNothing);
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
    expect(find.text('Star 24% full'), findsOneWidget);
    expect(find.text('5,630 XP to the next star'), findsOneWidget);
  });

  testWidgets('the expanded sheet shows star progress in Ukrainian', (
    tester,
  ) async {
    await _pump(tester, locales: const [Locale('uk')]);
    await tester.drag(find.text('Зараз тут'), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Зорю заповнено на 24\u00a0%'), findsOneWidget);
    expect(find.text('Ще 5\u00a0630 XP до наступної зорі'), findsOneWidget);
  });

  testWidgets('with the whole route lit the sheet says so', (tester) async {
    final days = [
      for (var i = 0; i < 400; i++)
        _day(LocalDate.parse('2025-08-01').addDays(i).toIsoString(), 30000),
    ];
    await _pump(tester, days: days);
    await _expandSheet(tester);

    expect(find.text('Sagittarius'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('The whole route is lit'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('to the next star'), findsNothing);
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

  testWidgets('no steps a day after the start shows the Health hint', (
    tester,
  ) async {
    await _pump(tester, days: const []);

    expect(
      find.text(
        'No steps yet? Allow Shlyakh to read Steps in the Health app: '
        'your profile → Apps → Shlyakh.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the Health hint in Ukrainian', (tester) async {
    await _pump(tester, days: const [], locales: const [Locale('uk')]);

    expect(
      find.text(
        'Кроків досі немає? Дозвольте Шляху читати кроки в застосунку '
        "Здоров'я: ваш профіль → Програми → Шлях.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('steps hide the Health hint', (tester) async {
    await _pump(tester);

    expect(find.textContaining('No steps yet?'), findsNothing);
  });
}

/// The iOS status bar brightness the Today screen asks for: `light` means a
/// light background, so the icons are dark.
Brightness? _statusBarBrightness(WidgetTester tester) => tester
    .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    )
    .value
    .statusBarBrightness;

/// The tint of the sheet's glass.
Color _sheetGlass(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('You are here'),
              matching: find.byType(GlassPanel),
            ),
            matching: find.byType(ColoredBox),
          )
          .first,
    )
    .color;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/time/clock_provider.dart';

import '../helpers/pump_app.dart';

final List<Override> _overrides = [
  clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 9, 28, 12))),
];

void main() {
  testWidgets('uses Geologica from the design tokens', (tester) async {
    await pumpApp(tester, overrides: _overrides);
    final context = tester.element(find.byType(FloatingTabBar));

    expect(Theme.of(context).textTheme.bodyMedium!.fontFamily, 'Geologica');
  });

  group('App locale resolution', () {
    final cases = <(String, List<Locale>, String)>[
      ('shows English Today tab for en', [const Locale('en')], 'Today'),
      ('shows Ukrainian Today tab for uk', [const Locale('uk')], 'Сьогодні'),
      (
        'shows Ukrainian Today tab for regional uk_UA',
        [const Locale('uk', 'UA')],
        'Сьогодні',
      ),
      (
        'shows English Today tab when regional en_UA comes before uk_UA',
        [const Locale('en', 'UA'), const Locale('uk', 'UA')],
        'Today',
      ),
      (
        'shows Ukrainian Today tab when regional uk_UA comes before en_UA',
        [const Locale('uk', 'UA'), const Locale('en', 'UA')],
        'Сьогодні',
      ),
      (
        'falls back to English for unsupported pl',
        [const Locale('pl')],
        'Today',
      ),
      (
        'prefers a supported second language over the fallback',
        [const Locale('pl'), const Locale('uk')],
        'Сьогодні',
      ),
    ];

    for (final (name, locales, title) in cases) {
      testWidgets(name, (tester) async {
        await pumpApp(tester, systemLocales: locales, overrides: _overrides);

        expect(
          find.descendant(
            of: find.byType(FloatingTabBar),
            matching: find.text(title),
          ),
          findsOneWidget,
        );
      });
    }
  });
}

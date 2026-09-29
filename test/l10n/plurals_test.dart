import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/l10n/app_localizations.dart';

void main() {
  final uk = lookupAppLocalizations(const Locale('uk'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('Ukrainian steps plural', () {
    final cases = <(int, String)>[
      (1, 'крок'),
      (2, 'кроки'),
      (4, 'кроки'),
      (5, 'кроків'),
      (11, 'кроків'),
      (12, 'кроків'),
      (21, 'крок'),
      (22, 'кроки'),
      (0, 'кроків'),
    ];
    for (final (count, word) in cases) {
      test('$count → $word', () => expect(uk.stepsUnit(count), word));
    }

    test('reaches the steps label and the week total', () {
      expect(uk.todayStepsLabel(21), 'крок сьогодні');
      expect(uk.todayStepsLabel(3), 'кроки сьогодні');
      expect(uk.todayStepsLabel(6870), 'кроків сьогодні');
      expect(uk.weekTotal(5, '5'), 'Разом 5 кроків');
    });
  });

  group('English steps plural', () {
    test('1 → step', () => expect(en.stepsUnit(1), 'step'));
    test('2 → steps', () => expect(en.stepsUnit(2), 'steps'));
    test('reaches the steps label and the week total', () {
      expect(en.todayStepsLabel(1), 'step today');
      expect(en.todayStepsLabel(6870), 'steps today');
      expect(en.weekTotal(2, '2'), '2 steps in total');
    });
  });
}

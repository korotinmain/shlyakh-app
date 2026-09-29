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

  group('Path plurals in Ukrainian', () {
    for (final (days, text) in [
      (1, '≈ 1 день у твоєму темпі'),
      (3, '≈ 3 дні у твоєму темпі'),
      (5, '≈ 5 днів у твоєму темпі'),
      (21, '≈ 21 день у твоєму темпі'),
    ]) {
      test('ETA of $days days', () => expect(uk.pathEta(days), text));
    }
    for (final (count, text) in [
      (0, "Перше сузір'я попереду"),
      (1, "Складено 1 сузір'я"),
      (3, "Складено 3 сузір'я"),
      (5, "Складено 5 сузір'їв"),
    ]) {
      test('$count complete', () => expect(uk.pathCompletedCount(count), text));
    }
    for (final (count, text) in [
      (1, '1 зоря'),
      (4, '4 зорі'),
      (23, '23 зорі'),
      (25, '25 зір'),
    ]) {
      test('$count stars', () => expect(uk.pathStarCount(count), text));
    }
  });

  group('Lit stars in Ukrainian', () {
    for (final (count, text) in [
      (1, 'Засвічено 1 зорю'),
      (4, 'Засвічено 4 зорі'),
      (27, 'Засвічено 27 зір'),
      (21, 'Засвічено 21 зорю'),
    ]) {
      test('$count', () => expect(uk.pathLitStars(count), text));
    }
  });

  group('Path plurals in English', () {
    test('ETA', () {
      expect(en.pathEta(1), '≈ 1 day at your pace');
      expect(en.pathEta(4), '≈ 4 days at your pace');
    });
    test('complete', () {
      expect(en.pathCompletedCount(0), 'Your first constellation is ahead');
      expect(en.pathCompletedCount(1), '1 constellation complete');
      expect(en.pathCompletedCount(5), '5 constellations complete');
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

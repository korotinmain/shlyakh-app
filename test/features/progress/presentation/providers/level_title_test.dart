import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/progress/domain/level_titles.dart';
import 'package:shlyakh/features/progress/presentation/providers/level_title.dart';
import 'package:shlyakh/l10n/app_localizations.dart';

// The level titles table of docs/PRODUCT.md: (uk masculine, uk feminine, en).
const _titles = <(String, String, String)>[
  ('Новачок', 'Новачка', 'Newcomer'),
  ('Перехожий', 'Перехожа', 'Passer-by'),
  ('Мандрівник', 'Мандрівниця', 'Wanderer'),
  ('Шукач стежок', 'Шукачка стежок', 'Pathfinder'),
  ('Знавець околиць', 'Знавчиня околиць', 'Local Guide'),
  ('Подорожній', 'Подорожня', 'Traveller'),
  ('Прочанин', 'Прочанка', 'Pilgrim'),
  ('Прудконогий', 'Прудконога', 'Swift-foot'),
  ('Посланець', 'Посланниця', 'Messenger'),
  ('Вартовий шляху', 'Вартова шляху', 'Road Warden'),
  ('Погонич', 'Погоничка', 'Drover'),
  ('Чумак', 'Чумачка', 'Salt Trader'),
  ('Бувалий чумак', 'Бувала чумачка', 'Seasoned Trader'),
  ('Знавець степу', 'Знавчиня степу', 'Steppe-wise'),
  ('Отаман валки', 'Отаманка валки', 'Caravan Chief'),
  ('Верховинець', 'Верховинка', 'Highlander'),
  ('Пастух полонин', 'Пастушка полонин', 'Meadow Shepherd'),
  ('Легінь', 'Легінка', 'Highland Daredevil'),
  ('Підкорювач перевалів', 'Підкорювачка перевалів', 'Pass Conqueror'),
  ('Володар вершин', 'Володарка вершин', 'Lord of the Peaks'),
  ('Зорезнавець', 'Зорезнавчиня', 'Stargazer'),
  ('Нічний мандрівник', 'Нічна мандрівниця', 'Night Wanderer'),
  ('Провідник за зорями', 'Провідниця за зорями', 'Star Guide'),
  ('Хранитель шляху', 'Хранителька шляху', 'Keeper of the Way'),
  ('Зоряний мандрівник', 'Зоряна мандрівниця', 'Star Wanderer'),
];

const _chapters = <(String, String)>[
  ('Рідний край', 'Home Land'),
  ('Битий шлях', 'The Beaten Road'),
  ('Чумацький тракт', 'The Salt Road'),
  ('Гори й перевали', 'Peaks and Passes'),
  ('Чумацький Шлях', 'The Milky Way'),
];

void main() {
  final uk = lookupAppLocalizations(const Locale('uk'));
  final en = lookupAppLocalizations(const Locale('en'));
  const male = GrammaticalGender.masculine;
  const female = GrammaticalGender.feminine;

  group('levelTitle', () {
    for (var i = 0; i < _titles.length; i++) {
      final level = i + 1;
      final (ukMale, ukFemale, english) = _titles[i];
      test('level $level is "$ukMale" / "$ukFemale" / "$english"', () {
        expect(levelTitle(uk, level, male), ukMale);
        expect(levelTitle(uk, level, female), ukFemale);
        expect(levelTitle(en, level, male), english);
        expect(levelTitle(en, level, female), english);
      });
    }

    test('adds a Roman degree on the continuation', () {
      expect(levelTitle(uk, 26, male), 'Зоряний мандрівник II');
      expect(levelTitle(uk, 29, female), 'Зоряна мандрівниця V');
      expect(levelTitle(en, 100, male), 'Star Wanderer LXXVI');
    });

    test('rejects level 0', () {
      expect(() => levelTitle(uk, 0, male), throwsArgumentError);
    });
  });

  group('levelChapter', () {
    for (var chapter = 1; chapter <= _chapters.length; chapter++) {
      final (ukName, enName) = _chapters[chapter - 1];
      final firstLevel = (chapter - 1) * levelsPerChapter + 1;
      test('chapter $chapter is "$ukName" / "$enName"', () {
        expect(levelChapter(uk, firstLevel), ukName);
        expect(levelChapter(en, firstLevel + levelsPerChapter - 1), enName);
      });
    }

    test('keeps the continuation in the last chapter', () {
      expect(levelChapter(en, 26), 'The Milky Way');
    });
  });

  test(
    'grammaticalGenderProvider defaults to masculine until registration',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(grammaticalGenderProvider), male);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/progress/domain/level_up.dart';

void main() {
  group('levelUp', () {
    test('nothing to celebrate at the celebrated level', () {
      expect(levelUp(celebrated: 4, current: 4), isNull);
    });

    test('nothing to celebrate below it (a level went down)', () {
      expect(levelUp(celebrated: 5, current: 2), isNull);
    });

    test('one level', () {
      _expectLevelUp(levelUp(celebrated: 1, current: 2), from: 1, to: 2);
    });

    test('several levels list the ones passed', () {
      expect(levelUp(celebrated: 1, current: 4)?.passed, [2, 3]);
    });

    test('reaching a chapter start opens the chapter', () {
      expect(levelUp(celebrated: 5, current: 6)?.newChapter, 2);
    });

    test('a chapter start inside the jump opens the chapter', () {
      final up = levelUp(celebrated: 4, current: 7);

      expect(up?.passed, [5, 6]);
      expect(up?.newChapter, 2);
    });

    test('passing level 25 finishes the main path', () {
      final up = levelUp(celebrated: 24, current: 26);

      expect(up?.passed, [25]);
      expect(up?.finishesMainPath, isTrue);
      expect(up?.newChapter, isNull);
    });

    test('continuation levels are plain', () {
      _expectLevelUp(levelUp(celebrated: 30, current: 31), from: 30, to: 31);
    });

    test('a level below 1 is rejected', () {
      expect(() => levelUp(celebrated: 0, current: 2), throwsArgumentError);
    });
  });
}

/// Records compare lists by identity, so the fields are checked one by one.
void _expectLevelUp(
  LevelUp? up, {
  required int from,
  required int to,
  List<int> passed = const [],
  int? newChapter,
  bool finishesMainPath = false,
}) {
  expect(up, isNotNull);
  expect(up!.from, from);
  expect(up.to, to);
  expect(up.passed, passed);
  expect(up.newChapter, newChapter);
  expect(up.finishesMainPath, finishesMainPath);
}

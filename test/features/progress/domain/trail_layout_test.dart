import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/progress/domain/trail_layout.dart';

void main() {
  group('trailNode', () {
    test('the line winds centre, left, centre, right', () {
      expect(
        [for (var l = 1; l <= 5; l++) trailNode(l).side],
        [
          TrailSide.centre,
          TrailSide.left,
          TrailSide.centre,
          TrailSide.right,
          TrailSide.centre,
        ],
      );
    });

    test('chapter starts are marked', () {
      expect(trailNode(1).startsChapter, isTrue);
      expect(trailNode(6).startsChapter, isTrue);
      expect(trailNode(21).startsChapter, isTrue);
      expect(trailNode(5).startsChapter, isFalse);
    });

    test('nodes know their chapter', () {
      expect(trailNode(6).chapter, 2);
      expect(trailNode(25).chapter, 5);
    });

    test('continuation levels stay in the last chapter', () {
      expect(trailNode(26), (
        level: 26,
        chapter: 5,
        side: TrailSide.left,
        startsChapter: false,
      ));
    });

    test('a level below 1 is rejected', () {
      expect(() => trailNode(0), throwsArgumentError);
    });
  });
}

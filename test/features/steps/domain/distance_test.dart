import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/features/steps/domain/distance.dart';

void main() {
  group('approximateDistanceMeters', () {
    final cases = <(int, int)>[(0, 0), (1, 1), (1000, 740), (10000, 7400)];
    for (final (steps, meters) in cases) {
      test('of $steps steps is $meters m', () {
        expect(approximateDistanceMeters(steps), meters);
      });
    }

    test('rejects negative steps', () {
      expect(() => approximateDistanceMeters(-1), throwsArgumentError);
    });
  });
}

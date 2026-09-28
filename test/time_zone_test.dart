import 'package:flutter_test/flutter_test.dart';

/// Tests with local `DateTime`s (DST, local midnight) only mean something
/// in a zone with DST; the suite runs with `TZ=Europe/Kyiv`, locally and
/// in CI, so every machine computes the same local times.
void main() {
  test('tests run in Europe/Kyiv', () {
    const reason = 'run the tests with TZ=Europe/Kyiv';

    expect(
      DateTime(2026, 9, 28).timeZoneOffset,
      const Duration(hours: 3),
      reason: reason,
    );
    // The last Sunday of October 2026 has 25 hours in Kyiv.
    expect(
      DateTime(2026, 10, 26).difference(DateTime(2026, 10, 25)),
      const Duration(hours: 25),
      reason: reason,
    );
  });
}

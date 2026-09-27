import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/sky/sky_keyframes.dart';
import 'package:shlyakh/core/design/sky/sky_palette.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/sky_provider.dart';

// Records compare their List fields by identity: compare by value.
Matcher _isPalette(SkyPalette expected) => predicate<SkyPalette>(
  (p) =>
      listEquals(p.sky, expected.sky) &&
      listEquals(p.hills, expected.hills) &&
      p.accent == expected.accent &&
      p.onSky == expected.onSky &&
      p.surfaceTone == expected.surfaceTone,
  'the palette of $expected',
);

bool listEquals(List<int> a, List<int> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) i].every((i) => a[i] == b[i]);

void main() {
  testWidgets('emits now and again at each minute boundary', (tester) async {
    // Dawn, so consecutive minutes give different colours.
    var now = DateTime(2026, 9, 28, 6, 30, 30);
    final start = now;
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(Clock(() => now))],
    );
    final values = <SkyPalette>[];
    container.listen(
      skyProvider,
      (_, next) => next.whenData(values.add),
      fireImmediately: true,
    );

    await tester.pump();
    expect(values, [_isPalette(skyAt(start))]);

    now = start.add(const Duration(seconds: 29));
    await tester.pump(const Duration(seconds: 29));
    expect(values, hasLength(1), reason: 'no value before the boundary');

    now = DateTime(2026, 9, 28, 6, 31);
    await tester.pump(const Duration(seconds: 1));
    expect(values, hasLength(2));
    expect(values.last, _isPalette(skyAt(DateTime(2026, 9, 28, 6, 31))));

    now = DateTime(2026, 9, 28, 6, 32);
    await tester.pump(const Duration(minutes: 1));
    expect(values, hasLength(3));
    expect(values.last, _isPalette(skyAt(DateTime(2026, 9, 28, 6, 32))));

    container.dispose();
    await tester.pump(const Duration(minutes: 2));
    expect(values, hasLength(3), reason: 'timers stop on dispose');
  });
}

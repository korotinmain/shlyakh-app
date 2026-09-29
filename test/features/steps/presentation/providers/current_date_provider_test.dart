import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/time/clock_provider.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/presentation/providers/current_date_provider.dart';

void main() {
  for (final (name, before, after, next) in [
    (
      'at midnight',
      DateTime(2026, 9, 28, 23, 59),
      DateTime(2026, 9, 29, 0, 0, 1),
      '2026-09-29',
    ),
    // 2026-10-25 is 25 hours long in Kyiv: the clocks go back at 04:00.
    (
      'on the night the clocks go back',
      DateTime(2026, 10, 25, 23, 30),
      DateTime(2026, 10, 26, 0, 0, 1),
      '2026-10-26',
    ),
  ]) {
    testWidgets('moves to the next day $name', (tester) async {
      var now = before;
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(Clock(() => now))],
      );
      final date = container.listen(currentDateProvider, (_, _) {});
      expect(date.read(), LocalDate.fromDateTime(before));

      now = after;
      await tester.pump(after.difference(before));

      expect(date.read(), LocalDate.parse(next));
      // Disposing cancels the next midnight's timer before the pending
      // timers check.
      container.dispose();
    });
  }

  testWidgets('stays on the day before midnight', (tester) async {
    var now = DateTime(2026, 9, 28, 23);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(Clock(() => now))],
    );
    final date = container.listen(currentDateProvider, (_, _) {});

    now = DateTime(2026, 9, 28, 23, 59);
    await tester.pump(const Duration(minutes: 59));

    expect(date.read(), LocalDate.parse('2026-09-28'));
    container.dispose();
  });
}

import 'package:clock/clock.dart' show Clock;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// The only source of "now" in the app.
///
/// Presentation reads this provider; domain classes receive a [Clock]
/// through their constructor. Tests override it with `Clock.fixed(...)`.
/// See docs/decisions/0002-explicit-clock-injection.md.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const Clock();

// SPIKE (throwaway): Dart <-> Swift bridge for the HealthKit spike.
// Regenerate with: dart run pigeon --input pigeons/health_spike_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/spike/health_spike_api.g.dart',
    swiftOut: 'ios/Runner/HealthSpikeApi.g.swift',
  ),
)
class NativeDailySteps {
  new({required this.localDate, required this.steps});

  /// Local calendar day, `yyyy-MM-dd`, as computed by iOS `Calendar.current`.
  String localDate;
  int steps;
}

class WakeupEvent {
  new({
    required this.epochMs,
    required this.appState,
    this.error,
  });

  int epochMs;

  /// `active`, `inactive` or `background` at the moment the observer fired.
  String appState;

  /// Observer error description, if any. Never contains health values.
  String? error;
}

@HostApi()
abstract class HealthSpikeHostApi {
  /// Daily step totals via HKStatisticsCollectionQuery (deduplicated by
  /// HealthKit), for the last [days] local days including today.
  @async
  List<NativeDailySteps> dailySteps(int days);

  /// Moments when HKObserverQuery fired, oldest first.
  List<WakeupEvent> wakeups();

  void clearWakeups();

  /// (Re)registers the observer query and background delivery. Called on
  /// launch natively, and from Dart right after authorization is granted.
  void startObserving();
}

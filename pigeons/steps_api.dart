// Dart <-> Swift bridge for HealthKit steps (ADR 0007).
// Regenerate with: dart run pigeon --input pigeons/steps_api.dart, then
// dart format lib/features/steps/data/healthkit/steps_api.g.dart
// The Dart output is not committed, the Swift output is (ADR 0001).
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/features/steps/data/healthkit/steps_api.g.dart',
    swiftOut: 'ios/Runner/Steps/StepsApi.g.swift',
  ),
)
/// One local day's step total.
class NativeDay {
  new({required this.localDate, required this.steps});

  /// `yyyy-MM-dd` in the device's current calendar and time zone.
  String localDate;

  /// Deduplicated by HealthKit, fractional steps truncated.
  int steps;
}

/// Calls from Dart into HealthKit. Errors carry the codes `unavailable`,
/// `locked` or `healthkit` and never a message.
@HostApi()
abstract class StepsHostApi {
  /// Whether HealthKit is available on this device.
  bool isAvailable();

  /// Shows the system prompt for read access to step count. Completes
  /// without saying what the user chose: iOS never tells.
  @async
  void requestAccess();

  /// Every local day from [fromEpochMs] to the end of today, oldest first;
  /// the first day is partial when [fromEpochMs] is not a local midnight.
  @async
  List<NativeDay> dailySteps(int fromEpochMs);

  /// The device's IANA time zone identifier, e.g. `Europe/Kyiv`.
  String timeZoneId();

  /// SPIKE: appends an event (time and app state added natively). Never
  /// pass step counts, dates or ids.
  void probeLog(String event);

  /// SPIKE: the journal, oldest first.
  List<String> probeJournal();

  /// SPIKE: clears the journal.
  void clearProbeJournal();
}

/// Calls from HealthKit's observer into Dart.
@FlutterApi()
abstract class StepsEventsApi {
  /// New step data exists. Completes when Dart has finished its sync.
  @async
  void onStepsChanged();
}

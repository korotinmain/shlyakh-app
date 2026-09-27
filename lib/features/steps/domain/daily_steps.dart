import 'package:shlyakh/features/steps/domain/local_date.dart';

/// One user's step total for one local day, as reported by HealthKit.
///
/// `timezone` is the IANA identifier (e.g. `Europe/Kyiv`) the day was
/// counted in. Keyed by (`userId`, `localDate`).
typedef DailySteps = ({
  String userId,
  LocalDate localDate,
  String timezone,
  int steps,
});

import 'package:shlyakh/features/steps/data/local/daily_steps_dao.dart';
import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';
import 'package:shlyakh/features/steps/domain/steps_repository.dart';

/// Steps from Drift, the local source of truth; `StepsSync` fills it from
/// HealthKit.
final class DriftStepsRepository implements StepsRepository {
  new(this._days);

  final DailyStepsDao _days;

  @override
  Stream<List<DailySteps>> watchDays({
    required String userId,
    LocalDate? from,
    LocalDate? to,
  }) => _days.watchForUser(userId, from: from, to: to);
}

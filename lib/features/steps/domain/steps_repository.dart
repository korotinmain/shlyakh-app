import 'package:shlyakh/features/steps/domain/daily_steps.dart';
import 'package:shlyakh/features/steps/domain/local_date.dart';

/// Source of a user's daily step totals.
abstract interface class StepsRepository {
  /// The days of [userId] between [from] and [to] (inclusive, either bound
  /// optional), ascending by date. Emits again whenever they change.
  Stream<List<DailySteps>> watchDays({
    required String userId,
    LocalDate? from,
    LocalDate? to,
  });
}

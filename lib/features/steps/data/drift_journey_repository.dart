import 'package:shlyakh/core/database/storage_errors.dart';
import 'package:shlyakh/features/steps/data/local/journey_start_dao.dart';
import 'package:shlyakh/features/steps/domain/journey_repository.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';

/// The journey start in Drift; SQLite errors become `StorageFailure`.
final class DriftJourneyRepository implements JourneyRepository {
  new(this._starts);

  final JourneyStartDao _starts;

  @override
  Stream<JourneyStart?> watchStart(String userId) =>
      _starts.watch(userId).translateStorageErrors();

  @override
  Future<bool> start(JourneyStart start) =>
      guardStorage(() => _starts.insertOnce(start));
}

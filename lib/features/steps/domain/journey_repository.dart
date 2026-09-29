import 'package:shlyakh/features/steps/domain/journey_start.dart';

/// Where a user's journey start is kept.
abstract interface class JourneyRepository {
  /// The start of [userId], null before it; emits again when it changes.
  Stream<JourneyStart?> watchStart(String userId);

  /// Stores [start] unless the user already has one, which is never
  /// overwritten. Returns whether it was stored.
  Future<bool> start(JourneyStart start);
}

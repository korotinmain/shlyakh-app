/// An expected failure a user can be told about
/// (docs/decisions/0005-error-handling.md).
///
/// Repositories translate specific low-level exceptions into a [Failure]
/// and keep the original as [cause]. Programmer errors (`ArgumentError`,
/// `StateError`) are never turned into failures.
sealed class Failure implements Exception {
  const new({this.cause});

  /// The original exception, for debugging only. Never logged or shown:
  /// its message may contain user data.
  final Object? cause;

  /// Stable name of the variant, also in obfuscated release builds.
  String get variantName;

  /// Only the variant name, so interpolating a failure cannot leak [cause].
  @override
  String toString() => variantName;
}

/// HealthKit read access was not granted or was revoked.
final class HealthAccessDenied extends Failure {
  const new({super.cause});

  @override
  String get variantName => 'HealthAccessDenied';
}

/// HealthKit is not available on this device.
final class HealthUnavailable extends Failure {
  const new({super.cause});

  @override
  String get variantName => 'HealthUnavailable';
}

/// HealthKit data is encrypted while the device is locked; a background
/// read failed.
final class HealthDataLocked extends Failure {
  const new({super.cause});

  @override
  String get variantName => 'HealthDataLocked';
}

/// The local database failed (disk full, corrupt file).
final class StorageFailure extends Failure {
  const new({super.cause});

  @override
  String get variantName => 'StorageFailure';
}

/// An unknown exception at a platform or SDK boundary.
final class UnexpectedFailure extends Failure {
  const new({super.cause});

  @override
  String get variantName => 'UnexpectedFailure';
}

/// Average step length used to estimate distance, in metres.
///
/// An approximation shown with "≈" (docs/PRODUCT.md); HealthKit distance
/// would need another permission.
const averageStepLengthMeters = 0.74;

/// Approximate distance walked with [steps], in whole metres.
///
/// Throws [ArgumentError] for negative steps.
int approximateDistanceMeters(int steps) {
  if (steps < 0) throw ArgumentError.value(steps, 'steps', 'must be >= 0');
  return (steps * averageStepLengthMeters).round();
}

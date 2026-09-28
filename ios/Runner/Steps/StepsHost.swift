import HealthKit

/// HealthKit behind `StepsHostApi` (ADR 0007). Reads step count only and
/// never puts health values into errors: `PigeonError.message` is nil.
final class StepsHost: StepsHostApi {
  static let shared = StepsHost()

  let store = HKHealthStore()
  let stepType = HKQuantityType(.stepCount)

  func isAvailable() throws -> Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  func requestAccess() async throws {
    guard HKHealthStore.isHealthDataAvailable() else { throw Self.unavailable }
    do {
      try await store.requestAuthorization(toShare: [], read: [stepType])
    } catch {
      throw Self.pigeonError(error)
    }
  }

  func dailySteps(fromEpochMs: Int64) async throws -> [NativeDay] {
    guard HKHealthStore.isHealthDataAvailable() else { throw Self.unavailable }
    let calendar = Calendar.current
    let from = Date(timeIntervalSince1970: TimeInterval(fromEpochMs) / 1000)
    guard let range = StepsDays.queryRange(from: from, now: Date(), calendar: calendar) else {
      return []
    }

    let collection: HKStatisticsCollection = try await withCheckedThrowingContinuation {
      continuation in
      let query = HKStatisticsCollectionQuery(
        quantityType: stepType,
        quantitySamplePredicate: HKQuery.predicateForSamples(
          withStart: range.from, end: range.end, options: .strictStartDate),
        options: .cumulativeSum,
        anchorDate: range.dayStart,
        intervalComponents: DateComponents(day: 1))
      query.initialResultsHandler = { _, result, error in
        if let result {
          continuation.resume(returning: result)
        } else {
          continuation.resume(throwing: Self.pigeonError(error))
        }
      }
      store.execute(query)
    }

    var days: [NativeDay] = []
    collection.enumerateStatistics(from: range.dayStart, to: range.end) { stats, _ in
      let sum = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
      days.append(
        NativeDay(
          localDate: StepsDays.localDateString(stats.startDate, calendar: calendar),
          steps: StepsDays.truncatedSteps(sum)))
    }
    return days
  }

  func timeZoneId() throws -> String {
    TimeZone.current.identifier
  }

  // MARK: Errors

  private static let unavailable = PigeonError(code: "unavailable", message: nil, details: nil)

  /// Maps a HealthKit error to the codes Dart knows; anything else keeps
  /// HealthKit's code as `details`.
  static func pigeonError(_ error: Error?) -> PigeonError {
    guard let error = error as? HKError else {
      return PigeonError(code: "healthkit", message: nil, details: nil)
    }
    switch error.code {
    case .errorHealthDataUnavailable: return unavailable
    case .errorDatabaseInaccessible:
      return PigeonError(code: "locked", message: nil, details: nil)
    default:
      return PigeonError(code: "healthkit", message: nil, details: error.code.rawValue)
    }
  }
}

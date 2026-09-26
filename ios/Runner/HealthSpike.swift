// SPIKE (throwaway): native HealthKit probe for stage 1 of the roadmap.
// Never logs step values: only wakeup timestamps and error descriptions.
import HealthKit
import UIKit

final class HealthSpike: HealthSpikeHostApi {
  static let shared = HealthSpike()

  private let store = HKHealthStore()
  private let stepType = HKQuantityType(.stepCount)
  private let wakeupsKey = "spike.healthkit.wakeups"
  private var observer: HKObserverQuery?

  /// Must run on every launch (from didFinishLaunching): iOS relaunches the
  /// app in the background and delivers updates only to observer queries
  /// registered before launch finishes.
  func startObserving() {
    guard HKHealthStore.isHealthDataAvailable() else { return }
    if let observer { store.stop(observer) }

    let query = HKObserverQuery(sampleType: stepType, predicate: nil) {
      [weak self] _, completionHandler, error in
      self?.recordWakeup(error: error)
      // Tell HealthKit we handled the update; otherwise it backs off.
      completionHandler()
    }
    observer = query
    store.execute(query)

    store.enableBackgroundDelivery(for: stepType, frequency: .immediate) {
      [weak self] success, error in
      if !success {
        self?.recordWakeup(error: error ?? PigeonError(
          code: "background-delivery", message: "enable returned false", details: nil))
      }
    }
  }

  // MARK: HealthSpikeHostApi

  func dailySteps(days: Int64) async throws -> [NativeDailySteps] {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())
    guard
      let start = calendar.date(byAdding: .day, value: -Int(days - 1), to: startOfToday),
      let end = calendar.date(byAdding: .day, value: 1, to: startOfToday)
    else {
      throw PigeonError(code: "date", message: "could not compute range", details: nil)
    }

    let collection: HKStatisticsCollection = try await withCheckedThrowingContinuation {
      continuation in
      let query = HKStatisticsCollectionQuery(
        quantityType: stepType,
        quantitySamplePredicate: HKQuery.predicateForSamples(
          withStart: start, end: end, options: .strictStartDate),
        options: .cumulativeSum,
        anchorDate: startOfToday,
        intervalComponents: DateComponents(day: 1))
      query.initialResultsHandler = { _, result, error in
        if let result {
          continuation.resume(returning: result)
        } else {
          continuation.resume(throwing: error ?? PigeonError(
            code: "query", message: "no result", details: nil))
        }
      }
      store.execute(query)
    }

    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"

    var result: [NativeDailySteps] = []
    collection.enumerateStatistics(from: start, to: end) { stats, _ in
      let steps = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
      result.append(NativeDailySteps(
        localDate: formatter.string(from: stats.startDate), steps: Int64(steps.rounded())))
    }
    return result
  }

  func wakeups() throws -> [WakeupEvent] {
    let raw = UserDefaults.standard.array(forKey: wakeupsKey) as? [[String: Any]] ?? []
    return raw.compactMap { entry in
      guard let epochMs = entry["epochMs"] as? Int64,
        let appState = entry["appState"] as? String
      else { return nil }
      return WakeupEvent(epochMs: epochMs, appState: appState, error: entry["error"] as? String)
    }
  }

  func clearWakeups() throws {
    UserDefaults.standard.removeObject(forKey: wakeupsKey)
  }

  // MARK: Private

  private func recordWakeup(error: Error?) {
    // applicationState must be read on the main thread; observer callbacks
    // arrive on a background queue.
    DispatchQueue.main.async { [self] in
      let state: String
      switch UIApplication.shared.applicationState {
      case .active: state = "active"
      case .inactive: state = "inactive"
      case .background: state = "background"
      @unknown default: state = "unknown"
      }
      var entry: [String: Any] = [
        "epochMs": Int64(Date().timeIntervalSince1970 * 1000),
        "appState": state,
      ]
      if let error { entry["error"] = error.localizedDescription }

      var all = UserDefaults.standard.array(forKey: wakeupsKey) as? [[String: Any]] ?? []
      all.append(entry)
      UserDefaults.standard.set(Array(all.suffix(500)), forKey: wakeupsKey)
    }
  }
}

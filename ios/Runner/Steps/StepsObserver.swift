import HealthKit

/// The step count observer with hourly background delivery (ADR 0007).
/// Registered on every launch before `didFinishLaunching` returns, and
/// again right after the access prompt.
@MainActor
final class StepsObserver {
  static let shared = StepsObserver()

  /// HealthKit's completion is called after Dart's sync, or after 20 s.
  let relay = StepsEventsRelay(timeout: 20)
  private var query: HKObserverQuery?

  func start() {
    guard HKHealthStore.isHealthDataAvailable() else { return }
    let host = StepsHost.shared
    if let query { host.store.stop(query) }

    let query = HKObserverQuery(sampleType: host.stepType, predicate: nil) {
      [weak self] _, completionHandler, error in
      // Called on a background queue.
      DispatchQueue.main.async {
        guard let self, error == nil else {
          completionHandler()
          return
        }
        self.relay.stepsChanged(completion: completionHandler)
      }
    }
    self.query = query
    host.store.execute(query)
    // A refused request only means no background wakeups; the app still
    // syncs on launch and in the foreground.
    host.store.enableBackgroundDelivery(for: host.stepType, frequency: .hourly) { _, _ in }
  }

  func attach(events: StepsEventsApiProtocol) {
    relay.attach(events)
  }
}

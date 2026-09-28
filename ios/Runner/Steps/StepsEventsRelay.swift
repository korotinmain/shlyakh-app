import Foundation

/// Passes observer wakeups to Dart and reports back when Dart is done.
///
/// A wakeup's completion runs after Dart's `onStepsChanged` returns (or
/// fails), or after `timeout`, whichever comes first. Wakeups that arrive
/// before Dart is attached (a cold background launch) wait for `attach`.
@MainActor
final class StepsEventsRelay {
  private let timeout: TimeInterval
  private var events: StepsEventsApiProtocol?
  private var waiting: [OnceCompletion] = []

  var isAttached: Bool { events != nil }  // SPIKE

  init(timeout: TimeInterval) {
    self.timeout = timeout
  }

  func attach(_ events: StepsEventsApiProtocol) {
    self.events = events
    let pending = waiting
    waiting = []
    pending.forEach(deliver)
  }

  func stepsChanged(completion: @escaping () -> Void) {
    let once = OnceCompletion(timeout: timeout, queue: .main, completion: completion)
    if events == nil {
      waiting.append(once)
    } else {
      deliver(once)
    }
  }

  private func deliver(_ once: OnceCompletion) {
    guard let events else { return }
    Task { @MainActor in
      // A failed reply (no Dart handler yet, a Dart error) still ends the
      // wakeup: HealthKit backs off when its completion is never called,
      // and the next launch or foreground syncs anyway.
      do {
        try await events.onStepsChanged()
        ProbeJournal.log("dart replied")
      } catch {
        ProbeJournal.log("dart reply failed")
      }
      once.fire()
    }
  }
}

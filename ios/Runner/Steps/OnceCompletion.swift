import Foundation

/// Runs `completion` exactly once: on the first `fire()` or when `timeout`
/// elapses, whichever comes first. HealthKit's observer completion handler
/// must always be called, even when Dart never replies.
final class OnceCompletion {
  private let lock = NSLock()
  private var completion: (() -> Void)?

  init(timeout: TimeInterval, queue: DispatchQueue, completion: @escaping () -> Void) {
    self.completion = completion
    // Strong capture: the timeout must fire even when nobody keeps this
    // object; fire() drops the completion, so nothing lingers after it.
    queue.asyncAfter(deadline: .now() + timeout) { self.fire() }
  }

  func fire() {
    lock.lock()
    let pending = completion
    completion = nil
    lock.unlock()
    pending?()
  }
}

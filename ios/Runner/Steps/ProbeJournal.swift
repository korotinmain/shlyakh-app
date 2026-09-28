// SPIKE (throwaway, never merged): journal of launches, observer wakeups
// and Dart syncs, to learn whether Dart runs in a background relaunch.
// Records times, app states and counts only; never step values.
import UIKit

enum ProbeJournal {
  private static let key = "spike.background-dart.journal"

  static func log(_ event: String) {
    DispatchQueue.main.async {
      let state: String
      switch UIApplication.shared.applicationState {
      case .active: state = "active"
      case .inactive: state = "inactive"
      case .background: state = "background"
      @unknown default: state = "unknown"
      }
      let formatter = DateFormatter()
      formatter.dateFormat = "MM-dd HH:mm:ss"
      var all = UserDefaults.standard.stringArray(forKey: key) ?? []
      all.append("\(formatter.string(from: Date())) [\(state)] \(event)")
      UserDefaults.standard.set(Array(all.suffix(400)), forKey: key)
    }
  }

  static func all() -> [String] {
    UserDefaults.standard.stringArray(forKey: key) ?? []
  }

  static func clear() {
    UserDefaults.standard.removeObject(forKey: key)
  }
}

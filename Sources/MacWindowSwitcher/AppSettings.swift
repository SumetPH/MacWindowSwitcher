import Combine
import Foundation
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
  struct Values {
    let switcherEnabled: Bool
  }

  private enum Key {
    static let switcherEnabled = "switcherEnabled"
  }

  @Published var switcherEnabled: Bool {
    didSet { saveAndNotify() }
  }
  @Published var launchAtLogin: Bool {
    didSet { updateLaunchAtLogin() }
  }

  var onChange: ((Values) -> Void)?

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    switcherEnabled = defaults.object(forKey: Key.switcherEnabled) as? Bool ?? true
    launchAtLogin = SMAppService.mainApp.status == .enabled
  }

  var values: Values {
    Values(
      switcherEnabled: switcherEnabled
    )
  }

  private func saveAndNotify() {
    defaults.set(switcherEnabled, forKey: Key.switcherEnabled)
    onChange?(values)
  }

  private func updateLaunchAtLogin() {
    let service = SMAppService.mainApp
    if launchAtLogin {
      if service.status != .enabled {
        do {
          try service.register()
        } catch {
          print("Failed to register SMAppService: \(error)")
        }
      }
    } else {
      if service.status == .enabled {
        do {
          try service.unregister()
        } catch {
          print("Failed to unregister SMAppService: \(error)")
        }
      }
    }
  }
}

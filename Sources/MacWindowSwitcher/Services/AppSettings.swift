import Combine
import Foundation
import ServiceManagement
import os

private let logger = Logger.forCategory("AppSettings")

@MainActor
final class AppSettings: ObservableObject {
  struct Values {
    let switcherEnabled: Bool
  }

  private enum Key {
    static let switcherEnabled = "switcherEnabled"
    static let hideMenuBarIcon = "hideMenuBarIcon"
  }

  @Published var switcherEnabled: Bool {
    didSet { saveAndNotify() }
  }
  @Published var hideMenuBarIcon: Bool {
    didSet {
      defaults.set(hideMenuBarIcon, forKey: Key.hideMenuBarIcon)
      onMenuBarIconVisibilityChange?(hideMenuBarIcon)
    }
  }
  @Published var launchAtLogin: Bool {
    didSet { updateLaunchAtLogin() }
  }

  var onChange: ((Values) -> Void)?
  var onMenuBarIconVisibilityChange: ((Bool) -> Void)?

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    switcherEnabled = defaults.object(forKey: Key.switcherEnabled) as? Bool ?? true
    hideMenuBarIcon = defaults.object(forKey: Key.hideMenuBarIcon) as? Bool ?? false
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
          logger.error("Failed to register SMAppService: \(String(describing: error), privacy: .public)")
        }
      }
    } else {
      if service.status == .enabled {
        do {
          try service.unregister()
        } catch {
          logger.error("Failed to unregister SMAppService: \(String(describing: error), privacy: .public)")
        }
      }
    }
  }
}

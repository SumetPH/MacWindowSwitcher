import AppKit
import Foundation
import ServiceManagement
import os

private let logger = Logger.forCategory("AppDelegate")

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = SwitcherController()
    private var settings: AppSettings?
    private var menuBarController: MenuBarController?
    
    private var permissionWindow: NSWindow?
    private var permissionTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application launching...")
        
        let appSettings = AppSettings()
        self.settings = appSettings
        self.menuBarController = MenuBarController(settings: appSettings)

        appSettings.onMenuBarIconVisibilityChange = { [weak self] hidden in
            self?.menuBarController?.setMenuBarIconHidden(hidden)
        }
        
        appSettings.onChange = { [weak self] values in
            guard let self else { return }
            if values.switcherEnabled {
                if PermissionManager.checkAccessibilityPermission() {
                    _ = self.controller.start()
                } else {
                    PermissionManager.requestAccessibilityPermissionPrompt()
                    self.showPermissionWindow()
                }
            } else {
                self.controller.stop()
            }
        }
        
        // Check for accessibility permissions at startup
        if PermissionManager.checkAccessibilityPermission() {
            startApp()
            if !Self.wasLaunchedAsLoginItem() {
                menuBarController?.showPanelTemporarilyIfNeeded()
            }
        } else {
            // Trigger prompt and show custom instructions window
            PermissionManager.requestAccessibilityPermissionPrompt()
            showPermissionWindow()
        }
    }

    // Only valid while handling the launch ('oapp') Apple event, i.e. in applicationDidFinishLaunching.
    private static func wasLaunchedAsLoginItem() -> Bool {
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuBarController?.showPanelTemporarilyIfNeeded()
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application terminating...")
        permissionTimer?.invalidate()
        controller.stop()
    }
    
    private func startApp() {
        guard let settings, settings.switcherEnabled else { return }
        logger.info("Starting event tap...")
        if !controller.start() {
            logger.error("Failed to start event tap. Showing permission window.")
            showPermissionWindow()
        }
    }
    
    private func showPermissionWindow() {
        guard permissionWindow == nil else { return }
        
        let window = PermissionWindow(
            target: self,
            openSettingsAction: #selector(openSettingsAction),
            quitAction: #selector(quitAction)
        )
        
        window.makeKeyAndOrderFront(nil)
        self.permissionWindow = window
        NSApp.activate(ignoringOtherApps: true)
        
        // Start polling for permission status
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if PermissionManager.checkAccessibilityPermission() {
                    logger.info("Accessibility permission granted dynamically!")
                    self.permissionTimer?.invalidate()
                    self.permissionTimer = nil
                    self.permissionWindow?.close()
                    self.permissionWindow = nil
                    self.startApp()
                    self.menuBarController?.showPanelTemporarilyIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func openSettingsAction() {
        PermissionManager.openAccessibilitySettings()
    }
    
    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}

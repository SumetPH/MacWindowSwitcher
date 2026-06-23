import AppKit
import Foundation
import ServiceManagement

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = SwitcherController()
    private var settings: AppSettings?
    private var menuBarController: MenuBarController?
    
    private var permissionWindow: NSWindow?
    private var permissionTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[MacWindowSwitcher] [AppDelegate] Application launching...")
        
        let appSettings = AppSettings()
        self.settings = appSettings
        self.menuBarController = MenuBarController(settings: appSettings)
        
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
        } else {
            // Trigger prompt and show custom instructions window
            PermissionManager.requestAccessibilityPermissionPrompt()
            showPermissionWindow()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("[MacWindowSwitcher] [AppDelegate] Application terminating...")
        permissionTimer?.invalidate()
        controller.stop()
    }
    
    private func startApp() {
        guard let settings, settings.switcherEnabled else { return }
        NSLog("[MacWindowSwitcher] [AppDelegate] Starting event tap...")
        if !controller.start() {
            NSLog("[MacWindowSwitcher] [AppDelegate] Failed to start event tap. Showing permission window.")
            showPermissionWindow()
        }
    }
    
    private func showPermissionWindow() {
        guard permissionWindow == nil else { return }
        
        let width: CGFloat = 380
        let height: CGFloat = 180
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Mac Window Switcher Setup"
        window.center()
        window.isReleasedWhenClosed = false
        
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 16
        container.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = NSTextField(labelWithString: "Accessibility Permission Required")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 15)
        titleLabel.alignment = .center
        container.addArrangedSubview(titleLabel)
        
        let descLabel = NSTextField(labelWithString: "Mac Window Switcher requires Accessibility privileges to monitor the Cmd+Tab hotkey and bring selected windows to the front.")
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.lineBreakMode = .byWordWrapping
        container.addArrangedSubview(descLabel)
        
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        
        let settingsButton = NSButton(title: "Open System Settings", target: self, action: #selector(openSettingsAction))
        settingsButton.bezelStyle = .rounded
        buttonStack.addArrangedSubview(settingsButton)
        
        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quitAction))
        quitButton.bezelStyle = .rounded
        buttonStack.addArrangedSubview(quitButton)
        
        container.addArrangedSubview(buttonStack)
        window.contentView = container
        
        if let contentView = window.contentView {
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                container.topAnchor.constraint(equalTo: contentView.topAnchor),
                container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                
                settingsButton.widthAnchor.constraint(equalToConstant: 160),
                quitButton.widthAnchor.constraint(equalToConstant: 80)
            ])
        }
        
        window.makeKeyAndOrderFront(nil)
        self.permissionWindow = window
        NSApp.activate(ignoringOtherApps: true)
        
        // Start polling for permission status
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if PermissionManager.checkAccessibilityPermission() {
                    NSLog("[MacWindowSwitcher] [AppDelegate] Accessibility permission granted dynamically!")
                    self.permissionTimer?.invalidate()
                    self.permissionTimer = nil
                    self.permissionWindow?.close()
                    self.permissionWindow = nil
                    self.startApp()
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

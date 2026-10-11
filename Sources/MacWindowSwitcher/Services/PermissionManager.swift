import AppKit
import ApplicationServices

class PermissionManager {
    /// Checks if the app is trusted to use Accessibility APIs.
    static func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Requests accessibility permission, displaying the system prompt if not already trusted.
    static func requestAccessibilityPermissionPrompt() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Opens System Settings directly to the Accessibility privacy panel.
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback for older macOS
            if let fallbackUrl = URL(string: "macappstore://showPrivacySettingsPage?section=Accessibility") {
                NSWorkspace.shared.open(fallbackUrl)
            }
        }
    }
    
    /// Opens System Settings directly to the Input Monitoring privacy panel.
    static func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring") {
            NSWorkspace.shared.open(url)
        }
    }
}

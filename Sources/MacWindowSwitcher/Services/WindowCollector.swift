import AppKit
import ApplicationServices
import CoreGraphics
import MacWindowSwitcherCore
import os

private let logger = Logger.forCategory("WindowCollector")

class WindowCollector {
    static func focusedWindowID() -> CGWindowID? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let getWindow = PrivateApis.AXUIElementGetWindow else { return nil }
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.1)
        var focusedRef: AnyObject?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &focusedRef) == .success,
              let focusedRef,
              CFGetTypeID(focusedRef) == AXUIElementGetTypeID() else { return nil }
        let focusedWindow = focusedRef as! AXUIElement
        var windowID: CGWindowID = 0
        return getWindow(focusedWindow, &windowID) == .success ? windowID : nil
    }

    /// Collects and filters all switchable window candidates across all applications.
    static func collectCandidates() -> [WindowCandidate] {
        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            logger.error("Failed to retrieve window list.")
            return []
        }
        
        var candidates: [WindowCandidate] = []
        let runningApps = NSWorkspace.shared.runningApplications
        let pidToApp = Dictionary(uniqueKeysWithValues: runningApps.map { ($0.processIdentifier, $0) })
        
        // Batch by application while retaining the front-to-back (last-focused) app order.
        let windowInfoGroups = WindowFilterRules.groupWindowInfosPreservingOwnerOrder(
            infoList,
            frontmostPID: NSWorkspace.shared.frontmostApplication?.processIdentifier
        )

        for (pid, infos) in windowInfoGroups {
            guard let app = pidToApp[pid] ?? NSRunningApplication(processIdentifier: pid) else { continue }
            
            // Only include regular user-interactive apps.
            // Exclude helper tools, background daemons, and hidden applications.
            guard app.activationPolicy == .regular else { continue }
            guard !app.isHidden else { continue }
            
            // Query application window references via Accessibility API
            let appElement = AXUIElementCreateApplication(pid)
            // Set message timeout to 100ms so we don't hang on unresponsive applications.
            AXUIElementSetMessagingTimeout(appElement, 0.1)
            
            var windowsRef: AnyObject?
            let axStatus = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
            
            var axWindowMap: [CGWindowID: AXUIElement] = [:]
            let canMatchAXWindows = axStatus == .success && PrivateApis.AXUIElementGetWindow != nil
            if axStatus == .success, let axWindows = windowsRef as? [AXUIElement] {
                for axWindow in axWindows {
                    var axWindowID: CGWindowID = 0
                    if let getWindowFunc = PrivateApis.AXUIElementGetWindow {
                        if getWindowFunc(axWindow, &axWindowID) == .success {
                            axWindowMap[axWindowID] = axWindow
                        }
                    }
                }
            }
            
            for info in infos {
                // Layer, alpha, and bounds rules live in Core so they can be unit tested.
                guard let (windowID, bounds) = WindowFilterRules.switchableWindow(from: info) else { continue }
                
                // Check minimized state or invalid AX roles
                let axWindow = axWindowMap[windowID]
                if canMatchAXWindows, axWindow == nil {
                    continue
                }

                if let axWindow = axWindow {
                    if !isSwitchableAXWindow(axWindow) {
                        continue
                    }
                }
                
                let appName = app.localizedName ?? (info[kCGWindowOwnerName as String] as? String ?? "")
                let cgWindowTitle = info[kCGWindowName as String] as? String ?? ""
                let windowTitle = titleForWindow(cgTitle: cgWindowTitle, axWindow: axWindow)
                if WindowFilterRules.isTransientHelperWindow(appName: appName, title: windowTitle) {
                    continue
                }
                
                let appIcon = app.icon ?? NSWorkspace.shared.icon(forFile: app.bundleURL?.path ?? "")
                
                let candidate = WindowCandidate(
                    windowID: windowID,
                    pid: pid,
                    appName: appName,
                    windowTitle: windowTitle,
                    appIcon: appIcon,
                    axWindow: axWindow,
                    cgBounds: bounds
                )
                candidates.append(candidate)
            }
        }
        
        return candidates
    }

    private static func isSwitchableAXWindow(_ axWindow: AXUIElement) -> Bool {
        var minimizedValue: AnyObject?
        if AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minimizedValue) == .success,
           let isMinimized = minimizedValue as? Bool, isMinimized {
            return false
        }

        var roleValue: AnyObject?
        if AXUIElementCopyAttributeValue(axWindow, kAXRoleAttribute as CFString, &roleValue) == .success,
           let role = roleValue as? String, role != kAXWindowRole {
            return false
        }

        var subroleValue: AnyObject?
        if AXUIElementCopyAttributeValue(axWindow, kAXSubroleAttribute as CFString, &subroleValue) == .success,
           let subrole = subroleValue as? String,
           subrole != kAXStandardWindowSubrole {
            return false
        }

        return true
    }

    private static func titleForWindow(cgTitle: String, axWindow: AXUIElement?) -> String {
        if !cgTitle.isEmpty {
            return cgTitle
        }

        guard let axWindow = axWindow else {
            return ""
        }

        var axTitle: AnyObject?
        if AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &axTitle) == .success,
           let title = axTitle as? String,
           !title.isEmpty {
            return title
        }

        return cgTitle
    }
}

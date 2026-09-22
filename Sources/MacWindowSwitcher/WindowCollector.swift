import AppKit
import ApplicationServices
import CoreGraphics

class WindowCollector {
    typealias WindowInfoGroup = (pid: pid_t, infos: [[String: Any]])

    /// Groups windows without losing the front-to-back owner order from Core Graphics.
    static func groupWindowInfosPreservingOwnerOrder(
        _ infoList: [[String: Any]],
        frontmostPID: pid_t? = nil
    ) -> [WindowInfoGroup] {
        var ownerOrder: [pid_t] = []
        var infosByPID: [pid_t: [[String: Any]]] = [:]

        for info in infoList {
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t else { continue }
            if infosByPID[pid] == nil {
                ownerOrder.append(pid)
            }
            infosByPID[pid, default: []].append(info)
        }

        var groups = ownerOrder.map { pid in
            (pid: pid, infos: infosByPID[pid] ?? [])
        }

        if let frontmostPID,
           let index = groups.firstIndex(where: { $0.pid == frontmostPID }),
           index != 0 {
            groups.insert(groups.remove(at: index), at: 0)
        }

        return groups
    }

    /// Collects and filters all switchable window candidates across all applications.
    static func collectCandidates() -> [WindowCandidate] {
        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            NSLog("[MacWindowSwitcher] [WindowCollector] Failed to retrieve window list.")
            return []
        }
        
        var candidates: [WindowCandidate] = []
        let runningApps = NSWorkspace.shared.runningApplications
        let pidToApp = Dictionary(uniqueKeysWithValues: runningApps.map { ($0.processIdentifier, $0) })
        
        // Batch by application while retaining the front-to-back (last-focused) app order.
        let windowInfoGroups = groupWindowInfosPreservingOwnerOrder(
            infoList,
            frontmostPID: NSWorkspace.shared.frontmostApplication?.processIdentifier
        )

        for (pid, infos) in windowInfoGroups {
            guard let app = pidToApp[pid] else { continue }
            
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
                guard let windowID = info[kCGWindowNumber as String] as? CGWindowID else { continue }
                guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
                
                // Exclude invisible windows (alpha 0)
                if let alpha = info[kCGWindowAlpha as String] as? Double, alpha == 0 { continue }
                
                // Exclude windows with invalid/empty/too small bounds (filter shadows/helpers)
                guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                      let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }
                guard bounds.width > 50 && bounds.height > 50 else { continue }
                
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
                if isTransientChromeFindWindow(appName: appName, title: windowTitle) {
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

    private static func isTransientChromeFindWindow(appName: String, title: String) -> Bool {
        appName == "Google Chrome" && title == "Find in page"
    }
}

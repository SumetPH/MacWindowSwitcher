import AppKit
import ApplicationServices
import CoreGraphics

class WindowCollector {
    typealias WindowInfoGroup = (pid: pid_t, infos: [[String: Any]])

    /// Groups windows without losing the front-to-back owner order from Core Graphics.
    static func groupWindowInfosPreservingOwnerOrder(_ infoList: [[String: Any]]) -> [WindowInfoGroup] {
        var ownerOrder: [pid_t] = []
        var infosByPID: [pid_t: [[String: Any]]] = [:]

        for info in infoList {
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t else { continue }
            if infosByPID[pid] == nil {
                ownerOrder.append(pid)
            }
            infosByPID[pid, default: []].append(info)
        }

        return ownerOrder.map { pid in
            (pid: pid, infos: infosByPID[pid] ?? [])
        }
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
        let windowInfoGroups = groupWindowInfosPreservingOwnerOrder(infoList)

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
                if let axWindow = axWindow {
                    var minimizedValue: AnyObject?
                    if AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minimizedValue) == .success,
                       let isMinimized = minimizedValue as? Bool, isMinimized {
                        continue
                    }
                    
                    var roleValue: AnyObject?
                    if AXUIElementCopyAttributeValue(axWindow, kAXRoleAttribute as CFString, &roleValue) == .success,
                       let role = roleValue as? String, role != kAXWindowRole {
                        continue
                    }
                }
                
                let appName = app.localizedName ?? (info[kCGWindowOwnerName as String] as? String ?? "")
                var windowTitle = info[kCGWindowName as String] as? String ?? ""
                
                // Fallback title query via AX if window info has empty string
                if windowTitle.isEmpty, let axWindow = axWindow {
                    var axTitle: AnyObject?
                    if AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &axTitle) == .success,
                       let titleStr = axTitle as? String {
                        windowTitle = titleStr
                    }
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
}

import AppKit
import ApplicationServices

class WindowActivator {
    /// Activates the owning application and raises the specific window candidate.
    static func activate(candidate: WindowCandidate) {
        let pid = candidate.pid
        let windowID = candidate.windowID
        
        NSLog("[MacWindowSwitcher] [WindowActivator] Activating app: \(candidate.appName) (PID: \(pid), Window: \(windowID))")
        
        // 1. Activate the owning application
        if let app = NSRunningApplication(processIdentifier: pid) {
            let options: NSApplication.ActivationOptions = [.activateIgnoringOtherApps]
            app.activate(options: options)
        }
        
        // 2. Focus and raise the window via Accessibility API
        if let axWindow = candidate.axWindow {
            focusAndRaise(axWindow: axWindow)
        } else {
            // Fallback: If AX reference was missing during collection, query it dynamically
            NSLog("[MacWindowSwitcher] [WindowActivator] AX reference missing. Performing fallback scan.")
            let appRef = AXUIElementCreateApplication(pid)
            AXUIElementSetMessagingTimeout(appRef, 0.1)
            var windowsRef: AnyObject?
            if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef) == .success,
               let axWindows = windowsRef as? [AXUIElement] {
                for axWindow in axWindows {
                    var axWindowID: CGWindowID = 0
                    if let getWindowFunc = PrivateApis.AXUIElementGetWindow {
                        if getWindowFunc(axWindow, &axWindowID) == .success, axWindowID == windowID {
                            focusAndRaise(axWindow: axWindow)
                            break
                        }
                    }
                }
            }
        }
    }
    
    private static func focusAndRaise(axWindow: AXUIElement) {
        // Perform AXRaise to bring the window to the front
        let raiseStatus = AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
        if raiseStatus != .success {
            NSLog("[MacWindowSwitcher] [WindowActivator] AXRaise action returned: \(raiseStatus.rawValue)")
        }
        
        // Set main attribute to true (primary window)
        AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
        
        // Set focused attribute to true (focus keyboard cursor)
        AXUIElementSetAttributeValue(axWindow, kAXFocusedAttribute as CFString, kCFBooleanTrue)
    }
}

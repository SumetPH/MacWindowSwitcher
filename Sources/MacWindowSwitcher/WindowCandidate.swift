import AppKit
import ApplicationServices

struct WindowCandidate {
    /// Unique Window identifier within Core Graphics window server.
    let windowID: CGWindowID
    
    /// Process identifier of the application owning the window.
    let pid: pid_t
    
    /// User-facing application name.
    let appName: String
    
    /// Window title, falls back to empty if not provided.
    let windowTitle: String
    
    /// Application icon image.
    let appIcon: NSImage
    
    /// Accessibility reference of the window, used for focusing/raising.
    let axWindow: AXUIElement?
    
    /// Bounding box geometry of the window in Core Graphics coordinates (y-down).
    let cgBounds: CGRect
}

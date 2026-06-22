import Foundation
import ApplicationServices
import CoreGraphics

/// Helper class to dynamically load private SkyLight/CGS and Accessibility APIs.
/// This prevents crashes at startup if any signature changes or symbols are missing.
class PrivateApis {
    typealias SLSMainConnectionIDType = @convention(c) () -> UInt32
    typealias CGSCopyManagedDisplaySpacesType = @convention(c) (UInt32) -> CFArray?
    typealias CGSCopySpacesForWindowsType = @convention(c) (UInt32, Int32, CFArray) -> CFArray?
    typealias AXUIElementGetWindowType = @convention(c) (AXUIElement, UnsafeMutablePointer<CGWindowID>) -> AXError

    /// Resolves SLSMainConnectionID dynamically from SkyLight.framework
    static let SLSMainConnectionID: SLSMainConnectionIDType? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY) else {
            NSLog("[MacWindowSwitcher] [PrivateApis] Failed to dlopen SkyLight.framework")
            return nil
        }
        guard let sym = dlsym(handle, "SLSMainConnectionID") else {
            NSLog("[MacWindowSwitcher] [PrivateApis] Failed to locate SLSMainConnectionID")
            return nil
        }
        return unsafeBitCast(sym, to: SLSMainConnectionIDType.self)
    }()

    /// Resolves CGSCopyManagedDisplaySpaces dynamically from SkyLight.framework
    static let CGSCopyManagedDisplaySpaces: CGSCopyManagedDisplaySpacesType? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY) else {
            return nil
        }
        guard let sym = dlsym(handle, "CGSCopyManagedDisplaySpaces") else {
            NSLog("[MacWindowSwitcher] [PrivateApis] Failed to locate CGSCopyManagedDisplaySpaces")
            return nil
        }
        return unsafeBitCast(sym, to: CGSCopyManagedDisplaySpacesType.self)
    }()

    /// Resolves CGSCopySpacesForWindows dynamically from SkyLight.framework
    static let CGSCopySpacesForWindows: CGSCopySpacesForWindowsType? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY) else {
            return nil
        }
        guard let sym = dlsym(handle, "CGSCopySpacesForWindows") else {
            NSLog("[MacWindowSwitcher] [PrivateApis] Failed to locate CGSCopySpacesForWindows")
            return nil
        }
        return unsafeBitCast(sym, to: CGSCopySpacesForWindowsType.self)
    }()

    /// Resolves the private _AXUIElementGetWindow function dynamically
    static let AXUIElementGetWindow: AXUIElementGetWindowType? = {
        guard let handle = dlopen(nil, RTLD_LAZY) else {
            return nil
        }
        guard let sym = dlsym(handle, "_AXUIElementGetWindow") else {
            NSLog("[MacWindowSwitcher] [PrivateApis] Failed to locate _AXUIElementGetWindow")
            return nil
        }
        return unsafeBitCast(sym, to: AXUIElementGetWindowType.self)
    }()
}

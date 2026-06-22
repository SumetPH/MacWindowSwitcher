import AppKit
@preconcurrency import CoreGraphics

@MainActor
protocol KeyboardEventTapDelegate: AnyObject {
    /// Returns true if the key down event was handled and should be swallowed (suppressed).
    func handleKeyDown(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool
    
    /// Returns true if the key up event was handled and should be swallowed (suppressed).
    func handleKeyUp(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool
    
    /// Returns true if the flags changed event was handled and should be swallowed (suppressed).
    func handleFlagsChanged(flags: CGEventFlags) -> Bool
}

/// A Sendable wrapper around UnsafeMutableRawPointer to allow safe transfer across actor boundaries
struct SendablePointer: @unchecked Sendable {
    let pointer: UnsafeMutableRawPointer
}

private func keyboardEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let sendableUserInfo = SendablePointer(pointer: userInfo)
    
    // Auto-recovery if macOS disables the event tap due to timeout or user intervention
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        MainActor.assumeIsolated {
            let tap = Unmanaged<KeyboardEventTap>.fromOpaque(sendableUserInfo.pointer).takeUnretainedValue()
            if let machPort = tap.machPort {
                CGEvent.tapEnable(tap: machPort, enable: true)
            }
            NSLog("[MacWindowSwitcher] [KeyboardEventTap] Re-enabled event tap due to timeout or user input disable.")
        }
        return Unmanaged.passUnretained(event)
    }
    
    let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = event.flags
    
    // Invoke delegate on the MainActor, passing only Sendable value types (keyCode, flags)
    let swallowed = MainActor.assumeIsolated { [sendableUserInfo] () -> Bool in
        let tap = Unmanaged<KeyboardEventTap>.fromOpaque(sendableUserInfo.pointer).takeUnretainedValue()
        guard let delegate = tap.delegate else {
            return false
        }
        
        switch type {
        case .keyDown:
            return delegate.handleKeyDown(keyCode: keyCode, flags: flags)
        case .keyUp:
            return delegate.handleKeyUp(keyCode: keyCode, flags: flags)
        case .flagsChanged:
            return delegate.handleFlagsChanged(flags: flags)
        default:
            return false
        }
    }
    
    if swallowed {
        return nil // swallow event (suppress from system/other apps)
    } else {
        return Unmanaged.passUnretained(event) // let event pass through
    }
}

class KeyboardEventTap {
    weak var delegate: KeyboardEventTapDelegate?
    fileprivate var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init() {}
    
    /// Starts the global session keyboard event tap.
    /// Returns true if successful, false otherwise.
    func start() -> Bool {
        let mask = (1 << CGEventType.keyDown.rawValue) |
                   (1 << CGEventType.keyUp.rawValue) |
                   (1 << CGEventType.flagsChanged.rawValue)
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        // Use cgSessionEventTap to intercept keyboard shortcuts globally at the session level
        machPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: keyboardEventCallback,
            userInfo: selfPointer
        )
        
        guard let machPort else {
            NSLog("[MacWindowSwitcher] [KeyboardEventTap] Failed to create event tap. Accessibility permission is likely missing.")
            return false
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0)
        guard let runLoopSource else {
            NSLog("[MacWindowSwitcher] [KeyboardEventTap] Failed to create run loop source.")
            return false
        }
        
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: machPort, enable: true)
        
        NSLog("[MacWindowSwitcher] [KeyboardEventTap] Event tap started successfully.")
        return true
    }
    
    /// Stops the global keyboard event tap and cleans up sources.
    func stop() {
        if let machPort {
            CGEvent.tapEnable(tap: machPort, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        machPort = nil
        runLoopSource = nil
        NSLog("[MacWindowSwitcher] [KeyboardEventTap] Event tap stopped.")
    }
}

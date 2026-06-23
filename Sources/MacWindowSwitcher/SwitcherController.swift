import AppKit
import CoreGraphics

@MainActor
class SwitcherController: KeyboardEventTapDelegate {
    private let eventTap = KeyboardEventTap()
    private var candidates: [WindowCandidate] = []
    private var selectedIndex: Int = 0
    private var isSwitcherActive: Bool = false
    
    private var overlayWindow: SwitcherOverlayWindow?
    private var overlayView: SwitcherOverlayView?
    
    init() {
        eventTap.delegate = self
    }
    
    func start() -> Bool {
        return eventTap.start()
    }
    
    func stop() {
        eventTap.stop()
        hideOverlay()
    }
    
    // MARK: - KeyboardEventTapDelegate
    
    func handleKeyDown(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        // Tab key code is 48
        if keyCode == 48 {
            // Must have Command key pressed
            if flags.contains(.maskCommand) {
                let isShiftPressed = flags.contains(.maskShift)
                
                if !isSwitcherActive {
                    // 1. First trigger: Scan and collect windows
                    let allCandidates = WindowCollector.collectCandidates()
                    let spaceFiltered = filterByCurrentSpace(allCandidates)
                    let screenFiltered = filterByScreenContainingMouse(spaceFiltered)
                    
                    // Cap candidates to a reasonable maximum (e.g. 8) to fit on screen
                    let maxCandidates = 8
                    if screenFiltered.count > maxCandidates {
                        self.candidates = Array(screenFiltered.prefix(maxCandidates))
                    } else {
                        self.candidates = screenFiltered
                    }
                    
                    if candidates.isEmpty {
                        // Suppress anyway to avoid native switcher showing
                        return true
                    }
                    
                    // Set selected index: normally index 1 (previous window) on first press
                    selectedIndex = 0
                    isSwitcherActive = true
                    
                    // Immediately cycle once
                    cycle(forward: !isShiftPressed)
                    
                    // 2. Display overlay
                    showOverlay()
                } else {
                    // Subsequent Tab presses: cycle selection
                    cycle(forward: !isShiftPressed)
                    overlayView?.updateSelection(index: selectedIndex)
                }
                
                return true // Swallow key press
            }
        }
        
        // Escape key code is 53
        if keyCode == 53 && isSwitcherActive {
            hideOverlay()
            isSwitcherActive = false
            return true // Swallow escape key press
        }
        
        // Swallow other key inputs while switcher is open to prevent background leak
        if isSwitcherActive {
            return true
        }
        
        return false
    }
    
    func handleKeyUp(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        // Swallow Tab key up if the switcher is currently active
        if keyCode == 48 && isSwitcherActive {
            return true
        }
        
        // Swallow other key ups while switcher is open
        if isSwitcherActive {
            return true
        }
        
        return false
    }
    
    func handleFlagsChanged(flags: CGEventFlags) -> Bool {
        // Check if command key is released
        let commandPressed = flags.contains(.maskCommand)
        
        if isSwitcherActive && !commandPressed {
            // Confirm selection and activate window
            let targetCandidate = candidates[selectedIndex]
            
            hideOverlay()
            isSwitcherActive = false
            
            WindowActivator.activate(candidate: targetCandidate)
            
            // Let the modifier release pass through to system cleanly
            return false
        }
        
        return false
    }
    
    // MARK: - Filtering Methods
    
    private func filterByCurrentSpace(_ list: [WindowCandidate]) -> [WindowCandidate] {
        let activeSpaces = SpaceManager.getActiveSpaceIDs()
        if activeSpaces.isEmpty {
            NSLog("[MacWindowSwitcher] [SwitcherController] Active Spaces list empty. Skipping space filter.")
            return list
        }
        
        return list.filter { candidate in
            let windowSpaces = SpaceManager.getSpaceIDs(forWindowID: candidate.windowID)
            // If API fails or window has no assigned spaces, retain it as fallback
            if windowSpaces.isEmpty {
                return true
            }
            return !activeSpaces.isDisjoint(with: windowSpaces)
        }
    }
    
    private func filterByScreenContainingMouse(_ list: [WindowCandidate]) -> [WindowCandidate] {
        guard let mouseScreen = ScreenManager.getScreenContainingMouse() else {
            return list
        }
        
        return list.filter { candidate in
            let winScreen = ScreenManager.getScreenWithLargestIntersection(forCGFrame: candidate.cgBounds)
            return winScreen == mouseScreen
        }
    }
    
    // MARK: - Cycle & Overlay
    
    private func cycle(forward: Bool) {
        guard !candidates.isEmpty else { return }
        if forward {
            selectedIndex = (selectedIndex + 1) % candidates.count
        } else {
            selectedIndex = (selectedIndex - 1 + candidates.count) % candidates.count
        }
    }
    
    private func showOverlay() {
        guard !candidates.isEmpty else { return }
        
        let count = candidates.count
        let cardWidth: CGFloat = 160
        let spacing: CGFloat = 10
        let padding: CGFloat = 14
        
        let width = CGFloat(padding * 2 + cardWidth * CGFloat(count) + spacing * CGFloat(count - 1))
        let height: CGFloat = 120 + padding * 2
        
        guard let screen = ScreenManager.getScreenContainingMouse() else { return }
        let screenFrame = screen.frame
        
        // Center on screen
        let rect = NSRect(
            x: screenFrame.origin.x + (screenFrame.width - width) / 2,
            y: screenFrame.origin.y + (screenFrame.height - height) / 2,
            width: width,
            height: height
        )
        
        hideOverlay()
        
        let window = SwitcherOverlayWindow(contentRect: rect)
        let view = SwitcherOverlayView(candidates: candidates, selectedIndex: selectedIndex)
        
        window.contentView = view
        self.overlayWindow = window
        self.overlayView = view
        
        // Show panel without stealing key focus
        window.orderFrontRegardless()
    }
    
    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
        overlayWindow?.close()
        overlayWindow = nil
        overlayView = nil
    }
}

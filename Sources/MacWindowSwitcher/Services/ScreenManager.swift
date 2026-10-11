import AppKit
import CoreGraphics
import MacWindowSwitcherCore

class ScreenManager {
    /// Detects which screen currently contains the mouse cursor.
    static func getScreenContainingMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            if NSMouseInRect(mouseLocation, screen.frame, false) {
                return screen
            }
        }
        return NSScreen.main
    }
    
    /// Returns the height of the primary screen (first screen in list),
    /// which acts as the reference height for coordinate translation.
    static func getPrimaryScreenHeight() -> CGFloat {
        return NSScreen.screens.first?.frame.height ?? 0
    }
    
    /// Finds the screen that has the largest intersection area with the given Core Graphics window frame.
    /// If no intersection exists, falls back to the screen containing the center point of the window.
    static func getScreenWithLargestIntersection(forCGFrame cgFrame: CGRect) -> NSScreen? {
        let primaryScreenHeight = getPrimaryScreenHeight()
        let appKitFrame = ScreenGeometry.cgRectToAppKit(cgFrame, primaryScreenHeight: primaryScreenHeight)
        let screens = NSScreen.screens
        
        var bestScreen = ScreenGeometry.indexOfLargestIntersection(
            of: appKitFrame,
            in: screens.map(\.frame)
        ).map { screens[$0] }
        
        // Fallback: Check which screen contains the window's midpoint center
        if bestScreen == nil {
            let center = CGPoint(x: appKitFrame.midX, y: appKitFrame.midY)
            for screen in screens {
                if NSMouseInRect(center, screen.frame, false) {
                    bestScreen = screen
                    break
                }
            }
        }
        
        return bestScreen ?? NSScreen.main
    }
}

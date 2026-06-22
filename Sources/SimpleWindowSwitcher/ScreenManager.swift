import AppKit
import CoreGraphics

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
    
    /// Translates a CGRect from Core Graphics coordinate space (origin top-left, y-down)
    /// to AppKit coordinate space (origin bottom-left, y-up).
    static func cgRectToAppKit(_ rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        return CGRect(
            x: rect.origin.x,
            y: primaryScreenHeight - rect.origin.y - rect.size.height,
            width: rect.size.width,
            height: rect.size.height
        )
    }
    
    /// Finds the screen that has the largest intersection area with the given Core Graphics window frame.
    /// If no intersection exists, falls back to the screen containing the center point of the window.
    static func getScreenWithLargestIntersection(forCGFrame cgFrame: CGRect) -> NSScreen? {
        let primaryScreenHeight = getPrimaryScreenHeight()
        let appKitFrame = cgRectToAppKit(cgFrame, primaryScreenHeight: primaryScreenHeight)
        
        var bestScreen: NSScreen? = nil
        var maxArea: CGFloat = 0
        
        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(appKitFrame)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                bestScreen = screen
            }
        }
        
        // Fallback: Check which screen contains the window's midpoint center
        if bestScreen == nil {
            let center = CGPoint(x: appKitFrame.midX, y: appKitFrame.midY)
            for screen in NSScreen.screens {
                if NSMouseInRect(center, screen.frame, false) {
                    bestScreen = screen
                    break
                }
            }
        }
        
        return bestScreen ?? NSScreen.main
    }
}

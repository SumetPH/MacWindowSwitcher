import CoreGraphics

public enum ScreenGeometry {
    /// Translates a CGRect from Core Graphics coordinate space (origin top-left, y-down)
    /// to AppKit coordinate space (origin bottom-left, y-up).
    public static func cgRectToAppKit(_ rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryScreenHeight - rect.origin.y - rect.size.height,
            width: rect.size.width,
            height: rect.size.height
        )
    }

    /// Index of the screen frame with the largest positive intersection area, or nil if none intersect.
    /// Ties keep the first frame.
    public static func indexOfLargestIntersection(of frame: CGRect, in screenFrames: [CGRect]) -> Int? {
        var bestIndex: Int?
        var maxArea: CGFloat = 0
        for (index, screenFrame) in screenFrames.enumerated() {
            let intersection = screenFrame.intersection(frame)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                bestIndex = index
            }
        }
        return bestIndex
    }
}

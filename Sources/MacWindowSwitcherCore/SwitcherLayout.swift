import CoreGraphics

/// Sizes and selection math for the switcher overlay.
public enum SwitcherLayout {
    public static let cardWidth: CGFloat = 160
    public static let cardHeight: CGFloat = 120
    public static let cardSpacing: CGFloat = 10
    public static let padding: CGFloat = 14
    /// Cap so the overlay fits on screen.
    public static let maxCandidates = 8

    public static func overlaySize(candidateCount count: Int) -> CGSize {
        let width = padding * 2 + cardWidth * CGFloat(count) + cardSpacing * CGFloat(count - 1)
        let height = cardHeight + padding * 2
        return CGSize(width: width, height: height)
    }

    /// Next selection index with wrap-around; returns `index` unchanged when there is nothing to cycle.
    public static func cycledIndex(from index: Int, count: Int, forward: Bool) -> Int {
        guard count > 0 else { return index }
        return forward ? (index + 1) % count : (index - 1 + count) % count
    }
}

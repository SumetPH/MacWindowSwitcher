import CoreGraphics

/// Remembers the most-recently-used window order per display so cycling on one
/// display does not disturb the order on another.
public struct ScreenCycleHistory {
    private var recentByDisplay: [CGDirectDisplayID: [CGWindowID]] = [:]

    public init() {}

    public mutating func orderedWindowIDs(
        displayID: CGDirectDisplayID,
        available: [CGWindowID],
        focused: CGWindowID?
    ) -> [CGWindowID] {
        guard !available.isEmpty else { return [] }
        let availableSet = Set(available)
        var order = (recentByDisplay[displayID] ?? []).filter { availableSet.contains($0) }
        order.append(contentsOf: available.filter { !order.contains($0) })
        if let focused, let index = order.firstIndex(of: focused) {
            order.insert(order.remove(at: index), at: 0)
        }
        recentByDisplay[displayID] = order
        return order
    }

    public mutating func remember(_ windowID: CGWindowID, on displayID: CGDirectDisplayID) {
        var order = recentByDisplay[displayID] ?? []
        order.removeAll { $0 == windowID }
        order.insert(windowID, at: 0)
        recentByDisplay[displayID] = order
    }
}

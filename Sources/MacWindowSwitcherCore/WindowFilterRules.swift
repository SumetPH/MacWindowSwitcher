import CoreGraphics

/// Pure filtering and ordering rules for Core Graphics window info dictionaries.
public enum WindowFilterRules {
    public typealias WindowInfo = [String: Any]
    public typealias WindowInfoGroup = (pid: pid_t, infos: [WindowInfo])

    /// Windows at or below this size are treated as shadows/helpers.
    public static let minimumWindowSide: CGFloat = 50

    /// Groups windows without losing the front-to-back owner order from Core Graphics.
    public static func groupWindowInfosPreservingOwnerOrder(
        _ infoList: [WindowInfo],
        frontmostPID: pid_t? = nil
    ) -> [WindowInfoGroup] {
        var ownerOrder: [pid_t] = []
        var infosByPID: [pid_t: [WindowInfo]] = [:]

        for info in infoList {
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t else { continue }
            if infosByPID[pid] == nil {
                ownerOrder.append(pid)
            }
            infosByPID[pid, default: []].append(info)
        }

        var groups = ownerOrder.map { pid in
            (pid: pid, infos: infosByPID[pid] ?? [])
        }

        if let frontmostPID,
           let index = groups.firstIndex(where: { $0.pid == frontmostPID }),
           index != 0 {
            groups.insert(groups.remove(at: index), at: 0)
        }

        return groups
    }

    /// Returns the window ID and bounds when the info describes a normal-layer,
    /// visible window with usable bounds; nil when it must be skipped.
    public static func switchableWindow(from info: WindowInfo) -> (windowID: CGWindowID, bounds: CGRect)? {
        guard let windowID = info[kCGWindowNumber as String] as? CGWindowID else { return nil }
        guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { return nil }

        // Exclude invisible windows (alpha 0)
        if let alpha = info[kCGWindowAlpha as String] as? Double, alpha == 0 { return nil }

        // Exclude windows with invalid/empty/too small bounds (filter shadows/helpers)
        guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
              let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { return nil }
        guard bounds.width > minimumWindowSide && bounds.height > minimumWindowSide else { return nil }

        return (windowID, bounds)
    }

    /// Transient helper windows that look like normal windows but should not be switchable.
    public static func isTransientHelperWindow(appName: String, title: String) -> Bool {
        appName == "Google Chrome" && title == "Find in page"
    }

    /// A window with no known Spaces is kept as a fallback when the private API fails.
    public static func isOnActiveSpace(windowSpaces: [Int], activeSpaces: Set<Int>) -> Bool {
        windowSpaces.isEmpty || !activeSpaces.isDisjoint(with: windowSpaces)
    }
}

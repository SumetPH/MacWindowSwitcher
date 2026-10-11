import CoreGraphics
import MacWindowSwitcherCore
import Testing

@Suite struct WindowInfoGroupingTests {
    @Test func groupsWindowsByFirstSeenOwnerOrder() {
        let windowInfos: [[String: Any]] = [
            [kCGWindowOwnerPID as String: pid_t(30), kCGWindowNumber as String: CGWindowID(301)],
            [kCGWindowOwnerPID as String: pid_t(10), kCGWindowNumber as String: CGWindowID(101)],
            [kCGWindowOwnerPID as String: pid_t(30), kCGWindowNumber as String: CGWindowID(302)],
            [kCGWindowOwnerPID as String: pid_t(20), kCGWindowNumber as String: CGWindowID(201)],
        ]

        let groups = WindowFilterRules.groupWindowInfosPreservingOwnerOrder(windowInfos)

        #expect(groups.map(\.pid) == [30, 10, 20])
        #expect(groups.map { $0.infos.count } == [2, 1, 1])
    }

    @Test func placesFrontmostApplicationBeforeStaleWindowOrder() {
        let windowInfos: [[String: Any]] = [
            [kCGWindowOwnerPID as String: pid_t(30), kCGWindowNumber as String: CGWindowID(301)],
            [kCGWindowOwnerPID as String: pid_t(10), kCGWindowNumber as String: CGWindowID(101)],
            [kCGWindowOwnerPID as String: pid_t(20), kCGWindowNumber as String: CGWindowID(201)],
        ]

        let groups = WindowFilterRules.groupWindowInfosPreservingOwnerOrder(
            windowInfos,
            frontmostPID: 10
        )

        #expect(groups.map(\.pid) == [10, 30, 20])
    }
}

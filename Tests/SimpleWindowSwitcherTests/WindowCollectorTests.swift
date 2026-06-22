import CoreGraphics
import XCTest
@testable import SimpleWindowSwitcher

final class WindowCollectorTests: XCTestCase {
    func testGroupsWindowsByFirstSeenOwnerOrder() {
        let windowInfos: [[String: Any]] = [
            [kCGWindowOwnerPID as String: pid_t(30), kCGWindowNumber as String: CGWindowID(301)],
            [kCGWindowOwnerPID as String: pid_t(10), kCGWindowNumber as String: CGWindowID(101)],
            [kCGWindowOwnerPID as String: pid_t(30), kCGWindowNumber as String: CGWindowID(302)],
            [kCGWindowOwnerPID as String: pid_t(20), kCGWindowNumber as String: CGWindowID(201)],
        ]

        let groups = WindowCollector.groupWindowInfosPreservingOwnerOrder(windowInfos)

        XCTAssertEqual(groups.map(\.pid), [30, 10, 20])
        XCTAssertEqual(groups.map { $0.infos.count }, [2, 1, 1])
    }
}

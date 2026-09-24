import CoreGraphics
import XCTest
@testable import MacWindowSwitcher

final class ScreenCycleHistoryTests: XCTestCase {
    func testOtherDisplayDoesNotChangePreviousAppOnThisDisplay() {
        var history = ScreenCycleHistory()
        let vscode: CGWindowID = 1
        let finder: CGWindowID = 2
        let chromeOnFirst: CGWindowID = 3
        let chromeOnSecond: CGWindowID = 4

        _ = history.orderedWindowIDs(displayID: 1, available: [vscode, finder, chromeOnFirst], focused: vscode)
        history.remember(finder, on: 1)
        _ = history.orderedWindowIDs(displayID: 1, available: [finder, vscode, chromeOnFirst], focused: vscode)
        _ = history.orderedWindowIDs(displayID: 2, available: [chromeOnSecond], focused: chromeOnSecond)
        XCTAssertEqual(
            history.orderedWindowIDs(displayID: 1, available: [chromeOnFirst, vscode, finder], focused: nil),
            [vscode, finder, chromeOnFirst]
        )

        let order = history.orderedWindowIDs(
            displayID: 1,
            available: [chromeOnFirst, vscode, finder],
            focused: vscode
        )
        XCTAssertEqual(order, [vscode, finder, chromeOnFirst])
        XCTAssertEqual(order[1], finder)
    }
}

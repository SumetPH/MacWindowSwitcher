import CoreGraphics
import MacWindowSwitcherCore
import Testing

@Suite struct WindowFilterRulesTests {
    private func info(layer: Int = 0, alpha: Double = 1, width: CGFloat = 800, height: CGFloat = 600) -> [String: Any] {
        [
            kCGWindowNumber as String: CGWindowID(7),
            kCGWindowLayer as String: layer,
            kCGWindowAlpha as String: alpha,
            kCGWindowBounds as String: CGRect(x: 10, y: 20, width: width, height: height).dictionaryRepresentation,
        ]
    }

    @Test func acceptsNormalVisibleWindow() throws {
        let window = try #require(WindowFilterRules.switchableWindow(from: info()))
        #expect(window.windowID == 7)
        #expect(window.bounds == CGRect(x: 10, y: 20, width: 800, height: 600))
    }

    @Test(arguments: [
        (1, 1.0, CGFloat(800), CGFloat(600)),  // non-normal layer
        (0, 0.0, 800, 600),                    // invisible
        (0, 1.0, 50, 600),                     // too narrow
        (0, 1.0, 800, 50),                     // too short
    ])
    func rejectsNonSwitchableWindows(layer: Int, alpha: Double, width: CGFloat, height: CGFloat) {
        #expect(WindowFilterRules.switchableWindow(from: info(layer: layer, alpha: alpha, width: width, height: height)) == nil)
    }

    @Test func rejectsWindowWithoutBounds() {
        var missingBounds = info()
        missingBounds[kCGWindowBounds as String] = nil
        #expect(WindowFilterRules.switchableWindow(from: missingBounds) == nil)
    }

    @Test func detectsChromeFindInPageHelper() {
        #expect(WindowFilterRules.isTransientHelperWindow(appName: "Google Chrome", title: "Find in page"))
        #expect(!WindowFilterRules.isTransientHelperWindow(appName: "Google Chrome", title: "Inbox"))
        #expect(!WindowFilterRules.isTransientHelperWindow(appName: "Safari", title: "Find in page"))
    }

    @Test func keepsWindowsOnActiveSpaceOrWithUnknownSpaces() {
        #expect(WindowFilterRules.isOnActiveSpace(windowSpaces: [], activeSpaces: [1]))
        #expect(WindowFilterRules.isOnActiveSpace(windowSpaces: [2, 1], activeSpaces: [1]))
        #expect(!WindowFilterRules.isOnActiveSpace(windowSpaces: [3], activeSpaces: [1, 2]))
    }
}

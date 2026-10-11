import CoreGraphics
import MacWindowSwitcherCore
import Testing

@Suite struct SwitcherLayoutTests {
    @Test func cyclesForwardAndBackwardWithWrapAround() {
        #expect(SwitcherLayout.cycledIndex(from: 0, count: 3, forward: true) == 1)
        #expect(SwitcherLayout.cycledIndex(from: 2, count: 3, forward: true) == 0)
        #expect(SwitcherLayout.cycledIndex(from: 0, count: 3, forward: false) == 2)
        #expect(SwitcherLayout.cycledIndex(from: 4, count: 0, forward: true) == 4)
    }

    @Test func overlaySizeFitsCardsPaddingAndSpacing() {
        #expect(SwitcherLayout.overlaySize(candidateCount: 1) == CGSize(width: 188, height: 148))
        #expect(SwitcherLayout.overlaySize(candidateCount: 2) == CGSize(width: 358, height: 148))
    }

    @Test func convertsCoreGraphicsRectToAppKitCoordinates() {
        let rect = ScreenGeometry.cgRectToAppKit(CGRect(x: 10, y: 100, width: 300, height: 200), primaryScreenHeight: 1000)
        #expect(rect == CGRect(x: 10, y: 700, width: 300, height: 200))
    }

    @Test func picksScreenWithLargestIntersection() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800), CGRect(x: 1000, y: 0, width: 1000, height: 800)]
        #expect(ScreenGeometry.indexOfLargestIntersection(of: CGRect(x: 900, y: 0, width: 400, height: 300), in: screens) == 1)
        #expect(ScreenGeometry.indexOfLargestIntersection(of: CGRect(x: 5000, y: 0, width: 10, height: 10), in: screens) == nil)
    }
}

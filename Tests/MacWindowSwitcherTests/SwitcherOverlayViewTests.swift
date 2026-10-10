import AppKit
import XCTest
@testable import MacWindowSwitcher

@MainActor
final class SwitcherOverlayViewTests: XCTestCase {
    func testAcceptsFirstClickWithoutTakingKeyboardFocus() async {
        let card = CandidateCardView(candidate: candidate(id: 1))
        XCTAssertTrue(card.acceptsFirstMouse(for: nil))

        let panel = SwitcherOverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 358, height: 148))
        XCTAssertFalse(panel.canBecomeKey)
        XCTAssertFalse(panel.canBecomeMain)
        XCTAssertFalse(panel.ignoresMouseEvents)
        XCTAssertFalse(panel.isMovable)
    }

    func testCommandClickOnEveryCardPartSendsCorrectIndex() async throws {
        var selections: [Int] = []
        let view = SwitcherOverlayView(candidates: [candidate(id: 1), candidate(id: 2)], selectedIndex: 0) {
            selections.append($0)
        }
        view.frame = NSRect(x: 0, y: 0, width: 358, height: 148)
        view.layoutSubtreeIfNeeded()
        let cards = cardViews(in: view)
        XCTAssertEqual(cards.count, 2)

        for (index, card) in cards.enumerated() {
            // Card background, icon, app name, and window title.
            let points = [NSPoint(x: 4, y: 4)] + card.subviews.map {
                NSPoint(x: $0.frame.midX, y: $0.frame.midY)
            }
            for point in points {
                let location = view.convert(point, from: card)
                let target = try XCTUnwrap(view.hitTest(location))
                XCTAssertTrue(target === card)
                XCTAssertTrue(target.acceptsFirstMouse(for: nil))
                let event = try XCTUnwrap(NSEvent.mouseEvent(
                    with: .leftMouseDown,
                    location: location,
                    modifierFlags: [.command],
                    timestamp: 0,
                    windowNumber: 0,
                    context: nil,
                    eventNumber: 0,
                    clickCount: 1,
                    pressure: 1
                ))
                let countBefore = selections.count
                target.mouseDown(with: event)
                XCTAssertEqual(selections.count, countBefore + 1)
                XCTAssertEqual(selections.last, index)
            }
        }

        view.updateSelection(index: 1)
        XCTAssertFalse(cards[0].isSelected)
        XCTAssertTrue(cards[1].isSelected)
    }

    func testCardDoesNotCaptureClicksOutsideItsBounds() async {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 160))
        let card = CandidateCardView(candidate: candidate(id: 1))
        parent.addSubview(card)
        card.frame = NSRect(x: 10, y: 10, width: 160, height: 120)
        XCTAssertNil(card.hitTest(NSPoint(x: 5, y: 5)))
        XCTAssertFalse(parent.hitTest(NSPoint(x: 5, y: 5)) === card)
    }

    private func cardViews(in view: NSView) -> [CandidateCardView] {
        if let card = view as? CandidateCardView { return [card] }
        return view.subviews.flatMap { cardViews(in: $0) }
    }

    private func candidate(id: CGWindowID) -> WindowCandidate {
        WindowCandidate(
            windowID: id,
            pid: 1,
            appName: "Test App",
            windowTitle: "Window \(id)",
            appIcon: NSImage(size: NSSize(width: 40, height: 40)),
            axWindow: nil,
            cgBounds: CGRect(x: 0, y: 0, width: 800, height: 600)
        )
    }
}

import XCTest
import CoreGraphics
@testable import ScrollCore

final class ScrollTransformTests: XCTestCase {
    private func wheel(continuous: Bool = false) -> CGEvent {
        let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: 3, wheel2: -2, wheel3: 0)!
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: continuous ? 1 : 0)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 0)
        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 1.25)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 17)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -0.5)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -8)
        return event
    }

    func testReversesAllRepresentationsOnBothAxes() {
        let event = wheel()
        XCTAssertTrue(ScrollTransform.apply(to: event, enabled: true, vertical: true, horizontal: true))
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -3)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), -1.25)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), -17)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis2), 2)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2), 0.5)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2), 8)
    }

    func testContinuousInputIsUntouched() {
        assertUnchanged(wheel(continuous: true))
    }

    func testGestureAndMomentumRemainUntouchedEvenWhenDiscreteFlagIsSet() {
        let phases: [(CGEventField, [Int64])] = [
            (.scrollWheelEventScrollPhase, [1, 2, 4, 8, 128]),
            (.scrollWheelEventMomentumPhase, [1, 2, 3])
        ]
        for (field, validValues) in phases {
            for phase in validValues {
                let event = wheel()
                event.setIntegerValueField(field, value: phase)
                XCTAssertNotEqual(event.getIntegerValueField(field), 0, "Fixture must retain the phase")
                assertUnchanged(event)
            }
        }
    }

    func testPauseAndDisabledAxesAreUntouched() {
        for config in [(false, true, true), (true, false, false)] {
            let event = wheel()
            let original = values(event)
            XCTAssertFalse(ScrollTransform.apply(to: event, enabled: config.0, vertical: config.1, horizontal: config.2))
            XCTAssertEqual(values(event), original)
        }
    }

    func testAxesCanBeControlledIndependently() {
        let vertical = wheel()
        ScrollTransform.apply(to: vertical, enabled: true, vertical: true, horizontal: false)
        XCTAssertEqual(vertical.getIntegerValueField(.scrollWheelEventDeltaAxis1), -3)
        XCTAssertEqual(vertical.getIntegerValueField(.scrollWheelEventDeltaAxis2), -2)
        let horizontal = wheel()
        ScrollTransform.apply(to: horizontal, enabled: true, vertical: false, horizontal: true)
        XCTAssertEqual(horizontal.getIntegerValueField(.scrollWheelEventDeltaAxis1), 3)
        XCTAssertEqual(horizontal.getIntegerValueField(.scrollWheelEventDeltaAxis2), 2)
    }

    func testAlternatingDevicesDoesNotLeaveStickyClassification() {
        for index in 0..<100 {
            let isTrackpad = index % 2 == 0
            let event = wheel(continuous: isTrackpad)
            ScrollTransform.apply(to: event, enabled: true, vertical: true, horizontal: true)
            XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), isTrackpad ? 3 : -3)
        }
    }

    func testNonScrollInputIsIgnored() {
        let event = wheel()
        event.type = .mouseMoved
        assertUnchanged(event)
    }

    private func values(_ event: CGEvent) -> [Double] {
        [.scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1,
         .scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2]
            .map { event.getDoubleValueField($0) }
    }

    private func assertUnchanged(_ event: CGEvent, file: StaticString = #filePath, line: UInt = #line) {
        let original = values(event)
        XCTAssertFalse(ScrollTransform.apply(to: event, enabled: true, vertical: true, horizontal: true), file: file, line: line)
        XCTAssertEqual(values(event), original, file: file, line: line)
    }
}

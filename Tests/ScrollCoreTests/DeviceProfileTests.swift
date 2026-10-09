import XCTest
import CoreGraphics
@testable import ScrollCore

final class DeviceProfileTests: XCTestCase {
    func testIndependentProfilesPersistAcrossReloads() {
        let suite = "SplitScroll.Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DeviceProfileStore(defaults: defaults)
        let natural = DeviceProfile(vertical: false, horizontal: false)
        let traditional = DeviceProfile(vertical: true, horizontal: true)
        store.register(traditional, for: "mouse-a")
        store.register(natural, for: "trackpad-a")
        store.register(natural, for: "mouse-b")
        store.set(DeviceProfile(vertical: false, horizontal: true), for: "mouse-a")
        // Reconnection and changes to defaults must not overwrite a saved choice.
        store.register(traditional, for: "mouse-a")
        let reloaded = DeviceProfileStore(defaults: defaults)
        XCTAssertEqual(reloaded.profile(for: "mouse-a", default: traditional), DeviceProfile(vertical: false, horizontal: true))
        XCTAssertEqual(reloaded.profile(for: "mouse-b", default: traditional), natural)
        XCTAssertEqual(reloaded.profile(for: "trackpad-a", default: traditional), natural)
        XCTAssertEqual(reloaded.profile(for: "new-device", default: traditional), traditional)
    }

    func testCorruptStoredProfilesFallBackSafely() {
        let suite = "SplitScroll.Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid".utf8), forKey: "deviceProfiles")
        let fallback = DeviceProfile(vertical: false, horizontal: false)
        XCTAssertEqual(DeviceProfileStore(defaults: defaults).profile(for: "trackpad", default: fallback), fallback)
    }

    func testIdentifiedTrackpadCanReverseWithoutChangingGesturePhases() {
        let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 12, wheel2: -7, wheel3: 0)!
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 2)
        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 2)
        let beforeY = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        let beforeX = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
        XCTAssertTrue(ScrollTransform.apply(to: event, enabled: true, vertical: true, horizontal: false, identifiedDevice: true))
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), -beforeY)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2), beforeX)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventIsContinuous), 1)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventScrollPhase), 2)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventMomentumPhase), 2)
    }
}

import CoreGraphics

/// Unidentified continuous or phased input is preserved. A separately validated
/// hardware sender allows that device's explicit profile to transform any scroll
/// event while preserving gesture and momentum metadata.
public enum ScrollTransform {
    public static func isDiscreteWheel(_ event: CGEvent) -> Bool {
        event.type == .scrollWheel &&
        event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 &&
        event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0 &&
        event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0
    }

    @discardableResult
    public static func apply(to event: CGEvent, enabled: Bool, vertical: Bool, horizontal: Bool,
                             identifiedDevice: Bool = false) -> Bool {
        guard enabled, event.type == .scrollWheel,
              identifiedDevice || isDiscreteWheel(event), vertical || horizontal else { return false }
        if vertical {
            reverse(event, line: .scrollWheelEventDeltaAxis1,
                    fixed: .scrollWheelEventFixedPtDeltaAxis1, point: .scrollWheelEventPointDeltaAxis1)
        }
        if horizontal {
            reverse(event, line: .scrollWheelEventDeltaAxis2,
                    fixed: .scrollWheelEventFixedPtDeltaAxis2, point: .scrollWheelEventPointDeltaAxis2)
        }
        return true
    }

    private static func reverse(_ event: CGEvent, line: CGEventField, fixed: CGEventField, point: CGEventField) {
        // Read all representations before writing; fixed-point values use double access
        // to preserve fractional line deltas rather than rounding them away.
        let lineValue = event.getIntegerValueField(line)
        let fixedValue = event.getDoubleValueField(fixed)
        let pointValue = event.getIntegerValueField(point)
        event.setIntegerValueField(line, value: negated(lineValue))
        event.setDoubleValueField(fixed, value: -fixedValue)
        event.setIntegerValueField(point, value: negated(pointValue))
    }

    private static func negated(_ value: Int64) -> Int64 {
        value == .min ? .max : -value
    }
}

import XCTest
import MIDIKitCore
@testable import EurorackMIDILib

final class VelocityCurveTests: XCTestCase {
    func testLinearCurve() {
        let curve = VelocityCurve.linear

        // Linear should return input unchanged
        XCTAssertEqual(curve.apply(to: 0.0), 0.0, accuracy: 0.01)
        XCTAssertEqual(curve.apply(to: 0.5), 0.5, accuracy: 0.01)
        XCTAssertEqual(curve.apply(to: 1.0), 1.0, accuracy: 0.01)
    }

    func testSoftCurve() {
        let curve = VelocityCurve.soft

        // Soft curve (exponent 0.6) makes it easier to reach high velocities
        let midpoint = curve.apply(to: 0.5)
        XCTAssertGreaterThan(midpoint, 0.5, "Soft curve should output > 0.5 for input 0.5")
        XCTAssertLessThan(midpoint, 1.0)

        // Edge cases
        XCTAssertEqual(curve.apply(to: 0.0), 0.0, accuracy: 0.01)
        XCTAssertEqual(curve.apply(to: 1.0), 1.0, accuracy: 0.01)
    }

    func testHardCurve() {
        let curve = VelocityCurve.hard

        // Hard curve (exponent 1.8) requires more force for high velocities
        let midpoint = curve.apply(to: 0.5)
        XCTAssertLessThan(midpoint, 0.5, "Hard curve should output < 0.5 for input 0.5")
        XCTAssertGreaterThan(midpoint, 0.0)

        // Edge cases
        XCTAssertEqual(curve.apply(to: 0.0), 0.0, accuracy: 0.01)
        XCTAssertEqual(curve.apply(to: 1.0), 1.0, accuracy: 0.01)
    }

    func testFixedCurve() {
        let curve = VelocityCurve.fixed

        // Fixed should always return 1.0
        XCTAssertEqual(curve.apply(to: 0.0), 1.0, accuracy: 0.01)
        XCTAssertEqual(curve.apply(to: 0.5), 1.0, accuracy: 0.01)
        XCTAssertEqual(curve.apply(to: 1.0), 1.0, accuracy: 0.01)
    }

    func testToMIDIVelocityLinear() {
        let curve = VelocityCurve.linear

        // Test conversion to MIDI velocity (1-127 range)
        let velocity0 = curve.toMIDIVelocity(from: 0.0)
        let velocity50 = curve.toMIDIVelocity(from: 0.5)
        let velocity100 = curve.toMIDIVelocity(from: 1.0)

        XCTAssertEqual(velocity0, 1) // Clamped to minimum 1
        XCTAssertEqual(velocity50, 63, accuracy: 1) // ~50% of 127
        XCTAssertEqual(velocity100, 127) // Maximum
    }

    func testToMIDIVelocityClamping() {
        let curve = VelocityCurve.linear

        // Test that values are clamped to valid MIDI range (1-127)
        let velocityNegative = curve.toMIDIVelocity(from: -0.5)
        let velocityTooHigh = curve.toMIDIVelocity(from: 2.0)

        XCTAssertGreaterThanOrEqual(velocityNegative, 1)
        XCTAssertLessThanOrEqual(velocityNegative, 127)
        XCTAssertGreaterThanOrEqual(velocityTooHigh, 1)
        XCTAssertLessThanOrEqual(velocityTooHigh, 127)
    }

    func testFixedVelocityValue() {
        let curve = VelocityCurve.fixed

        // Fixed curve should use provided fixed value
        let velocity64 = curve.toMIDIVelocity(from: 0.5, fixedValue: 64)
        let velocity100 = curve.toMIDIVelocity(from: 0.0, fixedValue: 100)

        XCTAssertEqual(velocity64, 64)
        XCTAssertEqual(velocity100, 100)

        // Test clamping of fixed values
        let velocityTooLow = curve.toMIDIVelocity(from: 0.5, fixedValue: 0)
        let velocityTooHigh = curve.toMIDIVelocity(from: 0.5, fixedValue: 200)

        XCTAssertEqual(velocityTooLow, 1)
        XCTAssertEqual(velocityTooHigh, 127)
    }

    func testDisplayNames() {
        XCTAssertEqual(VelocityCurve.linear.displayName, "Linear")
        XCTAssertEqual(VelocityCurve.soft.displayName, "Soft")
        XCTAssertEqual(VelocityCurve.hard.displayName, "Hard")
        XCTAssertEqual(VelocityCurve.fixed.displayName, "Fixed")
    }
}

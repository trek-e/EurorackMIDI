import Foundation
import MIDIKitCore

/// Velocity curve transformations for MIDI input
enum VelocityCurve: String, Codable, CaseIterable {
    case linear
    case soft
    case hard
    case fixed

    var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .soft: return "Soft"
        case .hard: return "Hard"
        case .fixed: return "Fixed"
        }
    }

    /// Apply velocity curve transformation to normalized input (0.0-1.0)
    /// - Parameter normalizedInput: Input value from 0.0 to 1.0
    /// - Returns: Transformed value from 0.0 to 1.0
    func apply(to normalizedInput: Double) -> Double {
        switch self {
        case .linear:
            return normalizedInput
        case .soft:
            // Easier to reach high velocities
            return pow(normalizedInput, 0.6)
        case .hard:
            // Requires more force for high velocities
            return pow(normalizedInput, 1.8)
        case .fixed:
            return 1.0
        }
    }

    /// Convert normalized input to MIDI velocity using this curve
    /// - Parameters:
    ///   - normalizedInput: Input value from 0.0 to 1.0
    ///   - fixedValue: Fixed velocity value (1-127) when curve is .fixed
    /// - Returns: MIDI velocity (1-127)
    func toMIDIVelocity(from normalizedInput: Double, fixedValue: Int? = nil) -> UInt7 {
        if self == .fixed, let fixed = fixedValue {
            return UInt7(clamping: max(1, min(127, fixed)))
        }

        let transformed = apply(to: normalizedInput)
        let scaled = Int(transformed * 127.0)
        let clamped = max(1, min(127, scaled))
        return UInt7(clamping: clamped)
    }
}

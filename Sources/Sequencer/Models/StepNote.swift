import Foundation

/// A single note event in a step sequencer track
struct StepNote: Codable, Identifiable, Equatable {
    let id: UUID
    /// Step position (0-based index)
    var step: Int
    /// MIDI note number (0-127)
    var note: UInt8
    /// Velocity (1-127)
    var velocity: UInt8
    /// Duration in steps (1.0 = full step, 0.5 = half step, etc.)
    var duration: Double

    init(id: UUID = UUID(), step: Int, note: UInt8, velocity: UInt8 = 100, duration: Double = 1.0) {
        self.id = id
        self.step = step
        self.note = note
        self.velocity = velocity
        self.duration = duration
    }
}

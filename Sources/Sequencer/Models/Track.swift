import Foundation

/// A single track in a pattern (represents one MIDI channel)
struct Track: Codable, Identifiable, Equatable {
    let id: UUID
    /// MIDI channel (1-16, 1-indexed for UI consistency)
    var channel: UInt8
    /// Note events in this track
    var notes: [StepNote]
    /// Track is muted (no output)
    var isMuted: Bool
    /// Track is soloed (only soloed tracks play)
    var isSoloed: Bool
    /// Track volume (0.0-1.0)
    var volume: Double
    /// Track name for UI display
    var name: String

    init(
        id: UUID = UUID(),
        channel: UInt8 = 1,
        notes: [StepNote] = [],
        isMuted: Bool = false,
        isSoloed: Bool = false,
        volume: Double = 1.0,
        name: String = "Track"
    ) {
        self.id = id
        self.channel = channel
        self.notes = notes
        self.isMuted = isMuted
        self.isSoloed = isSoloed
        self.volume = volume
        self.name = name
    }
}

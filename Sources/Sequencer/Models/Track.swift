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
        self.channel = max(1, min(16, channel))
        self.notes = notes
        self.isMuted = isMuted
        self.isSoloed = isSoloed
        self.volume = max(0.0, min(1.0, volume))
        self.name = name
    }
}

// MARK: - Track Helper Methods

extension Track {
    /// Add a note to the track
    mutating func addNote(_ note: StepNote) {
        notes.append(note)
    }

    /// Remove a note by ID
    mutating func removeNote(id: UUID) {
        notes.removeAll { $0.id == id }
    }

    /// Get note at a specific step (returns first match if multiple)
    func note(at step: Int) -> StepNote? {
        notes.first { $0.step == step }
    }

    /// Get all notes at a specific step
    func notes(at step: Int) -> [StepNote] {
        notes.filter { $0.step == step }
    }

    /// Clear all notes
    mutating func clearNotes() {
        notes.removeAll()
    }

    /// Check if track should play (considering mute/solo logic)
    func shouldPlay(anySoloed: Bool) -> Bool {
        if isMuted { return false }
        if anySoloed { return isSoloed }
        return true
    }
}

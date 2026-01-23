import Foundation

/// Complete device configuration profile
struct DeviceProfile: Codable, Identifiable {
    /// Schema version for future migrations
    var version: Int = 1

    /// Unique identifier for this profile
    var id: UUID = UUID()

    // Device Identity
    /// MIDIKit device uniqueID (for device-specific profiles)
    var deviceUniqueID: Int32?
    /// Device display name (fallback for matching)
    var deviceDisplayName: String?
    /// User-assigned nickname for this device
    var userNickname: String?

    // MIDI Configuration
    /// MIDI channel (1-16)
    var midiChannel: Int = 1

    // Octave Offsets
    /// Octave offset from C3 for piano keyboard (-3 to +3)
    var keyboardOctaveOffset: Int = 0
    /// Octave offset from C2 for performance pads (-3 to +3)
    var padOctaveOffset: Int = 0

    // UI Configuration
    /// Default tab on launch (0=Pads, 1=Keyboard)
    var defaultTab: Int = 0

    // Velocity Configuration
    var velocityCurve: VelocityCurve = .linear
    /// Fixed velocity value (1-127) when curve is .fixed
    var fixedVelocity: Int?

    // Pad Mapping Configuration
    var padMappingMode: PadMappingMode = .gmDrum
    /// Base note for chromatic mode (MIDI note number)
    var padBaseNote: Int = 36
    /// Custom note mapping for pads (16 MIDI note numbers)
    var customPadNotes: [Int]?

    // Metadata
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
}

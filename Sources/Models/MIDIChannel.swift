import MIDIKitCore

/// MIDI channel type using MIDIKit's UInt4 (1-16)
typealias MIDIChannel = UInt4

extension MIDIChannel {
    /// Default MIDI channel (1)
    static let `default`: MIDIChannel = 1
}

import Foundation

/// Transport state for sequencer playback control
enum TransportState: String, CaseIterable {
    case stopped
    case playing
    case recording

    /// Whether the transport is actively running (playing or recording)
    var isRunning: Bool {
        self != .stopped
    }
}

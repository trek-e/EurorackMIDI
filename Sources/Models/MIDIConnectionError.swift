import Foundation

/// User-friendly MIDI connection errors
enum MIDIConnectionError: LocalizedError {
    case noDeviceSelected
    case deviceUnavailable
    case sendFailed(underlying: Error)
    case powerLimitExceeded

    var errorDescription: String? {
        switch self {
        case .noDeviceSelected:
            return "No MIDI device selected. Pick your synth from the list?"
        case .deviceUnavailable:
            return "Can't reach your synth. Check the cable?"
        case .sendFailed(let error):
            return "Failed to send MIDI: \(error.localizedDescription)"
        case .powerLimitExceeded:
            return "Not enough power for your device. Try a powered USB hub or the USB 3 Camera Adapter."
        }
    }
}

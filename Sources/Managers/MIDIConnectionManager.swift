import Foundation
import MIDIKitIO
import MIDIKitCore
import Observation

/// Singleton MIDI connection manager with hot-plug detection
@Observable
final class MIDIConnectionManager {
    static let shared = MIDIConnectionManager()

    // MARK: - Properties

    private let midiManager: ObservableMIDIManager

    /// Currently selected MIDI output device
    var selectedDevice: MIDIOutputEndpoint?

    /// Current MIDI channel (1-16)
    var selectedChannel: MIDIChannel = .default

    /// Last selected device ID for auto-reconnect on hot-plug
    var lastSelectedDeviceID: MIDIIdentifier?

    /// User-facing connection error message
    var connectionError: String?

    /// Available MIDI output devices
    var availableOutputs: [MIDIOutputEndpoint] {
        midiManager.endpoints.outputs
    }

    // MARK: - Initialization

    private init() {
        // Create MIDI manager
        midiManager = ObservableMIDIManager(
            clientName: "EurorackMIDI",
            model: "EurorackMIDI",
            manufacturer: "YourCompany"
        )

        // Start MIDI system
        do {
            try midiManager.start()
        } catch {
            connectionError = "Failed to start MIDI system: \(error.localizedDescription)"
        }

        // Set up hot-plug detection
        setupHotPlugDetection()
    }

    // MARK: - Hot-Plug Detection

    private func setupHotPlugDetection() {
        midiManager.notificationHandler = { [weak self] notification in
            guard let self = self else { return }

            // Dispatch to main thread for UI updates
            Task { @MainActor in
                switch notification {
                case .added(_, parent: _):
                    // Check if this is our previously selected device
                    if let lastID = self.lastSelectedDeviceID {
                        // Refresh endpoints and check if the added device matches
                        let outputs = self.midiManager.endpoints.outputs
                        if let reconnectedDevice = outputs.first(where: { $0.uniqueID == lastID }) {
                            // Auto-reconnect
                            self.selectedDevice = reconnectedDevice
                            self.lastSelectedDeviceID = nil
                            self.connectionError = nil
                        }
                    }

                case .removed(let object, parent: _):
                    // Check if our selected device was removed
                    if let selectedID = self.selectedDevice?.uniqueID,
                       object.uniqueID == selectedID {
                        // Store ID for potential reconnect
                        self.lastSelectedDeviceID = selectedID
                        self.selectedDevice = nil
                        self.connectionError = "Device disconnected"
                    }

                default:
                    break
                }
            }
        }
    }

    // MARK: - MIDI Send Methods (stubs for Plan 02)

    /// Send MIDI Note On message
    func sendNoteOn(note: UInt7, velocity: UInt7) throws {
        // Implementation in Plan 02
        guard selectedDevice != nil else {
            throw MIDIConnectionError.noDeviceSelected
        }
    }

    /// Send MIDI Note Off message
    func sendNoteOff(note: UInt7) throws {
        // Implementation in Plan 02
        guard selectedDevice != nil else {
            throw MIDIConnectionError.noDeviceSelected
        }
    }
}

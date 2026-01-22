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

    /// Currently selected MIDI destination device (where we send TO)
    var selectedDevice: MIDIInputEndpoint?

    /// Current MIDI channel (1-16)
    var selectedChannel: MIDIChannel = .default

    /// Last selected device ID for auto-reconnect on hot-plug
    var lastSelectedDeviceID: MIDIIdentifier?

    /// User-facing connection error message
    var connectionError: String?

    /// Available MIDI destination devices (where we can send TO)
    var availableDestinations: [MIDIInputEndpoint] {
        midiManager.endpoints.inputs
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
                        let destinations = self.midiManager.endpoints.inputs
                        if let reconnectedDevice = destinations.first(where: { $0.uniqueID == lastID }) {
                            // Auto-reconnect
                            self.selectedDevice = reconnectedDevice
                            self.updateOutputConnection()
                            self.lastSelectedDeviceID = nil
                            self.connectionError = nil
                            ToastManager.shared.show(message: "Device reconnected", type: .success)
                        }
                    }

                case .removed(let object, parent: _):
                    // Check if our selected device was removed
                    if let selectedID = self.selectedDevice?.uniqueID,
                       object.uniqueID == selectedID {
                        // Store ID for potential reconnect
                        self.lastSelectedDeviceID = selectedID
                        self.selectedDevice = nil
                        self.updateOutputConnection()
                        self.connectionError = "Device disconnected"
                        ToastManager.shared.show(message: "Device unplugged", type: .warning)
                    }

                default:
                    break
                }
            }
        }
    }

    // MARK: - Output Connection Management

    private let outputConnectionTag = "MainOutput"

    /// Update output connection when device changes
    func updateOutputConnection() {
        // Remove existing connection if any
        midiManager.remove(.outputConnection, .withTag(outputConnectionTag))

        // Create new connection if device selected
        guard let device = selectedDevice else { return }

        do {
            try midiManager.addOutputConnection(
                to: .inputs(matching: [.uniqueID(device.uniqueID)]),
                tag: outputConnectionTag
            )
        } catch {
            connectionError = "Failed to create output connection: \(error.localizedDescription)"
        }
    }

    // MARK: - MIDI Send Methods

    /// Send MIDI Note On message
    func sendNoteOn(note: UInt7, velocity: UInt7) throws {
        guard selectedDevice != nil else {
            throw MIDIConnectionError.noDeviceSelected
        }

        guard let connection = midiManager.managedOutputConnections[outputConnectionTag] else {
            throw MIDIConnectionError.deviceUnavailable
        }

        do {
            let event = MIDIEvent.noteOn(
                note,
                velocity: .midi1(velocity),
                channel: selectedChannel
            )
            try connection.send(event: event)
        } catch {
            throw MIDIConnectionError.sendFailed(underlying: error)
        }
    }

    /// Send MIDI Note Off message
    func sendNoteOff(note: UInt7) throws {
        guard selectedDevice != nil else {
            throw MIDIConnectionError.noDeviceSelected
        }

        guard let connection = midiManager.managedOutputConnections[outputConnectionTag] else {
            throw MIDIConnectionError.deviceUnavailable
        }

        do {
            let event = MIDIEvent.noteOff(
                note,
                velocity: .midi1(0),
                channel: selectedChannel
            )
            try connection.send(event: event)
        } catch {
            throw MIDIConnectionError.sendFailed(underlying: error)
        }
    }

    /// Test connection by sending a note on/off sequence
    func testConnection() async throws {
        let testNote: UInt7 = 60 // Middle C
        try sendNoteOn(note: testNote, velocity: 64)
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        try sendNoteOff(note: testNote)
    }
}

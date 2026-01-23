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

    // MARK: - Auto-reconnect and Profile Management

    /// Pending device for restore settings prompt
    var pendingReconnectDevice: MIDIInputEndpoint?

    /// Show restore settings prompt when reconnecting to remembered device
    var showRestoreSettingsPrompt: Bool = false

    /// Show remember device prompt for new device connections
    var showRememberDevicePrompt: Bool = false

    /// Device to remember (pending user confirmation)
    var deviceToRemember: MIDIInputEndpoint?

    /// Currently loaded profile
    var currentProfile: DeviceProfile?

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

    // MARK: - Auto-reconnect

    /// Attempt to reconnect to last connected device on app launch
    @MainActor
    func attemptAutoReconnect() {
        // Check if there's a last connected device
        guard let lastDeviceID = ProfileManager.shared.lastConnectedDeviceID else {
            return
        }

        // Search for the device in available destinations
        guard let device = availableDestinations.first(where: { $0.uniqueID == lastDeviceID }) else {
            // Device not currently available
            return
        }

        // Set selected device and update connection
        selectedDevice = device
        updateOutputConnection()

        // Store device for pending restore settings prompt
        pendingReconnectDevice = device
        showRestoreSettingsPrompt = true
    }

    /// Apply a profile to the current connection
    func applyProfile(_ profile: DeviceProfile) {
        // Apply MIDI channel (convert 1-indexed to 0-indexed)
        selectedChannel = MIDIChannel(profile.midiChannel - 1)

        // Store current profile reference
        currentProfile = profile
    }

    /// Confirm restore settings from saved profile
    @MainActor
    func confirmRestoreSettings() {
        guard let device = pendingReconnectDevice else { return }

        // Load profile and apply settings
        let profile = ProfileManager.shared.profile(for: device.uniqueID)
        applyProfile(profile)

        // Clear prompt state
        showRestoreSettingsPrompt = false
        pendingReconnectDevice = nil

        ToastManager.shared.show(message: "Settings restored", type: .success)
    }

    /// Decline restore settings (use defaults)
    func declineRestoreSettings() {
        // Clear prompt state without applying profile
        showRestoreSettingsPrompt = false
        pendingReconnectDevice = nil
    }

    /// Remember current device
    @MainActor
    func rememberCurrentDevice() {
        guard let device = deviceToRemember else { return }

        // Remember the device
        ProfileManager.shared.rememberDevice(id: device.uniqueID, name: device.displayName)

        // Save current state as profile
        let profile = DeviceProfile(
            deviceUniqueID: device.uniqueID,
            deviceDisplayName: device.displayName,
            midiChannel: Int(selectedChannel) + 1 // Convert 0-indexed to 1-indexed
        )
        ProfileManager.shared.saveProfile(profile, for: device.uniqueID)

        // Clear prompt state
        showRememberDevicePrompt = false
        deviceToRemember = nil

        ToastManager.shared.show(message: "Device remembered", type: .success)
    }

    /// Decline remembering device
    func declineRememberDevice() {
        showRememberDevicePrompt = false
        deviceToRemember = nil
    }
}

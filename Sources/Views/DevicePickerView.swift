import SwiftUI
import MIDIKitIO

/// Device selection picker for MIDI destinations (where we send TO)
struct DevicePickerView: View {
    @State private var manager = MIDIConnectionManager.shared
    @State private var profileManager = ProfileManager.shared
    @State private var showSettings = false

    var body: some View {
        if manager.availableDestinations.isEmpty {
            Text("No devices found")
                .foregroundStyle(.secondary)
        } else {
            Picker("MIDI Device", selection: Binding(
                get: { manager.selectedDevice?.uniqueID },
                set: { newID in
                    if let newID = newID {
                        let device = manager.availableDestinations.first(where: { $0.uniqueID == newID })
                        manager.selectedDevice = device
                        manager.updateOutputConnection()

                        // Check if this is a new device (not remembered yet)
                        if let device = device {
                            let isRemembered = profileManager.lastConnectedDeviceID == device.uniqueID
                            if !isRemembered {
                                // Prompt to remember new device
                                manager.deviceToRemember = device
                                manager.showRememberDevicePrompt = true
                            }
                        }
                    } else {
                        manager.selectedDevice = nil
                        manager.updateOutputConnection()
                    }
                }
            )) {
                Text("No Device")
                    .tag(nil as MIDIIdentifier?)

                ForEach(manager.availableDestinations, id: \.uniqueID) { endpoint in
                    HStack {
                        Text(endpoint.displayName)
                        if isRemembered(endpoint) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .imageScale(.small)
                        }
                    }
                    .tag(endpoint.uniqueID as MIDIIdentifier?)
                    .contextMenu {
                        if isRemembered(endpoint) {
                            Button(role: .destructive) {
                                forgetDevice(endpoint)
                            } label: {
                                Label("Forget Device", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .pickerStyle(.menu)
            .onLongPressGesture {
                if manager.selectedDevice != nil {
                    showSettings = true
                }
            }
            .sheet(isPresented: $showSettings) {
                if let device = manager.selectedDevice {
                    DeviceSettingsView(device: device, isPresented: $showSettings)
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Check if device is remembered
    private func isRemembered(_ endpoint: MIDIInputEndpoint) -> Bool {
        return profileManager.lastConnectedDeviceID == endpoint.uniqueID
    }

    /// Forget a device
    private func forgetDevice(_ endpoint: MIDIInputEndpoint) {
        profileManager.forgetDevice(id: endpoint.uniqueID)
        ToastManager.shared.show(message: "Device forgotten", type: .info)
    }
}

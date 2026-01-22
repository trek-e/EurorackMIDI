import SwiftUI
import MIDIKitIO

/// Device selection picker for MIDI destinations (where we send TO)
struct DevicePickerView: View {
    @State private var manager = MIDIConnectionManager.shared

    var body: some View {
        if manager.availableDestinations.isEmpty {
            Text("No devices found")
                .foregroundStyle(.secondary)
        } else {
            Picker("MIDI Device", selection: Binding(
                get: { manager.selectedDevice?.uniqueID },
                set: { newID in
                    if let newID = newID {
                        manager.selectedDevice = manager.availableDestinations.first(where: { $0.uniqueID == newID })
                    } else {
                        manager.selectedDevice = nil
                    }
                    manager.updateOutputConnection()
                }
            )) {
                Text("No Device")
                    .tag(nil as MIDIIdentifier?)

                ForEach(manager.availableDestinations, id: \.uniqueID) { endpoint in
                    Text(endpoint.displayName)
                        .tag(endpoint.uniqueID as MIDIIdentifier?)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

import SwiftUI
import MIDIKitIO

/// Comprehensive settings UI for device profiles
struct DeviceSettingsView: View {
    let device: MIDIInputEndpoint
    @Binding var isPresented: Bool

    @State private var profileManager = ProfileManager.shared
    @State private var manager = MIDIConnectionManager.shared
    @State private var profile: DeviceProfile

    // Navigation
    @State private var showPresetList = false

    init(device: MIDIInputEndpoint, isPresented: Binding<Bool>) {
        self.device = device
        self._isPresented = isPresented

        // Load profile for this device
        let loadedProfile = ProfileManager.shared.profile(for: device.uniqueID)
        self._profile = State(initialValue: loadedProfile)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Device section
                Section {
                    HStack {
                        Text("System Name")
                        Spacer()
                        Text(device.displayName)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Nickname", text: Binding(
                        get: { profile.userNickname ?? "" },
                        set: { newValue in
                            profile.userNickname = newValue.isEmpty ? nil : newValue
                            saveProfile()
                        }
                    ))
                } header: {
                    Text("Device")
                }

                // MIDI section
                Section {
                    Picker("MIDI Channel", selection: Binding(
                        get: { profile.midiChannel },
                        set: { newValue in
                            profile.midiChannel = newValue
                            saveProfile()
                        }
                    )) {
                        ForEach(1...16, id: \.self) { channel in
                            Text("\(channel)").tag(channel)
                        }
                    }

                    Picker("Default Tab", selection: Binding(
                        get: { profile.defaultTab },
                        set: { newValue in
                            profile.defaultTab = newValue
                            saveProfile()
                        }
                    )) {
                        Text("Pads").tag(0)
                        Text("Keyboard").tag(1)
                    }
                } header: {
                    Text("MIDI")
                }

                // Velocity section
                VelocityCurveSection(
                    velocityCurve: Binding(
                        get: { profile.velocityCurve },
                        set: { newValue in
                            profile.velocityCurve = newValue
                            saveProfile()
                        }
                    ),
                    fixedVelocity: Binding(
                        get: { profile.fixedVelocity },
                        set: { newValue in
                            profile.fixedVelocity = newValue
                            saveProfile()
                        }
                    ),
                    midiChannel: profile.midiChannel
                )

                // Additional sections will be added in Task 2
            }
            .navigationTitle("Device Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func saveProfile() {
        profileManager.saveProfile(profile, for: device.uniqueID)
    }
}

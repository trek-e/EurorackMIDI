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

                // Pad mapping section
                PadMappingSection(
                    mappingMode: Binding(
                        get: { profile.padMappingMode },
                        set: { newValue in
                            profile.padMappingMode = newValue
                            saveProfile()
                        }
                    ),
                    padBaseNote: Binding(
                        get: { profile.padBaseNote },
                        set: { newValue in
                            profile.padBaseNote = newValue
                            saveProfile()
                        }
                    ),
                    customPadNotes: Binding(
                        get: { profile.customPadNotes },
                        set: { newValue in
                            profile.customPadNotes = newValue
                            saveProfile()
                        }
                    )
                )

                // Presets section
                Section {
                    NavigationLink {
                        PresetListView(device: device, isPresented: $isPresented)
                    } label: {
                        HStack {
                            Label("Presets", systemImage: "star.fill")
                            Spacer()
                            Text("\(profileManager.namedPresets.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Presets")
                } footer: {
                    Text("Save and apply preset configurations across devices.")
                }

                // Reset section
                Section {
                    Button(role: .destructive) {
                        resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Restore all settings to factory defaults for this device.")
                }
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
        #if os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        #else
        .frame(minWidth: 400, idealWidth: 500, minHeight: 500, idealHeight: 600)
        #endif
    }

    private func saveProfile() {
        profileManager.saveProfile(profile, for: device.uniqueID)
    }

    private func resetToDefaults() {
        // Create a new default profile for this device
        let defaultProfile = DeviceProfile(
            deviceUniqueID: device.uniqueID,
            deviceDisplayName: device.displayName,
            userNickname: profile.userNickname // Preserve nickname
        )

        profile = defaultProfile
        saveProfile()

        ToastManager.shared.show(message: "Settings reset to defaults", type: .info)
    }
}

import SwiftUI
import MIDIKitIO
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

/// Comprehensive settings UI for device profiles
struct DeviceSettingsView: View {
    let device: MIDIInputEndpoint
    @Binding var isPresented: Bool

    @State private var profileManager = ProfileManager.shared
    @State private var manager = MIDIConnectionManager.shared
    @State private var profile: DeviceProfile

    // Navigation
    @State private var showPresetSheet = false

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
                    #if os(iOS)
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
                    #else
                    Button {
                        showPresetSheet = true
                    } label: {
                        HStack {
                            Label("Presets", systemImage: "star.fill")
                            Spacer()
                            Text("\(profileManager.namedPresets.count)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    #endif
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
        .frame(minWidth: 500, minHeight: 600)
        .padding(.top, 8)
        .sheet(isPresented: $showPresetSheet) {
            PresetSheetView(device: device, isPresented: $showPresetSheet)
        }
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

// MARK: - macOS Preset Sheet

#if os(macOS)
/// Standalone preset sheet for macOS (avoids NavigationLink toolbar issues)
struct PresetSheetView: View {
    let device: MIDIInputEndpoint
    @Binding var isPresented: Bool

    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var toastManager = ToastManager.shared
    @State private var showCreatePreset = false
    @State private var showImportPicker = false
    @State private var presetToRename: NamedPreset?
    @State private var newPresetName = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header with toolbar
            HStack {
                Button("Done") {
                    isPresented = false
                }
                Spacer()
                Text("Presets")
                    .font(.headline)
                Spacer()
                Menu {
                    Button {
                        showCreatePreset = true
                    } label: {
                        Label("Create from Current", systemImage: "plus.circle")
                    }
                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            .padding()

            Divider()

            // Content
            if profileManager.namedPresets.isEmpty {
                ContentUnavailableView {
                    Label("No Presets", systemImage: "star.slash")
                } description: {
                    Text("Create a preset to save your current settings.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(profileManager.namedPresets) { preset in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.headline)
                            HStack(spacing: 8) {
                                Text(preset.tag.displayName)
                                Text("·")
                                Text("Ch \(preset.profile.midiChannel)")
                                Text("·")
                                Text(preset.profile.velocityCurve.displayName)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Apply") {
                            profileManager.applyPreset(preset, to: device.uniqueID)
                            toastManager.show(message: "Preset applied", type: .success)
                        }
                        .buttonStyle(.bordered)
                    }
                    .contextMenu {
                        Button {
                            profileManager.applyPreset(preset, to: device.uniqueID)
                            toastManager.show(message: "Preset applied", type: .success)
                        } label: {
                            Label("Apply", systemImage: "checkmark.circle")
                        }
                        Button {
                            exportPreset(preset)
                        } label: {
                            Label("Export JSON", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            presetToRename = preset
                            newPresetName = preset.name
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                            profileManager.deletePreset(id: preset.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .frame(width: 420, height: 400)
        .sheet(isPresented: $showCreatePreset) {
            CreatePresetSheet(
                device: device,
                isPresented: $showCreatePreset,
                onCreate: { name, tag in
                    let currentProfile = profileManager.profile(for: device.uniqueID)
                    profileManager.createPreset(name: name, from: currentProfile, tag: tag)
                    toastManager.show(message: "Preset created", type: .success)
                }
            )
        }
        .sheet(item: $presetToRename) { preset in
            RenamePresetSheet(
                preset: preset,
                newName: $newPresetName,
                onRename: { newName in
                    profileManager.renamePreset(id: preset.id, to: newName)
                    toastManager.show(message: "Preset renamed", type: .success)
                }
            )
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importPreset(result: result)
        }
    }

    private func exportPreset(_ preset: NamedPreset) {
        do {
            let data = try ProfileDocument.exportProfile(preset.profile)
            let filename = ProfileDocument.filename(for: preset.profile)

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = filename

            if savePanel.runModal() == .OK, let url = savePanel.url {
                try data.write(to: url)
                toastManager.show(message: "Preset exported", type: .success)
            }
        } catch {
            toastManager.show(message: "Export failed", type: .error)
        }
    }

    private func importPreset(result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            let profile = try ProfileDocument.importProfile(from: data)
            let name = url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
            profileManager.createPreset(name: name, from: profile, tag: .custom)
            toastManager.show(message: "Preset imported", type: .success)
        } catch {
            toastManager.show(message: "Import failed", type: .error)
        }
    }
}
#endif

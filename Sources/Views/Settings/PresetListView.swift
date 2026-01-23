import SwiftUI
import MIDIKitIO

/// List of named presets with CRUD and export/import functionality
struct PresetListView: View {
    let device: MIDIInputEndpoint
    @Binding var isPresented: Bool

    @State private var profileManager = ProfileManager.shared
    @State private var toastManager = ToastManager.shared
    @State private var presets: [NamedPreset] = []

    // UI state
    @State private var showCreatePreset = false
    @State private var showImportPicker = false
    @State private var presetToRename: NamedPreset?
    @State private var newPresetName = ""
    @State private var newPresetTag: PresetTag = .performance

    var body: some View {
        List {
            if presets.isEmpty {
                ContentUnavailableView {
                    Label("No Presets", systemImage: "star.slash")
                } description: {
                    Text("Create a preset to save your current settings for reuse on any device.")
                }
            } else {
                ForEach(presets) { preset in
                    PresetRow(preset: preset, device: device)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deletePreset(preset)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                presetToRename = preset
                                newPresetName = preset.name
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                applyPreset(preset)
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

                            Button(role: .destructive) {
                                deletePreset(preset)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Presets")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
        }
        .sheet(isPresented: $showCreatePreset) {
            CreatePresetSheet(
                device: device,
                isPresented: $showCreatePreset,
                onCreate: { name, tag in
                    createPreset(name: name, tag: tag)
                }
            )
        }
        .sheet(item: $presetToRename) { preset in
            RenamePresetSheet(
                preset: preset,
                newName: $newPresetName,
                onRename: { newName in
                    renamePreset(preset, to: newName)
                }
            )
        }
        .onAppear {
            loadPresets()
        }
    }

    // MARK: - Actions

    private func loadPresets() {
        presets = profileManager.namedPresets
    }

    private func createPreset(name: String, tag: PresetTag) {
        let currentProfile = profileManager.profile(for: device.uniqueID)
        profileManager.createPreset(name: name, from: currentProfile, tag: tag)
        loadPresets()
        toastManager.show(message: "Preset created", type: .success)
    }

    private func deletePreset(_ preset: NamedPreset) {
        profileManager.deletePreset(id: preset.id)
        loadPresets()
        toastManager.show(message: "Preset deleted", type: .info)
    }

    private func renamePreset(_ preset: NamedPreset, to newName: String) {
        profileManager.renamePreset(id: preset.id, to: newName)
        loadPresets()
        presetToRename = nil
        toastManager.show(message: "Preset renamed", type: .success)
    }

    private func applyPreset(_ preset: NamedPreset) {
        profileManager.applyPreset(preset, to: device.uniqueID)
        isPresented = false
        toastManager.show(message: "Preset applied", type: .success)
    }

    private func exportPreset(_ preset: NamedPreset) {
        do {
            let data = try ProfileDocument.exportProfile(preset.profile)
            let filename = ProfileDocument.filename(for: preset.profile)

            // Write to temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL)

            // Share using system share sheet
            #if os(iOS)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
            #endif

            toastManager.show(message: "Preset exported", type: .success)
        } catch {
            toastManager.show(message: "Export failed: \(error.localizedDescription)", type: .error)
        }
    }
}

// MARK: - Preset Row

struct PresetRow: View {
    let preset: NamedPreset
    let device: MIDIInputEndpoint

    @State private var profileManager = ProfileManager.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(preset.tag.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text("Ch \(preset.profile.midiChannel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(preset.profile.velocityCurve.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                profileManager.applyPreset(preset, to: device.uniqueID)
                ToastManager.shared.show(message: "Preset applied", type: .success)
            } label: {
                Text("Apply")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Create Preset Sheet

struct CreatePresetSheet: View {
    let device: MIDIInputEndpoint
    @Binding var isPresented: Bool
    let onCreate: (String, PresetTag) -> Void

    @State private var presetName = ""
    @State private var presetTag: PresetTag = .performance

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Preset Name", text: $presetName)
                        .autocorrectionDisabled()

                    Picker("Category", selection: $presetTag) {
                        ForEach(PresetTag.allCases, id: \.self) { tag in
                            Text(tag.displayName).tag(tag)
                        }
                    }
                } header: {
                    Text("New Preset")
                } footer: {
                    Text("Current device settings will be saved to this preset.")
                }
            }
            .navigationTitle("Create Preset")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(presetName, presetTag)
                        isPresented = false
                    }
                    .disabled(presetName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Rename Preset Sheet

struct RenamePresetSheet: View {
    let preset: NamedPreset
    @Binding var newName: String
    let onRename: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Preset Name", text: $newName)
                        .autocorrectionDisabled()
                } header: {
                    Text("Rename Preset")
                }
            }
            .navigationTitle("Rename")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onRename(newName)
                        dismiss()
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
    }
}

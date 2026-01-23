import SwiftUI

/// Main sequencer view containing grid, track selection, and controls
struct SequencerView: View {
    @ObservedObject private var patternManager = PatternManager.shared
    @State private var sequencerEngine = SequencerEngine.shared
    @State private var pattern: Pattern = Pattern.newPattern()
    @State private var selectedTrackIndex: Int = 0
    @State private var showPatternBrowser: Bool = false

    /// CRITICAL: Track where the current pattern was loaded from for proper persistence.
    /// When a pattern is loaded from the browser, this stores its bank/slot location.
    /// When nil, the pattern is a new unsaved pattern.
    @State private var editingPatternLocation: (bank: Int, slot: Int)?

    var body: some View {
        VStack(spacing: 0) {
            // Transport (always visible)
            TransportView()

            Divider()

            // Pattern info bar
            patternInfoBar

            Divider()

            // Track tabs
            if pattern.tracks.count > 1 {
                trackTabBar
            }

            // Piano roll grid
            if selectedTrackIndex < pattern.tracks.count {
                PianoRollGridView(
                    track: $pattern.tracks[selectedTrackIndex],
                    stepCount: pattern.stepCount
                )
            }

            Divider()

            // Bottom toolbar
            bottomToolbar
        }
        .sheet(isPresented: $showPatternBrowser) {
            PatternBrowserSheet(
                onSelect: { selectedPattern, location in
                    // Load pattern AND track where it came from
                    pattern = selectedPattern
                    editingPatternLocation = location
                    selectedTrackIndex = 0
                }
            )
        }
        .onChange(of: pattern) { _, newPattern in
            // Sync pattern to sequencer engine for playback
            sequencerEngine.activePattern = newPattern

            // Auto-save changes to the correct location
            if let location = editingPatternLocation {
                // Pattern was loaded from browser - save back to same location
                patternManager.savePattern(newPattern, bank: location.bank, slot: location.slot)
            }
            // If editingPatternLocation is nil, this is a new pattern - don't auto-save
        }
        .onAppear {
            // Set initial pattern for sequencer engine
            sequencerEngine.activePattern = pattern
        }
    }

    // MARK: - Pattern Info Bar

    private var patternInfoBar: some View {
        HStack {
            Button {
                showPatternBrowser = true
            } label: {
                HStack {
                    Circle()
                        .fill(pattern.color)
                        .frame(width: 12, height: 12)
                    Text(pattern.name)
                        .font(.headline)
                    // Show location indicator if pattern is from storage
                    if let location = editingPatternLocation {
                        Text("(\(patternManager.slotIdentifier(bank: location.bank, slot: location.slot)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Step count
            Picker("Steps", selection: $pattern.stepCount) {
                ForEach(Pattern.stepCountPresets, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            // Swing
            HStack {
                Text("Swing")
                    .font(.caption)
                Slider(value: $pattern.swing, in: 0...1)
                    .frame(width: 80)
                Text("\(Int(pattern.swing * 100))%")
                    .font(.caption)
                    .frame(width: 40)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Track Tab Bar

    private var trackTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(pattern.tracks.enumerated()), id: \.element.id) { index, track in
                    TrackTabButton(
                        track: track,
                        isSelected: index == selectedTrackIndex,
                        onSelect: { selectedTrackIndex = index },
                        onMuteToggle: { pattern.tracks[index].isMuted.toggle() },
                        onSoloToggle: { pattern.tracks[index].isSoloed.toggle() }
                    )
                }

                // Add track button
                Button {
                    pattern.addTrack()
                    selectedTrackIndex = pattern.tracks.count - 1
                } label: {
                    Image(systemName: "plus.circle")
                }
                .disabled(pattern.tracks.count >= 16)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            // Clear track
            Button {
                pattern.tracks[selectedTrackIndex].clearNotes()
            } label: {
                Label("Clear", systemImage: "trash")
            }

            Spacer()

            // Save pattern
            Button {
                saveCurrentPattern()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }

            Spacer()

            // New pattern (clears editingPatternLocation)
            Button {
                pattern = Pattern.newPattern()
                editingPatternLocation = nil  // New pattern has no location
                selectedTrackIndex = 0
            } label: {
                Label("New", systemImage: "plus")
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func saveCurrentPattern() {
        if let location = editingPatternLocation {
            // Already has a location - save there
            patternManager.savePattern(pattern, bank: location.bank, slot: location.slot)
            ToastManager.shared.show(
                message: "Saved to \(patternManager.slotIdentifier(bank: location.bank, slot: location.slot))",
                type: .success
            )
        } else {
            // New pattern - find first available slot
            if let location = patternManager.savePatternToFirstAvailable(pattern) {
                editingPatternLocation = location  // Now it has a location
                patternManager.currentPattern = pattern
                ToastManager.shared.show(
                    message: "Saved to \(patternManager.slotIdentifier(bank: location.bank, slot: location.slot))",
                    type: .success
                )
            } else {
                ToastManager.shared.show(message: "All slots full", type: .warning)
            }
        }
    }
}

// MARK: - Track Tab Button

struct TrackTabButton: View {
    let track: Track
    let isSelected: Bool
    let onSelect: () -> Void
    let onMuteToggle: () -> Void
    let onSoloToggle: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onSelect) {
                Text(track.name)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                    .foregroundColor(isSelected ? .white : .primary)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)

            // Mute button
            Button(action: onMuteToggle) {
                Text("M")
                    .font(.caption2.bold())
                    .foregroundColor(track.isMuted ? .red : .secondary)
            }
            .buttonStyle(.plain)

            // Solo button
            Button(action: onSoloToggle) {
                Text("S")
                    .font(.caption2.bold())
                    .foregroundColor(track.isSoloed ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Pattern Browser Sheet

/// Browser sheet that returns both pattern AND its location
struct PatternBrowserSheet: View {
    let onSelect: (Pattern, (bank: Int, slot: Int)) -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var patternManager = PatternManager.shared
    @State private var selectedBankIndex: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Bank selector
                Picker("Bank", selection: $selectedBankIndex) {
                    ForEach(0..<patternManager.banks.count, id: \.self) { index in
                        Text(patternManager.banks[index].name).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Pattern grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(0..<PatternBank.patternsPerBank, id: \.self) { slot in
                        PatternSlotButton(
                            pattern: patternManager.loadPattern(bank: selectedBankIndex, slot: slot),
                            slotLabel: patternManager.slotIdentifier(bank: selectedBankIndex, slot: slot),
                            onTap: {
                                if let pattern = patternManager.loadPattern(bank: selectedBankIndex, slot: slot) {
                                    onSelect(pattern, (bank: selectedBankIndex, slot: slot))
                                    dismiss()
                                }
                            },
                            onLongPress: { }
                        )
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Select Pattern")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// Note: PatternSlotButton is defined in PatternBrowserView.swift

// MARK: - Preview

#if DEBUG
struct SequencerView_Previews: PreviewProvider {
    static var previews: some View {
        SequencerView()
    }
}
#endif

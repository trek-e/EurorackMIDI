import SwiftUI

/// Transport controls for tempo and playback
struct TransportView: View {
    @State private var clockEngine = ClockEngine.shared
    @State private var manager = MIDIConnectionManager.shared
    @State private var bpmText: String = "120.0"
    @State private var isEditingBpm: Bool = false
    @FocusState private var bpmFieldFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Status bar
            statusBar

            // Main controls
            HStack(spacing: 16) {
                // Play/Stop Button
                playStopButton

                // BPM Display/Entry
                bpmControl

                // Tap Tempo Button
                tapTempoButton

                // PPQN Selector
                ppqnPicker

                // Clock Mode Picker
                clockModePicker
            }
            .padding()
        }
        .background(Color.secondary.opacity(0.1))
        .onAppear {
            bpmText = String(format: "%.1f", clockEngine.bpm)
        }
        .onChange(of: clockEngine.bpm) { _, newValue in
            if !isEditingBpm {
                bpmText = String(format: "%.1f", newValue)
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            // Transport state indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(transportStateColor)
                    .frame(width: 10, height: 10)
                Text(transportStateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Clock info
            if clockEngine.transportState == .playing {
                Text("Clock: \(String(format: "%.2f", clockEngine.clockIntervalMs))ms")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            Spacer()

            // MIDI connection status
            if manager.selectedDevice != nil {
                Image(systemName: "cable.connector")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "cable.connector")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var transportStateColor: Color {
        switch clockEngine.transportState {
        case .stopped: return .gray
        case .playing: return .green
        case .recording: return .red
        }
    }

    private var transportStateText: String {
        switch clockEngine.transportState {
        case .stopped: return "Stopped"
        case .playing: return "Playing"
        case .recording: return "Recording"
        }
    }

    // MARK: - Play/Stop Button

    private var playStopButton: some View {
        Button {
            togglePlayback()
        } label: {
            Image(systemName: clockEngine.transportState == .playing ? "stop.fill" : "play.fill")
                .font(.title)
                .foregroundColor(clockEngine.transportState == .playing ? .red : .green)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                )
        }
        .buttonStyle(.plain)
    }

    private func togglePlayback() {
        if clockEngine.transportState == .playing {
            clockEngine.stop()
        } else {
            clockEngine.start()
        }
    }

    // MARK: - BPM Control

    private var bpmControl: some View {
        VStack(spacing: 4) {
            Text("BPM")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                // Decrement
                Button {
                    adjustBpm(by: -1)
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                }
                .buttonStyle(.plain)

                // BPM Value (tap to edit)
                TextField("BPM", text: $bpmText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.center)
                    .font(.title.monospacedDigit())
                    .frame(width: 80)
                    .focused($bpmFieldFocused)
                    .onSubmit {
                        commitBpmEdit()
                    }
                    .onChange(of: bpmFieldFocused) { _, focused in
                        isEditingBpm = focused
                        if !focused {
                            commitBpmEdit()
                        }
                    }

                // Increment
                Button {
                    adjustBpm(by: 1)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func adjustBpm(by amount: Double) {
        let newBpm = clockEngine.bpm + amount
        clockEngine.bpm = max(20, min(300, newBpm))
    }

    private func commitBpmEdit() {
        if let value = Double(bpmText) {
            clockEngine.bpm = max(20, min(300, value))
        }
        bpmText = String(format: "%.1f", clockEngine.bpm)
    }

    // MARK: - Tap Tempo

    private var tapTempoButton: some View {
        Button {
            if let newBpm = clockEngine.processTap() {
                bpmText = String(format: "%.1f", newBpm)
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "hand.tap")
                    .font(.title2)
                Text("TAP")
                    .font(.caption2)
            }
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - PPQN Picker

    private var ppqnPicker: some View {
        VStack(spacing: 4) {
            Text("PPQN")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("PPQN", selection: Binding(
                get: { clockEngine.ppqn },
                set: { clockEngine.ppqn = $0 }
            )) {
                ForEach(ClockEngine.ppqnOptions, id: \.self) { ppqn in
                    Text("\(ppqn)").tag(ppqn)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
    }

    // MARK: - Clock Mode Picker

    private var clockModePicker: some View {
        VStack(spacing: 4) {
            Text("Clock")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Mode", selection: Binding(
                get: { clockEngine.clockMode },
                set: { clockEngine.clockMode = $0 }
            )) {
                ForEach(ClockMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)
        }
    }
}

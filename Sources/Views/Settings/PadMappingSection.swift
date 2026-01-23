import SwiftUI

/// Pad mapping mode configuration section
struct PadMappingSection: View {
    @Binding var mappingMode: PadMappingMode
    @Binding var padBaseNote: Int
    @Binding var customPadNotes: [Int]?

    var body: some View {
        Section {
            // Mode picker
            Picker("Mode", selection: $mappingMode) {
                ForEach(PadMappingMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            // Conditional sub-options based on mode
            switch mappingMode {
            case .gmDrum:
                Text("Standard General MIDI drum mapping (notes 36-51)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .chromaticBase:
                Stepper("Base Note: \(noteName(padBaseNote))", value: $padBaseNote, in: 0...127)
                Text("16 pads mapped chromatically from base note")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .custom:
                NavigationLink {
                    CustomPadMappingView(customPadNotes: $customPadNotes)
                } label: {
                    Text("Configure Custom Mapping")
                }
            }
        } header: {
            Text("Pad Mapping")
        }
    }

    private func noteName(_ midiNote: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midiNote / 12) - 1
        let note = noteNames[midiNote % 12]
        return "\(note)\(octave)"
    }
}

/// Custom pad mapping configuration view
struct CustomPadMappingView: View {
    @Binding var customPadNotes: [Int]?

    @State private var notes: [Int]

    init(customPadNotes: Binding<[Int]?>) {
        self._customPadNotes = customPadNotes
        // Initialize with existing custom notes or GM drum defaults
        let defaultNotes = Array(36..<52) // Notes 36-51
        self._notes = State(initialValue: customPadNotes.wrappedValue ?? defaultNotes)
    }

    var body: some View {
        Form {
            Section {
                ForEach(0..<16) { index in
                    HStack {
                        Text("Pad \(index + 1)")
                            .frame(width: 70, alignment: .leading)

                        Stepper("\(noteName(notes[index]))", value: $notes[index], in: 0...127)
                    }
                }
            } header: {
                Text("Custom Note Mapping")
            } footer: {
                Text("Set the MIDI note number for each of the 16 performance pads.")
            }

            Section {
                Button("Reset to GM Drums") {
                    notes = Array(36..<52)
                }

                Button("Save") {
                    customPadNotes = notes
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Custom Pad Mapping")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func noteName(_ midiNote: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midiNote / 12) - 1
        let note = noteNames[midiNote % 12]
        return "\(note)\(octave)"
    }
}

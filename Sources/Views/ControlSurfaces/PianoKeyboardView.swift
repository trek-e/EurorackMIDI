import SwiftUI
import MIDIKitCore

/// Single-octave piano keyboard with velocity-sensitive keys and octave controls
struct PianoKeyboardView: View {
    // MARK: - Properties

    @State private var manager = MIDIConnectionManager.shared
    @State private var octaveOffset: Int = 0

    // Layout constants
    private let whiteKeyWidth: CGFloat = 44
    private let whiteKeySpacing: CGFloat = 2
    private let blackKeyWidth: CGFloat = 30

    // Keyboard configuration
    private let baseOctave: Int = 4  // Base octave C4 (middle C)
    private let octaveSpan: Int = 1  // 1 octave (C4-B4 by default)
    private let whiteKeysPerOctave: Int = 7  // C D E F G A B

    // MARK: - Computed Properties

    /// White key MIDI notes based on current octave offset
    private var whiteKeyNotes: [UInt7] {
        let baseNote = UInt7(12 * (baseOctave + octaveOffset))  // C of the base octave
        let whiteKeyOffsets: [UInt7] = [0, 2, 4, 5, 7, 9, 11]  // C D E F G A B semitones

        var notes: [UInt7] = []
        for octave in 0..<octaveSpan {
            for offset in whiteKeyOffsets {
                let note = baseNote + UInt7(octave * 12) + offset
                notes.append(note)
            }
        }
        return notes
    }

    /// Black key data with MIDI notes and white key positions
    private var blackKeyData: [(note: UInt7, afterWhiteIndex: Int)] {
        let baseNote = UInt7(12 * (baseOctave + octaveOffset))  // C of the base octave
        // Black keys per octave: C#(after C), D#(after D), F#(after F), G#(after G), A#(after A)
        // Positions within white key array: 0, 1, 3, 4, 5
        let blackKeyPattern: [(semitoneOffset: UInt7, afterWhiteIndex: Int)] = [
            (1, 0), (3, 1), (6, 3), (8, 4), (10, 5)  // C#, D#, F#, G#, A#
        ]

        var keys: [(note: UInt7, afterWhiteIndex: Int)] = []
        for octave in 0..<octaveSpan {
            for (semitoneOffset, whiteIndexInOctave) in blackKeyPattern {
                let note = baseNote + UInt7(octave * 12) + semitoneOffset
                let whiteIndex = octave * whiteKeysPerOctave + whiteIndexInOctave
                keys.append((note: note, afterWhiteIndex: whiteIndex))
            }
        }
        return keys
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Octave controls
            OctaveControlsView(
                octaveOffset: $octaveOffset,
                baseOctave: baseOctave,
                octaveSpan: octaveSpan
            )
            .padding(.horizontal)

            // Keyboard
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // White keys layer
                    HStack(spacing: whiteKeySpacing) {
                        ForEach(whiteKeyNotes, id: \.self) { note in
                            PianoKeyView(
                                note: note,
                                isBlackKey: false,
                                manager: manager
                            )
                        }
                    }

                    // Black keys layer - each positioned absolutely
                    ForEach(blackKeyData, id: \.note) { data in
                        PianoKeyView(
                            note: data.note,
                            isBlackKey: true,
                            manager: manager
                        )
                        .offset(x: blackKeyXPosition(afterWhiteIndex: data.afterWhiteIndex))
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Helper Methods

    /// Calculate absolute X position for a black key
    /// Black key sits centered on the edge between white key at index and the next one
    private func blackKeyXPosition(afterWhiteIndex: Int) -> CGFloat {
        // Position of the right edge of the white key at this index
        let whiteKeyUnit = whiteKeyWidth + whiteKeySpacing
        let rightEdge = whiteKeyUnit * CGFloat(afterWhiteIndex + 1)

        // Center the black key on this edge
        return rightEdge - (blackKeyWidth / 2) - (whiteKeySpacing / 2)
    }
}

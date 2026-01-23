import SwiftUI
import MIDIKitCore

/// Single-octave piano keyboard with velocity-sensitive keys and octave controls
struct PianoKeyboardView: View {
    // MARK: - Properties

    @State private var manager = MIDIConnectionManager.shared
    @State private var octaveOffset: Int = 0

    // Layout constants - realistic piano key proportions
    private let whiteKeyWidth: CGFloat = 50
    private let whiteKeyHeight: CGFloat = 180
    private let whiteKeySpacing: CGFloat = 2
    private let blackKeyWidth: CGFloat = 32
    private let blackKeyHeight: CGFloat = 110

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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Octave controls
            OctaveControlsView(
                octaveOffset: $octaveOffset,
                baseOctave: baseOctave,
                octaveSpan: octaveSpan
            )
            .padding(.horizontal)

            // Keyboard container - centered horizontally
            HStack {
                Spacer()

                // Piano keyboard
                ZStack(alignment: .top) {
                    // White keys layer
                    HStack(spacing: whiteKeySpacing) {
                        ForEach(whiteKeyNotes, id: \.self) { note in
                            PianoKeyView(
                                note: note,
                                isBlackKey: false,
                                manager: manager,
                                whiteKeyWidth: whiteKeyWidth,
                                whiteKeyHeight: whiteKeyHeight,
                                blackKeyWidth: blackKeyWidth,
                                blackKeyHeight: blackKeyHeight
                            )
                        }
                    }

                    // Black keys layer - positioned over white keys
                    HStack(spacing: 0) {
                        ForEach(0..<whiteKeysPerOctave, id: \.self) { whiteIndex in
                            // Space for each white key position
                            ZStack(alignment: .trailing) {
                                Color.clear
                                    .frame(width: whiteKeyWidth + whiteKeySpacing)

                                // Add black key if this position has one
                                if hasBlackKey(afterWhiteIndex: whiteIndex) {
                                    PianoKeyView(
                                        note: blackKeyNote(afterWhiteIndex: whiteIndex),
                                        isBlackKey: true,
                                        manager: manager,
                                        whiteKeyWidth: whiteKeyWidth,
                                        whiteKeyHeight: whiteKeyHeight,
                                        blackKeyWidth: blackKeyWidth,
                                        blackKeyHeight: blackKeyHeight
                                    )
                                    .offset(x: blackKeyWidth / 2)
                                }
                            }
                        }
                    }
                }
                .background(Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
            }
            .padding()

            Spacer()
        }
    }

    // MARK: - Helper Methods

    /// Check if there's a black key after this white key index
    private func hasBlackKey(afterWhiteIndex: Int) -> Bool {
        // Black keys after: C(0), D(1), F(3), G(4), A(5)
        // No black keys after: E(2), B(6)
        return [0, 1, 3, 4, 5].contains(afterWhiteIndex)
    }

    /// Get the MIDI note for the black key after given white key index
    private func blackKeyNote(afterWhiteIndex: Int) -> UInt7 {
        let baseNote = UInt7(12 * (baseOctave + octaveOffset))
        let blackKeySemitones: [Int: UInt7] = [0: 1, 1: 3, 3: 6, 4: 8, 5: 10]
        return baseNote + (blackKeySemitones[afterWhiteIndex] ?? 0)
    }
}

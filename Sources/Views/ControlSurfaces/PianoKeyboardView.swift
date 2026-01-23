import SwiftUI
import MIDIKitCore

/// 2-octave piano keyboard (C3-B4) with velocity-sensitive keys
struct PianoKeyboardView: View {
    // MARK: - Properties

    @State private var manager = MIDIConnectionManager.shared

    // Layout constants
    private let whiteKeyWidth: CGFloat = 40
    private let whiteKeySpacing: CGFloat = 2
    private let blackKeyWidth: CGFloat = 28

    // White keys: C D E F G A B (repeated for 2 octaves)
    // MIDI notes for white keys (C3-B4)
    private let whiteKeyNotes: [UInt7] = [
        48, 50, 52, 53, 55, 57, 59,  // C3, D3, E3, F3, G3, A3, B3
        60, 62, 64, 65, 67, 69, 71   // C4, D4, E4, F4, G4, A4, B4
    ]

    // Black keys with their white key index positions
    // Each tuple: (MIDI note, white key index it follows)
    // Pattern per octave: C#(after 0), D#(after 1), F#(after 3), G#(after 4), A#(after 5)
    private let blackKeyData: [(note: UInt7, afterWhiteIndex: Int)] = [
        (49, 0), (51, 1), (54, 3), (56, 4), (58, 5),   // Octave 1: C#3, D#3, F#3, G#3, A#3
        (61, 7), (63, 8), (66, 10), (68, 11), (70, 12) // Octave 2: C#4, D#4, F#4, G#4, A#4
    ]

    // MARK: - Body

    var body: some View {
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
